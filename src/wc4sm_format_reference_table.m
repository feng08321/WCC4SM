function data = wc4sm_format_reference_table(wavelength,intensity,order,status)
%WC4SM_FORMAT_REFERENCE_TABLE Format reference values for consistent UI display.

    wavelength = wavelength(:);
    intensity = intensity(:);
    order = order(:);
    status = status(:);
    count = numel(wavelength);
    if numel(intensity)~=count || numel(order)~=count || numel(status)~=count
        error('WCC4SM:ReferenceTableSizeMismatch', ...
            'Reference-table columns must have the same number of rows.');
    end
    if any(~isfinite(intensity)) || any(~isfinite(order))
        error('WCC4SM:InvalidReferenceTableValue', ...
            'Reference intensity and order values must be finite.');
    end

    data = cell(count,4);
    for index = 1:count
        data(index,:) = {wavelength(index),sprintf('%.0f',intensity(index)), ...
            sprintf('%.0f',order(index)),char(string(status(index)))};
    end
end
