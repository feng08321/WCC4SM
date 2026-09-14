function p = wc4sm_empty_local_candidates()
%WC4SM_EMPTY_LOCAL_CANDIDATES Create an empty local-search candidate array.

    p = struct('Index',{},'Pixel',{},'InputX',{},'Height',{}, ...
        'Prominence',{},'Width',{});
end
