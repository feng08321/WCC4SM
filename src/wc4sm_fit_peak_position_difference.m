function result=wc4sm_fit_peak_position_difference(wavelength,difference,includeMask,degree)
%WC4SM_FIT_PEAK_POSITION_DIFFERENCE Fit position difference versus wavelength.
% Residual sign is observed position difference minus fitted difference.
    wavelength=wavelength(:);difference=difference(:);includeMask=logical(includeMask(:));
    if numel(wavelength)~=numel(difference)||numel(wavelength)~=numel(includeMask)
        error('WCC4SM:PeakDifferenceSizeMismatch','Wavelength, difference and include mask must have equal length.');
    end
    if ~isscalar(degree)||~isfinite(degree)||degree~=fix(degree)||degree<1||degree>3
        error('WCC4SM:PeakDifferenceInvalidDegree','Peak-position-difference fit degree must be 1, 2 or 3.');
    end
    fitMask=includeMask&isfinite(wavelength)&isfinite(difference);
    if sum(fitMask)<degree+1||numel(unique(wavelength(fitMask)))<degree+1
        error('WCC4SM:PeakDifferenceInsufficientPoints','Degree %d fit requires at least %d distinct included wavelengths.',degree,degree+1);
    end
    [coefficients,~,mu]=polyfit(wavelength(fitMask),difference(fitMask),degree);
    prediction=nan(size(difference));valid=isfinite(wavelength);
    prediction(valid)=polyval(coefficients,wavelength(valid),[],mu);
    residual=difference-prediction;
    fitResidual=residual(fitMask);observed=difference(fitMask);
    ssTotal=sum((observed-mean(observed)).^2);
    if ssTotal>eps,rsquared=1-sum(fitResidual.^2)/ssTotal;else,rsquared=NaN;end
    fitX=linspace(min(wavelength(fitMask)),max(wavelength(fitMask)),300).';
    fitY=polyval(coefficients,fitX,[],mu);
    result=struct('Degree',degree,'Coefficients',coefficients,'Mu',mu,'FitMask',fitMask, ...
        'Prediction',prediction,'Residual',residual,'FitResidual',fitResidual, ...
        'RMSE',sqrt(mean(fitResidual.^2)),'Bias',mean(fitResidual),'RSquared',rsquared, ...
        'N',sum(fitMask),'FitX',fitX,'FitY',fitY);
end
