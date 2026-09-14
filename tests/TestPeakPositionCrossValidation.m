classdef TestPeakPositionCrossValidation < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addProjectSourceFolder(testCase)
            % Resolve src from this test file so the test is independent of
            % MATLAB's current folder and of any older WCC4SM copy on path.
            projectRoot=fileparts(fileparts(mfilename('fullpath')));
            sourceFolder=fullfile(projectRoot,'src');
            previousPath=path;
            testCase.addTeardown(@()path(previousPath));
            addpath(sourceFolder,'-begin');
            rehash path;
        end
    end

    methods (Test)
        function diagonalFitIsExactAndMismatchIsVisible(testCase)
            x=linspace(10,100,24).';w=250+0.45*x+2e-4*x.^2;
            % Every synthetic position definition is an affine transform of
            % x, so a quadratic calibration can reproduce its own definition
            % exactly. Cross-definition application still exposes mismatch.
            positions=[x x+0.20 x-0.15 x+0.05];
            names={'Direct peak','Interpolated peak','FWHM center','Centroid'};
            r=wc4sm_cross_validate_peak_positions(positions,w,names,2,struct('ValidationMode','Full fit','PoolMode','Common intersection'));
            testCase.verifyLessThan(max(abs(diag(r.RMSE))),1e-9);
            testCase.verifyGreaterThan(r.RMSE(1,2),1e-3);
            testCase.verifyEqual(size(r.Cells),[4 4]);
            testCase.verifyEqual(r.Cells(1,2).TrainMethod,'Direct peak');
            testCase.verifyEqual(r.Cells(1,2).ApplicationMethod,'Interpolated peak');
            testCase.verifyEqual(r.CalibrationFitCount,4);
            testCase.verifyGreaterThanOrEqual(r.ElapsedSeconds,0);
        end

        function looAndCommonIntersectionAreSupported(testCase)
            x=linspace(1,20,20).';w=300+0.7*x-0.002*x.^2;
            positions=[x x+0.1 x-0.1 x+0.02];positions(4,4)=NaN;
            names={'Direct peak','Interpolated peak','FWHM center','Centroid'};
            r=wc4sm_cross_validate_peak_positions(positions,w,names,2,struct('ValidationMode','LOO','PoolMode','Common intersection'));
            testCase.verifyEqual(r.CommonN,19);
            testCase.verifyEqual(r.N,19*ones(4));
            testCase.verifyLessThan(max(abs(diag(r.RMSE))),1e-9);
            testCase.verifyEqual(r.CalibrationFitCount,4*19);
        end

        function pairwisePoolRetainsAvailableTrainingData(testCase)
            x=(1:12).';w=500+2*x;positions=[x x+0.1];positions(1:2,2)=NaN;
            r=wc4sm_cross_validate_peak_positions(positions,w,{'A','B'},1,struct('PoolMode','Pairwise available'));
            testCase.verifyEqual(r.Cells(1,2).NTrain,12);
            testCase.verifyEqual(r.Cells(1,2).N,10);
            testCase.verifyEqual(r.Cells(2,1).NTrain,10);
            testCase.verifyEqual(r.CalibrationFitCount,2);
        end

        function subsetTrainingCanBeEvaluatedOnFullPool(testCase)
            x=(1:12).';w=410+0.8*x+0.003*x.^2;
            positions=[x x+0.1 x-0.2 x+0.03];
            trainMask=false(12,1);trainMask([1 3 5 8 10 12])=true;
            options=struct('ValidationMode','Full fit','PoolMode','Common intersection', ...
                'TrainingMask',trainMask,'EvaluationMask',true(12,1), ...
                'TrainingSetLabel','Six-point set','EvaluationSetLabel','All twelve');
            r=wc4sm_cross_validate_peak_positions(positions,w,{'A','B','C','D'},2,options);
            testCase.verifyEqual(r.NTrain,6*ones(4));
            testCase.verifyEqual(r.N,12*ones(4));
            testCase.verifyEqual(r.TrainingSelectionN,6);
            testCase.verifyEqual(r.EvaluationSelectionN,12);
            testCase.verifyEqual(r.TrainingSetLabel,'Six-point set');
            testCase.verifyLessThan(max(abs(diag(r.RMSE))),1e-9);
        end

        function subsetLooUsesHeldOutTrainingPoints(testCase)
            x=(1:12).';w=410+0.8*x+0.003*x.^2;
            positions=[x x+0.1 x-0.2 x+0.03];trainMask=false(12,1);trainMask(1:6)=true;
            options=struct('ValidationMode','LOO','PoolMode','Common intersection', ...
                'TrainingMask',trainMask,'EvaluationMask',true(12,1));
            r=wc4sm_cross_validate_peak_positions(positions,w,{'A','B','C','D'},2,options);
            testCase.verifyEqual(r.NTrain,6*ones(4));
            testCase.verifyEqual(r.N,6*ones(4));
            testCase.verifyEqual(r.CalibrationFitCount,4*6);
        end

        function fullFitAllowsDegreeFiveFromSixPoints(testCase)
            x=(1:10).';w=polyval([1e-6 -2e-5 3e-4 -0.002 0.7 300],x);
            mask=false(10,1);mask(1:6)=true;
            r=wc4sm_cross_validate_peak_positions(x,w,{'A'},5, ...
                struct('ValidationMode','Full fit','TrainingMask',mask));
            testCase.verifyEqual(r.Cells.NTrain,6);
            testCase.verifyEqual(r.Cells.N,10);
            testCase.verifyEqual(r.Cells.Status,'Available');
        end
    end
end
