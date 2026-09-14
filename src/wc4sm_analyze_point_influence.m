function result = wc4sm_analyze_point_influence(pixel,wavelength,degree,options)
%WC4SM_ANALYZE_POINT_INFLUENCE Classify calibration points by deletion impact.
% All input points are retained in the result; classification is advisory.
    if nargin<3||isempty(degree),degree=3;end
    if nargin<4||isempty(options),options=struct;end
    pixel=pixel(:);wavelength=wavelength(:);n=numel(pixel);
    if n~=numel(wavelength),error('WCC4SM:InfluenceSizeMismatch','Pixel and wavelength vectors must match.');end
    if degree>20,error('WCC4SM:PolynomialDegreeLimit','Polynomial degree %d exceeds the supported analysis limit of 20.',degree);end
    if n<degree+3,error('WCC4SM:InfluenceInsufficientPoints','At least degree+3 points are required so every point-deleted model retains LOO validation.');end
    if any(~isfinite(pixel))||any(~isfinite(wavelength)),error('WCC4SM:InfluenceInvalidData','Input values must be finite.');end
    if ~isfield(options,'HighInfluenceFactor'),options.HighInfluenceFactor=2;end
    if ~isfield(options,'RedundantFactor'),options.RedundantFactor=0.25;end
    full=wc4sm_fit_calibration(pixel,wavelength,degree,pixel);
    e=wavelength-polyval(full.Coefficients,pixel,[],full.Mu);absE=abs(e);
    baseline=max(full.LOORMS,eps);
    empty=struct('Index',NaN,'Pixel',NaN,'Wavelength',NaN,'Residual',NaN, ...
        'DeletedRMS',NaN,'DeletedLOORMSE',NaN,'CurveChange',NaN, ...
        'InfluenceRatio',NaN,'Class','','Recommendation','');
    result=repmat(empty,n,1);
    for k=1:n
        use=true(n,1);use(k)=false;
        m=wc4sm_fit_calibration(pixel(use),wavelength(use),degree,pixel);
        deleted=wavelength-polyval(m.Coefficients,pixel,[],m.Mu);
        curve=max(abs(polyval(full.Coefficients,pixel,[],full.Mu)-polyval(m.Coefficients,pixel,[],m.Mu)));
        ratio=abs(full.LOORMS-m.LOORMS)/baseline;
        result(k).Index=k;result(k).Pixel=pixel(k);result(k).Wavelength=wavelength(k);
        result(k).Residual=e(k);result(k).DeletedRMS=m.RMS;result(k).DeletedLOORMSE=m.LOORMS;
        result(k).CurveChange=curve;result(k).InfluenceRatio=ratio;
        if absE(k)>max(3*baseline,median(absE)+3*std(absE))
            result(k).Class='Candidate outlier';result(k).Recommendation='Review measurement and reference match';
        elseif ratio>=options.HighInfluenceFactor
            result(k).Class='High influence';result(k).Recommendation='Retain unless independently invalid';
        elseif ratio<=options.RedundantFactor
            result(k).Class='Redundant';result(k).Recommendation='Optional; compare with nearby points';
        else
            result(k).Class='Optional';result(k).Recommendation='Retain for broader coverage';
        end
    end
    result=struct('Degree',degree,'FullModel',full,'Points',result);
end
