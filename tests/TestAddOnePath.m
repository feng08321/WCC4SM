classdef TestAddOnePath < matlab.unittest.TestCase
    methods (Test)
        function buildsSequentialHistory(testCase)
            p=(1:10).'; w=300+0.4*p+0.001*p.^2;
            seed=false(10,1);seed([1 5 10])=true;
            r=wc4sm_analyze_add_one_path(p,w,seed,2,p);
        %    testCase.verifyEqual(numel(r.History),7);
        %    testCase.verifyEqual(sum(r.SelectedMask),10);

            testCase.verifyEqual(numel(r.History),6);
            testCase.verifyEqual(sum(r.SelectedMask),9);

            testCase.verifyEqual(r.History(1).Ncal,4);
            testCase.verifyTrue(all(isfinite([r.History.ValidationRMSE])));
        end
    end
end
