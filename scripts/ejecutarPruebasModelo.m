function resultado = ejecutarPruebasModelo(datosLimpios, metricas, rutas)
%EJECUTARPRUEBASMODELO Ejecuta pruebas de prediccion sobre casos conocidos.
%   Carga el primer modelo valido encontrado en resultados/modelos, ejecuta
%   predicciones sobre un conjunto pequeno de configuraciones
%   representativas y guarda una tabla comparativa en resultados/tablas.

    if nargin < 3
        error('Uso: ejecutarPruebasModelo(datosLimpios, metricas, rutas)');
    end

    resultado = struct( ...
        'ejecutado', false, ...
        'ruta_modelo', "", ...
        'nombre_variable', "", ...
        'archivo_salida', "", ...
        'tabla', table());

    if ~isfield(rutas, 'modelos') || strlength(string(rutas.modelos)) == 0
        rutas.modelos = fullfile(rutas.resultados, 'modelos');
    end

    if ~isfolder(rutas.modelos)
        warning('No existe la carpeta de modelos: %s', rutas.modelos);
        return;
    end

    [modelo, nombreVariable, rutaModelo] = cargarModeloEntrenado(rutas.modelos);
    if isempty(modelo)
        warning('No se encontro un modelo exportado valido en: %s', rutas.modelos);
        return;
    end

    casos = construirCasosPrueba(metricas);
    if isempty(casos)
        warning('No se pudieron construir casos de prueba para el modelo.');
        return;
    end

    entradas = casos(:, {'tipo', 'algoritmo', 'N', 'NP', 'H', 'workers'});
    predichoUs = modelo.predictFcn(entradas);

    tabla = table();
    tabla.caso = string(casos.caso);
    tabla.tipo = string(casos.tipo);
    tabla.algoritmo = string(casos.algoritmo);
    tabla.N = casos.N;
    tabla.NP = casos.NP;
    tabla.H = casos.H;
    tabla.workers = casos.workers;
    tabla.tiempo_observado_medio_us = casos.media_tiempo_us;
    tabla.tiempo_predicho_us = predichoUs;
    tabla.error_absoluto_us = abs(tabla.tiempo_predicho_us - tabla.tiempo_observado_medio_us);
    tabla.error_relativo_pct = 100 .* tabla.error_absoluto_us ./ tabla.tiempo_observado_medio_us;
    tabla.tiempo_observado_medio_s = casos.media_tiempo_s;
    tabla.tiempo_predicho_s = tabla.tiempo_predicho_us / 1e6;
    tabla.GFLOPS_observado = casos.GFLOPS;
    tabla.speedup_observado = casos.speedup;
    tabla.eficiencia_observada = casos.eficiencia;

    archivoSalida = fullfile(rutas.tablas, 'pruebas_modelo_predictivo.csv');
    writetable(tabla, archivoSalida);

    fprintf('Pruebas del modelo predictivo guardadas en: %s\n', archivoSalida);

    resultado.ejecutado = true;
    resultado.ruta_modelo = string(rutaModelo);
    resultado.nombre_variable = string(nombreVariable);
    resultado.archivo_salida = string(archivoSalida);
    resultado.tabla = tabla;
end

function [modelo, nombreVariable, rutaModelo] = cargarModeloEntrenado(carpetaModelos)
    modelo = [];
    nombreVariable = "";
    rutaModelo = "";

    archivos = dir(fullfile(carpetaModelos, '*.mat'));
    for i = 1:numel(archivos)
        rutaArchivo = fullfile(archivos(i).folder, archivos(i).name);
        contenido = load(rutaArchivo);
        nombres = fieldnames(contenido);

        for j = 1:numel(nombres)
            candidato = contenido.(nombres{j});
            if isstruct(candidato) && isfield(candidato, 'predictFcn') && isa(candidato.predictFcn, 'function_handle')
                modelo = candidato;
                nombreVariable = string(nombres{j});
                rutaModelo = string(rutaArchivo);
                return;
            end
        end
    end
end

function casos = construirCasosPrueba(metricas)
    casos = table();

    if isempty(metricas)
        return;
    end

    [~, idxMejorTiempo] = min(metricas.media_tiempo_s);
    casos = agregarCaso(casos, 'mejor_tiempo', metricas(idxMejorTiempo, :));

    [~, idxMejorGflops] = max(metricas.GFLOPS);
    casos = agregarCaso(casos, 'mejor_gflops', metricas(idxMejorGflops, :));

    [~, idxMasEstable] = min(metricas.coef_variacion);
    casos = agregarCaso(casos, 'mas_estable', metricas(idxMasEstable, :));

    candidatosProcesos = metricas(string(metricas.tipo) == "Procesos", :);
    if ~isempty(candidatosProcesos)
        candidatosProcesos = sortrows(candidatosProcesos, {'N', 'workers', 'media_tiempo_us'}, {'descend', 'descend', 'ascend'});
        casos = agregarCaso(casos, 'procesos_extremo', candidatosProcesos(1, :));
    end

    candidatosHilos = metricas(string(metricas.tipo) == "Hilos", :);
    if ~isempty(candidatosHilos)
        candidatosHilos = sortrows(candidatosHilos, {'N', 'H', 'media_tiempo_us'}, {'descend', 'descend', 'ascend'});
        casos = agregarCaso(casos, 'hilos_extremo', candidatosHilos(1, :));
    end

    if height(casos) < 5
        relleno = sortrows(metricas, {'tipo', 'algoritmo', 'N', 'workers', 'H'});
        for i = 1:height(relleno)
            etiqueta = "relleno_" + string(i);
            casos = agregarCaso(casos, etiqueta, relleno(i, :));
            if height(casos) >= 5
                break;
            end
        end
    end

    casos = movevars(casos, 'caso', 'Before', 1);
end

function casos = agregarCaso(casos, etiqueta, fila)
    if isempty(fila)
        return;
    end

    if ~isempty(casos)
        duplicado = string(casos.tipo) == string(fila.tipo) & ...
            string(casos.algoritmo) == string(fila.algoritmo) & ...
            casos.N == fila.N & ...
            casos.NP == fila.NP & ...
            casos.H == fila.H & ...
            casos.workers == fila.workers;
        if any(duplicado)
            return;
        end
    end

    fila.caso = string(etiqueta);
    casos = [casos; fila];
end
