function limit = wc4sm_robust_upper_limit(v)
%WC4SM_ROBUST_UPPER_LIMIT Median + 3*1.4826*MAD outlier-resistant upper bound.
% Non-finite values are ignored. Empty input yields Inf; degenerate zero-MAD
% input falls back to a half-max based bound; the result is always positive.

    v=v(isfinite(v));if isempty(v),limit=Inf;return;end
    med=median(v);madv=median(abs(v-med));limit=med+3*1.4826*madv;
    if madv==0,limit=max(med,max(v)*0.5);end
    if limit<=0,limit=eps;end
end
