function result = wc4sm_analyze_model_order(pixel,wavelength,degreeRange,evaluationPixels,options)
%WC4SM_ANALYZE_MODEL_ORDER Compare polynomial calibration orders.
% Returns fit, LOO and optional fixed hold-out validation metrics for every order.
    if nargin<3||isempty(degreeRange),degreeRange=1:7;end
    if nargin<4||isempty(evaluationPixels),evaluationPixels=pixel;end
    if nargin<5||isempty(options),options=struct;end
    pixel=pixel(:);wavelength=wavelength(:);evaluationPixels=evaluationPixels(:);
    if numel(pixel)~=numel(wavelength),error('WCC4SM:CalibrationSizeMismatch','Pixel and wavelength vectors must have equal length.');end
    if ~isfield(options,'ValidationMask'),options.ValidationMask=false(size(pixel));end
    validationMask=logical(options.ValidationMask(:));
    if numel(validationMask)~=numel(pixel),error('WCC4SM:ValidationMaskSizeMismatch','ValidationMask must match the reference pool.');end
    %result=struct('Degree',num2cell(degreeRange(:)),'Status',cell(numel(degreeRange),1), ...
    %    'FitRMSE',nan(numel(degreeRange),1),'FitMAX',nan(numel(degreeRange),1), ...
    %    'LOORMSE',nan(numel(degreeRange),1),'LOOMAX',nan(numel(degreeRange),1), ...
    %    'ValidationRMSE',nan(numel(degreeRange),1),'ValidationP95',nan(numel(degreeRange),1), ...
    %    'ValidationMAX',nan(numel(degreeRange),1),'Model',cell(numel(degreeRange),1));
    
    emptyRecord=struct('Degree',NaN,'Status','','FitRMSE',NaN,'FitMAX',NaN, ...
    'LOORMSE',NaN,'LOOMAX',NaN,'ValidationRMSE',NaN, ...
    'ValidationP95',NaN,'ValidationMAX',NaN,'Model',[]);
result=repmat(emptyRecord,numel(degreeRange),1);
for k=1:numel(degreeRange)
    result(k).Degree=degreeRange(k);
end
    
    for k=1:numel(degreeRange)
        d=degreeRange(k);cal=~validationMask;
        if sum(cal)<d+1
            result(k).Status='Insufficient calibration points';continue;
        end
        try
            m=wc4sm_fit_calibration(pixel(cal),wavelength(cal),d,evaluationPixels);
            result(k).Model=m;result(k).Status='Fit available';
            result(k).FitRMSE=m.RMS;result(k).FitMAX=m.MaxAbsResidual;
            result(k).LOORMSE=m.LOORMS;result(k).LOOMAX=m.LOOMaxAbs;
            if any(validationMask)
                e=wavelength(validationMask)-polyval(m.Coefficients,pixel(validationMask),[],m.Mu);
                ae=abs(e);result(k).ValidationRMSE=sqrt(mean(e.^2));
                result(k).ValidationP95=percentile95(ae);result(k).ValidationMAX=max(ae);
            end
            if sum(cal)==d+1,result(k).Status='Fit available; LOO unavailable';end
        catch ME
            result(k).Status=['Failed: ' ME.identifier];
        end
    end
end

function q=percentile95(x)
    x=sort(x(isfinite(x)));if isempty(x),q=NaN;return;end
    q=x(max(1,min(numel(x),ceil(0.95*numel(x)))));
end
