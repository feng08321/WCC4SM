function performance = wc4sm_calculate_calibrated_performance(model,peakResults,pixelAxis)
%WC4SM_CALCULATE_CALIBRATED_PERFORMANCE Calculate wavelength-domain metrics.
% peakResults is a cell array (or struct array) of confirmed peak-analysis
% result structures. This function performs no plotting and changes no UI state.

    arguments
        model (1,1) struct
        peakResults
        pixelAxis (:,1) double
    end

    validateModel(model);
    if numel(pixelAxis) < 2 || any(~isfinite(pixelAxis)) || any(diff(pixelAxis)<=0)
        error('WCC4SM:InvalidPixelAxis', ...
            'Pixel axis must contain at least two finite, strictly increasing values.');
    end
    if isstruct(peakResults)
        peakResults = num2cell(peakResults(:));
    elseif iscell(peakResults)
        peakResults = peakResults(:);
    else
        error('WCC4SM:InvalidPeakResults', ...
            'Peak results must be a struct array or cell array of structures.');
    end

    n = numel(peakResults);
    centerWavelength = nan(n,1);
    fwhmNm = nan(n,1);
    erwNm = nan(n,1);
    sourceIndex = (1:n).';
    for k = 1:n
        result = peakResults{k};
        if ~isstruct(result)
            error('WCC4SM:InvalidPeakResult', ...
                'Every peak result must be a structure.');
        end
        center = fieldOrNaN(result,'CenterX');
        leftHalf = fieldOrNaN(result,'LeftHalfX');
        rightHalf = fieldOrNaN(result,'RightHalfX');
        peakHeight = fieldOrNaN(result,'InterpolatedPeakY');
        if isfinite(center)
            centerWavelength(k) = evaluateModel(model,center);
            if isfinite(leftHalf) && isfinite(rightHalf)
                fwhmNm(k) = evaluateModel(model,rightHalf)- ...
                    evaluateModel(model,leftHalf);
            end
        end
        if isfield(result,'InterpX') && isfield(result,'InterpNetY') && ...
                ~isempty(result.InterpX) && ~isempty(result.InterpNetY) && ...
                isfinite(peakHeight) && peakHeight > 0
            densePixel = result.InterpX(:);
            denseSignal = result.InterpNetY(:);
            if numel(densePixel) == numel(denseSignal) && ...
                    all(isfinite(densePixel)) && all(isfinite(denseSignal))
                denseWavelength = evaluateModel(model,densePixel);
                erwNm(k) = trapz(denseWavelength,max(denseSignal,0))/peakHeight;
            end
        end
    end

    [centerWavelength,order] = sort(centerWavelength);
    fwhmNm = fwhmNm(order);
    erwNm = erwNm(order);
    sourceIndex = sourceIndex(order);

    completeWidth = isfinite(fwhmNm) & isfinite(erwNm);
    relation = struct('ValidCount',sum(completeWidth),'Coefficients',[NaN NaN], ...
        'RSquared',NaN);
    if sum(completeWidth) >= 2 && ...
            max(fwhmNm(completeWidth))-min(fwhmNm(completeWidth)) > eps
        coefficients = polyfit(fwhmNm(completeWidth),erwNm(completeWidth),1);
        predicted = polyval(coefficients,fwhmNm(completeWidth));
        totalVariation = sum((erwNm(completeWidth)-mean(erwNm(completeWidth))).^2);
        rSquared = NaN;
        if totalVariation > eps
            rSquared = 1-sum((erwNm(completeWidth)-predicted).^2)/totalVariation;
        end
        relation.Coefficients = coefficients;
        relation.RSquared = rSquared;
    end

    positiveFwhm = fwhmNm(isfinite(fwhmNm) & fwhmNm > 0);
    fwhmStatistics = summarizePositiveValues(positiveFwhm);

    wavelengthAxis = evaluateModel(model,pixelAxis);
    intervalNm = diff(wavelengthAxis);
    intervalWavelength = 0.5*(wavelengthAxis(1:end-1)+wavelengthAxis(2:end));
    validInterval = isfinite(intervalNm) & isfinite(intervalWavelength) & intervalNm > 0;
    intervalStatistics = summarizePositiveValues(intervalNm(validInterval));

    performance = struct('PeakCount',n,'SourceIndex',sourceIndex, ...
        'CenterWavelength_nm',centerWavelength,'FWHM_nm',fwhmNm, ...
        'ERW_nm',erwNm,'ValidFWHM',isfinite(centerWavelength)&isfinite(fwhmNm), ...
        'ValidERW',isfinite(centerWavelength)&isfinite(erwNm), ...
        'WidthRelation',relation,'FWHMStatistics',fwhmStatistics, ...
        'PixelAxis',pixelAxis,'WavelengthAxis_nm',wavelengthAxis, ...
        'IntervalWavelength_nm',intervalWavelength, ...
        'PixelInterval_nm',intervalNm,'ValidPixelInterval',validInterval, ...
        'PixelIntervalStatistics',intervalStatistics);
end

function validateModel(model)
    required = {'valid','Coefficients','Mu'};
    if ~all(isfield(model,required)) || ~model.valid || ...
            isempty(model.Coefficients) || numel(model.Mu) ~= 2 || ...
            any(~isfinite(model.Coefficients)) || any(~isfinite(model.Mu))
        error('WCC4SM:InvalidCalibrationModel', ...
            'A valid calibration model with finite coefficients and mu is required.');
    end
end

function value = fieldOrNaN(result,name)
    if isfield(result,name) && isnumeric(result.(name)) && ...
            isscalar(result.(name)) && isfinite(result.(name))
        value = result.(name);
    else
        value = NaN;
    end
end

function wavelength = evaluateModel(model,pixel)
    wavelength = polyval(model.Coefficients,pixel,[],model.Mu);
end

function summary = summarizePositiveValues(values)
    values = values(:);
    if isempty(values)
        summary = struct('Count',0,'Mean',NaN,'Median',NaN,'STD',NaN, ...
            'Minimum',NaN,'Maximum',NaN);
    else
        summary = struct('Count',numel(values),'Mean',mean(values), ...
            'Median',median(values),'STD',std(values), ...
            'Minimum',min(values),'Maximum',max(values));
    end
end
