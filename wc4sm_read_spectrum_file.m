function spectrum = wc4sm_read_spectrum_file(filePath,inputKind,pixelStart)
%WC4SM_READ_SPECTRUM_FILE Read a one- or two-column spectrum file.
% This is a non-GUI candidate module for a future WCC4SM integration.
% It does not modify application state.

    arguments
        filePath {mustBeTextScalar}
        inputKind {mustBeTextScalar} = 'Wavelength'
        pixelStart (1,1) double {mustBeInteger} = 0
    end

    filePath = char(filePath);
    inputKind = validatestring(char(inputKind),{'Wavelength','Pixel'});
    if ~isfile(filePath)
        error('WCC4SM:FileNotFound','Spectrum file does not exist: %s',filePath);
    end

    matrix = readmatrix(filePath);
    matrix = removeEmptyNumericRowsAndColumns(matrix);
    if size(matrix,2) > 2
        matrix = matrix(:,1:2);
    end

    if size(matrix,2) == 1
        raw = matrix(:,1);
        inputX = (pixelStart:pixelStart+numel(raw)-1).';
        xKind = 'Pixel';
    else
        inputX = matrix(:,1);
        raw = matrix(:,2);
        good = isfinite(inputX) & isfinite(raw);
        inputX = inputX(good);
        raw = raw(good);
        xKind = inputKind;
    end

    if numel(raw) < 3
        error('WCC4SM:InsufficientSamples', ...
            'At least 3 finite samples are required.');
    end
    if any(~isfinite(inputX)) || any(~isfinite(raw))
        error('WCC4SM:InvalidSpectrum', ...
            'Spectrum coordinates and signal must be finite.');
    end
    if any(diff(inputX) <= 0)
        error('WCC4SM:InvalidSpectrumX', ...
            'The first column must be strictly increasing.');
    end

    naturalPixel = (pixelStart:pixelStart+numel(raw)-1).';
    inputWavelength = [];
    if strcmp(xKind,'Wavelength')
        inputWavelength = inputX(:);
    end
    spectrum = struct('raw',raw(:),'dark',[],'darkSource','', ...
        'corrected',[],'normalized',[],'pixel',naturalPixel, ...
        'inputX',inputX(:),'inputWavelength',inputWavelength, ...
        'calibratedWavelength',[],'xKind',xKind,'source',filePath);
end

function matrix = removeEmptyNumericRowsAndColumns(matrix)
    if ~isnumeric(matrix)
        error('WCC4SM:InvalidSpectrum','Spectrum file contains no numeric matrix.');
    end
    matrix = matrix(~all(isnan(matrix),2),:);
    matrix = matrix(:,~all(isnan(matrix),1));
    if isempty(matrix)
        error('WCC4SM:InvalidSpectrum','Spectrum file contains no numeric data.');
    end
end
