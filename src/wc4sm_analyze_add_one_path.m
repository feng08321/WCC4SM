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
    if isempty(pixel)||any(~isfinite(pixel))||any(~isfinite(wavelength))
        error('WCC4SM:AddOnePathInvalidData','Pixel and wavelength values must be finite and non-empty.');
    end
    if isempty(evaluationPixels)||any(~isfinite(evaluationPixels))
        error('WCC4SM:AddOnePathInvalidEvaluationPixels','evaluationPixels must contain finite values.');
    end
    if ~isscalar(degree)||~isfinite(degree)||degree<0||degree~=fix(degree)
        error('WCC4SM:AddOnePathInvalidDegree','degree must be a nonnegative integer scalar.');
    end
    if sum(seedMask)<degree+1
        error('WCC4SM:AddOnePathInsufficientSeed','Seed set must contain at least degree+1 points.');
    end
    validationMode='Remaining points';if isfield(options,'ValidationMode')&&~isempty(options.ValidationMode),validationMode=char(string(options.ValidationMode));end
    fixedValidation=strcmpi(validationMode,'All points')||strcmpi(validationMode,'All');
    if ~isfield(options,'StopWhenCandidates')
        if fixedValidation,options.StopWhenCandidates=0;else,options.StopWhenCandidates=1;end
    end
    stopCount=options.StopWhenCandidates;
    if ~isscalar(stopCount)||~isfinite(stopCount)||stopCount<0||stopCount~=fix(stopCount)
        error('WCC4SM:AddOnePathInvalidStopCount','StopWhenCandidates must be a nonnegative integer scalar.');
    end
    selected=seedMask;remaining=~selected;rounds=0;
    history=repmat(struct('Round',NaN,'Ncal',NaN,'SelectedIndex',NaN, ...
        'FitRMSE',NaN,'ValidationRMSE',NaN,'ValidationP95',NaN,'ValidationMAX',NaN, ...
        'CandidateCount',NaN,'Residual',[],'EvaluationPixels',[],'Status',''),0,1);
    candidateHistory=cell(0,1);
    while sum(remaining)>stopCount
        validationMask=remaining;if fixedValidation,validationMask=true(size(remaining));end
        candidates=wc4sm_analyze_add_one(pixel,wavelength,selected,remaining,degree,evaluationPixels,validationMask);
        valid=arrayfun(@(x) strcmp(x.Status,'Available')&&isfinite(x.ValidationRMSE),candidates);
        if ~any(valid),break;end
        ids=find(remaining); scores=[candidates.ValidationRMSE]; scores(~valid)=Inf;
        [~,best]=min(scores); chosen=ids(best); selected(chosen)=true; remaining(chosen)=false;
        model=wc4sm_fit_calibration(pixel(selected),wavelength(selected),degree,evaluationPixels);
        scoreMask=remaining;if fixedValidation,scoreMask=true(size(remaining));end
        e=wavelength(scoreMask)-polyval(model.Coefficients,pixel(scoreMask),[],model.Mu);
        ae=abs(e); rounds=rounds+1;
        history(rounds)=struct('Round',rounds,'Ncal',sum(selected), ...
            'SelectedIndex',chosen,'FitRMSE',model.RMS,'ValidationRMSE',sqrt(mean(e.^2)), ...
            'ValidationP95',percentile95(ae),'ValidationMAX',max(ae), ...
            'CandidateCount',sum(valid),'Residual',e,'EvaluationPixels',pixel(scoreMask), ...
            'Status','Selected');
        candidateHistory{rounds}=candidates;
    end
    fullSetRMSEGap=NaN;
    if fixedValidation&&~any(remaining)&&~isempty(history)
        fullSetRMSEGap=abs(history(end).FitRMSE-history(end).ValidationRMSE);
    end
    result=struct('Degree',degree,'SeedMask',seedMask,'SelectedMask',selected, ...
        'RemainingMask',remaining,'History',history,'CandidateHistory',{candidateHistory}, ...
        'StopWhenCandidates',stopCount,'ValidationMode',validationMode, ...
        'FullSetRMSEGap',fullSetRMSEGap,'TerminationReason',terminationReason(remaining,stopCount));
end

function reason=terminationReason(remaining,stopCount)
    if sum(remaining)<=stopCount
        reason='StopWhenCandidates reached';
    elseif isempty(remaining)||~any(remaining)
        reason='No candidates remaining';
    else
        reason='No valid candidate available';
    end
end

function q=percentile95(x)
    x=sort(x(isfinite(x)));if isempty(x),q=NaN;return;end
    q=x(max(1,min(numel(x),ceil(0.95*numel(x)))));
end
