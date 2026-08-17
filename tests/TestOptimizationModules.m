classdef TestOptimizationModules < matlab.unittest.TestCase
    methods (Test)
        function minimumSizeFitReportsLooUnavailable(testCase)
            p=(1:4).'; w=300+0.4*p+0.001*p.^2;
            m=wc4sm_fit_calibration(p,w,3,p);
            testCase.verifyEqual(m.LOOStatus,'Unavailable: minimum-size model');
            testCase.verifyTrue(isnan(m.LOORMS));
        end
        function modelOrderScanReturnsAllOrders(testCase)
            p=(1:10).'; w=300+0.4*p+0.001*p.^2;
            r=wc4sm_analyze_model_order(p,w,1:4,p);
            testCase.verifyEqual([r.Degree],[1 2 3 4]);
            testCase.verifyEqual(numel(r),4);
            testCase.verifyEqual(r(4).Status,'Fit available');
        end
        function addOneReportsCandidateGain(testCase)
            p=(1:8).'; w=300+0.4*p+0.001*p.^2;
            cal=false(8,1);cal([1 4 8])=true;candidate=~cal;
            r=wc4sm_analyze_add_one(p,w,cal,candidate,2,p);
            testCase.verifyEqual(numel(r),5);
            testCase.verifyTrue(all(strcmp({r.Status},'Available')));
            testCase.verifyTrue(all(isfinite([r.ValidationRMSE])));
        end
    end
end
