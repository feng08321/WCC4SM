function result = wc4sm_generate_subset_mask(wavelength,targetK,method,options)
%WC4SM_GENERATE_SUBSET_MASK Deterministic reference-space subset generator.
    if nargin<4||isempty(options),options=struct;end
    wavelength=wavelength(:);n=numel(wavelength);method=char(string(method));
    if ~isscalar(targetK)||targetK<1||targetK>n||targetK~=fix(targetK),error('WCC4SM:SubsetGeneratorInvalidK','Target K must be an integer from 1 to N.');end
    influence=getVector(options,'Influence',nan(n,1),n);quality=getVector(options,'Quality',nan(n,1),n);
    locked=logical(getVector(options,'LockedMask',false(n,1),n));forbidden=logical(getVector(options,'ForbiddenMask',false(n,1),n));
    if any(locked&forbidden),error('WCC4SM:SubsetGeneratorConflictingMask','A point cannot be both locked and forbidden.');end
    if sum(locked)>targetK,error('WCC4SM:SubsetGeneratorTooManyLocked','Locked points exceed target K.');end
    available=~forbidden;mask=locked;
    switch lower(strtrim(method))
        case {'manual','manual selection'}
            if ~isfield(options,'ManualMask'),error('WCC4SM:SubsetGeneratorMissingManual','ManualMask is required.');end
            mask=logical(getVector(options,'ManualMask',false(n,1),n));
            if any(mask&forbidden),error('WCC4SM:SubsetGeneratorForbiddenManual','Manual selection contains forbidden points.');end
            if sum(mask)~=targetK,error('WCC4SM:SubsetGeneratorManualCount','Manual selection must contain exactly target K points.');end
        case {'top-k influence','top-k'}
            mask=fillByRanking(mask,available,targetK,[-finiteLow(influence),-finiteLow(quality),wavelength]);
        case {'maximin coverage','maximin'}
            mask=fillMaximin(mask,available,wavelength,targetK,false);
        case {'locked boundary + coverage','locked boundary + maximin'}
            [~,a]=min(wavelength);[~,b]=max(wavelength);mask([a b])=true;
            if any(mask&forbidden),error('WCC4SM:SubsetGeneratorBoundaryForbidden','Boundary points are forbidden.');end
            mask=fillMaximin(mask,available,wavelength,targetK,true);
        case {'window influence','window quality','window center'}
            rule=extractAfter(lower(strtrim(method)),'window ');mask=selectWindows(mask,available,wavelength,influence,quality,targetK,rule);
        otherwise
            error('WCC4SM:SubsetGeneratorUnknownMethod','Unknown subset generation method: %s',method);
    end
    result=struct('Method',method,'TargetK',targetK,'Mask',mask,'SelectedIndices',find(mask).', ...
        'Wavelengths',wavelength(mask),'LockedIndices',find(locked).','ForbiddenIndices',find(forbidden).');
end

function value=getVector(options,name,default,n)
    value=default;if isfield(options,name)&&~isempty(options.(name)),value=options.(name);end;value=value(:);
    if numel(value)~=n,error('WCC4SM:SubsetGeneratorSizeMismatch','%s must match wavelength length.',name);end
end
function v=finiteLow(v),v(~isfinite(v))=-realmax;end
function mask=fillByRanking(mask,available,targetK,features)
    candidates=find(available&~mask);[~,ord]=sortrows(features(candidates,:),1:size(features,2));take=min(targetK-sum(mask),numel(ord));mask(candidates(ord(1:take)))=true;
    if sum(mask)~=targetK,error('WCC4SM:SubsetGeneratorInsufficientCandidates','Not enough available points to reach target K.');end
end
function mask=fillMaximin(mask,available,wavelength,targetK,useBoundary)
    if ~any(mask)
        if useBoundary
            candidates=find(available);[~,q]=min(wavelength(candidates));j=candidates(q);
        else
            candidates=find(available);[~,q]=min(abs(wavelength(candidates)-median(wavelength(candidates))));j=candidates(q);
        end
        mask(j)=true;
    end
    while sum(mask)<targetK
        candidates=find(available&~mask);if isempty(candidates),break;end
        selected=wavelength(mask);score=arrayfun(@(j)min(abs(wavelength(j)-selected)),candidates);[~,q]=max(score);mask(candidates(q))=true;
    end
    if sum(mask)~=targetK,error('WCC4SM:SubsetGeneratorInsufficientCandidates','Not enough available points to reach target K.');end
end
function mask=selectWindows(mask,available,wavelength,influence,quality,targetK,rule)
    candidates=find(available&~mask);[~,ord]=sort(wavelength(candidates));candidates=candidates(ord);slots=targetK-sum(mask);
    for q=1:slots
        lo=floor((q-1)*numel(candidates)/slots)+1;hi=floor(q*numel(candidates)/slots);group=candidates(lo:hi);
        switch rule
            case 'influence',[~,j]=max(finiteLow(influence(group)));
            case 'quality',[~,j]=max(finiteLow(quality(group)));
            otherwise,target=mean(wavelength(group));[~,j]=min(abs(wavelength(group)-target));
        end
        mask(group(j))=true;
    end
    if sum(mask)~=targetK,error('WCC4SM:SubsetGeneratorWindowCount','Window generation did not reach target K.');end
end
