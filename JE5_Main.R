#==============================================================================================
# JE5 - Quinta convocatoria Jovenes a la E
# Mecanismo de seleccion y aprobacion de las ofertas tecnicas
# Lineamiento operativo L45_EP v1 (aprobado 2026-05-04)
# 2026-05-08
#==============================================================================================
# ORQUESTADOR PRINCIPAL (Entry Point)
#==============================================================================================

#-----------------------------------------
# ACTIVAR RENV (Gestion de dependencias)
#-----------------------------------------
source("renv/activate.R")

#-----------------------------------------
# CONFIGURACION DEL ENTORNO
#-----------------------------------------
library(sqldf)
library(expss)
library(readr)
library(readxl)
library(dplyr)
library(tidyr)
library(eeptools)
library(openxlsx)
library(lubridate)
options(scipen=999)

#-----------------------------------------
# CARGAR INSUMOS PARA EL CALCULO DE OFERTA
#-----------------------------------------
load("data/JE5_Insumo.RData")

#-----------------------------------------
# EJECUTAR MODULOS
#-----------------------------------------

# Modulo 1: Habilitacion de IES y programas (convenio JE4 + ejecutoria SNIES)
source("modules/1_habilitacion.R")

# Modulo 2: Distribucion del presupuesto por IES (proporcional a valor convenio JE4)
source("modules/2_presupuesto_ies.R")

# Modulo 3: Asignacion ISOES - Paso 2 (intra-IES) y Paso 3 (excedente por nivel)
source("modules/3_asignacion_isoes.R")

# Modulo 4: Componente de alta demanda social (10% + excedente ISOES)
source("modules/4_demanda_social.R")

# Modulo 5: Consolidacion y exportacion de resultados a Excel
source("modules/5_exportacion.R")
