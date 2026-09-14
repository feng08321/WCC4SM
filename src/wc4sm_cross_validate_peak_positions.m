function result = wc4sm_cross_validate_peak_positions(positionMatrix,wavelength,methodNames,degree,options)
%WC4SM_CROSS_VALIDATE_PEAK_POSITIONS Quantify calibration/application position mismatch.
% Rows are matched spectral lines. Columns are alternative peak-position
% definitions. Cell (a,b) fits wavelength from method a and evaluates the
% resulting calibration with positions from method b.

    if nargin<5||isempty(options),options=struct();end
    if ~isfield(options,'ValidationMode')||isempty(options.ValidationMode),options.ValidationMode='Full fit';end
    if ~isfield(options,'PoolMode')||isempty(options.PoolMode),options.PoolMode='Common intersection';end
    if ~isfield(options,'TrainingSetLabel')||isempty(options.TrainingSetLabel),options.TrainingSetLabel='All matched pairs';end
    if ~isfield(options,'EvaluationSetLabel')||isempty(options.EvaluationSetLabel),options.EvaluationSetLabel='All matched pairs';end
    validationMode=char(string(options.ValidationMode));
    poolMode=char(string(options.PoolMode));
    x=double(positionMatrix);w=double(wavelength(:));names=cellstr(string(methodNames(:)));
    degree=round(double(degree));
    if size(x,1)~=numel(w),error('WCC4SM:CrossPositionSizeMismatch','Position rows must match wavelength values.');end
    if size(x,2)~=numel(names),error('WCC4SM:CrossPositionMethodMismatch','Method names must match position columns.');end
    if degree<1,error('WCC4SM:CrossPositionInvalidDegree','Polynomial degree must be at least one.');end
    if ~any(strcmpi(validationMode,{'Full fit','LOO'})),error('WCC4SM:CrossPositionInvalidValidationMode','ValidationMode must be Full fit or LOO.');end
    if ~any(strcmpi(poolMode,{'Common intersection','Pairwise available'})),error('WCC4SM:CrossPositionInvalidPoolMode','PoolMode must be Common intersection or Pairwise available.');end

    trainingSelection=selectionMask(options,'TrainingMask',numel(w));
    evaluationSelection=selectionMask(options,'EvaluationMask',numel(w));
    minimumTrainCount=degree+1+strcmpi(validationMode,'LOO');

    calculationTimer=tic;
    calibrationFitCount=0;
    methodCount=size(x,2);
    emptyCell=struct('TrainMethod','','ApplicationMethod','','ValidationMode',validationMode, ...
        'PoolMode',poolMode,'Degree',degree,'NTrain',0,'N',0,'ValidIndex',[], ...
        'Wavelength',[],'TrainPosition',[],'ApplicationPosition',[],'Residual',[], ...
        'Bias',NaN,'RMSE',NaN,'STD',NaN,'P95',NaN,'MAX',NaN,'Slope',NaN,'Status','Unavailable');
    cells=repmat(emptyCell,methodCount,methodCount);
    commonFiniteMask=isfinite(w)&all(isfinite(x),2);
    commonTrainMask=trainingSelection&commonFiniteMask;
    commonEvalMask=evaluationSelection&commonFiniteMask;
    for a=1:methodCount
        if strcmpi(poolMode,'Common intersection')
            trainMask=commonTrainMask;
        else
            trainMask=trainingSelection&isfinite(w)&isfinite(x(:,a));
        end
        nTrain=sum(trainMask);
        predicted=nan(size(x));
        if nTrain>=minimumTrainCount
            if strcmpi(validationMode,'Full fit')
                [coef,~,mu]=polyfit(x(trainMask,a),w(trainMask),degree);
                calibrationFitCount=calibrationFitCount+1;
                for b=1:methodCount
                    predicted(:,b)=polyval(coef,x(:,b),[],mu);
                end
            else
                trainIndex=find(trainMask);
                for k=1:numel(trainIndex)
                    i=trainIndex(k);foldMask=trainMask;foldMask(i)=false;
                    if sum(foldMask)<degree+1,continue;end
                    [coef,~,mu]=polyfit(x(foldMask,a),w(foldMask),degree);
                    calibrationFitCount=calibrationFitCount+1;
                    predicted(i,:)=polyval(coef,x(i,:),[],mu);
                end
            end
        end
        for b=1:methodCount
            cellResult=emptyCell;cellResult.TrainMethod=names{a};cellResult.ApplicationMethod=names{b};
            if strcmpi(poolMode,'Common intersection')
                evalMask=commonEvalMask;
            else
                evalMask=evaluationSelection&isfinite(w)&isfinite(x(:,a))&isfinite(x(:,b));
            end
            if strcmpi(validationMode,'LOO'),evalMask=evalMask&trainMask;end
            cellResult.NTrain=nTrain;evalIndex=find(evalMask);cellResult.N=numel(evalIndex);
            if nTrain<minimumTrainCount||cellResult.N<1
                cellResult.Status='Insufficient points';cells(a,b)=cellResult;continue;
            end
            residual=w(evalIndex)-predicted(evalIndex,b);
            good=isfinite(residual);evalIndex=evalIndex(good);residual=residual(good);
            if isempty(residual),cellResult.Status='No finite residuals';cells(a,b)=cellResult;continue;end
            cellResult.N=numel(residual);cellResult.ValidIndex=evalIndex;
            cellResult.Wavelength=w(evalIndex);cellResult.TrainPosition=x(evalIndex,a);
            cellResult.ApplicationPosition=x(evalIndex,b);cellResult.Residual=residual;
            cellResult.Bias=mean(residual);cellResult.RMSE=sqrt(mean(residual.^2));
            cellResult.STD=std(residual,1);cellResult.P95=percentile95(abs(residual));
            cellResult.MAX=max(abs(residual));
            if numel(residual)>=2&&(max(w(evalIndex))-min(w(evalIndex)))>0
                slopeFit=polyfit(w(evalIndex),residual,1);cellResult.Slope=slopeFit(1);
            end
            cellResult.Status='Available';cells(a,b)=cellResult;
        end
    end
    result=struct('Methods',{names},'Degree',degree,'ValidationMode',validationMode, ...
        'PoolMode',poolMode,'TrainingSetLabel',char(string(options.TrainingSetLabel)), ...
        'EvaluationSetLabel',char(string(options.EvaluationSetLabel)), ...
        'TrainingSelectionN',sum(trainingSelection),'EvaluationSelectionN',sum(evaluationSelection), ...
        'CommonTrainN',sum(commonTrainMask),'CommonN',sum(commonEvalMask),'Cells',cells, ...
        'Bias',metricMatrix(cells,'Bias'),'RMSE',metricMatrix(cells,'RMSE'), ...
        'STD',metricMatrix(cells,'STD'),'P95',metricMatrix(cells,'P95'), ...
        'MAX',metricMatrix(cells,'MAX'),'Slope',metricMatrix(cells,'Slope'), ...
        'NTrain',metricMatrix(cells,'NTrain'),'N',metricMatrix(cells,'N'),'CalibrationFitCount',calibrationFitCount, ...
        'ElapsedSeconds',toc(calculationTimer));
end

function mask=selectionMask(options,fieldName,n)
    if ~isfield(options,fieldName)||isempty(options.(fieldName))
        mask=true(n,1);return;
    end
    value=options.(fieldName);
    if ~(islogical(value)||isnumeric(value))||numel(value)~=n
        error('WCC4SM:CrossPositionSelectionSizeMismatch','%s must contain one logical value per input row.',fieldName);
    end
    mask=logical(value(:));
end

function values=metricMatrix(cells,fieldName)
    values=nan(size(cells));
    for i=1:numel(cells),values(i)=cells(i).(fieldName);end
end

function q=percentile95(values)
    values=sort(values(isfinite(values)));n=numel(values);
    if n==0,q=NaN;return;end
    p=1+0.95*(n-1);lo=floor(p);hi=ceil(p);
    if lo==hi,q=values(lo);else,q=values(lo)+(p-lo)*(values(hi)-values(lo));end
end
