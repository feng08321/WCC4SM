function [state,proposal] = wc4sm_backward_beam_step(state,parentNodeIDs)
%WC4SM_BACKWARD_BEAM_STEP Calculate exactly one K to K-1 proposal layer.
%   This function does not accept or advance the layer. The caller can
%   inspect proposal.Candidates and then call wc4sm_accept_beam_layer.
    if nargin<2||isempty(parentNodeIDs),parentNodeIDs=state.CurrentNodeIDs;end
    if state.Complete,error('WCC4SM:BeamAlreadyComplete','The target K has already been reached.');end
    if ~isempty(state.PendingCandidates)
        error('WCC4SM:BeamPendingLayer','Accept or discard the pending layer before calculating another.');
    end
    parentNodeIDs=unique(parentNodeIDs(:).','stable');
    if any(~ismember(parentNodeIDs,state.CurrentNodeIDs))
        error('WCC4SM:BeamInvalidParents','Parents must be selected from the current accepted Beam.');
    end
    parentK=[state.Nodes(parentNodeIDs).K];
    if isempty(parentK)||any(parentK~=parentK(1))
        error('WCC4SM:BeamMixedParentK','All selected parents must belong to one K layer.');
    end
    childK=parentK(1)-1;
    if childK<state.TargetK,error('WCC4SM:BeamBelowTarget','The next layer would be below target K.');end
    template=emptyCandidate();candidates=repmat(template,0,1);
    seen=containers.Map('KeyType','char','ValueType','logical');
    evalOptions=struct('PeakIDs',{state.PeakIDs},'PositionMethod',state.PositionMethod,'SkipLOO',true);
    for pp=1:numel(parentNodeIDs)
        parent=state.Nodes(parentNodeIDs(pp));
        removable=find(parent.Mask&~state.LockedMask).';
        for deleted=removable
            mask=parent.Mask;mask(deleted)=false;key=char('0'+mask.');
            if isKey(seen,key),continue;end
            seen(key)=true;
            try
                rec=wc4sm_evaluate_subset(state.Pixel,state.Wavelength,mask,state.Degree, ...
                    state.EvaluationPixels,state.BaselineModel,evalOptions);
                candidate=emptyCandidate();
                candidate.ParentNodeID=parent.NodeID;candidate.DeletedIndex=deleted;
                candidate.K=childK;candidate.Key=key;candidate.Mask=mask;
                candidate.Record=rec;candidate.Role='Not retained';
                candidate.Recommended=false;candidate.PathNodeIDs=parent.PathNodeIDs;
                candidates(end+1)=candidate; %#ok<AGROW>
            catch
                % Invalid or numerically singular subsets are omitted.
            end
        end
    end
    if isempty(candidates),error('WCC4SM:BeamNoCandidates','No valid child subsets were generated.');end
    [selected,roles]=recommendCandidates(candidates,state.BPerf,state.BDiv,state.EpsilonRMS,state.EpsilonMAX);
    for q=1:numel(selected)
        candidates(selected(q)).Recommended=true;
        candidates(selected(q)).Role=roles{q};
    end
    cover=wc4sm_build_epsilon_cover([candidates.Record],state.EpsilonRMS,state.EpsilonMAX);
    for q=1:numel(candidates),candidates(q).CoverID=cover.Assignment(q);end
    state.PendingCandidates=candidates;state.PendingK=childK;
    state.Status=sprintf('K=%d proposal ready: %d candidates, %d recommended', ...
        childK,numel(candidates),numel(selected));
    proposal=struct('K',childK,'Candidates',candidates,'RecommendedRows',selected, ...
        'Cover',cover,'ParentNodeIDs',parentNodeIDs,'Status',state.Status);
end

function [selected,roles]=recommendCandidates(candidates,bPerf,bDiv,epsilonRMS,epsilonMAX)
    rmse=arrayfun(@(x)x.Record.AllRMSE,candidates).';
    p95=arrayfun(@(x)x.Record.AllP95,candidates).';
    mx=arrayfun(@(x)x.Record.AllMAX,candidates).';
    [~,ord]=sortrows([rmse p95 mx],[1 2 3]);
    perf=ord(1:min(bPerf,numel(ord))).';selected=perf;
    for q=1:bDiv
        remaining=setdiff(1:numel(candidates),selected,'stable');
        if isempty(remaining),break;end
        novelty=zeros(size(remaining));
        for rr=1:numel(remaining)
            if isempty(selected)
                novelty(rr)=candidates(remaining(rr)).Record.DistanceRMS/max(epsilonRMS,eps);
            else
                values=inf(size(selected));
                for ss=1:numel(selected)
                    delta=candidates(remaining(rr)).Record.Curve-candidates(selected(ss)).Record.Curve;
                    values(ss)=max(sqrt(mean(delta.^2))/max(epsilonRMS,eps), ...
                        max(abs(delta))/max(epsilonMAX,eps));
                end
                novelty(rr)=min(values);
            end
        end
        [~,best]=max(novelty);selected(end+1)=remaining(best); %#ok<AGROW>
    end
    roles=repmat({'Diversity'},size(selected));roles(ismember(selected,perf))={'Performance'};
end

function candidate=emptyCandidate
    candidate=struct('ParentNodeID',NaN,'DeletedIndex',NaN,'K',NaN,'Key','', ...
        'Mask',[],'Role','','Recommended',false,'Record',[],'CoverID',NaN,'PathNodeIDs',[]);
end
