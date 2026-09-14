function m = wc4sm_empty_calibration_models()
%WC4SM_EMPTY_CALIBRATION_MODELS Create an empty model-comparison library array.

    m = struct('ModelID',{},'CreatedAt',{},'PairCount',{}, ...
        'PositionMethod',{},'Degree',{},'PairIDs',{},'Model',{}, ...
        'Visible',{});
end
