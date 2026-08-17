function result = wc4sm_analyze_add_one_path(pixel,wavelength,seedMask,degree,evaluationPixels,options)
%WC4SM_ANALYZE_ADD_ONE_PATH Build a sequential calibration-set selection path.
% Each round evaluates every remaining candidate and selects the candidate
% with the lowest validation RMSE on the remaining reference pool.
    if nargin<4||isempty(degree),degree=3;end
    if nargin<5||isempty(evaluationPixels),evaluationPixels=pixel;end
    if nargin<6||isempty(options),options=struct;end
    pixel=pixel(:);wavelength=wavelength(:);evaluationPixels=evaluationPixels(:);
    seedMask=logical(seedMask(:));
    if numel(pixel)~=numel(wavelength)||numel(seedMask)~=numel(pixel)
        error('WCC4SM:AddOnePathSizeMismatch','Pixel, wavelength and seedMask must have equal length.');
    end
    if sum(seedMask)<degree+1
        error('WCC4SM:AddOnePathInsufficientSeed','Seed set must contain at least degree+1 points.');
    end
    if ~isfield(options,'StopWhenCandidates'),options.StopWhenCandidates=0;end
    selected=seedMask;remaining=~selected;rounds=0;
    history=repmat(struct('Round',NaN,'Ncal',NaN,'SelectedIndex',NaN, ...
        'ValidationRMSE',NaN,'ValidationP95',NaN,'ValidationMAX',NaN, ...
        'CandidateCount',NaN,'Status',''),0,1);
    candidateHistory=cell(0,1);
    while sum(remaining)>options.StopWhenCandidates
        candidates=wc4sm_analyze_add_one(pixel,wavelength,selected,remaining,degree,evaluationPixels);
        valid=arrayfun(@(x) strcmp(x.Status,'Available')&&isfinite(x.ValidationRMSE),candidates);
        if ~any(valid),break;end
        ids=find(remaining); scores=[candidates.ValidationRMSE]; scores(~valid)=Inf;
        [~,best]=min(scores); chosen=ids(best); selected(chosen)=true; remaining(chosen)=false;
        model=wc4sm_fit_calibration(pixel(selected),wavelength(selected),degree,evaluationPixels);
        e=wavelength(remaining)-polyval(model.Coefficients,pixel(remaining),[],model.Mu);
        ae=abs(e); rounds=rounds+1;
        history(rounds)=struct('Round',rounds,'Ncal',sum(selected), ...
            'SelectedIndex',chosen,'ValidationRMSE',sqrt(mean(e.^2)), ...
            'ValidationP95',percentile95(ae),'ValidationMAX',max(ae), ...
            'CandidateCount',sum(valid),'Status','Selected');
        candidateHistory{rounds}=candidates;
    end
    result=struct('Degree',degree,'SeedMask',seedMask,'SelectedMask',selected, ...
        'RemainingMask',remaining,'History',history,'CandidateHistory',{candidateHistory});
end

function q=percentile95(x)
    x=sort(x(isfinite(x)));if isempty(x),q=NaN;return;end
    q=x(max(1,min(numel(x),ceil(0.95*numel(x)))));
end
