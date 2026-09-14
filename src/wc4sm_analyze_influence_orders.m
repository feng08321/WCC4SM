function result = wc4sm_analyze_influence_orders(pixel,wavelength,degreeRange,options)
%WC4SM_ANALYZE_INFLUENCE_ORDERS Summarize deletion influence by model order.
% Influence statistics are calculated from the point InfluenceRatio values
% returned by WC4SM_ANALYZE_POINT_INFLUENCE for each available degree.
% DeletionFitRMSE and DeletionLOORMSE are pooled RMS summaries across all
% one-point-deleted models at the same degree; both retain wavelength units.
% FullGeneralizationGap and DeletionGeneralizationGap are the corresponding
% signed LOO-minus-Fit RMSE differences. Positive growth indicates widening
% separation between validation and fitted-sample errors.
    if nargin<3||isempty(degreeRange),degreeRange=1:10;end
    if nargin<4||isempty(options),options=struct;end
    pixel=pixel(:);wavelength=wavelength(:);degreeRange=degreeRange(:).';
    if numel(pixel)~=numel(wavelength)
        error('WCC4SM:InfluenceOrderSizeMismatch','Pixel and wavelength vectors must have equal length.');
    end
    if any(~isfinite(pixel))||any(~isfinite(wavelength))
        error('WCC4SM:InfluenceOrderInvalidData','Pixel and wavelength values must be finite.');
    end
    empty=struct('Degree',NaN,'FullFitRMSE',NaN,'FullLOORMSE',NaN, ...
        'DeletionFitRMSE',NaN,'DeletionLOORMSE',NaN, ...
        'FullGeneralizationGap',NaN,'DeletionGeneralizationGap',NaN, ...
        'MeanInfluence',NaN,'RMSInfluence',NaN, ...
        'P95Influence',NaN,'MAXInfluence',NaN,'Status','','Result',[]);
    result=repmat(empty,numel(degreeRange),1);
    for k=1:numel(degreeRange)
        d=degreeRange(k);result(k).Degree=d;
        if ~isscalar(d)||~isfinite(d)||d<1||d~=fix(d)
            result(k).Status='Invalid degree';continue;
        end
        if d>20
            result(k).Status='Degree exceeds supported limit 20';continue;
        end
        if numel(pixel)<d+3
            result(k).Status='Insufficient points';continue;
        end
        try
            detail=wc4sm_analyze_point_influence(pixel,wavelength,d,options);
            v=[detail.Points.InfluenceRatio];v=v(isfinite(v));
            if isempty(v),result(k).Status='No finite influence values';continue;end
            deletedFit=[detail.Points.DeletedRMS];deletedFit=deletedFit(isfinite(deletedFit));
            deletedLOO=[detail.Points.DeletedLOORMSE];deletedLOO=deletedLOO(isfinite(deletedLOO));
            result(k).FullFitRMSE=detail.FullModel.RMS;
            result(k).FullLOORMSE=detail.FullModel.LOORMS;
            result(k).DeletionFitRMSE=sqrt(mean(deletedFit.^2));
            result(k).DeletionLOORMSE=sqrt(mean(deletedLOO.^2));
            result(k).FullGeneralizationGap=result(k).FullLOORMSE-result(k).FullFitRMSE;
            result(k).DeletionGeneralizationGap=result(k).DeletionLOORMSE-result(k).DeletionFitRMSE;
            result(k).MeanInfluence=mean(v);
            result(k).RMSInfluence=sqrt(mean(v.^2));
            result(k).P95Influence=percentile95(v);
            result(k).MAXInfluence=max(v);
            result(k).Status='Available';result(k).Result=detail;
        catch ME
            result(k).Status=['Failed: ' ME.identifier];
        end
    end
end

function q=percentile95(x)
    x=sort(x(isfinite(x)));
    if isempty(x),q=NaN;return;end
    q=x(max(1,min(numel(x),ceil(0.95*numel(x)))));
end
