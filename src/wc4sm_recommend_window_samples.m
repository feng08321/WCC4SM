function result = wc4sm_recommend_window_samples(windowIndex,influence,symmetryDistance,options)
%WC4SM_RECOMMEND_WINDOW_SAMPLES Rank and recommend samples inside windows.
% The score favors high deletion influence and small FWHM-center/centroid
% distance. Recommendations are advisory and never select samples silently.
    if nargin<4||isempty(options),options=struct;end
    windowIndex=windowIndex(:);influence=influence(:);symmetryDistance=symmetryDistance(:);
    n=numel(windowIndex);
    if numel(influence)~=n||numel(symmetryDistance)~=n
        error('WCC4SM:WindowRecommendationSizeMismatch','Window, influence and symmetry vectors must match.');
    end
    influenceThreshold=getOption(options,'InfluenceThresholdPercent',25);
    symmetryThreshold=getOption(options,'SymmetryThresholdPixels',0.2);
    maxPerWindow=round(getOption(options,'MaxPerWindow',3));
    maxPerWindow=max(1,min(3,maxPerWindow));
    score=nan(n,1);recommended=false(n,1);reason=repmat({''},n,1);
    windows=unique(windowIndex(isfinite(windowIndex)&windowIndex>0)).';
    for w=windows
        members=find(windowIndex==w);iv=influence(members);sd=symmetryDistance(members);
        meanInfluence=mean(iv(isfinite(iv)));if ~isfinite(meanInfluence)||meanInfluence<=0,meanInfluence=eps;end
        influenceRatio=iv/meanInfluence;
        symmetryPenalty=sd/max(symmetryThreshold,eps);
        score(members)=influenceRatio./(1+max(symmetryPenalty,0));
        eligible=members(isfinite(iv)&(iv>=meanInfluence*(1+influenceThreshold/100) | isfinite(sd)&sd<=symmetryThreshold));
        if isempty(eligible),eligible=members(isfinite(iv));end
        [~,ord]=sort(score(eligible),'descend');take=min(maxPerWindow,numel(ord));recommended(eligible(ord(1:take)))=true;
        reason(eligible(ord(1:take)))=repmat({'Recommended: influence/symmetry balance'},take,1);
    end
    result=struct('Score',score,'Recommended',recommended,'Reason',{reason}, ...
        'InfluenceThresholdPercent',influenceThreshold,'SymmetryThresholdPixels',symmetryThreshold, ...
        'MaxPerWindow',maxPerWindow);
end

function v=getOption(s,name,default)
    v=default;if isfield(s,name)&&isscalar(s.(name))&&isfinite(s.(name)),v=s.(name);end
end
