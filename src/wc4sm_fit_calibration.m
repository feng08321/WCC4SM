function model = wc4sm_fit_calibration(pixel,wavelength,degree,evaluationPixels,positionMethod,peakIDs,options)
%WC4SM_FIT_CALIBRATION Fit and validate a WCC4SM polynomial model.
% This non-GUI candidate module reproduces the V0.5.2 fitting statistics.

    arguments
        pixel (:,1) double
        wavelength (:,1) double
        degree (1,1) double {mustBeInteger,mustBeNonnegative}
        evaluationPixels (:,1) double = zeros(0,1)
        positionMethod {mustBeTextScalar} = 'Unspecified'
        peakIDs = {}
        options struct = struct()
    end

    if numel(pixel) ~= numel(wavelength)
        error('WCC4SM:CalibrationSizeMismatch', ...
            'Pixel and wavelength vectors must have equal length.');
    end
    if degree > 20
        error('WCC4SM:PolynomialDegreeLimit', ...
            'Polynomial degree %d exceeds the supported analysis limit of 20.',degree);
    end
    if numel(pixel) < degree+1
        error('WCC4SM:InsufficientCalibrationPoints', ...
            'Degree %d fitting requires at least %d valid points.',degree,degree+1);
    end
    if any(~isfinite(pixel)) || any(~isfinite(wavelength))
        error('WCC4SM:InvalidCalibrationData', ...
            'Pixel and wavelength values must be finite.');
    end
    if numel(unique(pixel)) ~= numel(pixel)
        error('WCC4SM:DuplicateCalibrationPixel', ...
            'Calibration pixel positions must be unique.');
    end

    if isempty(evaluationPixels)
        evaluationPixels = pixel;
    elseif any(~isfinite(evaluationPixels))
        error('WCC4SM:InvalidEvaluationPixels', ...
            'Evaluation pixels must be finite.');
    end

    if isempty(peakIDs)
        peakIDs = arrayfun(@(k) sprintf('P%03d',k), ...
            (1:numel(pixel)).','UniformOutput',false);
    elseif isstring(peakIDs)
        peakIDs = cellstr(peakIDs(:));
    elseif iscellstr(peakIDs) %#ok<ISCLSTR>
        peakIDs = peakIDs(:);
    else
        error('WCC4SM:InvalidPeakIDs','Peak IDs must be text values.');
    end
    if numel(peakIDs) ~= numel(pixel)
        error('WCC4SM:PeakIDSizeMismatch', ...
            'Peak ID count must equal the calibration point count.');
    end

    [pixel,order] = sort(pixel);
    wavelength = wavelength(order);
    peakIDs = peakIDs(order);
    [coefficients,S,mu] = polyfit(pixel,wavelength,degree);
    fitted = polyval(coefficients,pixel,[],mu);
    residual = wavelength-fitted;
    naturalCoefficients = normalizedToNaturalPolynomial(coefficients,mu);
    skipLOO=isfield(options,'SkipLOO')&&logical(options.SkipLOO);
    if numel(pixel) >= degree+2 && ~skipLOO
        validation = wc4sm_validate_calibration_loo(pixel,wavelength,degree, ...
            coefficients,mu,evaluationPixels);
        looStatus = 'Available';
    else
        validation = struct('LOOResidual',nan(numel(pixel),1), ...
            'DeletionMaxCurveChange',nan(numel(pixel),1),'LOORMS',NaN, ...
            'LOOMaxAbs',NaN,'MaxDeletionInfluence',NaN, ...
            'EvaluationPixels',evaluationPixels(:));
        if skipLOO,looStatus='Skipped for batch search';else,looStatus='Unavailable: minimum-size model';end
    end

    model = struct('valid',true,'PositionMethod',char(positionMethod), ...
        'Degree',degree,'Coefficients',coefficients,'Mu',mu,'S',S, ...
        'NaturalCoefficients',naturalCoefficients, ...
        'Equation',formatCalibrationEquation(naturalCoefficients), ...
        'PeakID',{peakIDs},'Pixel',pixel,'ReferenceWavelength',wavelength, ...
        'FittedWavelength',fitted,'Residual',residual, ...
        'MeanResidual',mean(residual),'STD',std(residual), ...
        'RMS',sqrt(mean(residual.^2)), ...
        'MaxAbsResidual',max(abs(residual)), ...
        'LOOResidual',validation.LOOResidual, ...
        'DeletionMaxCurveChange',validation.DeletionMaxCurveChange, ...
        'LOORMS',validation.LOORMS,'LOOMaxAbs',validation.LOOMaxAbs, ...
        'MaxDeletionInfluence',validation.MaxDeletionInfluence);
    model.LOOStatus=looStatus;
    model.DegreesOfFreedom=numel(pixel)-(degree+1);
end

function natural = normalizedToNaturalPolynomial(coefficients,mu)
    natural = 0;
    affine = [1/mu(2),-mu(1)/mu(2)];
    for k = 1:numel(coefficients)
        natural = conv(natural,affine);
        natural(end) = natural(end)+coefficients(k);
    end
    first = find(abs(natural) > ...
        max(1e-15,max(abs(natural))*1e-14),1,'first');
    if isempty(first)
        natural = 0;
    else
        natural = natural(first:end);
    end
end

function equation = formatCalibrationEquation(coefficients)
    degree = numel(coefficients)-1;
    parts = {};
    for k = 1:numel(coefficients)
        power = degree-k+1;
        value = coefficients(k);
        if abs(value) < 1e-15
            continue;
        end
        if power == 0
            term = sprintf('%.12g',abs(value));
        elseif power == 1
            term = sprintf('%.12g*p',abs(value));
        else
            term = sprintf('%.12g*p^%d',abs(value),power);
        end
        if isempty(parts)
            if value < 0, term = ['-' term]; end
            parts{end+1} = term; %#ok<AGROW>
        elseif value < 0
            parts{end+1} = [' - ' term]; %#ok<AGROW>
        else
            parts{end+1} = [' + ' term]; %#ok<AGROW>
        end
    end
    if isempty(parts), rightSide = '0'; else, rightSide = strjoin(parts,''); end
    equation = ['lambda(nm) = ' rightSide];
end
