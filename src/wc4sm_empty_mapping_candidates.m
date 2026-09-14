function m = wc4sm_empty_mapping_candidates()
%WC4SM_EMPTY_MAPPING_CANDIDATES Create an empty initial-mapping candidate array.

    m = struct('a',{},'b',{},'RMS',{},'ReferenceIndices',{}, ...
        'ReferenceWavelengths',{});
end
