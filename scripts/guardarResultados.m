function guardarResultados(rutas, tablas, resumen)
%GUARDARRESULTADOS Crea carpetas y guarda tablas/resumen cuando se indique.
%   guardarResultados(rutas) solo crea carpetas.
%   guardarResultados(rutas, tablas) guarda cada tabla del struct en CSV.
%   guardarResultados(rutas, tablas, resumen) tambien guarda resumen TXT.

    if nargin < 1 || isempty(rutas)
        error('Debe entregar una estructura de rutas.');
    end

    carpetas = {'resultados', 'tablas', 'graficas', 'modelos'};
    for i = 1:numel(carpetas)
        campo = carpetas{i};
        if isfield(rutas, campo) && ~isfolder(rutas.(campo))
            mkdir(rutas.(campo));
        end
    end

    if nargin >= 2 && ~isempty(tablas)
        nombres = fieldnames(tablas);
        for i = 1:numel(nombres)
            nombre = nombres{i};
            valor = tablas.(nombre);
            if istable(valor)
                archivo = fullfile(rutas.tablas, [nombre '.csv']);
                writetable(valor, archivo);
            end
        end
    end

    if nargin >= 3 && ~isempty(resumen)
        archivoResumen = fullfile(rutas.resultados, 'resumen_ejecutivo.txt');
        fid = fopen(archivoResumen, 'w');
        if fid == -1
            warning('No se pudo escribir el resumen: %s', archivoResumen);
            return;
        end
        limpieza = onCleanup(@() fclose(fid));
        for i = 1:numel(resumen)
            fprintf(fid, '%s\n', resumen(i));
        end
    end
end
