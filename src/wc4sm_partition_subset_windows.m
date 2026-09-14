function result = wc4sm_partition_subset_windows(wavelength,influence,targetK,rule,peakIDs)
%WC4SM_PARTITION_SUBSET_WINDOWS Partition a calibration pool without selecting samples.
% The returned window membership is deterministic and is defined by sample
% indices after wavelength sorting. Boundaries are display coordinates only.
    wavelength=reshape(wavelength,[],1);influence=reshape(influence,[],1);n=numel(wavelength);
    if nargin<4||isempty(rule),rule='Equal wavelength width';end
    if nargin<5||isempty(peakIDs)
        peakIDs=arrayfun(@(k)sprintf('P%03d',k),(1:n).','UniformOutput',false);
    else
        peakIDs=cellstr(string(peakIDs(:)));
    end
    if numel(influence)~=n||numel(peakIDs)~=n
        error('WCC4SM:WindowPartitionSizeMismatch','Wavelength, influence and Peak ID inputs must have equal length.');
    end
    if n<1||any(~isfinite(wavelength))||any(~isfinite(influence))||any(influence<0)
        error('WCC4SM:WindowPartitionInvalidData','Wavelengths must be finite and influence values must be finite and nonnegative.');
    end
    if ~isscalar(targetK)||~isfinite(targetK)||targetK~=fix(targetK)||targetK<1||targetK>n
        error('WCC4SM:WindowPartitionInvalidK','Window count K must be an integer from 1 to N.');
    end
    [~,order]=sortrows([wavelength,(1:n).'],[1 2]);
    wl=wavelength(order);infl=influence(order);ids=peakIDs(order);
    totalInfluence=sum(infl);
    if totalInfluence>0,weight=infl/totalInfluence;else,weight=zeros(n,1);end
    cumulative=cumsum(weight);method=lower(strtrim(char(string(rule))));
    warnings={};cutIndices=[];boundaries=[];
    switch method
        case {'equal wavelength width','equal wavelength','wavelength'}
            if targetK>1&&wl(end)<=wl(1)
                error('WCC4SM:WindowPartitionZeroRange','Equal-width partition requires a nonzero wavelength range.');
            end
            edges=linspace(wl(1),wl(end),targetK+1);
            windowIndex=zeros(n,1);
            for j=1:targetK-1
                windowIndex(wl>=edges(j)&wl<edges(j+1))=j;
            end
            windowIndex(wl>=edges(targetK)&wl<=edges(targetK+1))=targetK;
            boundaries=edges(2:end-1);startWavelength=edges(1:end-1);endWavelength=edges(2:end);
            cutIndices=nan(1,targetK-1);
            for j=1:targetK-1
                q=find(windowIndex<=j,1,'last');if ~isempty(q),cutIndices(j)=q;end
            end
        case {'equal cumulative influence','cumulative influence','influence weight'}
            if totalInfluence<=eps(max(1,max(infl)))
                error('WCC4SM:WindowPartitionZeroInfluence','Equal cumulative influence requires a positive total deletion influence.');
            end
            cutIndices=reshape(optimalInfluenceCuts(cumulative,wl,targetK),1,[]);
            windowIndex=zeros(n,1);first=1;
            for j=1:targetK-1
                windowIndex(first:cutIndices(j))=j;first=cutIndices(j)+1;
            end
            windowIndex(first:n)=targetK;
            if targetK>1
                leftWavelength=reshape(wl(cutIndices),1,[]);
                rightWavelength=reshape(wl(cutIndices+1),1,[]);
                boundaries=reshape((leftWavelength+rightWavelength)/2,1,[]);
            else
                boundaries=zeros(1,0);
            end
            startWavelength=reshape([wl(1),boundaries],1,[]);
            endWavelength=reshape([boundaries,wl(end)],1,[]);
            coincident=find(targetK>1 & wl(cutIndices)==wl(cutIndices+1));
            if ~isempty(coincident),warnings{end+1}=sprintf('%d boundary/boundaries split coincident wavelengths.',numel(coincident));end %#ok<AGROW>
        otherwise
            error('WCC4SM:WindowPartitionUnknownRule','Unknown partition rule: %s',rule);
    end
    dominant=find(weight>1/targetK);
    dominantTemplate=struct('SortedIndex',NaN,'OriginalIndex',NaN,'PeakID','','Wavelength',NaN,'NormalizedInfluence',NaN);
    dominantSamples=repmat(dominantTemplate,numel(dominant),1);
    for k=1:numel(dominant)
        q=dominant(k);dominantSamples(k)=struct('SortedIndex',q,'OriginalIndex',order(q), ...
            'PeakID',ids{q},'Wavelength',wl(q),'NormalizedInfluence',weight(q));
    end
    if ~isempty(dominant),warnings{end+1}=sprintf('%d dominant influence sample(s) exceed the target weight 1/K.',numel(dominant));end %#ok<AGROW>
    targetWeight=NaN;if contains(method,'influence'),targetWeight=1/targetK;end
    emptyWindow=struct('WindowID','','StartWavelength',NaN,'EndWavelength',NaN, ...
        'FirstSampleIndex',NaN,'LastSampleIndex',NaN,'NumberOfSamples',0, ...
        'SumInfluence',0,'NormalizedInfluenceSum',0,'MeanInfluence',NaN,'MaxInfluence',NaN, ...
        'MaxInfluencePeakID','','MaxInfluenceWavelength',NaN,'TargetWeight',NaN, ...
        'ActualWeight',0,'DeviationFromTarget',NaN,'CumulativeEndWeight',NaN,'Status','');
    windows=repmat(emptyWindow,targetK,1);
    for j=1:targetK
        members=find(windowIndex==j);status='OK';
        if isempty(members)
            firstIndex=NaN;lastIndex=NaN;meanInfluence=NaN;maxInfluence=NaN;maxID='';maxWL=NaN;status='Empty window';
        else
            firstIndex=members(1);lastIndex=members(end);meanInfluence=mean(infl(members));
            [maxInfluence,q]=max(infl(members));maxIndex=members(q);maxID=ids{maxIndex};maxWL=wl(maxIndex);
            if any(ismember(members,dominant)),status='Dominant influence sample';end
        end
        actualWeight=sum(weight(members));deviation=NaN;if isfinite(targetWeight),deviation=actualWeight-targetWeight;end
        cumulativeEnd=sum(weight(windowIndex<=j));
        windows(j)=struct('WindowID',sprintf('W%d',j),'StartWavelength',startWavelength(j), ...
            'EndWavelength',endWavelength(j),'FirstSampleIndex',firstIndex,'LastSampleIndex',lastIndex, ...
            'NumberOfSamples',numel(members),'SumInfluence',sum(infl(members)), ...
            'NormalizedInfluenceSum',actualWeight,'MeanInfluence',meanInfluence,'MaxInfluence',maxInfluence, ...
            'MaxInfluencePeakID',maxID,'MaxInfluenceWavelength',maxWL,'TargetWeight',targetWeight, ...
            'ActualWeight',actualWeight,'DeviationFromTarget',deviation, ...
            'CumulativeEndWeight',cumulativeEnd,'Status',status);
    end
    emptyCount=sum([windows.NumberOfSamples]==0);
    if emptyCount>0,warnings{end+1}=sprintf('%d empty equal-width window(s) were retained without moving the theoretical boundaries.',emptyCount);end %#ok<AGROW>
    originalWindowIndex=zeros(n,1);originalWindowIndex(order)=windowIndex;
    result=struct('Version',1,'Degree',3,'Rule',char(string(rule)),'TargetK',targetK, ...
        'SortedOriginalIndices',order(:).','SortedPeakIDs',{ids(:).'},'SortedWavelength',wl, ...
        'SortedInfluence',infl,'NormalizedWeight',weight,'CumulativeWeight',cumulative, ...
        'SortedWindowIndex',windowIndex,'SampleWindowIndex',originalWindowIndex, ...
        'CutIndices',cutIndices(:).','Boundaries',boundaries(:).','Windows',windows, ...
        'DominantSamples',dominantSamples,'Warnings',{warnings},'TotalInfluence',totalInfluence);
end

function cuts=optimalInfluenceCuts(cumulative,wavelength,targetK)
    n=numel(cumulative);if targetK==1,cuts=[];return;end
    stages=targetK-1;cost=inf(stages,n-1);gapScore=-inf(stages,n-1);previous=zeros(stages,n-1);
    gaps=diff(wavelength);tieTolerance=1e-10;
    for j=1:stages
        cMin=j;cMax=n-(targetK-j);target=j/targetK;
        for c=cMin:cMax
            localCost=abs(cumulative(c)-target);localGap=gaps(c);
            if j==1
                cost(j,c)=localCost;gapScore(j,c)=localGap;
            else
                for p=j-1:c-1
                    if ~isfinite(cost(j-1,p)),continue;end
                    candidateCost=cost(j-1,p)+localCost;candidateGap=gapScore(j-1,p)+localGap;
                    if candidateCost<cost(j,c)-tieTolerance|| ...
                            (abs(candidateCost-cost(j,c))<=tieTolerance&&candidateGap>gapScore(j,c))
                        cost(j,c)=candidateCost;gapScore(j,c)=candidateGap;previous(j,c)=p;
                    end
                end
            end
        end
    end
    candidates=stages:n-1;best=candidates(1);
    for c=candidates(2:end)
        if cost(stages,c)<cost(stages,best)-tieTolerance|| ...
                (abs(cost(stages,c)-cost(stages,best))<=tieTolerance&&gapScore(stages,c)>gapScore(stages,best))
            best=c;
        end
    end
    cuts=zeros(1,stages);cuts(stages)=best;
    for j=stages:-1:2,cuts(j-1)=previous(j,cuts(j));end
end
