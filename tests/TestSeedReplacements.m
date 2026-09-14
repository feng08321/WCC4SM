classdef TestSeedReplacements < matlab.unittest.TestCase
    methods (Test)
        function testsEveryOneForOneReplacement(testCase)
            p=(1:10).';w=300+0.4*p+0.001*p.^2;seed=false(10,1);seed([1 3 6 8 10])=true;
            r=wc4sm_analyze_seed_replacements(p,w,seed,3);
            testCase.verifyEqual(r.TotalTrials,25);testCase.verifyEqual(numel(r.BestByRemovedSeed),5);
            testCase.verifyEqual([r.BestByRemovedSeed.RemovedIndex],find(seed).');
            testCase.verifyTrue(all(strcmp({r.Records.Status},'Available')));testCase.verifyTrue(all(isfinite([r.Records.DeltaRMSE])));
        end
        function supportsAllPointValidation(testCase)
            p=(1:10).';w=300+0.4*p+0.001*p.^2;seed=false(10,1);seed([1 3 6 8 10])=true;
            r=wc4sm_analyze_seed_replacements(p,w,seed,3,struct('ValidationMode','All points'));
            testCase.verifyEqual(r.ValidationMode,'All points');testCase.verifyEqual(numel(r.EvaluationIndices),10);
            testCase.verifyTrue(all(isfinite([r.Baseline.Residual])));
        end

        function supportsArbitrarySelectedSetSize(testCase)
            p=(1:12).';w=300+0.4*p+0.001*p.^2;selected=false(12,1);selected([1 2 4 6 8 10 12])=true;
            r=wc4sm_analyze_seed_replacements(p,w,selected,3,struct('ValidationMode','All points'));
            testCase.verifyEqual(r.TotalTrials,35);
            testCase.verifyEqual(numel(r.BestByRemovedPoint),7);
            testCase.verifyEqual(r.SelectedIndices,find(selected).');
            testCase.verifyEqual([r.BestByRemovedPoint.RemovedIndex],find(selected).');
        end

        function rejectsNoFixedValidationPool(testCase)
            p=(1:5).';w=300+p;seed=true(5,1);
            testCase.verifyError(@() wc4sm_analyze_seed_replacements(p,w,seed,3),'WCC4SM:SeedReplacementNoValidationPoints');
        end
    end
end
