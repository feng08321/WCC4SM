function state = wc4sm_initialize_backward_beam(pixel,wavelength,degree,targetK,evaluationPixels,options)
%WC4SM_INITIALIZE_BACKWARD_BEAM Initialize a pausable backward Beam search.
%   The returned state is advanced one deletion layer at a time by
%   wc4sm_backward_beam_step and wc4sm_accept_beam_layer.
    if nargin<5||isempty(evaluationPixels)
        evaluationPixels=linspace(min(pixel),max(pixel),200).';
    end
    if nargin<6||isempty(options),options=struct;end
    pixel=pixel(:);wavelength=wavelength(:);evaluationPixels=evaluationPixels(:);
    n=numel(pixel);
    if numel(wavelength)~=n||any(~isfinite(pixel))||any(~isfinite(wavelength))
        error('WCC4SM:BeamInvalidData','Pixel and wavelength must be finite vectors of equal length.');
    end
    if targetK<degree+1||targetK>n||targetK~=fix(targetK)
        error('WCC4SM:BeamInvalidTargetK','Target K must be between degree+1 and N.');
    end
    bPerf=getOption(options,'BPerf',5);bDiv=getOption(options,'BDiv',5);
    epsilonRMS=getOption(options,'EpsilonRMS',0.01);
    epsilonMAX=getOption(options,'EpsilonMAX',0.03);
    if any([bPerf bDiv]<0)||any([bPerf bDiv]~=fix([bPerf bDiv]))||bPerf+bDiv<1
        error('WCC4SM:BeamInvalidWidth','BPerf and BDiv must be nonnegative integers with positive total.');
    end
    ids=arrayfun(@(k)sprintf('P%03d',k),(1:n).','UniformOutput',false);
    if isfield(options,'PeakIDs')&&~isempty(options.PeakIDs)
        ids=cellstr(string(options.PeakIDs(:)));
    end
    if numel(ids)~=n,error('WCC4SM:BeamPeakIDSizeMismatch','Peak IDs must match the full pool.');end
    positionMethod='Unspecified';
    if isfield(options,'PositionMethod'),positionMethod=char(string(options.PositionMethod));end
    locked=false(n,1);
    if isfield(options,'LockedMask')&&~isempty(options.LockedMask)
        locked=logical(options.LockedMask(:));
    end
    if numel(locked)~=n||sum(locked)>targetK
        error('WCC4SM:BeamInvalidLockedMask','LockedMask must match N and contain no more than target K points.');
    end
    baselineModel=wc4sm_fit_calibration(pixel,wavelength,degree,evaluationPixels,positionMethod,ids);
    evalOptions=struct('PeakIDs',{ids},'PositionMethod',positionMethod,'SkipLOO',false);
    baselineRecord=wc4sm_evaluate_subset(pixel,wavelength,true(n,1),degree,evaluationPixels,baselineModel,evalOptions);
    node=struct('NodeID',1,'ParentNodeID',0,'DeletedIndex',NaN,'K',n, ...
        'Key',char('0'+true(1,n)),'Mask',true(n,1),'Role','Baseline', ...
        'Record',baselineRecord,'CoverRepresentativeNodeID',1,'PathNodeIDs',1);
    layer=struct('K',n,'CandidateCount',1,'AcceptedNodeIDs',1,'CoverCount',1);
    state=struct('Pixel',pixel,'Wavelength',wavelength,'Degree',degree,'TargetK',targetK, ...
        'EvaluationPixels',evaluationPixels,'PeakIDs',{ids},'PositionMethod',positionMethod, ...
        'LockedMask',locked,'BPerf',bPerf,'BDiv',bDiv,'EpsilonRMS',epsilonRMS, ...
        'EpsilonMAX',epsilonMAX,'BaselineModel',baselineModel,'BaselineRecord',baselineRecord, ...
        'Nodes',node,'Layers',layer,'CurrentNodeIDs',1,'NextNodeID',2, ...
        'PendingCandidates',[],'PendingK',NaN,'Complete',targetK==n, ...
        'Status','Ready to calculate the next deletion layer');
    if state.Complete,state.Status='Target reached';end
end

function value=getOption(options,name,default)
    value=default;
    if isfield(options,name)&&~isempty(options.(name)),value=options.(name);end
end
