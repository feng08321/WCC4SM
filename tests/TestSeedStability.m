classdef TestSeedStability < matlab.unittest.TestCase
    methods (Test)
        function comparesMultipleSeedSets(testCase)
            p=(1:12).'; w=300+0.4*p+0.001*p.^2;
            seeds=false(12,2);seeds([1 5 12],1)=true;seeds([1 7 12],2)=true;
            r=wc4sm_analyze_seed_stability(p,w,seeds,2,p);
            testCase.verifyEqual(numel(r.Paths),2);
            testCase.verifyEqual([r.Summary.SeedCount],[3 3]);
            testCase.verifyTrue(all(isfinite([r.Summary.FinalValidationRMSE])));
        end
    end
end
