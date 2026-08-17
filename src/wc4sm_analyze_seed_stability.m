function result = wc4sm_analyze_seed_stability(pixel,wavelength,seedMasks,degree,evaluationPixels,options)
%WC4SM_ANALYZE_SEED_STABILITY Compare Add-One paths from multiple seeds.
    if nargin<4||isempty(degree),degree=3;end
    if nargin<5||isempty(evaluationPixels),evaluationPixels=pixel;end
    if nargin<6||isempty(options),options=struct;end
    pixel=pixel(:);wavelength=wavelength(:);evaluationPixels=evaluationPixels(:);
    if isvector(seedMasks),seedMasks=seedMasks(:);end
    if size(seedMasks,1)~=numel(pixel)
        error('WCC4SM:SeedMaskSizeMismatch','seedMasks rows must match pixel and wavelength.');
    end
    n=size(seedMasks,2);paths=cell(n,1);summary=repmat(struct( ...
        'SeedID',NaN,'SeedCount',NaN,'Rounds',NaN,'FinalNcal',NaN, ...
        'FinalValidationRMSE',NaN,'SelectedIndices',[]),n,1);
    for k=1:n
        path=wc4sm_analyze_add_one_path(pixel,wavelength,seedMasks(:,k),degree,evaluationPixels,options);
        paths{k}=path;h=path.History;summary(k).SeedID=k;
        summary(k).SeedCount=sum(seedMasks(:,k));summary(k).Rounds=numel(h);
        summary(k).FinalNcal=sum(path.SelectedMask);
        if ~isempty(h),summary(k).FinalValidationRMSE=h(end).ValidationRMSE;end
        summary(k).SelectedIndices=find(path.SelectedMask & ~seedMasks(:,k));
    end
    result=struct('Degree',degree,'Summary',summary,'Paths',{paths});
end
