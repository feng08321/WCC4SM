function result = wc4sm_preprocess_spectrum(raw,dark,manualBaseline,clampNegative)
%WC4SM_PREPROCESS_SPECTRUM Apply dark or baseline subtraction and normalize.
% Dark subtraction takes precedence over the manual constant baseline,
% matching WCC4SM V0.5.1 behavior.

    arguments
        raw (:,1) double
        dark (:,1) double = zeros(0,1)
        manualBaseline (1,1) double = 0
        clampNegative (1,1) logical = true
    end

    if numel(raw) < 3 || any(~isfinite(raw))
        error('WCC4SM:InvalidRawSpectrum', ...
            'Raw spectrum must contain at least 3 finite samples.');
    end
    if ~isfinite(manualBaseline)
        error('WCC4SM:InvalidBaseline','Manual baseline must be finite.');
    end

    if ~isempty(dark)
        if numel(dark) ~= numel(raw)
            error('WCC4SM:DarkLengthMismatch', ...
                'Dark spectrum and measured spectrum must have equal length.');
        end
        if any(~isfinite(dark))
            error('WCC4SM:InvalidDarkSpectrum', ...
                'Dark spectrum must contain finite values only.');
        end
        corrected = raw-dark;
        subtractionMode = 'Dark';
        appliedBaseline = NaN;
    else
        corrected = raw-manualBaseline;
        subtractionMode = 'ManualBaseline';
        appliedBaseline = manualBaseline;
    end

    if clampNegative
        corrected = max(corrected,0);
    end
    maximum = max(corrected);
    if maximum > 0
        normalized = corrected/maximum;
    else
        normalized = zeros(size(corrected));
    end

    result = struct('corrected',corrected(:),'normalized',normalized(:), ...
        'subtractionMode',subtractionMode,'manualBaselineApplied',appliedBaseline, ...
        'negativeClampApplied',clampNegative,'normalizationMaximum',maximum);
end
