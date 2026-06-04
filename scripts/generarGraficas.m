function generarGraficas(datosLimpios, metricas, rutaGraficas)
%GENERARGRAFICAS Crea y guarda graficas comparativas en PNG.

    if nargin < 3 || isempty(rutaGraficas)
        error('Debe indicar la carpeta donde se guardaran las graficas.');
    end
    if ~isfolder(rutaGraficas)
        mkdir(rutaGraficas);
    end

    fprintf('Generando graficas en %s\n', rutaGraficas);

    datos = datosLimpios;
    crearTiempoVsN(metricas, rutaGraficas);
    crearComparacionAlgoritmos(metricas, rutaGraficas);
    crearSpeedup(metricas, rutaGraficas);
    crearEficiencia(metricas, rutaGraficas);
    crearGflops(metricas, rutaGraficas);
    crearBoxplot(datos, rutaGraficas);
    crearHeatmapTiempo(metricas, rutaGraficas);
    crearHeatmapGflops(metricas, rutaGraficas);
    crearVariabilidad(metricas, rutaGraficas);

    close all;
end

function crearTiempoVsN(metricas, ruta)
    fig = nuevaFigura();
    hold on;
    claves = unique(metricas(:, {'tipo', 'algoritmo'}), 'rows');
    for i = 1:height(claves)
        idx = metricas.tipo == claves.tipo(i) & metricas.algoritmo == claves.algoritmo(i);
        datos = sortrows(metricas(idx, :), 'N');
        etiqueta = sprintf('%s - %s', string(claves.tipo(i)), string(claves.algoritmo(i)));
        plot(datos.N, datos.media_tiempo_s, '-o', 'LineWidth', 1.8, 'DisplayName', etiqueta);
    end
    xlabel('Tamano de matriz N');
    ylabel('Tiempo promedio (s)');
    title('Tiempo promedio vs tamano de matriz');
    legend('Location', 'best');
    grid on;
    guardarFigura(fig, ruta, '01_tiempo_promedio_vs_N.png');
end

function crearComparacionAlgoritmos(metricas, ruta)
    resumen = combinarPorNAlgoritmo(metricas, 'media_tiempo_s');
    fig = nuevaFigura();
    if isempty(resumen)
        title('Comparacion clasica vs transpuesta: sin datos suficientes');
    else
        bar(categorical(resumen.N), [resumen.clasica, resumen.transpuesta]);
        xlabel('Tamano de matriz N');
        ylabel('Tiempo promedio (s)');
        title('Comparacion de algoritmos por tiempo promedio');
        legend({'clasica', 'transpuesta'}, 'Location', 'best');
        grid on;
    end
    guardarFigura(fig, ruta, '02_comparacion_algoritmos.png');
end

function crearSpeedup(metricas, ruta)
    fig = nuevaFigura();
    hold on;
    claves = unique(metricas(:, {'tipo', 'algoritmo', 'N'}), 'rows');
    for i = 1:height(claves)
        idx = metricas.tipo == claves.tipo(i) & metricas.algoritmo == claves.algoritmo(i) & metricas.N == claves.N(i);
        datos = sortrows(metricas(idx, :), 'workers');
        etiqueta = sprintf('%s - %s - N=%d', string(claves.tipo(i)), string(claves.algoritmo(i)), claves.N(i));
        plot(datos.workers, datos.speedup, '-o', 'LineWidth', 1.5, 'DisplayName', etiqueta);
    end
    xlabel('Workers (NP - 1)');
    ylabel('Speedup');
    title('Speedup vs workers');
    legend('Location', 'eastoutside');
    grid on;
    guardarFigura(fig, ruta, '03_speedup_vs_workers.png');
end

function crearEficiencia(metricas, ruta)
    fig = nuevaFigura();
    hold on;
    claves = unique(metricas(:, {'algoritmo', 'N'}), 'rows');
    for i = 1:height(claves)
        idx = metricas.algoritmo == claves.algoritmo(i) & metricas.N == claves.N(i);
        datos = sortrows(metricas(idx, :), 'workers');
        etiqueta = sprintf('%s - N=%d', string(claves.algoritmo(i)), claves.N(i));
        plot(datos.workers, datos.eficiencia, '-o', 'LineWidth', 1.5, 'DisplayName', etiqueta);
    end
    xlabel('Workers (NP - 1)');
    ylabel('Eficiencia');
    title('Eficiencia vs workers');
    legend('Location', 'eastoutside');
    grid on;
    guardarFigura(fig, ruta, '04_eficiencia_vs_workers.png');
end

function crearGflops(metricas, ruta)
    fig = nuevaFigura();
    etiquetas = crearEtiquetaConfiguracion(metricas);
    bar(categorical(etiquetas), metricas.GFLOPS);
    ylabel('GFLOPS');
    title('GFLOPS por configuracion');
    grid on;
    ax = gca;
    ax.XTickLabelRotation = 70;
    guardarFigura(fig, ruta, '05_gflops_por_configuracion.png');
end

function crearBoxplot(datos, ruta)
    fig = nuevaFigura();
    if exist('boxplot', 'file') ~= 2
        warning('boxplot no esta disponible. Se omite la grafica 06_boxplot_tiempos.');
        close(fig);
        return;
    end
    etiquetas = crearEtiquetaConfiguracion(datos);
    boxplot(datos.tiempo_s, etiquetas, 'LabelOrientation', 'inline');
    ylabel('Tiempo (s)');
    title('Boxplot de tiempos por configuracion');
    grid on;
    ax = gca;
    ax.XTickLabelRotation = 70;
    guardarFigura(fig, ruta, '06_boxplot_tiempos.png');
end

function crearHeatmapTiempo(metricas, ruta)
    fig = nuevaFigura();
    crearHeatmap(metricas, 'media_tiempo_s', 'Tiempo promedio (s)');
    title('Heatmap de tiempo promedio');
    guardarFigura(fig, ruta, '07_heatmap_tiempo_promedio.png');
end

function crearHeatmapGflops(metricas, ruta)
    fig = nuevaFigura();
    crearHeatmap(metricas, 'GFLOPS', 'GFLOPS');
    title('Heatmap de GFLOPS');
    guardarFigura(fig, ruta, '08_heatmap_gflops.png');
end

function crearVariabilidad(metricas, ruta)
    fig = nuevaFigura();
    etiquetas = crearEtiquetaConfiguracion(metricas);
    bar(categorical(etiquetas), metricas.coef_variacion);
    ylabel('Coeficiente de variacion');
    title('Variabilidad por configuracion');
    grid on;
    ax = gca;
    ax.XTickLabelRotation = 70;
    guardarFigura(fig, ruta, '09_variabilidad_coeficiente_variacion.png');
end

function crearHeatmap(metricas, variable, etiquetaColor)
    if any(string(metricas.tipo) == "Hilos")
        filas = metricas.H;
        etiquetaY = 'Hilos OpenMP (H)';
    else
        filas = metricas.workers;
        etiquetaY = 'Workers';
    end

    valoresFila = unique(filas);
    valoresN = unique(metricas.N);
    matriz = nan(numel(valoresFila), numel(valoresN));

    for i = 1:numel(valoresFila)
        for j = 1:numel(valoresN)
            idx = filas == valoresFila(i) & metricas.N == valoresN(j);
            if any(idx)
                matriz(i, j) = mean(metricas.(variable)(idx), 'omitnan');
            end
        end
    end

    imagesc(valoresN, valoresFila, matriz);
    set(gca, 'YDir', 'normal');
    xlabel('Tamano de matriz N');
    ylabel(etiquetaY);
    colorbar;
    ylabel(colorbar, etiquetaColor);
    grid on;
end

function resumen = combinarPorNAlgoritmo(metricas, variable)
    tamanos = unique(metricas.N);
    resumen = table(tamanos, nan(numel(tamanos), 1), nan(numel(tamanos), 1), ...
        'VariableNames', {'N', 'clasica', 'transpuesta'});

    for i = 1:numel(tamanos)
        idxClasica = metricas.N == tamanos(i) & string(metricas.algoritmo) == "clasica";
        idxTranspuesta = metricas.N == tamanos(i) & string(metricas.algoritmo) == "transpuesta";
        if any(idxClasica)
            resumen.clasica(i) = mean(metricas.(variable)(idxClasica), 'omitnan');
        end
        if any(idxTranspuesta)
            resumen.transpuesta(i) = mean(metricas.(variable)(idxTranspuesta), 'omitnan');
        end
    end
end

function etiquetas = crearEtiquetaConfiguracion(tabla)
    etiquetas = strings(height(tabla), 1);
    for i = 1:height(tabla)
        etiquetas(i) = sprintf('%s-%s-N%d-W%d-H%d', string(tabla.tipo(i)), ...
            string(tabla.algoritmo(i)), tabla.N(i), tabla.workers(i), tabla.H(i));
    end
end

function fig = nuevaFigura()
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1300 750]);
end

function guardarFigura(fig, ruta, nombre)
    archivo = fullfile(ruta, nombre);
    try
        exportgraphics(fig, archivo, 'Resolution', 180);
    catch
        saveas(fig, archivo);
    end
end
