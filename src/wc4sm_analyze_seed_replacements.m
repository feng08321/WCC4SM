function result = wc4sm_analyze_seed_replacements(pixel,wavelength,seedMask,degree,options)
%WC4SM_ANALYZE_SEED_REPLACEMENTS Validate one-for-one selected-set substitutions.
% Each selected point is removed in turn and replaced by every unselected point.
    if nargin<4||isempty(degree),degree=3;end
    if nargin<5||isempty(options),options=struct;end
    rmseThreshold=0.1;if isfield(options,'RMSEThreshold')&&~isempty(options.RMSEThreshold),rmseThreshold=options.RMSEThreshold;end
    if ~isscalar(rmseThreshold)||~isfinite(rmseThreshold)||rmseThreshold<0,error('WCC4SM:SeedReplacementInvalidRMSEThreshold','RMSEThreshold must be a nonnegative finite scalar.');end
    pixel=pixel(:);wavelength=wavelength(:);seedMask=logical(seedMask(:));n=numel(pixel);
    if numel(wavelength)~=n||numel(seedMask)~=n,error('WCC4SM:SeedReplacementSizeMismatch','Pixel, wavelength, and seed mask must have equal length.');end
    if sum(seedMask)<degree+1,error('WCC4SM:SeedReplacementInsufficientSeed','Select at least degree+1 points.');end
    validationMode='Non-selected points';if isfield(options,'ValidationMode')&&~isempty(options.ValidationMode),validationMode=char(string(options.ValidationMode));end
    switch lower(validationMode)
        case {'all points','all','全部数据','全部有效点'},evaluationMask=true(n,1);validationMode='All points';
        otherwise,evaluationMask=~seedMask;validationMode='Non-selected points';
    end
    if ~any(evaluationMask),error('WCC4SM:SeedReplacementNoValidationPoints','At least one unselected point is required for this validation mode.');end
    baseline=scoreSeed(pixel,wavelength,seedMask,degree,evaluationMask);seedIndices=find(seedMask);candidateIndices=find(~seedMask);
    if isempty(candidateIndices),error('WCC4SM:SetReplacementNoCandidates','Leave at least one point unselected as a replacement candidate.');end
    empty=struct('RemovedIndex',NaN,'CandidateIndex',NaN,'SeedIndices',[],'ValidationRMSE',NaN,'ValidationP95',NaN,'ValidationMAX',NaN,'FitRMSE',NaN,'DeltaRMSE',NaN,'IsImprovement',false,'IsRecommended',false,'Residual',[],'EvaluationPixels',[],'Status','');
    records=repmat(empty,numel(seedIndices)*numel(candidateIndices),1);k=0;
    for removed=seedIndices.'
        for candidate=candidateIndices.'
            k=k+1;trialMask=seedMask;trialMask(removed)=false;trialMask(candidate)=true;records(k).RemovedIndex=removed;records(k).CandidateIndex=candidate;records(k).SeedIndices=find(trialMask).';
            try
                score=scoreSeed(pixel,wavelength,trialMask,degree,evaluationMask);records(k).ValidationRMSE=score.ValidationRMSE;records(k).ValidationP95=score.ValidationP95;records(k).ValidationMAX=score.ValidationMAX;records(k).FitRMSE=score.FitRMSE;records(k).Residual=score.Residual;records(k).EvaluationPixels=score.EvaluationPixels;records(k).DeltaRMSE=score.ValidationRMSE-baseline.ValidationRMSE;records(k).IsImprovement=records(k).DeltaRMSE<0;records(k).IsRecommended=records(k).DeltaRMSE<=-rmseThreshold;records(k).Status='Available';
            catch ME
                records(k).Status=['Failed: ' ME.identifier];
            end
        end
    end
    best=repmat(empty,numel(seedIndices),1);
    for j=1:numel(seedIndices)
        alternatives=records([records.RemovedIndex]==seedIndices(j) & strcmp({records.Status},'Available'));
        if ~isempty(alternatives),[~,order]=sort([alternatives.ValidationRMSE]);best(j)=alternatives(order(1));else,best(j).RemovedIndex=seedIndices(j);best(j).Status='No available replacement';end
    end
    result=struct('Degree',degree,'ValidationMode',validationMode,'RMSEThreshold',rmseThreshold, ...
        'SelectedIndices',seedIndices.','SeedIndices',seedIndices.','CandidateIndices',candidateIndices.', ...
        'EvaluationIndices',find(evaluationMask).','Baseline',baseline,'Records',records, ...
        'BestByRemovedPoint',best,'BestByRemovedSeed',best,'TotalTrials',numel(records));
end
function score=scoreSeed(pixel,wavelength,seedMask,degree,evaluationMask)
    model=wc4sm_fit_calibration(pixel(seedMask),wavelength(seedMask),degree,pixel);residual=wavelength(evaluationMask)-polyval(model.Coefficients,pixel(evaluationMask),[],model.Mu);absoluteResidual=abs(residual);
    score=struct('ValidationRMSE',sqrt(mean(residual.^2)),'ValidationP95',percentile95(absoluteResidual),'ValidationMAX',max(absoluteResidual),'FitRMSE',model.RMS,'Residual',residual,'EvaluationPixels',pixel(evaluationMask));
end
function q=percentile95(x)
    x=sort(x(isfinite(x)));if isempty(x),q=NaN;return;end;q=x(max(1,min(numel(x),ceil(0.95*numel(x)))));
end
