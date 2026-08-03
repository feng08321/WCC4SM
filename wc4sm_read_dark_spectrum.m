function dark = wc4sm_read_dark_spectrum(filePath,targetX)
%WC4SM_READ_DARK_SPECTRUM Read and align a dark spectrum to measured X.
% One-column input must have the same length as targetX. Two-column input
% is linearly interpolated and must cover the complete measured range.

    arguments
        filePath {mustBeTextScalar}
        targetX (:,1) double
    end

    filePath = char(filePath);
    if ~isfile(filePath)
        error('WCC4SM:FileNotFound','Dark-spectrum file does not exist: %s',filePath);
    end
    if numel(targetX) < 3 || any(~isfinite(targetX)) || any(diff(targetX) <= 0)
        error('WCC4SM:InvalidTargetX', ...
            'Measured target coordinates must be finite and strictly increasing.');
    end

    matrix = readmatrix(filePath);
    matrix = removeEmptyNumericRowsAndColumns(matrix);
    if size(matrix,2) > 2
        matrix = matrix(:,1:2);
    end

    interpolated = false;
    if size(matrix,2) == 1
        values = matrix(:,1);
        if numel(values) ~= numel(targetX)
            error('WCC4SM:DarkLengthMismatch', ...
                'A one-column dark spectrum must contain exactly %d samples.',numel(targetX));
        end
    else
        darkX = matrix(:,1);
        values = matrix(:,2);
        good = isfinite(darkX) & isfinite(values);
        darkX = darkX(good);
        values = values(good);
        if numel(darkX) < 2 || any(diff(darkX) <= 0)
            error('WCC4SM:InvalidDarkX', ...
                'The dark-spectrum X column must be strictly increasing.');
        end
        tolerance = 100*eps(max(1,max(abs(targetX))));
        if min(targetX) < min(darkX)-tolerance || ...
                max(targetX) > max(darkX)+tolerance
            error('WCC4SM:DarkRangeMismatch', ...
                'The dark spectrum does not cover the full X range of the measured spectrum.');
        end
        values = interp1(darkX,values,targetX,'linear');
        interpolated = true;
    end

    if any(~isfinite(values))
        error('WCC4SM:InvalidDarkSpectrum', ...
            'Dark-spectrum interpolation produced invalid values.');
    end
    dark = struct('values',values(:),'source',filePath, ...
        'interpolated',interpolated,'sampleCount',numel(values));
end

function matrix = removeEmptyNumericRowsAndColumns(matrix)
    matrix = matrix(~all(isnan(matrix),2),:);
    matrix = matrix(:,~all(isnan(matrix),1));
    if isempty(matrix)
        error('WCC4SM:InvalidDarkSpectrum', ...
            'Dark-spectrum file contains no numeric data.');
    end
end
