function v = wc4sm_number_or_nan(x)
%WC4SM_NUMBER_OR_NAN Numeric pass-through; text is parsed, failures give NaN.

    if isnumeric(x),v=x;else,v=str2double(string(x));end;if isempty(v)||~isfinite(v),v=NaN;end
end
