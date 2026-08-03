function validation = wc4sm_validate_calibration_loo(pixel,wavelength,degree,fullCoefficients,fullMu,evaluationPixels)
%WC4SM_VALIDATE_CALIBRATION_LOO Leave-one-out calibration diagnostics.
% Residual sign is reference wavelength minus predicted wavelength.

    arguments
        pixel (:,1) double
        wavelength (:,1) double
        degree (1,1) double {mustBeInteger,mustBeNonnegative}
        fullCoefficients (1,:) double
        fullMu (1,2) double
        evaluationPixels (:,1) double
    end

    if numel(pixel) ~= numel(wavelength)
        error('WCC4SM:CalibrationSizeMismatch', ...
            'Pixel and wavelength vectors must have equal length.');
    end
    if numel(pixel) < degree+2
        error('WCC4SM:InsufficientCalibrationPoints', ...
            'Degree %d LOO validation requires at least %d points.',degree,degree+2);
    end
    if any(~isfinite(pixel)) || any(~isfinite(wavelength)) || ...
            any(~isfinite(evaluationPixels))
        error('WCC4SM:InvalidCalibrationData', ...
            'Calibration and evaluation coordinates must be finite.');
    end
    if numel(unique(pixel)) ~= numel(pixel)
        error('WCC4SM:DuplicateCalibrationPixel', ...
            'Calibration pixel positions must be unique.');
    end
    if isempty(evaluationPixels)
        error('WCC4SM:EmptyEvaluationRange', ...
            'At least one evaluation pixel is required.');
    end

    n = numel(pixel);
    looResidual = nan(n,1);
    maxCurveChange = nan(n,1);
    fullCurve = polyval(fullCoefficients,evaluationPixels,[],fullMu);
    for k = 1:n
        keep = true(n,1);
        keep(k) = false;
        [coefficients,~,mu] = polyfit(pixel(keep),wavelength(keep),degree);
        prediction = polyval(coefficients,pixel(k),[],mu);
        looResidual(k) = wavelength(k)-prediction;
        deletedCurve = polyval(coefficients,evaluationPixels,[],mu);
        maxCurveChange(k) = max(abs(fullCurve-deletedCurve));
    end

    validation = struct('LOOResidual',looResidual, ...
        'DeletionMaxCurveChange',maxCurveChange, ...
        'LOORMS',sqrt(mean(looResidual.^2)), ...
        'LOOMaxAbs',max(abs(looResidual)), ...
        'MaxDeletionInfluence',max(maxCurveChange), ...
        'EvaluationPixels',evaluationPixels(:));
end
