function matchedRef = wc4sm_match_ordered_sequence(predicted,referenceWavelengths,referenceIndices,tolerance)
%WC4SM_MATCH_ORDERED_SEQUENCE Monotonic peak-to-reference sequence alignment.
%   Dynamic-programming alignment between predicted peak wavelengths and the
%   candidate reference lines. Matches must remain monotonic; either measured
%   or reference lines may be skipped. matchedRef(k) is the referenceIndices
%   entry matched to predicted(k), or 0 when peak k stays unmatched.

    arguments
        predicted (:,1) double
        referenceWavelengths (:,1) double
        referenceIndices (:,1) double
        tolerance (1,1) double {mustBePositive}
    end
    if numel(referenceWavelengths) ~= numel(referenceIndices)
        error('WCC4SM:ReferenceSequenceMismatch', ...
            'Reference wavelengths and indices must have equal length.');
    end

    n = numel(predicted);
    m = numel(referenceWavelengths);
    D = inf(n+1,m+1);
    B = zeros(n+1,m+1,'uint8');
    D(1,1) = 0;
    skipPeak = 1.0;
    skipReference = 0.03;
    for i = 0:n
        for j = 0:m
            base = D(i+1,j+1);
            if ~isfinite(base), continue; end
            if i<n && base+skipPeak < D(i+2,j+1)
                D(i+2,j+1) = base+skipPeak; B(i+2,j+1) = 2;
            end
            if j<m && base+skipReference < D(i+1,j+2)
                D(i+1,j+2) = base+skipReference; B(i+1,j+2) = 3;
            end
            if i<n && j<m
                dist = abs(predicted(i+1)-referenceWavelengths(j+1));
                if dist <= tolerance
                    cost = base+0.8*(dist/tolerance)^2;
                    if cost < D(i+2,j+2)
                        D(i+2,j+2) = cost; B(i+2,j+2) = 1;
                    end
                end
            end
        end
    end

    matchedRef = zeros(n,1);
    i = n; j = m;
    while i>0 || j>0
        action = B(i+1,j+1);
        if action==1
            matchedRef(i) = referenceIndices(j); i = i-1; j = j-1;
        elseif action==2
            i = i-1;
        elseif action==3
            j = j-1;
        else
            if i>0, i = i-1; elseif j>0, j = j-1; end
        end
    end
end
