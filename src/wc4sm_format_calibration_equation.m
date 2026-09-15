function s = wc4sm_format_calibration_equation(p)
%WC4SM_FORMAT_CALIBRATION_EQUATION Render natural polynomial coefficients as text.
% Terms with negligible coefficients are omitted; the result reads
% "lambda(nm) = a*p^n + b*p^(n-1) + ...".

    n=numel(p)-1;parts={};
    for k=1:numel(p)
        power=n-k+1;a=p(k);if abs(a)<1e-15,continue;end
        if power==0,term=sprintf('%.12g',abs(a));elseif power==1,term=sprintf('%.12g*p',abs(a));else,term=sprintf('%.12g*p^%d',abs(a),power);end
        if isempty(parts),if a<0,term=['-' term];end;parts{end+1}=term; %#ok<AGROW>
        elseif a<0,parts{end+1}=[' - ' term];else,parts{end+1}=[' + ' term];end %#ok<AGROW>
    end
    if isempty(parts),rhs='0';else,rhs=strjoin(parts,'');end
    s=['lambda(nm) = ' rhs];
end
