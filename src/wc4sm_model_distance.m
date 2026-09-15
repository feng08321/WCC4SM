function distance = wc4sm_model_distance(modelA,modelB,evaluationPixels)
%WC4SM_MODEL_DISTANCE Compare two calibration mappings on a common grid.
    if nargin<3||isempty(evaluationPixels)
        values=[];
        if isfield(modelA,'Pixel'),values=[values;modelA.Pixel(:)];end
        if isfield(modelB,'Pixel'),values=[values;modelB.Pixel(:)];end
        if isempty(values),error('WCC4SM:ModelDistanceNoGrid','A common evaluation grid is required.');end
        evaluationPixels=linspace(min(values),max(values),200).';
    else
        evaluationPixels=evaluationPixels(:);
    end
    if any(~isfinite(evaluationPixels))||isempty(evaluationPixels)
        error('WCC4SM:ModelDistanceInvalidGrid','Evaluation pixels must be finite and non-empty.');
    end
    validateModel(modelA,'A');validateModel(modelB,'B');
    curveA=polyval(modelA.Coefficients,evaluationPixels,[],modelA.Mu);
    curveB=polyval(modelB.Coefficients,evaluationPixels,[],modelB.Mu);
    delta=curveA-curveB;
    distance=struct('RMS',sqrt(mean(delta.^2)),'MAX',max(abs(delta)), ...
        'EvaluationPixels',evaluationPixels,'Delta',delta,'CurveA',curveA,'CurveB',curveB);
end

function validateModel(model,label)
    if ~isstruct(model)||~isfield(model,'Coefficients')||~isfield(model,'Mu')|| ...
            isempty(model.Coefficients)||numel(model.Mu)~=2
        error('WCC4SM:ModelDistanceInvalidModel','Model %s is not a valid polynomial calibration model.',label);
    end
end
