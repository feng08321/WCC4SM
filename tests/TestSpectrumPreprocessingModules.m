classdef TestSpectrumPreprocessingModules < matlab.unittest.TestCase
    properties
        Root
        MeasuredPath
        DarkPath
    end

    methods (TestMethodSetup)
        function locateData(testCase)
            testCase.Root = fileparts(fileparts(mfilename('fullpath')));
            testCase.MeasuredPath = fullfile(testCase.Root,'Data', ...
                'Spectrum_1_8ms_avg50.csv');
            testCase.DarkPath = fullfile(testCase.Root,'Data', ...
                'Spectrum_1_dark_8ms_avg50.csv');
        end
    end

    methods (Test)
        function readsSpectraSmartMeasuredFile(testCase)
            spectrum = wc4sm_read_spectrum_file( ...
                testCase.MeasuredPath,'Wavelength',0);
            testCase.verifySize(spectrum.raw,[1943 1]);
            testCase.verifyEqual(spectrum.inputX(1),285.34,'AbsTol',0.001);
            testCase.verifyEqual(spectrum.inputX(end),1099.69,'AbsTol',0.001);
            testCase.verifyEqual(spectrum.pixel([1 end]),[0;1942]);
            testCase.verifyEqual(spectrum.xKind,'Wavelength');
            testCase.verifyEqual(spectrum.inputWavelength,spectrum.inputX);
        end

        function readsAndAlignsRealDarkFile(testCase)
            spectrum = wc4sm_read_spectrum_file( ...
                testCase.MeasuredPath,'Wavelength',0);
            dark = wc4sm_read_dark_spectrum(testCase.DarkPath,spectrum.inputX);
            testCase.verifySize(dark.values,[1943 1]);
            testCase.verifyTrue(dark.interpolated);
            testCase.verifyEqual(mean(dark.values),821.2934,'AbsTol',0.1);
        end

        function reproducesRealDarkSubtraction(testCase)
            spectrum = wc4sm_read_spectrum_file( ...
                testCase.MeasuredPath,'Wavelength',0);
            dark = wc4sm_read_dark_spectrum(testCase.DarkPath,spectrum.inputX);
            processed = wc4sm_preprocess_spectrum( ...
                spectrum.raw,dark.values,12345,false);
            [peakValue,index] = max(processed.corrected);

            testCase.verifyEqual(processed.subtractionMode,'Dark');
            testCase.verifyTrue(isnan(processed.manualBaselineApplied));
            testCase.verifyEqual(mean(processed.corrected),364.7837,'AbsTol',0.1);
            testCase.verifyEqual(peakValue,55654.0107,'AbsTol',0.2);
            testCase.verifyEqual(spectrum.inputX(index),436.90,'AbsTol',0.01);
            testCase.verifyEqual(max(processed.normalized),1,'AbsTol',1e-12);
        end

        function manualBaselineAndClamp(testCase)
            raw = [5;10;15;20];
            processed = wc4sm_preprocess_spectrum(raw,[],10,true);
            testCase.verifyEqual(processed.corrected,[0;0;5;10]);
            testCase.verifyEqual(processed.normalized,[0;0;0.5;1]);
            testCase.verifyEqual(processed.subtractionMode,'ManualBaseline');
            testCase.verifyEqual(processed.manualBaselineApplied,10);
        end

        function allNonpositiveSignalNormalizesToZero(testCase)
            processed = wc4sm_preprocess_spectrum([1;2;3],[],5,false);
            testCase.verifyEqual(processed.corrected,[-4;-3;-2]);
            testCase.verifyEqual(processed.normalized,zeros(3,1));
        end

        function rejectsMismatchedDarkLength(testCase)
            testCase.verifyError(@() wc4sm_preprocess_spectrum( ...
                [1;2;3;4],[1;2;3],0,false),'WCC4SM:DarkLengthMismatch');
        end
    end
end
