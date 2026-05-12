# Mecanismo de Asignacion de Cupos: Quinta Convocatoria Jovenes a la E (JE5)

<div align="center">

![R Version](https://img.shields.io/badge/R-4.5.1%2B-blue?style=for-the-badge&logo=r)
![License](https://img.shields.io/badge/Licencia-CC%20BY-green?style=for-the-badge)
![Status](https://img.shields.io/badge/Estado-Producci%C3%B3n%20Auditada-success?style=for-the-badge)
![Reproducibilidad](https://img.shields.io/badge/Reproducibilidad-renv%20%7C%20Seed-orange?style=for-the-badge)

**Agencia Distrital para la Educacion Superior, la Ciencia y la Tecnologia (ATENEA)**
*Subgerencia de Analisis de Informacion y Gestion del Conocimiento*

</div>

---

## Tabla de Contenidos

1. [Ficha de Transparencia Algoritmica](#1-ficha-de-transparencia-algoritmica)
2. [Arquitectura del Proyecto](#2-arquitectura-del-proyecto)
3. [Requisitos Tecnicos](#3-requisitos-tecnicos)
4. [Logica Detallada del Algoritmo](#4-logica-detallada-del-algoritmo)
    * [Fase 1: Habilitacion de IES y Programas](#fase-1-habilitacion-de-ies-y-programas-modulo-1)
    * [Fase 2: Distribucion del Presupuesto por IES](#fase-2-distribucion-del-presupuesto-por-ies-modulo-2)
    * [Fase 3: Asignacion por Mecanismo ISOES](#fase-3-asignacion-por-mecanismo-isoes-modulo-3)
    * [Fase 4: Componente de Alta Demanda Social](#fase-4-componente-de-alta-demanda-social-modulo-4)
    * [Fase 5: Consolidacion y Exportacion](#fase-5-consolidacion-y-exportacion-modulo-5)
5. [Diferencias frente al algoritmo JE4](#5-diferencias-frente-al-algoritmo-je4)
6. [Diccionario de Datos](#6-diccionario-de-datos)
7. [Instrucciones de Ejecucion](#7-instrucciones-de-ejecucion)
8. [Garantia de Reproducibilidad](#8-garantia-de-reproducibilidad)
9. [Preguntas Frecuentes y Glosario](#9-preguntas-frecuentes-y-glosario)
10. [Uso del Codigo](#10-uso-del-codigo)

---

## 1. Ficha de Transparencia Algoritmica

| Campo | Contenido |
|---|---|
| **Tipo de algoritmo** | Procesamiento de datos (regla de negocio deterministica). No usa aprendizaje automatico ni inferencia estadistica. |
| **Nombre** | Seleccion de oferta de programas academicos - quinta convocatoria "Jovenes a la E" (JE5). |
| **Objetivo** | Aplicar los criterios del lineamiento operativo para seleccionar la cantidad de cupos a financiar por cada programa presentado por las IES con convenio JE4 vigente. |
| **Funcion institucional** | Asignar cupos a programas de niveles Tecnico, Tecnologico y Universitario del programa de beneficios de ATENEA "Jovenes a la E", que promueve acceso y permanencia en educacion superior y formacion para el trabajo de ciclo largo de los bachilleres de Bogota. |
| **Estado** | En implementacion (vigente para la quinta convocatoria - mayo 2026). |
| **Datos personales** | No procesa datos personales. Opera sobre atributos de IES y programas (codigos SNIES, costos, capacidad, ISOES, TIR). |
| **Tipo de datos** | Identificadores SNIES (IES y programa), costos por semestre, cupos por capacidad, ISOES, TIR, ejecutoria SNIES, valor convenio JE4, demanda historica por CINE F. Ver [Diccionario de Datos](#6-diccionario-de-datos). |
| **Desarrollador** | Agencia Distrital para la Educacion Superior, la Ciencia y la Tecnologia (ATENEA) - Subgerencia de Analisis de Informacion y Gestion del Conocimiento (SAIGC). |
| **Insumo normativo** | [Lineamiento Operativo L45_EP v1](docs/) (aprobado 2026-05-04). |
| **Presupuesto** | $17.753.034.702 COP, provenientes de la adicion de los Fondos de Desarrollo Local (Bosa, Kennedy, Ciudad Bolivar, Teusaquillo, Usme, Usaquen, Los Martires) a los convenios JE4. |

**Principios de diseno:**

* **Transparencia:** reglas de negocio codificadas explicitamente, sin "cajas negras".
* **Auditabilidad:** trazas intermedias en consola y libro Excel con hojas de auditoria presupuestal.
* **Reproducibilidad:** semilla fija `set.seed(20260427)` y dependencias congeladas con `renv`.

**Como funciona (resumen):** el algoritmo (1) **habilita** la oferta cruzando convenio JE4 y ejecutoria SNIES, (2) **reparte el presupuesto** en bolsas (90% mecanismo ISOES + 10% demanda social; dentro de ISOES, una bolsa por IES proporcional al valor de su convenio JE4), (3) **ordena los programas** por ISOES > costo de cohorte > capacidad > semilla, (4) **asigna cupos** hasta donde alcance la bolsa, (5) **reasigna excedentes** entre IES del mismo nivel y luego al componente de demanda social. El detalle paso a paso esta en la [Seccion 4](#4-logica-detallada-del-algoritmo).

---

## 2. Arquitectura del Proyecto

El codigo esta organizado en una arquitectura modular secuencial. Cada modulo aborda una fase del lineamiento operativo y puede auditarse por separado.

```text
AlgoritmoJE5_Oferta/
|
|-- JE5_Main.R                # ORQUESTADOR PRINCIPAL (Entry Point)
|-- README.md                 # Documentacion (este archivo)
|-- LICENSE                   # CC BY - Obra institucional ATENEA
|-- renv.lock                 # Manifiesto de dependencias exactas
|
|-- data/                     # Insumos
|   +-- JE5_Insumo.RData      # Oferta, costos, SNIES, convenios JE4, demanda historica
|
|-- output/                   # Resultados generados
|   +-- JE5_OFERTA_VF_YYYYMMDD.xlsx
|
|-- docs/                     # Lineamiento operativo y soporte
|   +-- l45_ep_lineamiento_operativo_..._JE5.pdf
|
+-- modules/                  # Logica de negocio
    |-- 1_habilitacion.R      # Habilitacion IES (convenio JE4) + programas (ejecutoria SNIES)
    |-- 2_presupuesto_ies.R   # Bolsa IES proporcional al valor convenio JE4
    |-- 3_asignacion_isoes.R  # Paso 2 (intra-IES) y Paso 3 (excedente por Nivel)
    |-- 4_demanda_social.R    # Componente 10% + excedente ISOES, bolsas CINE x Nivel
    +-- 5_exportacion.R       # Consolidacion y exportacion XLSX
```

---

## 3. Requisitos Tecnicos

* **R** 4.5.1 o superior y **renv** 1.1.5+.
* Dependencias declaradas en `renv.lock` y restauradas con `renv::restore()`.

Librerias principales: `dplyr`, `tidyr`, `sqldf`, `readr`, `readxl`, `openxlsx`, `lubridate`, `expss`, `eeptools`.

---

## 4. Logica Detallada del Algoritmo

### Fase 1: Habilitacion de IES y Programas (Modulo 1)

**Archivo:** `modules/1_habilitacion.R` - **Referencia:** Lineamiento operativo, numeral 5.4.1.3.

Una IES y sus programas se consideran habilitados solo si cumplen los tres criterios:

1. **Convenio vigente JE4:** la IES debe contar con convenio activo de la Invitacion Publica ATENEA-IA-JE-003-2025. Se cruza el listado de oferta contra `JE4_Valor_Convenios`.
2. **Ejecutoria SNIES vigente:** `FECHA_EJECUTORIA + VIGENCIA_AÑOS > 2026-12-06`. Corte SNIES: 30 de abril de 2026.
3. **Exclusion explicita de Medicina:** SNIES 20603, 1807, 5116, 21465 y 4911.

El nivel de formacion se homologa a dos categorias: `UNIVERSITARIO` y `TYT` (Tecnico/Tecnologico).

---

### Fase 2: Distribucion del Presupuesto por IES (Modulo 2)

**Archivo:** `modules/2_presupuesto_ies.R` - **Referencia:** Lineamiento operativo, numerales 5.1 y 5.4.1.4 Paso 1.

| Componente | % | Valor |
|---|---:|---|
| Mecanismo ISOES | 90% | $15.977.731.231,80 |
| Componente de Demanda Social | 10% | $1.775.303.470,20 |

**Bolsa por IES** (Paso 1), proporcional al valor del convenio JE4:

$$Recursos_{IES_i} = \left(\frac{ValorConvenio_{IES_i}}{\sum_{i=1}^{n} ValorConvenio_{IES_i}}\right) \times 90\% \times PPTO\_GENERAL$$

**Distribucion intra-IES por nivel** (Paso 1.1): 100% al nivel ofertado si la IES tiene un solo nivel; 95% Universitario / 5% TyT si tiene ambos.

---

### Fase 3: Asignacion por Mecanismo ISOES (Modulo 3)

**Archivo:** `modules/3_asignacion_isoes.R` - **Referencia:** Lineamiento operativo, numeral 5.4.1.4 Pasos 2 y 3.

**Ordenamiento de programas (estricto y deterministico):**

1. `desc(ISOES_PROGRAMA)` - mayor ISOES primero (indice ponderado de pertinencia, calidad y permanencia).
2. `TOTAL_VALOR_COHORTE_ATENEA` asc - menor costo primero (Nota del lineamiento: "se priorizara el programa con menor costo").
3. `desc(CUPOS_SEGUN_CAPACIDAD)` - mayor capacidad primero.
4. `SEMILLA` - desempate aleatorio reproducible.

**Paso 2 - Asignacion intra-IES (pseudocodigo):**

```text
PARA CADA (IES, Nivel) EN ORDEN:
    PARA CADA Programa EN ranking_intra_IES:

        CUPO_OFERTADO  = CUPOS_SEGUN_CAPACIDAD
        CUPO_CALCULADO = Bolsa_IES_Nivel_remanente / TOTAL_VALOR_COHORTE_ATENEA

        SI (CUPO_CALCULADO >= CUPO_OFERTADO):
            Asignar CUPO_OFERTADO
        SINO SI (CUPO_CALCULADO >= 1):
            Asignar floor(CUPO_CALCULADO)
        SINO:
            Sin asignacion en este paso
```

**Paso 3 - Reasignacion del excedente por Nivel:** los saldos de cada IES se agrupan en una bolsa comun por Nivel (Universitario / TyT). Se recorre nuevamente la lista en el mismo orden ISOES y se asignan cupos a programas con `CUPO_PENDIENTES > 0`, hasta agotar la bolsa o los programas.

---

### Fase 4: Componente de Alta Demanda Social (Modulo 4)

**Archivo:** `modules/4_demanda_social.R` - **Referencia:** Lineamiento operativo, numeral 5.4.1.5.

**Bolsa inicial:** 10% del PPTO_GENERAL **mas** todo el excedente del mecanismo ISOES.

**Indicador de demanda social** (calculado por nivel sobre datos historicos JE2):

$$Demanda\_Social_{CINE\_i} = \frac{NúmeroInscritos\ en\ CINE\ F\ Campo\ Detallado\ i}{NúmeroCupos\ en\ CINE\ F\ Campo\ Detallado\ i}$$

**Universo elegible** (filtros en cascada):

1. Programas con `< 6 cupos` asignados en ISOES (agregando por CINE F).
2. `CUPO_PENDIENTES > 0` segun capacidad.
3. Indicador de demanda social disponible.
4. Por encima del percentil 50 del indicador en su nivel.

**Distribucion:** 95% Universitario / 5% TyT. Dentro de cada nivel, las bolsas se reparten por **CINE x Nivel** proporcionalmente a los inscritos historicos (`DH_INSCRITOS`).

**Recorrido:** identico al Modulo 3 (intra-CINE primero, luego excedente por Nivel).

---

### Fase 5: Consolidacion y Exportacion (Modulo 5)

**Archivo:** `modules/5_exportacion.R`

1. Merge de resultados ISOES + Demanda Social por `ORDENAMIENTO_PROG`.
2. `CUPOS_ASIGNADOS_TOTAL = ISOES + Demanda_Social`; `COSTO = CUPOS * TOTAL_VALOR_COHORTE_ATENEA`.
3. Pruebas de cierre presupuestal en consola.
4. Exportacion a `output/JE5_OFERTA_VF_YYYYMMDD.xlsx` con cuatro hojas:

| Hoja | Contenido |
|---|---|
| `JE5_PROGRAMAS` | Resultado detallado por programa: ranking, cupos asignados por paso y costos. |
| `EXCEDENTES_NIVEL` | Saldo final de la bolsa comun por Nivel. |
| `IES_NIVEL` | Auditoria de la bolsa IES x Nivel (Paso 1) con remanente final. |
| `CINE` | Auditoria de la bolsa CINE x Nivel (componente demanda social). |

## 5. Diccionario de Datos

### Input: `data/JE5_Insumo.RData`

| Objeto | Descripcion |
|---|---|
| `LISTADO_OFERTA_PROPUESTA` | Oferta tecnica de las IES (programas, costos por semestre, capacidad, ISOES, TIR). |
| `JE5_InsumoCostos` | Costos actualizados por semestre desde 2026-2. |
| `SNIES_PROGRAMAS` | Datos SNIES por programa: fecha de ejecutoria, vigencia, estado. |
| `JE4_Valor_Convenios` | Convenios vigentes JE4 por IES (CODIGO_SNIES_IES, VALOR TOTAL, CONVENIO). |
| `DemandaHistorica` | Demanda social historica por CINE F detallado y Nivel (inscritos, cupos, indicador, percentil 50). |

**Campos clave de `LISTADO_OFERTA_PROPUESTA`:**

| Campo | Descripcion |
|---|---|
| `ID` | Identificador unico del registro de oferta |
| `COD_IES` | Codigo SNIES de la IES |
| `NOMBRE_IES` | Nombre de la IES |
| `CÓDIGO_SNIES_DEL_PROGRAMA_A_OFERTAR` | Codigo SNIES del programa |
| `NIVEL_DE_FORMACIÓN` | Nivel original del SNIES |
| `NIVEL_PROGRAMA_SNIES_AJUSTE` | Homologacion a UNIVERSITARIO / TYT |
| `CINE_F_2013_AC_CAMPO_DETALLADO` | CINE F campo detallado (base demanda social) |
| `ISOES_PROGRAMA` | Indice ISOES del programa |
| `TIR_PROGRAMA` | Tasa Interna de Retorno del programa |
| `TOTAL_VALOR_COHORTE_ATENEA` | Costo asumido por ATENEA por cohorte |
| `CUPOS_SEGÚN_CAPACIDAD` | Cupos ofertados por la IES |
| `PROGRAMA_HABILITADO` | Habilitacion administrativa previa |
| `HABILITADO_EJECUTORIA` | Habilitacion calculada en Modulo 1 |
| `CONVENIO` | Convenio JE4 (NA si la IES no tiene convenio) |

---

## 6. Instrucciones de Ejecucion

1. Instale R (4.5+) y RStudio. Clone este repositorio.
2. Instale dependencias:
   ```r
   if (!require("renv")) install.packages("renv")
   renv::restore()
   ```
3. El insumo `data/JE5_Insumo.RData` ya viene incluido en el repositorio.
4. Ejecute `source("JE5_Main.R")` desde RStudio. El script activa `renv`, carga librerias y corre los 5 modulos en secuencia. Los modulos **no se ejecutan de forma independiente**.
5. Resultado: `output/JE5_OFERTA_VF_YYYYMMDD.xlsx`.

---

## 7. Garantia de Reproducibilidad

El algoritmo es deterministico bajo las mismas entradas:

* **Semilla fija:** `set.seed(20260427)` (fecha de generacion del insumo de oferta) para desempates.
* **Cortes documentados:** SNIES 2026-04-30; cierre de ejecutoria 2026-12-06.
* **Presupuesto explicito:** `PPTO_GENERAL = 17.753.034.702 COP` en `modules/2_presupuesto_ies.R`.
* **Entorno controlado:** `renv.lock` congela versiones de dependencias.
* **Versionamiento:** codigo bajo git.

---

## 8. Preguntas Frecuentes y Glosario

**Por que un programa puede recibir menos cupos de los que oferto?**
Porque la bolsa de su IES (proporcional al valor del convenio JE4) no alcanza para financiar todos los cupos ofertados. Solo se aprueba lo que se puede financiar sin exceder el presupuesto.

**Por que una IES con oferta puede no recibir cupos?**
Porque JE5 requiere convenio vigente JE4. Si la IES no participo en JE4 o su convenio no esta vigente, queda fuera del universo elegible. Adicionalmente, los programas requieren ejecutoria SNIES vigente al 2026-12-06.

**Por que Medicina no aparece aprobada?**
Por decision explicita del lineamiento operativo: los SNIES 20603, 1807, 5116, 21465 y 4911 quedan excluidos.

**Que pasa con los excedentes del mecanismo ISOES?**
Se acumulan a la bolsa de demanda social (10% + excedente), que se reparte entre programas con baja asignacion ISOES, cupos pendientes y demanda historica por encima de la mediana de su nivel.

**Es posible replicar los resultados fuera de ATENEA?**
Si. Con este repositorio, el insumo `data/JE5_Insumo.RData` (incluido) y `renv::restore()` cualquier persona reproduce los resultados paso a paso.

### 9. Glosario

| Termino | Definicion |
|---|---|
| **IES** | Institucion de Educacion Superior. |
| **Cupo** | Matricula financiada para una persona en un programa especifico. |
| **Cohorte** | Grupo de cupos financiados en una misma "oleada". |
| **Vigencia** | Ano fiscal de ejecucion del gasto. |
| **ISOES** | Indice de Seleccion de Oferta para la Educacion Superior. Indice ponderado construido por ATENEA con tres dimensiones: pertinencia (TIR, empleabilidad, salario de enganche), calidad (Saber Pro/TyT y valor agregado ICFES) y permanencia (inverso de la desercion SPADIES). Pesos diferenciados para Universitario y TyT. |
| **TIR** | Tasa Interna de Retorno del programa (componente de pertinencia del ISOES). |
| **CINE F** | Clasificacion Internacional Normalizada de la Educacion - campo detallado (UNESCO). |
| **SNIES** | Sistema Nacional de Informacion de la Educacion Superior (MEN). |
| **SPADIES** | Sistema para la Prevencion del Riesgo de Desercion en Educacion Superior. |
| **Ejecutoria SNIES** | Fecha y vigencia del registro calificado del MEN. |
| **Convenio JE4** | Acuerdo suscrito con la IES en la cuarta convocatoria (ATENEA-IA-JE-003-2025). |
| **Mecanismo ISOES** | Componente que distribuye el 90% del presupuesto por ranking ISOES. |
| **Demanda Social** | Componente que distribuye el 10% por demanda historica. |

---

## 10. Uso del Codigo

Obra institucional de ATENEA (articulo 91 de la Ley 23 de 1982) publicada bajo **Creative Commons Attribution 4.0 (CC BY 4.0)**, en cumplimiento de los principios de transparencia y acceso a la informacion publica.

Cualquier persona puede reproducir, distribuir, comunicar publicamente y transformar esta obra, citando a ATENEA como autora institucional. Las modificaciones o versiones derivadas son responsabilidad exclusiva de quien las realice. Esta autorizacion no implica cesion de derechos patrimoniales ni afecta los derechos morales sobre la obra original.

(c) 2026 ATENEA - Agencia Distrital para la Educacion Superior, la Ciencia y la Tecnologia.

**Desarrollado por:** SAIGC - ATENEA · **Publicacion:** Mayo 2026
