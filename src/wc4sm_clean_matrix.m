function M = wc4sm_clean_matrix(M)
%WC4SM_CLEAN_MATRIX Drop all-NaN rows/columns and keep at most two columns.
% Used when importing spectrum CSV data with trailing empty cells.

    M=M(~all(isnan(M),2),:); M=M(:,~all(isnan(M),1));
    if isempty(M),error('CSV contains no numeric data.');end
    if size(M,2)>2,M=M(:,1:2);end
end
