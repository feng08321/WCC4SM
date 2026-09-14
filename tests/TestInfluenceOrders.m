classdef TestInfluenceOrders < matlab.unittest.TestCase
    methods (Test)
        function summarizesRequestedDegrees(testCase)
            p=(1:20).';w=300+0.4*p+0.002*p.^2+0.01*sin(p);
            r=wc4sm_analyze_influence_orders(p,w,1:5);
            testCase.verifyEqual([r.Degree],1:5);
            testCase.verifyTrue(all(strcmp({r.Status},'Available')));
            testCase.verifyTrue(all(isfinite([r.MeanInfluence])));
            testCase.verifyTrue(all(isfinite([r.RMSInfluence])));
            testCase.verifyTrue(all([r.MAXInfluence]>=[r.P95Influence]));
            testCase.verifyTrue(all([r.RMSInfluence]>=0));
            testCase.verifyTrue(all(isfinite([r.FullFitRMSE])));
            testCase.verifyTrue(all(isfinite([r.FullLOORMSE])));
            testCase.verifyTrue(all(isfinite([r.DeletionFitRMSE])));
            testCase.verifyTrue(all(isfinite([r.DeletionLOORMSE])));
            testCase.verifyTrue(all(isfinite([r.FullGeneralizationGap])));
            testCase.verifyTrue(all(isfinite([r.DeletionGeneralizationGap])));
            testCase.verifyTrue(all(arrayfun(@(x)all(isfinite([x.Result.Points.DeletedLOORMSE])),r)));
            for k=1:numel(r)
                expectedFit=sqrt(mean([r(k).Result.Points.DeletedRMS].^2));
                expectedLOO=sqrt(mean([r(k).Result.Points.DeletedLOORMSE].^2));
                testCase.verifyEqual(r(k).DeletionFitRMSE,expectedFit,'AbsTol',1e-12);
                testCase.verifyEqual(r(k).DeletionLOORMSE,expectedLOO,'AbsTol',1e-12);
                testCase.verifyEqual(r(k).FullGeneralizationGap,r(k).FullLOORMSE-r(k).FullFitRMSE,'AbsTol',1e-12);
                testCase.verifyEqual(r(k).DeletionGeneralizationGap,r(k).DeletionLOORMSE-r(k).DeletionFitRMSE,'AbsTol',1e-12);
            end
            order=wc4sm_analyze_model_order(p,w,1:5,p);
            testCase.verifyEqual([r.FullFitRMSE],[order.FitRMSE],'AbsTol',1e-12);
            testCase.verifyEqual([r.FullLOORMSE],[order.LOORMSE],'AbsTol',1e-12);
        end

        function marksUnsupportedDegree(testCase)
            p=(1:6).';w=300+0.4*p;
            r=wc4sm_analyze_influence_orders(p,w,[3 5]);
            testCase.verifyEqual(r(1).Status,'Available');
            testCase.verifyEqual(r(2).Status,'Insufficient points');
        end

        function marksDegreeAboveUnifiedLimit(testCase)
            p=(1:25).';w=300+0.4*p;
            r=wc4sm_analyze_influence_orders(p,w,21);
            testCase.verifyEqual(r.Status,'Degree exceeds supported limit 20');
        end

        function requiresNestedLooAfterDeletion(testCase)
            p=(1:6).';w=300+0.4*p+0.001*p.^2;
            testCase.verifyError(@()wc4sm_analyze_point_influence(p,w,4), ...
                'WCC4SM:InfluenceInsufficientPoints');
        end
    end
end
