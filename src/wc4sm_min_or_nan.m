function value = wc4sm_min_or_nan(values)
%WC4SM_MIN_OR_NAN Minimum of a vector, or NaN when the vector is empty.

    if isempty(values),value=NaN;else,value=min(values);end
end
