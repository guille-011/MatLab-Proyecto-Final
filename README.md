# Proyecto MATLAB - Análisis de rendimiento MPI + OpenMP

## 1. Objetivo

Este proyecto analiza datos experimentales de rendimiento de un clúster de computadores para multiplicación de matrices usando C, MPI y OpenMP.

Compara dos algoritmos:

- `clasica`: filas por columnas, ejecutable original `mxmOmpMPIfxc`.
- `transpuesta`: filas por transpuesta, ejecutable original `mxmOmpMPIfxt`.

El sistema carga automáticamente archivos `.dat`, extrae metadatos desde sus nombres, limpia mediciones inválidas, calcula métricas de rendimiento, genera gráficas comparativas y además puede apoyar una etapa de predicción de tiempos usando `Regression Learner`.

## 2. Estructura de carpetas

```text
ProyectoMatlab/
├── datos/
│   ├── archivos .dat experimentales
│   └── dataset_completo.csv
├── scripts/
│   ├── main.m
│   ├── cargarDatos.m
│   ├── limpiarDatos.m
│   ├── calcularMetricas.m
│   ├── generarGraficas.m
│   ├── ejecutarPruebasModelo.m
│   └── guardarResultados.m
├── resultados/
│   ├── tablas/
│   ├── graficas/
│   └── modelos/
└── README.md
```

## 3. Cómo poner los archivos `.dat`

Copie los archivos `.dat` en la carpeta `ProyectoMatlab/datos/`.

Los nombres esperados son de este estilo:

- `Procesos-Pr-clasica-N-800-NP-17.dat`
- `Procesos-Pr-transpuesta-N-1600-NP-33.dat`
- `Hilos-Pr-clasica-N-3200-NP-5-H-8.dat`
- `Hilos-Pr-transpuesta-N-1600-NP-5-H-4.dat`
- `ProcesosMaster-Pr-clasica-N-800-NP-2.dat`
- `ProcesosMaster-Pr-transpuesta-N-3200-NP-2.dat`

Desde cada nombre se extraen:

- tipo: `Procesos`, `Hilos` o `ProcesosMaster`
- algoritmo: `clasica` o `transpuesta`
- `N`: tamaño de matriz
- `NP`: número de procesos MPI
- `H`: número de hilos OpenMP, o `1` si no aparece
- `workers = NP - 1`

Cada línea numérica del archivo se interpreta como una repetición de tiempo en microsegundos.

Además, la carpeta `datos/` incluye:

- `dataset_completo.csv`: tabla consolidada con una fila por medición y las columnas `tipo`, `algoritmo`, `N`, `NP`, `H`, `workers` y `tiempo_us`.

## 3.1 Diccionario de parámetros experimentales

- `Procesos`: varía el número de procesos MPI y normalmente usa `H = 1`.
- `Hilos`: fija `NP = 5` y varía el número de hilos OpenMP, típicamente `H = 1, 4, 8`.
- `ProcesosMaster`: caso base con `NP = 2`, usado como referencia para `speedup` y `eficiencia`.
- `algoritmo`: compara multiplicación `clasica` contra `transpuesta`.
- `N`: controla el tamaño del problema, es decir, la dimensión de la matriz cuadrada.
- `workers`: representa el paralelismo efectivo y se calcula como `NP - 1`, porque el proceso master no realiza el cómputo principal.

## 4. Cómo ejecutar

En MATLAB:

1. Abra la carpeta `ProyectoMatlab/scripts/`.
2. Ejecute:

```matlab
main
```

También puede ejecutar el archivo desde el editor de MATLAB. El script calcula rutas relativas, por lo que no depende de una ruta absoluta específica.

Al finalizar, `main.m` también genera un archivo de texto con los resultados principales del análisis:

- `resultados/resumen_ejecutivo.txt`

## 5. Métricas calculadas

Las métricas se agrupan por:

- tipo
- algoritmo
- N
- NP
- H
- workers

Se calculan:

- cantidad de repeticiones
- media, mediana, desviación estándar, mínimo y máximo
- percentil 25 y percentil 75
- coeficiente de variación
- tiempo promedio en segundos
- GFLOPS
- speedup
- eficiencia
- overhead aproximado

Fórmula de GFLOPS:

```text
GFLOPS = (2 * N^3) / (tiempo_s * 1e9)
```

El speedup usa como baseline el menor número de workers disponible para cada algoritmo y tamaño `N`. Cuando existe `ProcesosMaster`, se usa preferiblemente como referencia.

## 6. Gráficas generadas

Los PNG se guardan en `resultados/graficas/`:

1. Tiempo promedio vs tamaño de matriz.
2. Comparación clásica vs transpuesta.
3. Speedup vs workers.
4. Eficiencia vs workers.
5. GFLOPS por configuración.
6. Boxplot de tiempos por configuración.
7. Heatmap de tiempo promedio.
8. Heatmap de GFLOPS.
9. Comparación de variabilidad por coeficiente de variación.

## 7. Limitaciones

- Los datos pueden tener ruido por red, sistema operativo, comunicación MPI o carga externa.
- Las métricas dependen de la calidad y estabilidad de las mediciones experimentales.
- La disponibilidad de ciertas gráficas puede depender de toolboxes instaladas en MATLAB.

## 8. Modelo predictivo con Regression Learner

Además del análisis descriptivo, se construyó un modelo de regresión en la app `Regression Learner` de MATLAB para estimar tiempos de ejecución a partir de la configuración experimental.

### Dataset usado

Se utilizó `datos/dataset_completo.csv` con:

- respuesta: `tiempo_us`
- predictores: `tipo`, `algoritmo`, `N`, `NP`, `H`, `workers`

### Flujo seguido

1. Abrir `Regression Learner`.
2. Importar `dataset_completo.csv`.
3. Definir `tiempo_us` como variable respuesta.
4. Entrenar varios modelos rápidos con validación cruzada de 5 folds.
5. Comparar `RMSE`, `MAE`, `MAPE` y `R²`.
6. Exportar el modelo seleccionado al workspace.
7. Guardarlo como archivo `.mat` en `resultados/modelos/`.
8. Guardar también la sesión completa de `Regression Learner` dentro de `resultados/modelos/`.

### Modelo seleccionado

Se conservaron los árboles de regresión porque superaron claramente a los modelos lineales. Entre `Fine Tree` y `Medium Tree`, se eligió `Medium Tree` porque obtuvo desempeño prácticamente idéntico con menor complejidad.

Archivo guardado:

- `resultados/modelos/modelo_medium_tree.mat` o equivalente

Sesión recomendada:

- `resultados/modelos/sesion_regression_learner.mat` o equivalente

Diferencia importante:

- el modelo exportado `.mat` sirve para cargar el predictor y usar `predictFcn` en código;
- la sesión guardada de `Regression Learner` conserva los modelos entrenados, la tabla comparativa y las gráficas asociadas para volver a abrirlas después.

### Pruebas integradas al flujo del proyecto

Se añadió `scripts/ejecutarPruebasModelo.m`, que es invocado automáticamente desde `main.m` cuando detecta un archivo `.mat` válido en `resultados/modelos/`.

La rutina:

1. Carga el modelo exportado.
2. Selecciona varios casos representativos a partir de las métricas observadas.
3. Ejecuta predicciones sobre esas configuraciones.
4. Compara predicción vs. tiempo medio observado.
5. Guarda una tabla de resultados en `resultados/tablas/pruebas_modelo_predictivo.csv`.

### Interpretación de la tabla de pruebas

En `pruebas_modelo_predictivo.csv` aparecen, entre otras, las columnas `speedup_observado`, `eficiencia_observada`, `tiempo_observado_medio_us`, `tiempo_predicho_us` y `error_absoluto_us`.

- `speedup_observado` se calcula como la razón entre el tiempo baseline y el tiempo de la configuración evaluada.
- `eficiencia_observada` se calcula como `speedup_observado / workers`.

Por eso, cuando `eficiencia_observada = 1`, normalmente significa que la configuración corresponde al caso baseline con `workers = 1`. En ese escenario también suele ocurrir `speedup_observado = 1`, ya que la configuración se está comparando contra sí misma como referencia. No implica que sea la mejor configuración global, sino que representa el punto base con eficiencia ideal del 100% bajo esa definición.

Cuando una fila presenta `error_absoluto_us = 0`, significa que el modelo predijo exactamente el mismo valor que el tiempo medio observado para esa configuración. En este proyecto eso puede ocurrir porque las pruebas se ejecutan sobre configuraciones ya presentes en el dataset original y el árbol de regresión puede recuperar exactamente el promedio aprendido para una combinación de predictores ya vista.

En consecuencia:

- `eficiencia_observada = 1` debe leerse como un efecto natural del baseline con un solo worker.
- `error_absoluto_us = 0` debe interpretarse como coincidencia exacta sobre una configuración conocida, no como garantía de generalización perfecta sobre configuraciones nuevas.

## Archivos de salida principales

- `resultados/tablas/datos_crudos.csv`
- `resultados/tablas/datos_limpios.csv`
- `resultados/tablas/metricas_configuraciones.csv`
- `resultados/tablas/pruebas_modelo_predictivo.csv`
- `resultados/resumen_ejecutivo.txt`
- `resultados/modelos/modelo_medium_tree.mat`
- `resultados/modelos/sesion_regression_learner.mat`

## Conclusiones

- El uso combinado de MPI y OpenMP permitió mejorar significativamente el rendimiento de la multiplicación de matrices, reduciendo los tiempos de ejecución a medida que aumentó el nivel de paralelismo disponible.
- La comparación entre los algoritmos clásico y transpuesto mostró diferencias de desempeño asociadas al acceso a memoria. En varias configuraciones, la versión transpuesta obtuvo mejores resultados gracias a un uso más eficiente de la caché.
- Aunque el incremento de procesos e hilos generó mejoras importantes en velocidad, la eficiencia tendió a disminuir para configuraciones de paralelismo más altas debido a los costos de comunicación y sincronización entre procesos.
- El modelo predictivo desarrollado en MATLAB demostró que es posible estimar los tiempos de ejecución a partir de las características de la configuración experimental, constituyendo una herramienta útil para apoyar la toma de decisiones y el análisis de rendimiento.