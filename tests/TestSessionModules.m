classdef TestSessionModules < matlab.unittest.TestCase
    methods (Test)
        function createsVersionedSessionWithAllSections(testCase)
            session = wc4sm_create_session();
            report = wc4sm_validate_session(session);
            testCase.verifyTrue(report.IsValid);
            testCase.verifyEqual(session.Application,'WCC4SM');
            testCase.verifyEqual(session.FormatVersion,'1.0');
            testCase.verifyTrue(all(isfield(session.State, ...
                {'Spectrum','PeakDataset','CalibrationPairs','FinalCalibration'})));
            testCase.verifyTrue(isfield(session.State,'SetDesign'));
            testCase.verifyTrue(isfield(session.State,'PositionCrossValidation'));
            testCase.verifyGreaterThan(report.WarningCount,0);
        end

        function roundTripPreservesSpectrumAndProvenance(testCase)
            root = fileparts(fileparts(mfilename('fullpath')));
            spectrum = wc4sm_read_spectrum_file(fullfile(root,'test_data', ...
                'Spectrum_1_8ms_avg50.csv'),'Wavelength',0);
            state = struct('Spectrum',spectrum);
            provenance = struct('MasterLibrary','NIST_ASD_HgAr_20260729.lit', ...
                'MasterVersion','project copy 2026-08-03','Authority','NIST', ...
                'WavelengthMedium','Air','SelectionMode', ...
                'WCC4SM_NIST_ASD_HgAr_20260729_Mode01.csv', ...
                'SelectionModeVersion','01');
            metadata = struct('InstrumentID','TEST-INSTRUMENT-001', ...
                'ReferenceProvenance',provenance);
            session = wc4sm_create_session(state,metadata);
            path = [tempname '.mat']; cleanup = onCleanup(@() deleteIfPresent(path)); %#ok<NASGU>
            wc4sm_save_session(path,session);
            [loaded,report] = wc4sm_load_session(path);

            testCase.verifyTrue(report.IsValid);
            testCase.verifyEqual(loaded.State.Spectrum.raw,spectrum.raw);
            testCase.verifyEqual(loaded.Metadata.ReferenceProvenance.Authority,'NIST');
            testCase.verifyEqual(loaded.Metadata.InstrumentID,'TEST-INSTRUMENT-001');
        end

        function roundTripPreservesCalibrationModel(testCase)
            pixel = (0:10).'; wavelength = 300+0.4*pixel;
            model = wc4sm_fit_calibration(pixel([1 6 11]), ...
                wavelength([1 6 11]),1,pixel,'Test',{});
            session = wc4sm_create_session(struct('FinalCalibration',model));
            path = [tempname '.mat']; cleanup = onCleanup(@() deleteIfPresent(path)); %#ok<NASGU>
            wc4sm_save_session(path,session);
            loaded = wc4sm_load_session(path);
            testCase.verifyEqual(loaded.State.FinalCalibration.Coefficients, ...
                model.Coefficients,'AbsTol',0);
            testCase.verifyEqual(loaded.State.FinalCalibration.LOOResidual, ...
                model.LOOResidual,'AbsTol',0);
        end

        function roundTripPreservesSetDesignState(testCase)
            partition=struct('Rule','Equal cumulative influence','TargetK',3,'CutIndices',[2 5]);
            design=struct('SelectedCandidate',2,'PoolUseMask',logical([1;0;1]), ...
                'WindowPartition',partition,'Settings',struct('TargetK',2,'BPerf',5,'BDiv',5,'WindowK',3));
            session=wc4sm_create_session(struct('SetDesign',design));
            path=[tempname '.mat'];cleanup=onCleanup(@() deleteIfPresent(path)); %#ok<NASGU>
            wc4sm_save_session(path,session);
            loaded=wc4sm_load_session(path);
            testCase.verifyEqual(loaded.State.SetDesign.SelectedCandidate,2);
            testCase.verifyEqual(loaded.State.SetDesign.PoolUseMask,logical([1;0;1]));
            testCase.verifyEqual(loaded.State.SetDesign.Settings.BPerf,5);
            testCase.verifyEqual(loaded.State.SetDesign.WindowPartition.CutIndices,[2 5]);
            testCase.verifyEqual(loaded.State.SetDesign.Settings.WindowK,3);
        end

        function roundTripPreservesPositionCrossValidation(testCase)
            crossResult=struct('Degree',3,'ValidationMode','LOO','RMSE',eye(4));
            session=wc4sm_create_session(struct('PositionCrossValidation',crossResult));
            path=[tempname '.mat'];cleanup=onCleanup(@() deleteIfPresent(path)); %#ok<NASGU>
            wc4sm_save_session(path,session);loaded=wc4sm_load_session(path);
            testCase.verifyEqual(loaded.State.PositionCrossValidation.Degree,3);
            testCase.verifyEqual(loaded.State.PositionCrossValidation.ValidationMode,'LOO');
            testCase.verifyEqual(loaded.State.PositionCrossValidation.RMSE,eye(4));
        end

        function roundTripPreservesPixelCoordinateMetadata(testCase)
            pixel = (1:11).'; wavelength = 300+0.4*pixel;
            model = wc4sm_fit_calibration(pixel([1 6 11]), ...
                wavelength([1 6 11]),1,pixel,'Test',{});
            model.PixelCoordinateMode = 'Valid-pixel sequence';
            model.PixelFirst = 1; model.PixelLast = 11; model.PixelCount = 11;
            model.CalibrationPixelFirst = 1; model.CalibrationPixelLast = 11;
            spectrum = struct('raw',ones(11,1),'inputX',pixel,'pixel',pixel, ...
                'dark',[],'PixelCoordinateMode','Valid-pixel sequence');
            session = wc4sm_create_session(struct('Spectrum',spectrum, ...
                'FinalCalibration',model));
            path = [tempname '.mat']; cleanup = onCleanup(@() deleteIfPresent(path)); %#ok<NASGU>
            wc4sm_save_session(path,session);
            loaded = wc4sm_load_session(path);
            testCase.verifyEqual(loaded.State.FinalCalibration.PixelCoordinateMode, ...
                'Valid-pixel sequence');
            testCase.verifyEqual(loaded.State.Spectrum.PixelCoordinateMode, ...
                'Valid-pixel sequence');
        end

        function rejectsUnsupportedPixelCoordinateMode(testCase)
            spectrum = struct('raw',[1;2;3],'inputX',[1;2;3], ...
                'pixel',[1;2;3],'dark',[],'PixelCoordinateMode','Ambiguous');
            session = wc4sm_create_session(struct('Spectrum',spectrum));
            report = wc4sm_validate_session(session);
            testCase.verifyFalse(report.IsValid);
            testCase.verifyTrue(any(contains(report.Errors,'pixel coordinate mode')));
        end

        function detectsDarkLengthMismatch(testCase)
            spectrum = struct('raw',[1;2;3],'inputX',[1;2;3], ...
                'pixel',[0;1;2],'dark',[1;2]);
            session = wc4sm_create_session(struct('Spectrum',spectrum));
            report = wc4sm_validate_session(session);
            testCase.verifyFalse(report.IsValid);
            testCase.verifyTrue(any(contains(report.Errors,'Dark spectrum length')));
        end

        function rejectsUnsupportedMajorVersion(testCase)
            session = wc4sm_create_session();
            session.FormatVersion = '2.0';
            report = wc4sm_validate_session(session);
            testCase.verifyFalse(report.IsValid);
            testCase.verifyTrue(any(contains(report.Errors,'Unsupported')));
        end

        function saveRejectsInvalidSession(testCase)
            session = wc4sm_create_session();
            session.State = rmfield(session.State,'Spectrum');
            path = [tempname '.mat']; cleanup = onCleanup(@() deleteIfPresent(path)); %#ok<NASGU>
            testCase.verifyError(@() wc4sm_save_session(path,session), ...
                'WCC4SM:InvalidSession');
        end

        function loadRejectsUnrelatedMatFile(testCase)
            path = [tempname '.mat']; cleanup = onCleanup(@() deleteIfPresent(path)); %#ok<NASGU>
            unrelated = 1; save(path,'unrelated');
            testCase.verifyError(@() wc4sm_load_session(path), ...
                'WCC4SM:SessionVariableMissing');
        end
    end
end

function deleteIfPresent(path)
    if isfile(path), delete(path); end
end
