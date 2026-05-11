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

1. [Introduccion y Contexto](#1-introduccion-y-contexto)
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
9. [Uso del Codigo](#9-uso-del-codigo)

---

## 1. Introduccion y Contexto

Este repositorio contiene la implementacion tecnica del **Mecanismo de Seleccion y Aprobacion de Ofertas Tecnicas** para la quinta convocatoria del programa "Jovenes a la E" (JE5). El algoritmo prioriza programas academicos presentados por Instituciones de Educacion Superior (IES) privadas con convenio vigente en la cuarta convocatoria y asigna cupos contra el presupuesto disponible, con base en el indice ISOES y el componente de alta demanda social.

El insumo normativo es el **Lineamiento Operativo L45_EP v1** (aprobado el 4 de mayo de 2026), incluido en [docs/](docs/). El presupuesto disponible proviene de la adicion de los Fondos de Desarrollo Local (FDL) de Bosa, Kennedy, Ciudad Bolivar, Teusaquillo, Usme, Usaquen y Los Martires a los convenios JE4.

El algoritmo ha sido disenado bajo los principios de:
* **Transparencia:** reglas de negocio codificadas explicitamente sin "cajas negras".
* **Eficiencia:** procesamiento vectorial con `dplyr` y SQL embebido para validaciones.
* **Auditabilidad:** trazas intermedias en consola y libro Excel con hojas de auditoria presupuestal.
* **Reproducibilidad:** semilla fija (`set.seed`) y `renv` para fijar versiones de las dependencias.

---

## 2. Arquitectura del Proyecto

El codigo ha sido refactorizado desde un script monolitico a una arquitectura modular secuencial. Cada modulo aborda una fase del lineamiento operativo y puede auditarse por separado.

```text
AlgoritmoJE5_Oferta/
|
|-- .gitignore                # Configuracion de exclusion de archivos sensibles
|-- JE5_Main.R                # ORQUESTADOR PRINCIPAL (Entry Point)
|-- README.md                 # Documentacion tecnica (este archivo)
|-- LICENSE                   # CC BY - Obra institucional ATENEA
|-- renv.lock                 # Manifiesto de dependencias exactas (Freeze)
|
|-- data/                     # Carpeta de insumos (ignorada en git)
|   +-- JE5_Insumo.RData      # Listado de oferta, costos, SNIES, convenios JE4, demanda historica
|
|-- output/                   # Resultados generados (ignorada en git)
|   +-- JE5_OFERTA_VF_YYYYMMDD.xlsx
|
|-- docs/                     # Lineamiento operativo y documentos de soporte
|   +-- l45_ep_lineamiento_operativo_..._JE5.pdf
|
+-- modules/                  # Logica de negocio desagregada
    |-- 1_habilitacion.R      # Habilitacion IES (convenio JE4) + programas (ejecutoria SNIES)
    |-- 2_presupuesto_ies.R   # Paso 0 + Paso 1: bolsa IES proporcional al valor convenio JE4
    |-- 3_asignacion_isoes.R  # Paso 2 (intra-IES) y Paso 3 (excedente por Nivel)
    |-- 4_demanda_social.R    # Componente 10% + excedente ISOES, bolsas CINE x Nivel
    +-- 5_exportacion.R       # Consolidacion y exportacion XLSX con auditoria
```

---

## 3. Requisitos Tecnicos

### Software

* **Lenguaje R:** Version 4.5.1 o superior.
* **Gestor de Paquetes:** `renv` (version 1.1.5+).

### Dependencias (Librerias R)

El entorno se restaura automaticamente usando `renv.lock`. Librerias base:

| Libreria    | Funcion Principal                                            |
|-------------|--------------------------------------------------------------|
| `sqldf`     | Consultas SQL sobre dataframes para validaciones.            |
| `expss`     | Tablas cruzadas y etiquetado.                                |
| `readr`     | Lectura eficiente de archivos planos.                        |
| `readxl`    | Lectura de archivos Excel.                                   |
| `dplyr`     | Manipulacion de dataframes, mutaciones y agregaciones.       |
| `tidyr`     | Transformacion y reestructuracion de datos.                  |
| `eeptools`  | Herramientas auxiliares.                                     |
| `openxlsx`  | Escritura y formateo de reportes finales en Excel.           |
| `lubridate` | Aritmetica de fechas para la habilitacion por ejecutoria.    |

---

## 4. Logica Detallada del Algoritmo

### Fase 1: Habilitacion de IES y Programas (Modulo 1)

**Archivo:** `modules/1_habilitacion.R`
**Referencia normativa:** Lineamiento operativo, numeral 5.4.1.3.

Para la quinta convocatoria, una IES y sus programas se consideran habilitados unicamente si cumplen los tres criterios siguientes:

1. **Convenio vigente JE4:** la IES debe contar con convenio activo suscrito en el marco de la Invitacion Publica ATENEA-IA-JE-003-2025. Se cruza el listado de oferta contra `JE4_Valor_Convenios`.
2. **Ejecutoria SNIES vigente:** `FECHA_EJECUTORIA + VIGENCIA_AÑOS > 2026-12-06` (seis meses contados a partir de la publicacion del lineamiento). Corte SNIES: 30 de abril de 2026.
3. **Exclusion explicita de programas de Medicina:** se marcan como `NO_HABILITADO` los SNIES 20603, 1807, 5116, 21465 y 4911.

Adicionalmente, el nivel de formacion se homologa a dos categorias: `UNIVERSITARIO` y `TYT` (Tecnico/Tecnologico).

---

### Fase 2: Distribucion del Presupuesto por IES (Modulo 2)

**Archivo:** `modules/2_presupuesto_ies.R`
**Referencia normativa:** Lineamiento operativo, numerales 5.1 y 5.4.1.4 Paso 1.

**Presupuesto general:** `$17.753.034.702 COP` (≈450 cupos para semestre 2026-2).

**Particion macro del presupuesto:**

| Componente                  | % Asignacion | Valor                  |
|-----------------------------|-------------:|------------------------|
| Mecanismo ISOES             |       90%    | $15.977.731.231,80     |
| Componente de Demanda Social|       10%    | $1.775.303.470,20      |

**Bolsa por IES (Paso 1):** proporcional al **valor del convenio suscrito en JE4**, conforme a la formula del lineamiento:

$$Recursos_{IES_i} = \left(\frac{Valor\_convenio_{IES_i}}{\sum_{i=1}^{n} Valor\_convenio_{IES_i}}\right) \times 90\% \times PPTO\_GENERAL$$

**Distribucion intra-IES por nivel (Paso 1.1):**

* Si la IES tiene oferta en **un solo nivel** -> 100% al nivel ofertado.
* Si la IES tiene oferta en **ambos niveles** -> 95% Universitario / 5% TyT.

---

### Fase 3: Asignacion por Mecanismo ISOES (Modulo 3)

**Archivo:** `modules/3_asignacion_isoes.R`
**Referencia normativa:** Lineamiento operativo, numeral 5.4.1.4 Pasos 2 y 3.

#### Paso 2: Asignacion de cupos al interior de la IES

**Ordenamiento de programas (estricto y deterministico):**

1. `desc(ISOES_PROGRAMA)` — mayor ISOES primero.
2. `TOTAL_VALOR_COHORTE_ATENEA` ascendente — menor costo de cohorte primero (Nota del lineamiento: "se priorizara el programa con menor costo").
3. `desc(CUPOS_SEGUN_CAPACIDAD)` — mayor capacidad ofertada primero.
4. `SEMILLA` aleatoria auditable — ultimo criterio de desempate.

**Iteracion (pseudocodigo):**

```text
PARA CADA (IES, Nivel) EN ORDEN:
    PARA CADA Programa EN ranking_dentro_de_IES:

        CUPO_OFERTADO  = Cupos segun capacidad
        CUPO_CALCULADO = Bolsa_IES_Nivel_remanente / Valor_cohorte_Atenea

        SI (CUPO_CALCULADO >= CUPO_OFERTADO):
            # Alcanza para todos los cupos ofertados
            Asignar CUPO_OFERTADO

        SINO SI (CUPO_CALCULADO >= 1):
            # Alcanza para al menos 1 cupo - se trunca al entero
            Asignar floor(CUPO_CALCULADO)

        SINO:
            # No alcanza para ningun cupo completo - se reporta
            Sin asignacion en este paso
```

#### Paso 3: Reasignacion del excedente por Nivel

Los saldos de cada IES se agrupan en una bolsa comun por Nivel (Universitario / TyT). Se recorre nuevamente la lista de programas (en el mismo orden ISOES) y se asignan cupos a aquellos con `CUPO_PENDIENTES > 0`, hasta agotar la bolsa o agotar los programas.

---

### Fase 4: Componente de Alta Demanda Social (Modulo 4)

**Archivo:** `modules/4_demanda_social.R`
**Referencia normativa:** Lineamiento operativo, numeral 5.4.1.5.

**Bolsa inicial:** 10% del PPTO_GENERAL **mas** todo el excedente que haya dejado el mecanismo ISOES.

**Indicador de demanda social** (calculado por nivel sobre datos historicos JE2):

$$Demanda\_Social_{CINE\_i} = \frac{\#\ inscritos\ en\ CINE\ F\ Campo\ Detallado\ i}{\#\ cupos\ en\ CINE\ F\ Campo\ Detallado\ i}$$

**Universo de programas elegibles:** se aplican estos filtros en cascada:

1. Programas con `< 6 cupos` asignados en el mecanismo ISOES (agregando por CINE F).
2. Con `CUPO_PENDIENTES > 0` segun capacidad.
3. Con indicador de demanda social disponible (no nulo).
4. Por **encima del percentil 50** en el indicador de demanda social del nivel.

**Distribucion:** 95% Universitario / 5% TyT sobre el presupuesto de demanda social. Dentro de cada nivel, las bolsas se reparten por **CINE x Nivel** proporcionalmente a los inscritos historicos (`DH_INSCRITOS`).

**Recorrido:** identico al Modulo 3 — primero asignacion intra-CINE (analogo al Paso 2), luego reasignacion del excedente CINE en bolsa comun por Nivel (analogo al Paso 3).

---

### Fase 5: Consolidacion y Exportacion (Modulo 5)

**Archivo:** `modules/5_exportacion.R`

1. **Merge final:** se cruzan los resultados del mecanismo ISOES con los del componente de demanda social por `ORDENAMIENTO_PROG`.
2. **Totales:** `CUPOS_ASIGNADOS_TOTAL = ISOES + Demanda_Social`; `COSTO = CUPOS * TOTAL_VALOR_COHORTE_ATENEA`.
3. **Pruebas de cierre presupuestal** en consola: cupos por componente, costo total y diferencia vs. PPTO_GENERAL.
4. **Exportacion:** `output/JE5_OFERTA_VF_YYYYMMDD.xlsx` con cuatro hojas:

| Hoja                 | Contenido                                                                       |
|----------------------|---------------------------------------------------------------------------------|
| **JE5_PROGRAMAS**    | Resultado detallado por programa: ranking, cupos asignados por paso y costos.  |
| **EXCEDENTES_NIVEL** | Saldo final de la bolsa comun por Nivel.                                        |
| **IES_NIVEL**        | Auditoria de la bolsa IES x Nivel (Paso 1) con remanente final.                 |
| **CINE**             | Auditoria de la bolsa CINE x Nivel (componente demanda social).                 |

---

## 5. Diferencias frente al algoritmo JE4

| Aspecto                          | JE4                                                                         | JE5                                                                                          |
|----------------------------------|-----------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|
| Presupuesto general              | Definido por convocatoria abierta                                           | $17.753.034.702 (adicion FDL a convenios JE4)                                                 |
| Universo de IES                  | Todas las IES participantes en la convocatoria                              | Solo IES con **convenio vigente JE4** (~39 IES)                                               |
| Criterio para bolsa IES (Paso 1) | TIR ponderada por IES y nivel; se excluyen IES con TIR ponderada negativa   | **Proporcion del valor del convenio JE4** (sin exclusion por TIR)                            |
| Habilitacion de programas        | Habilitacion administrativa (`PROGRAMA_HABILITADO`)                         | Agrega **vigencia de ejecutoria SNIES > 2026-12-06** + exclusion explicita de Medicina       |
| Distribucion intra-IES por Nivel | 95% Universitario / 5% TyT                                                  | Igual                                                                                          |
| Semilla reproducible             | `set.seed(20251010)`                                                        | `set.seed(20260427)`                                                                           |
| Particion ISOES / Demanda Social | 90% / 10%                                                                   | Igual                                                                                          |
| Salida                           | XLSX con `JE4_PROGRAMAS`, `EXCEDENTES_NIVEL`, `BOLSA_ANUAL`, `IES`, `CINE`  | XLSX con `JE5_PROGRAMAS`, `EXCEDENTES_NIVEL`, `IES_NIVEL`, `CINE`                              |

> El repositorio JE4 publicable se encuentra en [ATENEA-SAIGC/Selecci-n-JE4](https://github.com/ATENEA-SAIGC/Selecci-n-JE4).

---

## 6. Diccionario de Datos

### Input: `data/JE5_Insumo.RData`

Contiene los siguientes objetos:

| Objeto                       | Descripcion                                                                                       |
|------------------------------|---------------------------------------------------------------------------------------------------|
| `LISTADO_OFERTA_PROPUESTA`   | Oferta tecnica presentada por las IES (programas, costos por semestre, capacidad, ISOES, TIR).    |
| `JE5_InsumoCostos`           | Costos actualizados por semestre desde 2026-2.                                                     |
| `SNIES_PROGRAMAS`            | Datos del SNIES por programa: fecha de ejecutoria, vigencia, estado.                              |
| `JE4_Valor_Convenios`        | Convenios vigentes JE4 por IES (CODIGO_SNIES_IES, VALOR TOTAL, CONVENIO).                          |
| `DemandaHistorica`           | Demanda social historica por CINE F detallado y Nivel (inscritos, cupos, indicador, percentil 50).|

**Campos clave de `LISTADO_OFERTA_PROPUESTA`:**

| Campo                                  | Descripcion                                                |
|----------------------------------------|------------------------------------------------------------|
| `ID`                                   | Identificador unico del registro de oferta                 |
| `COD_IES`                              | Codigo SNIES de la IES                                     |
| `NOMBRE_IES`                           | Nombre de la IES                                           |
| `CÓDIGO_SNIES_DEL_PROGRAMA_A_OFERTAR`  | Codigo SNIES del programa                                  |
| `NIVEL_DE_FORMACIÓN`                   | Nivel original del SNIES                                   |
| `NIVEL_PROGRAMA_SNIES_AJUSTE`          | Homologacion a UNIVERSITARIO / TYT                         |
| `CINE_F_2013_AC_CAMPO_DETALLADO`       | CINE F campo detallado (base para demanda social)          |
| `ISOES_PROGRAMA`                       | Indice ISOES del programa                                  |
| `TIR_PROGRAMA`                         | Tasa Interna de Retorno del programa                       |
| `TOTAL_VALOR_COHORTE_ATENEA`           | Costo asumido por Atenea por cohorte                       |
| `CUPOS_SEGÚN_CAPACIDAD`                | Cupos ofertados por la IES                                 |
| `PROGRAMA_HABILITADO`                  | Habilitacion administrativa previa                         |
| `HABILITADO_EJECUTORIA`                | Habilitacion calculada en Modulo 1 (ejecutoria + medicina) |
| `CONVENIO`                             | Convenio JE4 (NA si la IES no tiene convenio)              |

### Output: `output/JE5_OFERTA_VF_YYYYMMDD.xlsx`

Ver tabla en [Fase 5](#fase-5-consolidacion-y-exportacion-modulo-5).

---

## 7. Instrucciones de Ejecucion

Siga estos pasos para replicar los resultados oficiales.

1. **Preparar el entorno:**
   * Instale R (4.5+) y RStudio.
   * Clone este repositorio.

2. **Instalar dependencias (renv):**
   Abra el proyecto en RStudio y ejecute en la consola:
   ```r
   if (!require("renv")) install.packages("renv")
   renv::restore()
   ```

3. **Cargar insumos:**
   Coloque `JE5_Insumo.RData` (entregado por el equipo de datos) en la carpeta `data/`.

4. **Ejecutar el algoritmo:**
   Abra `JE5_Main.R` y ejecute con `source("JE5_Main.R")` o el boton "Source" de RStudio.
   * El script activa `renv`, carga las librerias y ejecuta los 5 modulos en secuencia.
   * Vera en consola el progreso de la asignacion programa por programa.
   * Los modulos **no se ejecutan de forma independiente**: siempre debe ejecutarse desde `JE5_Main.R`.

5. **Validar resultados:**
   Al finalizar, busque el archivo `JE5_OFERTA_VF_YYYYMMDD.xlsx` en la carpeta `output/`.

---

## 8. Garantia de Reproducibilidad

Este algoritmo es deterministico. Bajo las mismas entradas siempre generara exactamente el mismo resultado, gracias a:

1. **Semilla Fija:** `set.seed(20260427)` (fecha de generacion del insumo de oferta) para los desempates aleatorios.
2. **Cortes documentados:** Corte SNIES 30 de abril de 2026; fecha de cierre de ejecutoria 6 de diciembre de 2026.
3. **Presupuesto explicito:** `PPTO_GENERAL = 17.753.034.702 COP` definido como constante en `modules/2_presupuesto_ies.R`.
4. **Entorno Controlado:** `renv.lock` asegura que las funciones matematicas de las librerias no cambien por actualizaciones de software.
5. **Versionamiento:** Codigo fuente bajo control de versiones (git), permitiendo rastrear cualquier cambio en la logica.

---

## 9. Uso del Codigo

### Autorizacion de Uso (CC BY)

Este algoritmo de asignacion de cupos es una obra institucional de ATENEA (bajo el articulo 91 de la Ley 23 de 1982) y se publica bajo Autorizacion general de explotacion con atribucion (CC BY), en cumplimiento de los principios de transparencia y acceso a la informacion publica.

Cualquier persona puede reproducir, distribuir, comunicar publicamente y transformar esta obra, siempre que reconozca a ATENEA como autora institucional, indicando el nombre de la Agencia. Las modificaciones o versiones derivadas son responsabilidad exclusiva de quien las realice.

(c) 2026 ATENEA - Agencia Distrital para la Educacion Superior, la Ciencia y la Tecnologia.

Esta autorizacion no implica cesion de derechos patrimoniales ni afecta los derechos morales sobre la obra original.

**Desarrollado por:** SAIGC - ATENEA
**Fecha de Publicacion:** Mayo 2026
