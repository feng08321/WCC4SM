function files = wc4sm_export_optimization_csv(orderResult,pathResult,outputFolder)
%WC4SM_EXPORT_OPTIMIZATION_CSV Export optimization histories for review.
    if nargin<3||isempty(outputFolder),outputFolder=pwd;end
    if ~isfolder(outputFolder),mkdir(outputFolder);end
    files=struct('ModelOrder','','AddOneHistory','');
    if ~isempty(orderResult)
        n=numel(orderResult); degree=zeros(n,1); fitRMSE=zeros(n,1); looRMSE=zeros(n,1);
        fitMAX=zeros(n,1); looMAX=zeros(n,1); status=strings(n,1);
        for k=1:n
            degree(k)=orderResult(k).Degree;fitRMSE(k)=orderResult(k).FitRMSE;
            looRMSE(k)=orderResult(k).LOORMSE;fitMAX(k)=orderResult(k).FitMAX;
            looMAX(k)=orderResult(k).LOOMAX;status(k)=string(orderResult(k).Status);
        end
        t=table(degree,fitRMSE,looRMSE,fitMAX,looMAX,status, ...
            'VariableNames',{'Degree','FitRMSE','LOORMSE','FitMAX','LOOMAX','Status'});
        files.ModelOrder=fullfile(outputFolder,'model_order_results.csv');writetable(t,files.ModelOrder);
    end
    if nargin>=2&&~isempty(pathResult)&&~isempty(pathResult.History)
        h=pathResult.History;
        t=table([h.Round].',[h.Ncal].',[h.SelectedIndex].', ...
            [h.FitRMSE].',[h.ValidationRMSE].',[h.ValidationP95].',[h.ValidationMAX].', ...
            [h.CandidateCount].',string({h.Status}.'), ...
            'VariableNames',{'Round','Ncal','SelectedIndex','FitRMSE','ValidationRMSE', ...
            'ValidationP95','ValidationMAX','CandidateCount','Status'});
        files.AddOneHistory=fullfile(outputFolder,'add_one_history.csv');writetable(t,files.AddOneHistory);
    end
end
