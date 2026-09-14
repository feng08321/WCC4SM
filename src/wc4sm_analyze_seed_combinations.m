function result = wc4sm_analyze_seed_combinations(pixel,wavelength,seedSize,degree,options)
%WC4SM_ANALYZE_SEED_COMBINATIONS Rank seed combinations by validation error.
    if nargin<3||isempty(seedSize),seedSize=5;end
    if nargin<4||isempty(degree),degree=3;end
    if nargin<5||isempty(options),options=struct;end
    pixel=pixel(:);wavelength=wavelength(:);n=numel(pixel);
    if n~=numel(wavelength),error('WCC4SM:SeedCombinationSizeMismatch','Pixel and wavelength vectors must match.');end
    if n<seedSize||seedSize<degree+1,error('WCC4SM:SeedCombinationInsufficientPoints','Insufficient points for the requested seed size and degree.');end
    if ~isfield(options,'ValidationMode'),options.ValidationMode='Remaining';end
    if ~isfield(options,'TopN'),options.TopN=20;end
    if ~isfield(options,'MaxCombinations'),options.MaxCombinations=1e6;end
    combos=nchoosek(1:n,seedSize);total=size(combos,1);
    if total>options.MaxCombinations,error('WCC4SM:SeedCombinationTooMany','%d combinations exceed MaxCombinations.',total);end
    empty=struct('Rank',NaN,'SeedIndices',[],'ValidationRMSE',NaN,'ValidationP95',NaN,'ValidationMAX',NaN,'FitRMSE',NaN,'Status','');
    records=repmat(empty,total,1);
    for k=1:total
        seed=combos(k,:);validate=true(n,1);
        if strcmpi(options.ValidationMode,'Remaining'),validate(seed)=false;end
        try
            m=wc4sm_fit_calibration(pixel(seed),wavelength(seed),degree,pixel);
            e=wavelength(validate)-polyval(m.Coefficients,pixel(validate),[],m.Mu);ae=abs(e);
            records(k).SeedIndices=seed;records(k).ValidationRMSE=sqrt(mean(e.^2));records(k).ValidationP95=percentile95(ae);records(k).ValidationMAX=max(ae);records(k).FitRMSE=m.RMS;records(k).Status='Available';
        catch ME
            records(k).SeedIndices=seed;records(k).Status=['Failed: ' ME.identifier];
        end
    end
    scores=[records.ValidationRMSE];[~,order]=sort(scores);records=records(order);
    allRecords=records;for k=1:numel(allRecords),allRecords(k).Rank=k;end
    keep=min(options.TopN,numel(records));records=records(1:keep);
    result=struct('SeedSize',seedSize,'Degree',degree,'ValidationMode',options.ValidationMode,'TotalCombinations',total,'Records',records,'AllRecords',allRecords);
end
function q=percentile95(x)
    x=sort(x(isfinite(x)));if isempty(x),q=NaN;return;end
    q=x(max(1,min(numel(x),ceil(0.95*numel(x)))));
end
