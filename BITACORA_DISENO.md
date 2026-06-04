# Bitácora de diseño del proyecto

Documento resumido de decisiones y avances del sistema de análisis en MATLAB.

## 2026-05-19 - Estructura inicial

Prompt: Diseña la estructura base de un proyecto MATLAB para analizar resultados de rendimiento y define un script principal que orqueste todo el flujo.

Definimos `ProyectoMatlab` como un proyecto autocontenido con separación entre `datos`, `scripts` y `resultados`. También fijamos `main.m` como punto de entrada para coordinar carga, limpieza, métricas, gráficas y resumen ejecutivo.

Archivos relacionados:
- `scripts/main.m`
- `scripts/guardarResultados.m`
- `README.md`

Estado:
- Quedó establecida la arquitectura general del proyecto.

## 2026-05-19 - Integración de datos experimentales

Revisamos los resultados originales del estudio MPI + OpenMP realizado para la materia de sistemas distribuídos en la universidad y decidimos reutilizar los `.dat` ya generados en el experimento base. El análisis quedó orientado a los tres tipos de ejecución observados: `Procesos`, `Hilos` y `ProcesosMaster`.

Archivos relacionados:
- `ProyectoMatlab/datos/*.dat`

Estado:
- El proyecto quedó conectado con 56 archivos `.dat` reales del experimento.

## 2026-05-19 - Carga y limpieza de datos

Prompt: Implementa la carga automática de datos desde los nombres de archivo y aplica una limpieza mínima para descartar mediciones inválidas.

Resolvimos la carga automática de archivos a partir del nombre de cada `.dat`, extrayendo `tipo`, `algoritmo`, `N`, `NP`, `H` y `workers`. También se definió una limpieza mínima para eliminar valores vacíos, no numéricos, no finitos o menores o iguales a cero.

Archivos relacionados:
- `scripts/cargarDatos.m`
- `scripts/limpiarDatos.m`

Estado:
- La etapa de preparación de datos quedó automatizada y resistente a archivos imperfectos.

## 2026-05-19 - Métricas de rendimiento

Prompt: Calcula métricas de rendimiento por configuración experimental, incluyendo estadísticos descriptivos, GFLOPS, speedup y eficiencia.

Definimos el cálculo por configuración experimental usando agrupación por `tipo`, `algoritmo`, `N`, `NP`, `H` y `workers`. Se incluyeron estadísticos descriptivos, `GFLOPS`, `speedup`, `eficiencia` y `overhead`, usando `ProcesosMaster` como baseline preferente cuando existe.

Archivos relacionados:
- `scripts/calcularMetricas.m`

Estado:
- El proyecto ya produce tablas comparables entre algoritmos y configuraciones paralelas.

## 2026-05-19 - Visualización del análisis

Prompt: Genera un conjunto de gráficas que permita comparar algoritmos, escalabilidad, eficiencia, rendimiento y variabilidad experimental.

Diseñamos un conjunto de gráficas para resumir tiempo, speedup, eficiencia, GFLOPS, variabilidad y comparaciones entre algoritmos.

Archivos relacionados:
- `scripts/generarGraficas.m`

Estado:
- El flujo descriptivo del análisis quedó implementado de extremo a extremo.

## 2026-05-31 - Depuración del workspace y ajuste de la vía oficial

Prompt: Revisa el workspace completo, elimina artefactos residuales y deja el proyecto alineado con una única vía de trabajo en MATLAB.

Revisamos el workspace completo para identificar artefactos residuales y alinear el proyecto con MATLAB como entorno principal. Se limpiaron resultados previos y se dejó la estructura preparada para una ejecución limpia desde `main.m`.

Archivos relacionados:
- `scripts/main.m`
- `resultados/`

Estado:
- La ruta oficial del proyecto quedó reducida a MATLAB y la carpeta de resultados quedó limpia.

## 2026-05-31 - Consolidación del flujo principal

Prompt: Ajusta `main.m` para que concentre el flujo completo del análisis con rutas relativas y salidas reproducibles.

Antes de ejecutar el sistema completo, revisamos que `main.m` integrara correctamente todas las etapas del análisis y que las rutas fueran relativas al proyecto. Se mantuvo un flujo lineal: cargar datos, limpiar, calcular métricas, guardar tablas, generar gráficas y producir un resumen final.

Archivos relacionados:
- `scripts/main.m`

Estado:
- El script principal quedó como punto único de ejecución del proyecto.

## 2026-05-31 - Ajuste de la carga de datos

Prompt: Haz que la carga de archivos `.dat` sea robusta frente a nombres inesperados y líneas no numéricas.

Verificamos que la lectura de archivos `.dat` fuera tolerante a nombres inesperados y a líneas no numéricas. Se consolidó la extracción de metadatos desde el nombre del archivo para evitar parametrización manual y asegurar consistencia entre configuraciones experimentales.

Archivos relacionados:
- `scripts/cargarDatos.m`

Estado:
- La carga quedó lista para procesar automáticamente los archivos del experimento.

## 2026-05-31 - Revisión de la limpieza y validez de mediciones

Prompt: Revisa los criterios de limpieza para mantener solo mediciones válidas sin alterar innecesariamente el conjunto experimental.

Revisamos la etapa de limpieza para asegurar que solo se descartaran valores claramente inválidos y que no se alterara innecesariamente el conjunto experimental. El criterio final se mantuvo deliberadamente simple para preservar trazabilidad.

Archivos relacionados:
- `scripts/limpiarDatos.m`

Estado:
- La validación de mediciones quedó acotada a errores evidentes en los tiempos registrados.

## 2026-05-31 - Cierre de métricas por configuración

Prompt: Verifica el cálculo agregado por configuración y asegúrate de usar un baseline consistente para speedup y eficiencia.

Repasamos el cálculo agregado por configuración experimental y confirmamos el uso de `ProcesosMaster` como referencia preferente para escalabilidad. También se dejó centralizado en un solo módulo el cálculo de estadísticos descriptivos y métricas de rendimiento paralelo.

Archivos relacionados:
- `scripts/calcularMetricas.m`

Estado:
- Las métricas quedaron unificadas y ordenadas por configuración.

## 2026-05-31 - Formalización del diccionario experimental

Prompt: Documenta de forma explícita el significado de `Procesos`, `Hilos`, `ProcesosMaster`, `algoritmo`, `N` y `workers`.

Dejamos explícita la interpretación de los parámetros principales del experimento para evitar ambigüedades en la lectura del proyecto. Se documentó el papel de `Procesos`, `Hilos`, `ProcesosMaster`, `algoritmo`, `N` y `workers` como base común para análisis y métricas.

Archivos relacionados:
- `README.md`
- `scripts/cargarDatos.m`
- `scripts/calcularMetricas.m`

Estado:
- El proyecto quedó documentado con un diccionario mínimo de parámetros experimentales.

## 2026-05-31 - Organización de resultados y salidas

Prompt: Centraliza la escritura de tablas, resumen ejecutivo y carpetas de salida para que el proyecto sea reproducible.

Revisamos la forma de persistir resultados para que el proyecto pudiera regenerar carpetas y salidas sin depender de intervención manual. Se concentró en un solo script la escritura de CSV, del archivo `resultados/resumen_ejecutivo.txt` y de la creación de directorios de trabajo.

Archivos relacionados:
- `scripts/guardarResultados.m`

Estado:
- La salida del proyecto quedó organizada y reproducible.

## 2026-05-31 - Cierre de visualización

Prompt: Deja cerrada la parte de visualización del proyecto con tablas, gráficas y resumen final listos para revisión.

Finalmente, revisamos los módulos de gráficas para dejar cubierta la interpretación visual del experimento junto con las tablas de métricas y el resumen final.

Archivos relacionados:
- `scripts/generarGraficas.m`

Estado:
- El sistema quedó completo desde la exploración de datos hasta la visualización de resultados.

## 2026-05-31 - Limitación detectada en gráficas

Prompt: Haz que la generación de gráficas siga funcionando aunque `boxplot` no esté disponible en la instalación de MATLAB.

Durante una ejecución del flujo principal observamos que `boxplot` no está disponible en la instalación actual de MATLAB sin toolboxes adicionales. Ajustamos la generación de gráficas para que esa ausencia no interrumpa el resto del análisis.

Archivos relacionados:
- `scripts/generarGraficas.m`

Estado:
- El flujo principal ya puede continuar aunque la gráfica de boxplot no esté disponible.

## 2026-05-31 - Construcción del modelo predictivo en Regression Learner

Prompt: Usa `dataset_completo.csv` para entrenar varios modelos en `Regression Learner`, compáralos y conserva el más razonable.

A partir de `datos/dataset_completo.csv` abrimos una sesión en `Regression Learner` para estimar `tiempo_us` desde `tipo`, `algoritmo`, `N`, `NP`, `H` y `workers`. Se compararon varios modelos rápidos con validación cruzada de 5 folds y observamos que los árboles de regresión superaban ampliamente a las alternativas lineales.

Entre `Fine Tree` y `Medium Tree` el desempeño fue prácticamente igual, por lo que conservamos `Medium Tree` como opción final por ser una alternativa más simple con el mismo nivel de ajuste observado. El modelo exportado se guardó como archivo `.mat` dentro de la carpeta de resultados.

Archivos relacionados:
- `datos/dataset_completo.csv`
- `resultados/modelos/trainedModel.mat`
- `README.md`

Estado:
- Quedó registrada la primera versión del modelo predictivo de tiempos.

## 2026-05-31 - Integración de pruebas automáticas del modelo

Prompt: Crea una rutina separada del `main` que cargue el modelo exportado y ejecute pruebas automáticas sobre configuraciones representativas.

Después de guardar el modelo exportado en `resultados/modelos/`, se separó la validación manual del modelo en una rutina propia para no cargar `main.m` con lógica adicional. Se creó una función específica que detecta el archivo `.mat`, carga el predictor exportado y ejecuta un conjunto pequeño de pruebas sobre configuraciones representativas extraídas del propio estudio.

Las pruebas comparan el tiempo predicho contra el tiempo medio observado y dejan una tabla consolidada en `resultados/tablas/`. Con esto, el flujo principal conserva el análisis descriptivo original y al mismo tiempo puede reutilizar el modelo ya entrenado sin depender de la app de MATLAB en cada ejecución.

Archivos relacionados:
- `scripts/ejecutarPruebasModelo.m`
- `scripts/main.m`
- `resultados/modelos/modelo_medium_tree.mat`
- `resultados/tablas/pruebas_modelo_predictivo.csv`

Estado:
- El flujo principal ya puede invocar pruebas básicas del modelo predictivo de forma automática.
