function s = wc4sm_format_value(v)
%WC4SM_FORMAT_VALUE Compact numeric display: 'NaN', 'Inf', or '%.8g'.

    if isnan(v),s='NaN';elseif isinf(v),s='Inf';else,s=sprintf('%.8g',v);end
end
