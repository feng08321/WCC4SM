function p = wc4sm_poly_normalized_to_natural(c,mu)
%WC4SM_POLY_NORMALIZED_TO_NATURAL Expand a normalized polynomial to natural form.
% Horner composition of c(z), z=(pixel-mu(1))/mu(2).

    p=0;affine=[1/mu(2),-mu(1)/mu(2)];
    for k=1:numel(c)
        p=conv(p,affine);p(end)=p(end)+c(k);
    end
    first=find(abs(p)>max(1e-15,max(abs(p))*1e-14),1,'first');
    if isempty(first),p=0;else,p=p(first:end);end
end
