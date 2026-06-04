%% Proyecto MATLAB - Analisis de rendimiento MPI + OpenMP
% Ejecutar este archivo para cargar datos, calcular metricas, generar
% graficas y guardar resultados.

clear;
clc;
close all;

fprintf('=== Analisis de rendimiento de cluster MPI + OpenMP ===\n\n');

%% 1. Definir rutas del proyecto
rutaScripts = fileparts(mfilename('fullpath'));
rutaProyecto = fileparts(rutaScripts);
addpath(rutaScripts);

rutas.proyecto = rutaProyecto;
rutas.datos = fullfile(rutaProyecto, 'datos');
rutas.resultados = fullfile(rutaProyecto, 'resultados');
rutas.tablas = fullfile(rutas.resultados, 'tablas');
rutas.graficas = fullfile(rutas.resultados, 'graficas');
rutas.modelos = fullfile(rutas.resultados, 'modelos');

guardarResultados(rutas);

%% 2. Cargar datos experimentales
datos = cargarDatos(rutas.datos);

%% 3. Limpiar datos invalidos
datosLimpios = limpiarDatos(datos);

%% 4. Calcular metricas por configuracion
metricas = calcularMetricas(datosLimpios);

%% 5. Guardar tablas procesadas
tablas = struct();
tablas.datos_crudos = datos;
tablas.datos_limpios = datosLimpios;
tablas.metricas_configuraciones = metricas;
guardarResultados(rutas, tablas);

%% 6. Generar graficas comparativas
generarGraficas(datosLimpios, metricas, rutas.graficas);

%% 7. Ejecutar pruebas del modelo predictivo si existe
resultadoPruebasModelo = ejecutarPruebasModelo(datosLimpios, metricas, rutas);

%% 8. Preparar resumen ejecutivo
[~, idxMejorTiempo] = min(metricas.media_tiempo_s);
[~, idxMejorGflops] = max(metricas.GFLOPS);
[~, idxMasEstable] = min(metricas.coef_variacion);

mejorTiempo = metricas(idxMejorTiempo, :);
mejorGflops = metricas(idxMejorGflops, :);
masEstable = metricas(idxMasEstable, :);

resumen = strings(0, 1);
resumen(end + 1) = "Resumen ejecutivo del analisis";
resumen(end + 1) = "Fecha: " + string(datetime('now'));
resumen(end + 1) = "";
resumen(end + 1) = "Total de archivos cargados: " + string(numel(unique(datos.archivo)));
resumen(end + 1) = "Total de mediciones validas: " + string(height(datosLimpios));
resumen(end + 1) = "";
resumen(end + 1) = "Mejor configuracion por tiempo promedio:";
resumen(end + 1) = string(describirConfiguracion(mejorTiempo, "media_tiempo_s"));
resumen(end + 1) = "Mejor configuracion por GFLOPS:";
resumen(end + 1) = string(describirConfiguracion(mejorGflops, "GFLOPS"));
resumen(end + 1) = "Configuracion mas estable por coeficiente de variacion:";
resumen(end + 1) = string(describirConfiguracion(masEstable, "coef_variacion"));
if resultadoPruebasModelo.ejecutado
    resumen(end + 1) = "";
    resumen(end + 1) = "Pruebas del modelo predictivo:";
    resumen(end + 1) = "Modelo usado: " + resultadoPruebasModelo.ruta_modelo;
    resumen(end + 1) = "Resultados de prueba: " + resultadoPruebasModelo.archivo_salida;
end

guardarResultados(rutas, struct(), resumen);

%% 9. Mostrar resumen en consola
fprintf('\n=== Resumen ejecutivo ===\n');
fprintf('- Total de archivos cargados: %d\n', numel(unique(datos.archivo)));
fprintf('- Total de mediciones: %d\n', height(datos));
fprintf('- Mediciones validas: %d\n', height(datosLimpios));
fprintf('- Mejor configuracion por tiempo promedio: %s\n', describirConfiguracion(mejorTiempo, "media_tiempo_s"));
fprintf('- Mejor configuracion por GFLOPS: %s\n', describirConfiguracion(mejorGflops, "GFLOPS"));
fprintf('- Configuracion mas estable: %s\n', describirConfiguracion(masEstable, "coef_variacion"));
if resultadoPruebasModelo.ejecutado
    fprintf('- Pruebas del modelo guardadas en: %s\n', char(resultadoPruebasModelo.archivo_salida));
else
    fprintf('- No se ejecutaron pruebas del modelo predictivo.\n');
end
fprintf('\nResultados guardados en: %s\n', rutas.resultados);

function texto = describirConfiguracion(fila, nombreMetrica)
    valor = fila.(nombreMetrica);
    if nombreMetrica == "media_tiempo_s"
        unidad = "s";
    elseif nombreMetrica == "GFLOPS"
        unidad = "GFLOPS";
    else
        unidad = "";
    end

    texto = sprintf('%s | %s | N=%d | NP=%d | H=%d | workers=%d | %s=%.6g %s', ...
        string(fila.tipo), string(fila.algoritmo), fila.N, fila.NP, fila.H, ...
        fila.workers, nombreMetrica, valor, unidad);
end
