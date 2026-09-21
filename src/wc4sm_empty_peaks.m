function p = wc4sm_empty_peaks()
%WC4SM_EMPTY_PEAKS Create an empty detected-peak candidate struct array.

    p = struct('ID',{},'Index',{},'Pixel',{},'InputX',{},'Height',{}, ...
        'Prominence',{},'Width',{},'Status',{},'Result',{},'AnalysisParams',{});
end
