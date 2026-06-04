function resultado = limpiarDatos(datos)
%LIMPIARDATOS Elimina mediciones invalidas de la tabla experimental.
%   Se eliminan tiempos vacios, NaN, infinitos, negativos o iguales a cero.

    validarColumnas(datos, {'tipo', 'algoritmo', 'N', 'NP', 'H', 'workers', 'tiempo_us', 'tiempo_s'});

    fprintf('Limpiando datos invalidos...\n');

    esValido = ~ismissing(datos.tiempo_us) & ...
        ~isnan(datos.tiempo_us) & ...
        isfinite(datos.tiempo_us) & ...
        datos.tiempo_us > 0;

    invalidos = sum(~esValido);
    if invalidos > 0
        fprintf('Mediciones invalidas eliminadas: %d\n', invalidos);
    end

    datosValidos = datos(esValido, :);
    datosValidos.tiempo_s = datosValidos.tiempo_us / 1e6;

    resultado = datosValidos;

    fprintf('Mediciones validas para analisis: %d\n', height(resultado));
end

function validarColumnas(tabla, columnas)
    faltantes = setdiff(columnas, tabla.Properties.VariableNames);
    if ~isempty(faltantes)
        error('Faltan columnas requeridas: %s', strjoin(faltantes, ', '));
    end
end
