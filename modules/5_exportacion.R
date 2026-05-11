#==============================================================================================
# MODULO 5: CONSOLIDACION Y EXPORTACION DE RESULTADOS
#==============================================================================================
# Une la asignacion del mecanismo ISOES (Modulo 3) con la del componente de
# demanda social (Modulo 4) y exporta un libro Excel con las hojas:
#   - JE5_PROGRAMAS:    resultado detallado por programa
#   - EXCEDENTES_NIVEL: saldo final de la bolsa comun por Nivel
#   - IES_NIVEL:        auditoria de la bolsa IES x Nivel (Paso 1)
#   - CINE:             auditoria de la bolsa CINE x Nivel (componente demanda social)
#----------------------------------------------------------------------------------------------

RESULTADOS <- merge(
  x = ORDENAMIENTO_PROG,
  y = OFERTA_DEMANDA_SOCIAL[, c("ORDENAMIENTO_PROG", "EVALUADO_DEMANDA_SOCIAL",
                                "CUPO_ASIGNADO_CINE", "COSTO_CUPOS_ASIGNADO_CINE",
                                "CUPO_ASIGNADO_NIVEL_DH", "COSTO_CUPOS_ASIGNADO_NIVEL_DH",
                                "CUPOS_ASIGNADOS_DEMANDA_SOCIAL",
                                "COSTO_CUPOS_DEMANDA_SOCIAL")],
  by = "ORDENAMIENTO_PROG",
  all.x = TRUE
)

# Imputacion de programas no evaluados en demanda social
RESULTADOS[is.na(RESULTADOS$EVALUADO_DEMANDA_SOCIAL), "EVALUADO_DEMANDA_SOCIAL"] <- "N"
RESULTADOS[RESULTADOS$EVALUADO_DEMANDA_SOCIAL == "N", "CUPO_ASIGNADO_CINE"]          <- 0
RESULTADOS[RESULTADOS$EVALUADO_DEMANDA_SOCIAL == "N", "CUPO_ASIGNADO_NIVEL_DH"]      <- 0
RESULTADOS[RESULTADOS$EVALUADO_DEMANDA_SOCIAL == "N", "COSTO_CUPOS_ASIGNADO_CINE"]   <- 0
RESULTADOS[RESULTADOS$EVALUADO_DEMANDA_SOCIAL == "N", "COSTO_CUPOS_ASIGNADO_NIVEL_DH"] <- 0
RESULTADOS[is.na(RESULTADOS$CUPOS_ASIGNADOS_DEMANDA_SOCIAL), "CUPOS_ASIGNADOS_DEMANDA_SOCIAL"] <- 0
RESULTADOS[is.na(RESULTADOS$COSTO_CUPOS_DEMANDA_SOCIAL),    "COSTO_CUPOS_DEMANDA_SOCIAL"]    <- 0

# Totales finales (ISOES + demanda social)
RESULTADOS$CUPOS_ASIGNADOS_TOTAL <-
  RESULTADOS$CUPOS_ASIGNADOS_MECANISMO_ACTUAL + RESULTADOS$CUPOS_ASIGNADOS_DEMANDA_SOCIAL
RESULTADOS$COSTO_CUPOS_ASIGNADOS_TOTAL <-
  RESULTADOS$CUPOS_ASIGNADOS_TOTAL * RESULTADOS$TOTAL_VALOR_COHORTE_ATENEA

#-------------------------------------------------------------------------------
# Pruebas de cierre presupuestal
#-------------------------------------------------------------------------------
print(paste("Cupos asignados (ISOES):",        sum(RESULTADOS$CUPOS_ASIGNADOS_MECANISMO_ACTUAL)))
print(paste("Cupos asignados (Demanda Social):", sum(RESULTADOS$CUPOS_ASIGNADOS_DEMANDA_SOCIAL)))
print(paste("Cupos asignados TOTAL:",          sum(RESULTADOS$CUPOS_ASIGNADOS_TOTAL)))
print(paste("Costo TOTAL:",
            format(sum(RESULTADOS$COSTO_CUPOS_ASIGNADOS_TOTAL),
                   big.mark = ".", decimal.mark = ",", nsmall = 2)))
print(paste("Excedente final:",
            format(sum(EXCEDENTE_NIVEL$VALOR_SOBRANTE_NIVEL),
                   big.mark = ".", decimal.mark = ",", nsmall = 2)))
print(paste("Diferencia vs PPTO_GENERAL:",
            PPTO_GENERAL - (sum(RESULTADOS$COSTO_CUPOS_ASIGNADOS_TOTAL) +
                              sum(EXCEDENTE_NIVEL$VALOR_SOBRANTE_NIVEL))))

#-------------------------------------------------------------------------------
# Exportacion a Excel
#-------------------------------------------------------------------------------
OUTPUT_FILE <- file.path("output",
                        paste0("JE5_OFERTA_VF_", format(Sys.Date(), "%Y%m%d"), ".xlsx"))

write.xlsx(RESULTADOS, OUTPUT_FILE, sheetName = "JE5_PROGRAMAS", append = TRUE)
wb <- loadWorkbook(OUTPUT_FILE)
addWorksheet(wb, "EXCEDENTES_NIVEL"); writeData(wb, "EXCEDENTES_NIVEL", EXCEDENTE_NIVEL)
addWorksheet(wb, "IES_NIVEL");        writeData(wb, "IES_NIVEL",        IES)
addWorksheet(wb, "CINE");             writeData(wb, "CINE",             CINE_NIVEL)
saveWorkbook(wb, OUTPUT_FILE, overwrite = TRUE)

print(paste("Archivo exportado:", OUTPUT_FILE))
