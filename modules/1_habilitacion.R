#==============================================================================================
# MODULO 1: HABILITACION DE IES Y PROGRAMAS
#==============================================================================================
# Aplica los criterios habilitantes del lineamiento operativo (numeral 5.4.1.3):
#   a) IES con convenio vigente JE4 (Invitacion Publica ATENEA-IA-JE-003-2025)
#   b) Programa con vigencia SNIES > 2026-12-06 (6 meses desde publicacion lineamiento)
#   c) Exclusion explicita de programas de Medicina
#----------------------------------------------------------------------------------------------

#----------------------------------------------------------
# ACTUALIZACION DE PERIODOS Y COSTOS desde 2026-2
#----------------------------------------------------------
# Pegue de costos actualizados sobre el listado de oferta
LISTADO_OFERTA_PROPUESTA <- merge(
  x  = LISTADO_OFERTA_PROPUESTA[, c(1:21)],
  y  = JE5_InsumoCostos[, c(1, 35, 53:67)],
  by = "ID",
  all.x = TRUE
)

#----------------------------------------------------------
# HABILITACION POR EJECUTORIA SNIES
# Programa habilitado si FECHA_EJECUTORIA + VIGENCIA_ANNOS > 2026-12-06
# Corte SNIES: 30 de abril de 2026
#----------------------------------------------------------
HABILITACION_EJECUTORIA <- unique(SNIES_PROGRAMAS[, c(8, 28, 18, 19, 30, 31)])
HABILITACION_EJECUTORIA <- merge(
  x = LISTADO_OFERTA_PROPUESTA[, c(1:22)],
  y = HABILITACION_EJECUTORIA,
  by.x  = "CÓDIGO_SNIES_DEL_PROGRAMA_A_OFERTAR",
  by.y  = "CÓDIGO_SNIES_DEL_PROGRAMA",
  all.x = TRUE
)

# Normalizacion del separador decimal
HABILITACION_EJECUTORIA$VIGENCIA_AÑOS <- chartr(",", ".", HABILITACION_EJECUTORIA$VIGENCIA_AÑOS)

# Fecha de fin de ejecutoria
HABILITACION_EJECUTORIA$FECHA_EJECUTORIA_FIN <- HABILITACION_EJECUTORIA$FECHA_EJECUTORIA +
  years(as.integer(HABILITACION_EJECUTORIA$VIGENCIA_AÑOS))

# Regla de habilitacion por ejecutoria
HABILITACION_EJECUTORIA$HABILITADO_EJECUTORIA <- "HABILITADO"
HABILITACION_EJECUTORIA[is.na(HABILITACION_EJECUTORIA$FECHA_EJECUTORIA_FIN), "HABILITADO_EJECUTORIA"] <- "NO_HABILITADO"
HABILITACION_EJECUTORIA[!is.na(HABILITACION_EJECUTORIA$FECHA_EJECUTORIA_FIN) &
                         HABILITACION_EJECUTORIA$FECHA_EJECUTORIA_FIN <= "2026-12-06",
                       "HABILITADO_EJECUTORIA"] <- "NO_HABILITADO"

# Restriccion explicita: programas de Medicina excluidos
HABILITACION_EJECUTORIA[HABILITACION_EJECUTORIA$CÓDIGO_SNIES_DEL_PROGRAMA_A_OFERTAR %in%
                         c(20603, 1807, 5116, 21465, 4911),
                       "HABILITADO_EJECUTORIA"] <- "NO_HABILITADO"
cro(HABILITACION_EJECUTORIA$HABILITADO_EJECUTORIA)

# Pegue de la habilitacion al listado de oferta
LISTADO_OFERTA_PROPUESTA <- merge(
  x = LISTADO_OFERTA_PROPUESTA,
  y = HABILITACION_EJECUTORIA[, c("ID", "FECHA_EJECUTORIA", "VIGENCIA_AÑOS",
                                  "FECHA_EJECUTORIA_FIN", "HABILITADO_EJECUTORIA")],
  by = "ID",
  all.x = TRUE
)
rm(HABILITACION_EJECUTORIA)

#----------------------------------------------------------
# HABILITACION POR CONVENIO JE4
# Solo IES con convenio vigente en la cuarta convocatoria (ATENEA-IA-JE-003-2025)
#----------------------------------------------------------
OFERTAS_CONVENIO_JE4 <- merge(
  x = LISTADO_OFERTA_PROPUESTA,
  y = JE4_Valor_Convenios[, c("CODIGO_SNIES_IES", "CONVENIO")],
  by.x = "COD_IES",
  by.y = "CODIGO_SNIES_IES",
  all  = FALSE
)
LISTADO_OFERTA_PROPUESTA <- merge(
  x = LISTADO_OFERTA_PROPUESTA,
  y = OFERTAS_CONVENIO_JE4[, c("ID", "CONVENIO")],
  by = "ID",
  all.x = TRUE
)
rm(OFERTAS_CONVENIO_JE4)

#==============================================================================================
# AJUSTE DE NIVEL DE FORMACION (Universitario / TyT)
#==============================================================================================
LISTADO_OFERTA_PROPUESTA$NIVEL_PROGRAMA_SNIES_AJUSTE <- "UNIVERSITARIO"
LISTADO_OFERTA_PROPUESTA[LISTADO_OFERTA_PROPUESTA$NIVEL_DE_FORMACIÓN != "Universitario",
                        "NIVEL_PROGRAMA_SNIES_AJUSTE"] <- "TYT"
cro(LISTADO_OFERTA_PROPUESTA$NIVEL_DE_FORMACIÓN,
    LISTADO_OFERTA_PROPUESTA$NIVEL_PROGRAMA_SNIES_AJUSTE)
