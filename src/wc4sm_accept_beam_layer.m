function [state,acceptedNodeIDs] = wc4sm_accept_beam_layer(state,selectedRows)
%WC4SM_ACCEPT_BEAM_LAYER Accept selected rows from the pending proposal.
%   With no selectedRows, the automatically recommended performance and
%   diversity candidates are accepted.
    candidates=state.PendingCandidates;
    if isempty(candidates),error('WCC4SM:BeamNoPendingLayer','Calculate a proposal layer first.');end
    if nargin<2||isempty(selectedRows),selectedRows=find([candidates.Recommended]);end
    selectedRows=unique(selectedRows(:).','stable');
    if isempty(selectedRows)||any(selectedRows<1)||any(selectedRows>numel(candidates))||any(selectedRows~=fix(selectedRows))
        error('WCC4SM:BeamInvalidSelection','Select at least one valid pending candidate row.');
    end
    selected=candidates(selectedRows);
    acceptedNodeIDs=zeros(1,numel(selected));
    for q=1:numel(selected)
        id=state.NextNodeID;state.NextNodeID=id+1;acceptedNodeIDs(q)=id;
        role=selected(q).Role;
        if ~selected(q).Recommended,role='Manual';end
        node=struct('NodeID',id,'ParentNodeID',selected(q).ParentNodeID, ...
            'DeletedIndex',selected(q).DeletedIndex,'K',selected(q).K, ...
            'Key',selected(q).Key,'Mask',selected(q).Mask,'Role',role, ...
            'Record',selected(q).Record,'CoverRepresentativeNodeID',NaN, ...
            'PathNodeIDs',[selected(q).PathNodeIDs id]);
        state.Nodes(id)=node;
    end
    cover=wc4sm_build_epsilon_cover([state.Nodes(acceptedNodeIDs).Record],state.EpsilonRMS,state.EpsilonMAX);
    for q=1:numel(acceptedNodeIDs)
        group=cover.Assignment(q);repLocal=cover.RepresentativeIndices(group);
        state.Nodes(acceptedNodeIDs(q)).CoverRepresentativeNodeID=acceptedNodeIDs(repLocal);
    end
    layer=struct('K',state.PendingK,'CandidateCount',numel(candidates), ...
        'AcceptedNodeIDs',acceptedNodeIDs,'CoverCount',cover.Count);
    state.Layers(end+1)=layer;state.CurrentNodeIDs=acceptedNodeIDs;
    acceptedK=state.PendingK;state.PendingCandidates=[];state.PendingK=NaN;
    state.Complete=acceptedK<=state.TargetK;
    if state.Complete
        state.Status=sprintf('Target K=%d reached; %d subsets retained',acceptedK,numel(acceptedNodeIDs));
    else
        state.Status=sprintf('K=%d accepted; ready to calculate K=%d',acceptedK,acceptedK-1);
    end
end
