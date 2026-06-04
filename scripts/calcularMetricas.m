function metricas = calcularMetricas(datos)
%CALCULARMETRICAS Calcula estadisticos y metricas de rendimiento.
%   Agrupa por tipo, algoritmo, N, NP, H y workers.

    if isempty(datos)
        error('No hay datos para calcular metricas.');
    end

    fprintf('Calculando metricas por configuracion...\n');

    variablesGrupo = {'tipo', 'algoritmo', 'N', 'NP', 'H', 'workers'};
    [grupos, claves] = findgroups(datos(:, variablesGrupo));

    cantidad = splitapply(@numel, datos.tiempo_us, grupos);
    media_us = splitapply(@mean, datos.tiempo_us, grupos);
    mediana_us = splitapply(@median, datos.tiempo_us, grupos);
    desviacion_us = splitapply(@std, datos.tiempo_us, grupos);
    minimo_us = splitapply(@min, datos.tiempo_us, grupos);
    maximo_us = splitapply(@max, datos.tiempo_us, grupos);
    p25_us = splitapply(@(x) prctile(x, 25), datos.tiempo_us, grupos);
    p75_us = splitapply(@(x) prctile(x, 75), datos.tiempo_us, grupos);

    metricas = claves;
    metricas.repeticiones = cantidad;
    metricas.media_tiempo_us = media_us;
    metricas.mediana_tiempo_us = mediana_us;
    metricas.desviacion_tiempo_us = desviacion_us;
    metricas.min_tiempo_us = minimo_us;
    metricas.max_tiempo_us = maximo_us;
    metricas.percentil25_us = p25_us;
    metricas.percentil75_us = p75_us;
    metricas.coef_variacion = desviacion_us ./ media_us;
    metricas.media_tiempo_s = media_us / 1e6;
    metricas.mediana_tiempo_s = mediana_us / 1e6;
    metricas.GFLOPS = (2 .* (metricas.N .^ 3)) ./ (metricas.media_tiempo_s .* 1e9);

    [speedup, eficiencia, overhead] = calcularEscalabilidad(metricas);
    metricas.speedup = speedup;
    metricas.eficiencia = eficiencia;
    metricas.overhead_aproximado_s = overhead;

    metricas = sortrows(metricas, {'algoritmo', 'N', 'tipo', 'workers', 'H'});
    fprintf('Configuraciones calculadas: %d\n', height(metricas));
end

function [speedup, eficiencia, overhead] = calcularEscalabilidad(metricas)
    speedup = nan(height(metricas), 1);
    eficiencia = nan(height(metricas), 1);
    overhead = nan(height(metricas), 1);

    algoritmos = categories(categorical(metricas.algoritmo));
    tamanos = unique(metricas.N);

    for a = 1:numel(algoritmos)
        for n = 1:numel(tamanos)
            idxBaseGrupo = string(metricas.algoritmo) == string(algoritmos{a}) & metricas.N == tamanos(n);

            if ~any(idxBaseGrupo)
                continue;
            end

            idxMaster = idxBaseGrupo & string(metricas.tipo) == "ProcesosMaster";
            if any(idxMaster)
                candidatos = find(idxMaster);
            else
                candidatos = find(idxBaseGrupo);
            end

            [~, posMinWorkers] = min(metricas.workers(candidatos));
            idxBaseline = candidatos(posMinWorkers);
            tiempoBaseline = metricas.media_tiempo_s(idxBaseline);

            indices = find(idxBaseGrupo);
            for k = 1:numel(indices)
                i = indices(k);
                tiempoConfig = metricas.media_tiempo_s(i);
                speedup(i) = tiempoBaseline / tiempoConfig;

                if metricas.workers(i) > 0
                    eficiencia(i) = speedup(i) / metricas.workers(i);
                    overhead(i) = metricas.workers(i) * tiempoConfig - tiempoBaseline;
                end
            end
        end
    end
end
