#==============================================================================================
# MODULO 2: DISTRIBUCION DEL PRESUPUESTO POR IES
#==============================================================================================
# Implementa los pasos 0 y 1 del lineamiento (numerales 5.1 y 5.4.1.4):
#   - 90% del presupuesto se asigna por el mecanismo ISOES
#   - 10% se reserva para el componente de alta demanda social
#   - La bolsa por IES se calcula como proporcion del valor del convenio JE4:
#         Recursos_IES_i = (Valor_convenio_i / Sum(Valor_convenio)) * 90% * PPTO_GENERAL
#   - Distribucion intra-IES por nivel: 95% Universitario / 5% TyT cuando hay ambos
#----------------------------------------------------------------------------------------------

#===============================================================================
# Paso 0: DISTRIBUCION GENERAL DEL PRESUPUESTO
#===============================================================================

# Presupuesto total disponible para la quinta convocatoria
# Fuente: adicion FDL Bosa, Kennedy, Ciudad Bolivar, Teusaquillo, Usme, Usaquen, Los Martires
PPTO_GENERAL         <- 17753034702
PPTO_MecanismoActual <- PPTO_GENERAL * 0.9    # 90% mecanismo ISOES
PPTO_DemandaSocial   <- PPTO_GENERAL * 0.1    # 10% componente de alta demanda social

#===============================================================================
# Paso 1: Bolsa de recursos por IES segun % de Valor Convenio JE4
#===============================================================================

# Distribucion proporcional al valor del convenio suscrito en JE4
JE4_Valor_Convenios$DISTRIBUCION <-
  JE4_Valor_Convenios$`VALOR TOTAL` / sum(JE4_Valor_Convenios$`VALOR TOTAL`)

# Valor monetario asignado a cada IES (90% del PPTO_GENERAL)
JE4_Valor_Convenios$VALOR_DISTRIBUCION_IES <-
  PPTO_MecanismoActual * JE4_Valor_Convenios$DISTRIBUCION

#===============================================================================
# Paso 1.1: Distribucion intra-IES por Nivel (95% Universitario / 5% TyT)
#===============================================================================

# Total de ofertas habilitadas por IES y nivel
PRESUPUESTO_IES_NIVEL <- LISTADO_OFERTA_PROPUESTA[
  LISTADO_OFERTA_PROPUESTA$PROGRAMA_HABILITADO == "Habilitado" &
    LISTADO_OFERTA_PROPUESTA$HABILITADO_EJECUTORIA == "HABILITADO" &
    !is.na(LISTADO_OFERTA_PROPUESTA$CONVENIO),
] %>%
  group_by(COD_IES, NIVEL_PROGRAMA_SNIES_AJUSTE) %>%
  summarise(OFERTA_IES_NIVEL = n())

# Cruzar con presupuesto IES
PRESUPUESTO_IES_NIVEL <- merge(
  x = PRESUPUESTO_IES_NIVEL,
  y = JE4_Valor_Convenios[, c("CODIGO_SNIES_IES", "VALOR_DISTRIBUCION_IES")],
  by.x = "COD_IES",
  by.y = "CODIGO_SNIES_IES",
  all  = FALSE
)

# Identificar si la IES tiene uno o dos niveles ofertados
IES <- PRESUPUESTO_IES_NIVEL %>%
  group_by(COD_IES) %>%
  summarise(TOTAL_REGISTROS_IES_NIVEL = n())

PRESUPUESTO_IES_NIVEL <- merge(
  x = PRESUPUESTO_IES_NIVEL,
  y = IES,
  by  = "COD_IES",
  all = FALSE
)

# Distribucion por nivel:
#   IES con UNICO nivel  -> 100% al nivel ofertado
#   IES con AMBOS niveles -> 95% UNIVERSITARIO / 5% TYT
PRESUPUESTO_IES_NIVEL$DISTRIBUCION_IES_NIVEL <- 1
PRESUPUESTO_IES_NIVEL[PRESUPUESTO_IES_NIVEL$TOTAL_REGISTROS_IES_NIVEL == 2 &
                       PRESUPUESTO_IES_NIVEL$NIVEL_PROGRAMA_SNIES_AJUSTE == "UNIVERSITARIO",
                     "DISTRIBUCION_IES_NIVEL"] <- 0.95
PRESUPUESTO_IES_NIVEL[PRESUPUESTO_IES_NIVEL$TOTAL_REGISTROS_IES_NIVEL == 2 &
                       PRESUPUESTO_IES_NIVEL$NIVEL_PROGRAMA_SNIES_AJUSTE == "TYT",
                     "DISTRIBUCION_IES_NIVEL"] <- 0.05

# Valor final por IES x Nivel
PRESUPUESTO_IES_NIVEL$VALOR_DISTRIBUCION_IES_NIVEL <-
  PRESUPUESTO_IES_NIVEL$VALOR_DISTRIBUCION_IES *
  PRESUPUESTO_IES_NIVEL$DISTRIBUCION_IES_NIVEL
