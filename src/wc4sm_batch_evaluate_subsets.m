function result = wc4sm_batch_evaluate_subsets(pixel,wavelength,subsetMasks,degree,evaluationPixels,options)
%WC4SM_BATCH_EVALUATE_SUBSETS Evaluate multiple subsets on one fixed pool.
    if nargin<5||isempty(evaluationPixels),evaluationPixels=linspace(min(pixel),max(pixel),200).';end
    if nargin<6||isempty(options),options=struct;end
    pixel=pixel(:);wavelength=wavelength(:);n=numel(pixel);
    if isvector(subsetMasks),subsetMasks=logical(subsetMasks(:));else,subsetMasks=logical(subsetMasks);end
    if size(subsetMasks,1)~=n,error('WCC4SM:SubsetBatchSizeMismatch','Subset mask rows must match the full pool.');end
    baseline=[];if isfield(options,'BaselineModel'),baseline=options.BaselineModel;end
    if isempty(baseline)
        positionMethod='Unspecified';if isfield(options,'PositionMethod'),positionMethod=options.PositionMethod;end
        ids={};if isfield(options,'PeakIDs'),ids=options.PeakIDs;end
        baseline=wc4sm_fit_calibration(pixel,wavelength,degree,evaluationPixels,positionMethod,ids);
    end
    empty=struct('Key','','SubsetMask',[],'SelectedIndices',[],'SelectedIDs',{{}},'K',NaN,'Degree',degree, ...
        'PositionMethod','','FitRMSE',NaN,'AllRMSE',NaN,'AllP95',NaN,'AllMAX',NaN,'Residual',[], ...
        'AllPixels',[],'AllWavelengths',[],'CoverageMin',NaN,'CoverageMax',NaN,'MaxWavelengthGap',NaN, ...
        'ShortBoundaryIncluded',false,'LongBoundaryIncluded',false,'DistanceRMS',NaN,'DistanceMAX',NaN, ...
        'EvaluationPixels',[],'Curve',[],'BaselineCurve',[],'Model',[],'Status','');
    records=repmat(empty,size(subsetMasks,2),1);
    for k=1:size(subsetMasks,2)
        try
            records(k)=wc4sm_evaluate_subset(pixel,wavelength,subsetMasks(:,k),degree,evaluationPixels,baseline,options);
        catch ME
            records(k).Key=char('0'+subsetMasks(:,k).');records(k).SubsetMask=subsetMasks(:,k);records(k).K=sum(subsetMasks(:,k));records(k).Status=['Failed: ' ME.identifier];
        end
    end
    result=struct('Degree',degree,'Pixel',pixel,'Wavelength',wavelength,'EvaluationPixels',evaluationPixels, ...
        'BaselineModel',baseline,'Records',records);
end
