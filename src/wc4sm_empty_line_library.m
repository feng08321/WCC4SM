function L = wc4sm_empty_line_library()
%WC4SM_EMPTY_LINE_LIBRARY Create an empty reference line library structure.
% wavelength/intensity/order/effective are column vectors aligned per line;
% enabled marks lines included by the current selection mode.

    L = struct('wavelength',[],'intensity',[],'order',[],'effective',[], ...
        'enabled',[],'source','','loaded',false);
end
