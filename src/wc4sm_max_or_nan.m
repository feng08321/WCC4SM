function value = wc4sm_max_or_nan(values)
%WC4SM_MAX_OR_NAN Maximum of a vector, or NaN when the vector is empty.

    if isempty(values),value=NaN;else,value=max(values);end
end
