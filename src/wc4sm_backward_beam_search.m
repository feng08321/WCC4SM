function result = wc4sm_backward_beam_search(pixel,wavelength,degree,targetK,evaluationPixels,options)
%WC4SM_BACKWARD_BEAM_SEARCH Deterministic performance/diversity backward search.
    if nargin<5||isempty(evaluationPixels),evaluationPixels=linspace(min(pixel),max(pixel),200).';end
    if nargin<6||isempty(options),options=struct;end
    pixel=pixel(:);wavelength=wavelength(:);evaluationPixels=evaluationPixels(:);n=numel(pixel);
    if numel(wavelength)~=n||any(~isfinite(pixel))||any(~isfinite(wavelength)),error('WCC4SM:BeamInvalidData','Pixel and wavelength must be finite vectors of equal length.');end
    if targetK<degree+1||targetK>n||targetK~=fix(targetK),error('WCC4SM:BeamInvalidTargetK','Target K must be between degree+1 and N.');end
    bPerf=getOption(options,'BPerf',5);bDiv=getOption(options,'BDiv',5);epsilonRMS=getOption(options,'EpsilonRMS',0.01);epsilonMAX=getOption(options,'EpsilonMAX',0.03);
    if any([bPerf bDiv]<0)||any([bPerf bDiv]~=fix([bPerf bDiv]))||bPerf+bDiv<1,error('WCC4SM:BeamInvalidWidth','BPerf and BDiv must be nonnegative integers with positive total.');end
    ids=arrayfun(@(k)sprintf('P%03d',k),(1:n).','UniformOutput',false);if isfield(options,'PeakIDs')&&~isempty(options.PeakIDs),ids=cellstr(string(options.PeakIDs(:)));end
    if numel(ids)~=n,error('WCC4SM:BeamPeakIDSizeMismatch','Peak IDs must match the full pool.');end
    positionMethod='Unspecified';if isfield(options,'PositionMethod'),positionMethod=char(string(options.PositionMethod));end
    locked=false(n,1);if isfield(options,'LockedMask')&&~isempty(options.LockedMask),locked=logical(options.LockedMask(:));end
    if numel(locked)~=n||sum(locked)>targetK,error('WCC4SM:BeamInvalidLockedMask','LockedMask must match N and contain no more than target K points.');end
    evalOptions=struct('PeakIDs',{ids},'PositionMethod',positionMethod,'SkipLOO',true);
    baselineModel=wc4sm_fit_calibration(pixel,wavelength,degree,evaluationPixels,positionMethod,ids);
    baselineRecord=wc4sm_evaluate_subset(pixel,wavelength,true(n,1),degree,evaluationPixels,baselineModel,struct('PeakIDs',{ids},'PositionMethod',positionMethod,'SkipLOO',false));
    template=emptyNode();nodes=template;nodes(1)=makeNode(1,0,NaN,true(n,1),'Baseline',baselineRecord,1,1);currentIDs=1;nextID=2;
    layers=repmat(struct('K',NaN,'CandidateCount',NaN,'AcceptedNodeIDs',[],'CoverCount',NaN),0,1);
    layers(1)=struct('K',n,'CandidateCount',1,'AcceptedNodeIDs',1,'CoverCount',1);
    for childK=n-1:-1:targetK
        candidates=repmat(template,0,1);seen=containers.Map('KeyType','char','ValueType','logical');
        for pp=1:numel(currentIDs)
            parent=nodes(currentIDs(pp));removable=find(parent.Mask&~locked).';
            for deleted=removable
                mask=parent.Mask;mask(deleted)=false;key=char('0'+mask.');if isKey(seen,key),continue;end;seen(key)=true;
                try
                    rec=wc4sm_evaluate_subset(pixel,wavelength,mask,degree,evaluationPixels,baselineModel,evalOptions);
                    candidates(end+1)=makeNode(0,parent.NodeID,deleted,mask,'Candidate',rec,0,[parent.PathNodeIDs 0]); %#ok<AGROW>
                catch
                end
            end
        end
        if isempty(candidates),break;end
        [selected,roles]=selectCandidates(candidates,bPerf,bDiv,epsilonRMS,epsilonMAX);accepted=candidates(selected);
        for aa=1:numel(accepted)
            accepted(aa).Role=roles{aa};
            accepted(aa).NodeID=nextID;accepted(aa).PathNodeIDs(end)=nextID;nodes(nextID)=accepted(aa);nextID=nextID+1; %#ok<AGROW>
        end
        currentIDs=[accepted.NodeID];records=[accepted.Record];cover=wc4sm_build_epsilon_cover(records,epsilonRMS,epsilonMAX);
        for aa=1:numel(accepted)
            group=cover.Assignment(aa);repLocal=cover.RepresentativeIndices(group);nodes(currentIDs(aa)).CoverRepresentativeNodeID=currentIDs(repLocal);
        end
        layers(end+1)=struct('K',childK,'CandidateCount',numel(candidates),'AcceptedNodeIDs',currentIDs,'CoverCount',cover.Count); %#ok<AGROW>
        if isfield(options,'ProgressFcn')&&~isempty(options.ProgressFcn),options.ProgressFcn(childK,numel(candidates),numel(currentIDs));end
    end
    finalIDs=currentIDs([nodes(currentIDs).K]==targetK);finalCover=struct();
    if ~isempty(finalIDs),finalCover=wc4sm_build_epsilon_cover([nodes(finalIDs).Record],epsilonRMS,epsilonMAX);end
    result=struct('Degree',degree,'TargetK',targetK,'BPerf',bPerf,'BDiv',bDiv,'EpsilonRMS',epsilonRMS,'EpsilonMAX',epsilonMAX, ...
        'BaselineModel',baselineModel,'BaselineRecord',baselineRecord,'Nodes',nodes,'Layers',layers,'FinalNodeIDs',finalIDs,'FinalCover',finalCover, ...
        'EvaluationPixels',evaluationPixels,'PeakIDs',{ids},'LockedMask',locked,'Status',terminationStatus(finalIDs,targetK));
end

function [selected,roles]=selectCandidates(candidates,bPerf,bDiv,epsilonRMS,epsilonMAX)
    metric=arrayfun(@(x)x.Record.AllRMSE,candidates).';p95=arrayfun(@(x)x.Record.AllP95,candidates).';mx=arrayfun(@(x)x.Record.AllMAX,candidates).';
    [~,ord]=sortrows([metric p95 mx],[1 2 3]);perf=ord(1:min(bPerf,numel(ord))).';selected=perf;
    for q=1:bDiv
        remaining=setdiff(1:numel(candidates),selected,'stable');if isempty(remaining),break;end
        novelty=zeros(size(remaining));
        for rr=1:numel(remaining)
            if isempty(selected),novelty(rr)=candidates(remaining(rr)).Record.DistanceRMS/max(epsilonRMS,eps);continue;end
            values=inf(size(selected));
            for ss=1:numel(selected)
                delta=candidates(remaining(rr)).Record.Curve-candidates(selected(ss)).Record.Curve;
                values(ss)=max(sqrt(mean(delta.^2))/max(epsilonRMS,eps),max(abs(delta))/max(epsilonMAX,eps));
            end
            novelty(rr)=min(values);
        end
        [~,best]=max(novelty);selected(end+1)=remaining(best); %#ok<AGROW>
    end
    roles=repmat({'Diversity'},size(selected));roles(ismember(selected,perf))={'Performance'};
end

function node=makeNode(id,parent,deleted,mask,role,record,coverID,path)
    node=emptyNode();node.NodeID=id;node.ParentNodeID=parent;node.DeletedIndex=deleted;node.K=sum(mask);node.Key=char('0'+mask.');node.Mask=mask;node.Role=role;node.Record=record;node.CoverRepresentativeNodeID=coverID;node.PathNodeIDs=path;
end
function node=emptyNode
    node=struct('NodeID',NaN,'ParentNodeID',NaN,'DeletedIndex',NaN,'K',NaN,'Key','','Mask',[], ...
        'Role','','Record',[],'CoverRepresentativeNodeID',NaN,'PathNodeIDs',[]);
end
function value=getOption(options,name,default),value=default;if isfield(options,name)&&~isempty(options.(name)),value=options.(name);end;end
function status=terminationStatus(finalIDs,targetK),if isempty(finalIDs),status=sprintf('Stopped before target K=%d',targetK);else,status='Target reached';end;end
