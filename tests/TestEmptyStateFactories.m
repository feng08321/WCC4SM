classdef TestEmptyStateFactories < matlab.unittest.TestCase
    % Verify the shared empty-state factories extracted from the GUI file.
    % These structures are the single source of truth for state layout and
    % must remain stable because sessions, the GUI and (later) the Python
    % port all depend on their exact field sets.

    methods (Test)
        function emptyDataFields(testCase)
            D = wc4sm_empty_data();
            testCase.verifyEqual(fieldnames(D),{'raw';'dark';'darkSource'; ...
                'corrected';'normalized';'pixel';'inputX';'inputWavelength'; ...
                'calibratedWavelength';'xKind';'source';'PixelCoordinateMode'; ...
                'PixelFirst';'PixelLast'});
            testCase.verifyTrue(isempty(D.raw));
            testCase.verifyEqual(D.xKind,'Pixel');
            testCase.verifyTrue(isnan(D.PixelFirst));
            testCase.verifyTrue(isnan(D.PixelLast));
        end

        function emptyReferenceFields(testCase)
            R = wc4sm_empty_reference();
            testCase.verifyEqual(fieldnames(R),{'x';'y';'source';'loaded'});
            testCase.verifyFalse(R.loaded);
        end

        function emptyLineLibraryFields(testCase)
            L = wc4sm_empty_line_library();
            testCase.verifyEqual(fieldnames(L),{'wavelength';'intensity'; ...
                'order';'effective';'enabled';'source';'loaded'});
            testCase.verifyFalse(L.loaded);
            testCase.verifyTrue(isempty(L.wavelength));
        end

        function emptyPeaksIsEmptyStructArray(testCase)
            p = wc4sm_empty_peaks();
            testCase.verifyEqual(fieldnames(p),{'ID';'Index';'Pixel'; ...
                'InputX';'Height';'Prominence';'Width';'Status';'Result'});
            testCase.verifyTrue(isempty(p));
            testCase.verifyEqual(size(p),[0 0]);
        end

        function emptyLocalCandidatesFields(testCase)
            p = wc4sm_empty_local_candidates();
            testCase.verifyEqual(fieldnames(p),{'Index';'Pixel';'InputX'; ...
                'Height';'Prominence';'Width'});
            testCase.verifyTrue(isempty(p));
        end

        function emptyPeakDatasetFields(testCase)
            d = wc4sm_empty_peak_dataset();
            testCase.verifyEqual(fieldnames(d),{'PeakID';'PeakIndex'; ...
                'Pixel';'InputX';'ReferenceWavelength';'Source'; ...
                'WindowPixel';'WindowADCounts';'WindowCorrected'; ...
                'AnalysisResult';'FindPeakHeight';'FindPeakProminence'; ...
                'FindPeakWidth';'Status';'Confirmed';'ConfirmedAt'; ...
                'ConfirmedSettings'});
            testCase.verifyTrue(isempty(d));
        end

        function emptyCalibrationPairsFields(testCase)
            p = wc4sm_empty_calibration_pairs();
            testCase.verifyEqual(fieldnames(p),{'PeakID';'PeakIndex'; ...
                'DetectionPixel';'ReferenceIndex';'ReferenceWavelength'; ...
                'Order';'Mode';'Confidence';'Locked';'Status'});
            testCase.verifyTrue(isempty(p));
        end

        function makeCalibrationPairDefaults(testCase)
            q = wc4sm_make_calibration_pair('P1',3,512.5,7,546.07,1,'Auto',false,'Confirmed');
            testCase.verifyEqual(q.PeakID,'P1');
            testCase.verifyEqual(q.DetectionPixel,512.5);
            testCase.verifyEqual(q.ReferenceWavelength,546.07);
            testCase.verifyTrue(isnan(q.Confidence));
            testCase.verifyFalse(q.Locked);
            testCase.verifyEqual(q.Status,'Confirmed');
        end

        function emptyMappingCandidatesFields(testCase)
            m = wc4sm_empty_mapping_candidates();
            testCase.verifyEqual(fieldnames(m),{'a';'b';'RMS'; ...
                'ReferenceIndices';'ReferenceWavelengths'});
            testCase.verifyTrue(isempty(m));
        end

        function emptyInitialModelDefaults(testCase)
            m = wc4sm_empty_initial_model();
            testCase.verifyEqual(fieldnames(m),{'valid';'Degree'; ...
                'Coefficients';'Mu';'a';'b'});
            testCase.verifyFalse(m.valid);
            testCase.verifyEqual(m.Degree,0);
            testCase.verifyEqual(m.Mu,[0 1]);
        end

        function emptyFinalModelDefaults(testCase)
            f = wc4sm_empty_final_model();
            testCase.verifyEqual(fieldnames(f),{'valid';'PositionMethod'; ...
                'Degree';'Coefficients';'Mu';'S';'NaturalCoefficients'; ...
                'Equation';'PeakID';'Pixel';'ReferenceWavelength'; ...
                'FittedWavelength';'Residual';'MeanResidual';'STD';'RMS'; ...
                'MaxAbsResidual';'LOOResidual';'DeletionMaxCurveChange'; ...
                'LOORMS';'LOOMaxAbs';'MaxDeletionInfluence'});
            testCase.verifyFalse(f.valid);
            testCase.verifyTrue(isnan(f.STD));
            testCase.verifyTrue(isempty(f.PeakID));
        end

        function emptyCalibrationModelsFields(testCase)
            m = wc4sm_empty_calibration_models();
            testCase.verifyEqual(fieldnames(m),{'ModelID';'CreatedAt'; ...
                'PairCount';'PositionMethod';'Degree';'PairIDs';'Model'; ...
                'Visible'});
            testCase.verifyTrue(isempty(m));
        end
    end
end
