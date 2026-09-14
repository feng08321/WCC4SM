classdef TestWindowPartition < matlab.unittest.TestCase
    methods (Test)
        function equalWidthUsesLeftClosedRightOpenIntervals(testCase)
            wl=(0:4).';infl=ones(5,1);ids=arrayfun(@(k)sprintf('P%d',k),(1:5).','UniformOutput',false);
            r=wc4sm_partition_subset_windows(wl,infl,2,'Equal wavelength width',ids);
            testCase.verifyEqual(r.Boundaries,2,'AbsTol',0);
            testCase.verifyEqual(r.SortedWindowIndex,[1;1;2;2;2]);
            testCase.verifyEqual([r.Windows.NumberOfSamples],[2 3]);
        end

        function equalInfluenceBalancesDiscreteWeights(testCase)
            wl=(1:6).';r=wc4sm_partition_subset_windows(wl,ones(6,1),3,'Equal cumulative influence');
            testCase.verifyEqual(r.CutIndices,[2 4]);
            testCase.verifyEqual([r.Windows.NumberOfSamples],[2 2 2]);
            testCase.verifyEqual([r.Windows.ActualWeight],ones(1,3)/3,'AbsTol',1e-12);
            testCase.verifyEqual([r.Windows.DeviationFromTarget],zeros(1,3),'AbsTol',1e-12);
        end

        function detectsDominantInfluenceWithoutSelectingIt(testCase)
            wl=(1:5).';infl=[1;1;10;1;1];
            r=wc4sm_partition_subset_windows(wl,infl,3,'Equal cumulative influence');
            testCase.verifyEqual(numel(r.DominantSamples),1);
            testCase.verifyEqual(r.DominantSamples.PeakID,'P003');
            testCase.verifyGreaterThan(r.DominantSamples.NormalizedInfluence,1/3);
            testCase.verifyTrue(all([r.Windows.NumberOfSamples]>=1));
            testCase.verifyEqual(sum(r.SortedWindowIndex>0),5);
        end

        function retainsEmptyEqualWidthWindows(testCase)
            wl=[0;.1;.2;10];r=wc4sm_partition_subset_windows(wl,ones(4,1),3,'Equal wavelength width');
            testCase.verifyTrue(any([r.Windows.NumberOfSamples]==0));
            testCase.verifyTrue(any(contains(string(r.Warnings),'empty equal-width')));
        end

        function rejectsZeroInfluenceForWeightedPartition(testCase)
            testCase.verifyError(@()wc4sm_partition_subset_windows((1:5).',zeros(5,1),3, ...
                'Equal cumulative influence'),'WCC4SM:WindowPartitionZeroInfluence');
        end

        function isDeterministicWithUnsortedInput(testCase)
            wl=[5;1;4;2;3];infl=[1;2;3;4;5];ids={'E';'A';'D';'B';'C'};
            a=wc4sm_partition_subset_windows(wl,infl,3,'Equal cumulative influence',ids);
            b=wc4sm_partition_subset_windows(wl,infl,3,'Equal cumulative influence',ids);
            testCase.verifyEqual(a.CutIndices,b.CutIndices);
            testCase.verifyEqual(a.SampleWindowIndex,b.SampleWindowIndex);
            testCase.verifyEqual(a.SortedPeakIDs,{'A','B','C','D','E'});
        end
    end
end
