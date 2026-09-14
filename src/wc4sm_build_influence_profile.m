function profile = wc4sm_build_influence_profile(pixel,wavelength,degree,peakIDs,quality)
%WC4SM_BUILD_INFLUENCE_PROFILE Rank fixed-pool deletion influence by sample.
    pixel=pixel(:);wavelength=wavelength(:);n=numel(pixel);
    if nargin<3||isempty(degree),degree=3;end
    if nargin<4||isempty(peakIDs),peakIDs=arrayfun(@(k)sprintf('P%03d',k),(1:n).','UniformOutput',false);else,peakIDs=cellstr(string(peakIDs(:)));end
    if nargin<5||isempty(quality),quality=nan(n,1);else,quality=quality(:);end
    if numel(wavelength)~=n||numel(peakIDs)~=n||numel(quality)~=n,error('WCC4SM:InfluenceProfileSizeMismatch','All profile inputs must have equal length.');end
    analysis=wc4sm_analyze_point_influence(pixel,wavelength,degree);points=analysis.Points;influence=[points.InfluenceRatio].';
    [~,order]=sortrows([-influence,-quality,wavelength],[1 2 3]);rank=zeros(n,1);rank(order)=1:n;
    if n>1,percentile=100*(n-rank)/(n-1);else,percentile=100;end
    [sortedWavelength,ordW]=sort(wavelength);spacing=inf(n,1);
    for k=1:n
        q=find(ordW==k,1);neighbors=[];if q>1,neighbors(end+1)=sortedWavelength(q)-sortedWavelength(q-1);end %#ok<AGROW>
        if q<n,neighbors(end+1)=sortedWavelength(q+1)-sortedWavelength(q);end %#ok<AGROW>
        if ~isempty(neighbors),spacing(k)=min(neighbors);end
    end
    [~,shortIndex]=min(wavelength);[~,longIndex]=max(wavelength);
    empty=struct('Index',NaN,'PeakID','','Pixel',NaN,'Wavelength',NaN,'Influence',NaN,'Rank',NaN, ...
        'Percentile',NaN,'CurveChange',NaN,'Residual',NaN,'Quality',NaN,'LocalSpacing',NaN, ...
        'Boundary','','Class','','Recommendation','');samples=repmat(empty,n,1);
    for k=1:n
        boundary='Interior';if k==shortIndex,boundary='Short';elseif k==longIndex,boundary='Long';end
        samples(k)=struct('Index',k,'PeakID',peakIDs{k},'Pixel',pixel(k),'Wavelength',wavelength(k), ...
            'Influence',influence(k),'Rank',rank(k),'Percentile',percentile(k),'CurveChange',points(k).CurveChange, ...
            'Residual',points(k).Residual,'Quality',quality(k),'LocalSpacing',spacing(k),'Boundary',boundary, ...
            'Class',points(k).Class,'Recommendation',points(k).Recommendation);
    end
    profile=struct('Degree',degree,'FullModel',analysis.FullModel,'Samples',samples,'OrderByInfluence',order(:).');
end
