function result = wc4sm_analyze_add_one(pixel,wavelength,calibrationMask,candidateMask,degree,evaluationPixels)
%WC4SM_ANALYZE_ADD_ONE Evaluate each candidate reference added to a fixed set.
    if nargin<6||isempty(evaluationPixels),evaluationPixels=pixel;end
    pixel=pixel(:);wavelength=wavelength(:);calibrationMask=logical(calibrationMask(:));candidateMask=logical(candidateMask(:));
    if any([numel(wavelength),numel(calibrationMask),numel(candidateMask)]~=numel(pixel)),error('WCC4SM:AddOneSizeMismatch','All vectors must have equal length.');end
    ids=find(candidateMask);n=numel(ids);result=repmat(struct('Index',NaN,'ValidationRMSE',NaN,'ValidationP95',NaN,'ValidationMAX',NaN,'Gain',NaN,'RelativeGain',NaN,'Status',''),n,1);
    base=wc4sm_fit_calibration(pixel(calibrationMask),wavelength(calibrationMask),degree,evaluationPixels);
    baseErrors=wavelength(candidateMask)-polyval(base.Coefficients,pixel(candidateMask),[],base.Mu);baseRMSE=sqrt(mean(baseErrors.^2));
    for k=1:n
        j=ids(k);use=calibrationMask;use(j)=true;val=candidateMask;val(j)=false;
        result(k).Index=j;
        if sum(use)<degree+1,result(k).Status='Insufficient calibration points';continue;end
        m=wc4sm_fit_calibration(pixel(use),wavelength(use),degree,evaluationPixels);
        e=wavelength(val)-polyval(m.Coefficients,pixel(val),[],m.Mu);ae=abs(e);
        result(k).ValidationRMSE=sqrt(mean(e.^2));result(k).ValidationP95=percentile95(ae);result(k).ValidationMAX=max(ae);
        result(k).Gain=baseRMSE-result(k).ValidationRMSE;result(k).RelativeGain=result(k).Gain/max(baseRMSE,eps);result(k).Status='Available';
    end
end
function q=percentile95(x)
    x=sort(x(isfinite(x)));if isempty(x),q=NaN;return;end
    q=x(max(1,min(numel(x),ceil(0.95*numel(x)))));
end
