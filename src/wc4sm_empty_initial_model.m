function m = wc4sm_empty_initial_model()
%WC4SM_EMPTY_INITIAL_MODEL Create an empty provisional linear mapping model.
% a/b are the slope/offset of the seed-line pixel-to-wavelength mapping;
% Coefficients/Mu follow the normalized-polynomial convention.

    m = struct('valid',false,'Degree',0,'Coefficients',[],'Mu',[0 1], ...
        'a',NaN,'b',NaN);
end
