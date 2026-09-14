function q = wc4sm_make_calibration_pair(id,idx,pixel,refIdx,refWavelength,ord,mode,locked,status,confidence)
%WC4SM_MAKE_CALIBRATION_PAIR Build one calibration-pair structure.
% confidence defaults to NaN when not provided.

    if nargin<10,confidence=NaN;end
    q = struct('PeakID',id,'PeakIndex',idx,'DetectionPixel',pixel, ...
        'ReferenceIndex',refIdx,'ReferenceWavelength',refWavelength, ...
        'Order',ord,'Mode',mode,'Confidence',confidence,'Locked',locked, ...
        'Status',status);
end
