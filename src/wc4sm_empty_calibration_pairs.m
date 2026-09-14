function p = wc4sm_empty_calibration_pairs()
%WC4SM_EMPTY_CALIBRATION_PAIRS Create an empty calibration-pair struct array.
% Each pair binds a confirmed peak position to a reference wavelength with
% matching metadata (order, mode, confidence, lock and status flags).

    p = struct('PeakID',{},'PeakIndex',{},'DetectionPixel',{}, ...
        'ReferenceIndex',{},'ReferenceWavelength',{},'Order',{},'Mode',{}, ...
        'Confidence',{},'Locked',{},'Status',{});
end
