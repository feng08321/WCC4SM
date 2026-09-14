function record = wc4sm_evaluate_subset(pixel,wavelength,subsetMask,degree,evaluationPixels,baselineModel,options)
%WC4SM_EVALUATE_SUBSET Fit one subset and score it on the fixed full pool.
    if nargin<5||isempty(evaluationPixels),evaluationPixels=linspace(min(pixel),max(pixel),200).';end
    if nargin<6,baselineModel=[];end
    if nargin<7||isempty(options),options=struct;end
    pixel=pixel(:);wavelength=wavelength(:);subsetMask=logical(subsetMask(:));evaluationPixels=evaluationPixels(:);
    n=numel(pixel);
    if numel(wavelength)~=n||numel(subsetMask)~=n,error('WCC4SM:SubsetSizeMismatch','Pixel, wavelength and subset mask must have equal length.');end
    if sum(subsetMask)<degree+1,error('WCC4SM:SubsetInsufficientPoints','Subset must contain at least degree+1 points.');end
    if any(~isfinite(pixel))||any(~isfinite(wavelength))||any(~isfinite(evaluationPixels)),error('WCC4SM:SubsetInvalidData','Subset inputs must be finite.');end
    positionMethod='Unspecified';if isfield(options,'PositionMethod'),positionMethod=char(string(options.PositionMethod));end
    ids=arrayfun(@(k)sprintf('P%03d',k),(1:n).','UniformOutput',false);if isfield(options,'PeakIDs')&&~isempty(options.PeakIDs),ids=cellstr(string(options.PeakIDs(:)));end
    if numel(ids)~=n,error('WCC4SM:SubsetPeakIDSizeMismatch','Peak ID count must match the full pool.');end
    skipLOO=isfield(options,'SkipLOO')&&logical(options.SkipLOO);
    model=wc4sm_fit_calibration(pixel(subsetMask),wavelength(subsetMask),degree,evaluationPixels,positionMethod,ids(subsetMask),struct('SkipLOO',skipLOO));
    predicted=polyval(model.Coefficients,pixel,[],model.Mu);residual=wavelength-predicted;absoluteResidual=abs(residual);
    selectedWavelength=sort(wavelength(subsetMask));if numel(selectedWavelength)>1,maxGap=max(diff(selectedWavelength));else,maxGap=Inf;end
    distanceRMS=NaN;distanceMAX=NaN;curve=polyval(model.Coefficients,evaluationPixels,[],model.Mu);baselineCurve=nan(size(curve));
    if ~isempty(baselineModel)
        d=wc4sm_model_distance(model,baselineModel,evaluationPixels);distanceRMS=d.RMS;distanceMAX=d.MAX;baselineCurve=d.CurveB;
    end
    [~,shortIndex]=min(wavelength);[~,longIndex]=max(wavelength);key=char('0'+subsetMask.');
    record=struct('Key',key,'SubsetMask',subsetMask,'SelectedIndices',find(subsetMask).', ...
        'SelectedIDs',{ids(subsetMask)},'K',sum(subsetMask),'Degree',degree,'PositionMethod',positionMethod, ...
        'FitRMSE',model.RMS,'AllRMSE',sqrt(mean(residual.^2)),'AllP95',percentile95(absoluteResidual), ...
        'AllMAX',max(absoluteResidual),'Residual',residual,'AllPixels',pixel,'AllWavelengths',wavelength, ...
        'CoverageMin',min(selectedWavelength),'CoverageMax',max(selectedWavelength),'MaxWavelengthGap',maxGap, ...
        'ShortBoundaryIncluded',subsetMask(shortIndex),'LongBoundaryIncluded',subsetMask(longIndex), ...
        'DistanceRMS',distanceRMS,'DistanceMAX',distanceMAX,'EvaluationPixels',evaluationPixels, ...
        'Curve',curve,'BaselineCurve',baselineCurve,'Model',model,'Status','Available');
end

function q=percentile95(x)
    x=sort(x(isfinite(x)));if isempty(x),q=NaN;return;end
    q=x(max(1,min(numel(x),ceil(0.95*numel(x)))));
end
