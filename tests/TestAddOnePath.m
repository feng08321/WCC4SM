classdef TestAddOnePath < matlab.unittest.TestCase
    methods (Test)
        function buildsSequentialHistory(testCase)
            p=(1:10).'; w=300+0.4*p+0.001*p.^2;
            seed=false(10,1);seed([1 5 10])=true;
            r=wc4sm_analyze_add_one_path(p,w,seed,2,p);
            testCase.verifyEqual(numel(r.History),6);
            testCase.verifyEqual(sum(r.SelectedMask),9);
            testCase.verifyEqual(r.History(1).Ncal,4);
            testCase.verifyTrue(all(isfinite([r.History.FitRMSE])));
            testCase.verifyTrue(all(isfinite([r.History.ValidationRMSE])));
            testCase.verifyEqual(numel(r.History(1).Residual),numel(r.History(1).EvaluationPixels));
            testCase.verifyTrue(isnan(r.FullSetRMSEGap));
        end
        function fixedAllPointValidationIsReported(testCase)
            p=(1:10).';w=300+0.4*p+0.001*p.^2;seed=false(10,1);seed([1 5 10])=true;
            r=wc4sm_analyze_add_one_path(p,w,seed,2,p,struct('ValidationMode','All points','StopWhenCandidates',1));
            testCase.verifyEqual(r.ValidationMode,'All points');testCase.verifyTrue(all(isfinite([r.History.ValidationRMSE])));
            testCase.verifyTrue(isnan(r.FullSetRMSEGap));
        end
        function fullSetFitAndValidationRMSEAgree(testCase)
            p=(1:10).';w=300+0.4*p+0.001*p.^2;seed=false(10,1);seed([1 5 10])=true;
            r=wc4sm_analyze_add_one_path(p,w,seed,2,p,struct('ValidationMode','All points','StopWhenCandidates',0));
            testCase.verifyEqual(sum(r.SelectedMask),10);
            testCase.verifyEqual(r.History(end).Ncal,10);
            testCase.verifyLessThanOrEqual(r.FullSetRMSEGap,1e-12);
        end
    end
end
