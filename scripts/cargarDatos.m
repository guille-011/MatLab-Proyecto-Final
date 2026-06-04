function datos = cargarDatos(rutaDatos)
%CARGARDATOS Carga todos los archivos .dat y extrae metadatos del nombre.
%   Cada archivo debe tener tiempos en microsegundos. Las lineas vacias o
%   no numericas se ignoran para que el analisis resista archivos con texto.

    if nargin < 1 || ~isfolder(rutaDatos)
        error('La carpeta de datos no existe: %s', string(rutaDatos));
    end

    archivos = dir(fullfile(rutaDatos, '*.dat'));
    if isempty(archivos)
        error('No se encontraron archivos .dat en: %s', rutaDatos);
    end

    fprintf('Cargando %d archivos .dat desde %s\n', numel(archivos), rutaDatos);

    datos = table();
    archivosIgnorados = strings(0, 1);

    for i = 1:numel(archivos)
        nombreArchivo = string(archivos(i).name);
        rutaArchivo = fullfile(archivos(i).folder, archivos(i).name);

        metadatos = extraerMetadatos(nombreArchivo);
        if ~metadatos.valido
            warning('Nombre de archivo inesperado. Se ignora: %s', nombreArchivo);
            archivosIgnorados(end + 1) = nombreArchivo; %#ok<AGROW>
            continue;
        end

        tiempos = leerTiemposNumericos(rutaArchivo);
        if isempty(tiempos)
            warning('Archivo sin datos numericos. Se ignora: %s', nombreArchivo);
            archivosIgnorados(end + 1) = nombreArchivo; %#ok<AGROW>
            continue;
        end

        n = numel(tiempos);
        tablaArchivo = table();
        tablaArchivo.tipo = repmat(metadatos.tipo, n, 1);
        tablaArchivo.algoritmo = repmat(metadatos.algoritmo, n, 1);
        tablaArchivo.N = repmat(metadatos.N, n, 1);
        tablaArchivo.NP = repmat(metadatos.NP, n, 1);
        tablaArchivo.H = repmat(metadatos.H, n, 1);
        tablaArchivo.workers = repmat(metadatos.workers, n, 1);
        tablaArchivo.archivo = repmat(nombreArchivo, n, 1);
        tablaArchivo.repeticion = (1:n)';
        tablaArchivo.tiempo_us = tiempos(:);
        tablaArchivo.tiempo_s = tiempos(:) / 1e6;

        datos = [datos; tablaArchivo]; %#ok<AGROW>
    end

    if isempty(datos)
        error('No fue posible cargar mediciones validas desde la carpeta de datos.');
    end

    datos.tipo = categorical(datos.tipo);
    datos.algoritmo = categorical(datos.algoritmo);
    datos.archivo = string(datos.archivo);

    datos = sortrows(datos, {'tipo', 'algoritmo', 'N', 'NP', 'H', 'repeticion'});

    fprintf('Mediciones cargadas: %d\n', height(datos));
    if ~isempty(archivosIgnorados)
        fprintf('Archivos ignorados: %d\n', numel(archivosIgnorados));
    end
end

function metadatos = extraerMetadatos(nombreArchivo)
    patron = "^(ProcesosMaster|Procesos|Hilos)-Pr-(clasica|transpuesta)-N-(\d+)-NP-(\d+)(?:-H-(\d+))?\.dat$";
    partes = regexp(char(nombreArchivo), char(patron), 'tokens', 'once');

    metadatos = struct('valido', false);
    if isempty(partes)
        return;
    end

    metadatos.valido = true;
    metadatos.tipo = string(partes{1});
    metadatos.algoritmo = string(partes{2});
    metadatos.N = str2double(partes{3});
    metadatos.NP = str2double(partes{4});

    if numel(partes) >= 5 && ~isempty(partes{5})
        metadatos.H = str2double(partes{5});
    else
        metadatos.H = 1;
    end

    metadatos.workers = metadatos.NP - 1;
end

function tiempos = leerTiemposNumericos(rutaArchivo)
    fid = fopen(rutaArchivo, 'r');
    if fid == -1
        warning('No se pudo abrir el archivo: %s', rutaArchivo);
        tiempos = [];
        return;
    end

    tiempos = [];
    limpieza = onCleanup(@() fclose(fid));

    while true
        linea = fgetl(fid);
        if ~ischar(linea)
            break;
        end

        linea = strtrim(linea);
        if isempty(linea)
            continue;
        end

        valor = str2double(linea);
        if ~isnan(valor)
            tiempos(end + 1, 1) = valor; %#ok<AGROW>
        end
    end
end
