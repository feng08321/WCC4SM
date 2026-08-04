classdef TestWcc4smDataAssets < matlab.unittest.TestCase
    properties
        Root
    end

    methods (TestMethodSetup)
        function locatePackage(testCase)
            testCase.Root = fileparts(fileparts(mfilename('fullpath')));
        end
    end

    methods (Test)
        function measuredAndDarkSpectraAreAligned(testCase)
            measured = testCase.readTwoNumericColumns(fullfile(testCase.Root, ...
                'Data','Spectrum_1_8ms_avg50.csv'));
            dark = testCase.readTwoNumericColumns(fullfile(testCase.Root, ...
                'Data','Spectrum_1_dark_8ms_avg50.csv'));

            testCase.verifySize(measured,[1943 2]);
            testCase.verifySize(dark,[1943 2]);
            testCase.verifyEqual(measured(:,1),dark(:,1),'AbsTol',1e-12);
            testCase.verifyGreaterThan(min(diff(measured(:,1))),0);
            testCase.verifyEqual(measured(1,1),285.34,'AbsTol',0.001);
            testCase.verifyEqual(measured(end,1),1099.69,'AbsTol',0.001);
        end

        function darkSubtractedSpectrumHasStableCharacteristics(testCase)
            measured = testCase.readTwoNumericColumns(fullfile(testCase.Root, ...
                'Data','Spectrum_1_8ms_avg50.csv'));
            dark = testCase.readTwoNumericColumns(fullfile(testCase.Root, ...
                'Data','Spectrum_1_dark_8ms_avg50.csv'));
            corrected = measured(:,2)-dark(:,2);
            [peakValue,index] = max(corrected);

            % These are regression characteristics, not certified instrument values.
            testCase.verifyEqual(mean(dark(:,2)),821.2934,'AbsTol',0.1);
            testCase.verifyEqual(mean(corrected),364.7837,'AbsTol',0.1);
            testCase.verifyEqual(peakValue,55654.0107,'AbsTol',0.2);
            testCase.verifyEqual(measured(index,1),436.90,'AbsTol',0.01);
            testCase.verifyLessThan(min(corrected),0); % random dark noise is retained
        end

        function nistLibraryAndSelectionModeAreConsistent(testCase)
            nistPath = fullfile(testCase.Root,'reference_data', ...
                'NIST_ASD_HgAr_20260729.lit');
            modePath = fullfile(testCase.Root, ...
                'reference_data', ...
                'WCC4SM_NIST_ASD_HgAr_20260729_Mode01.csv');
            nist = testCase.readTwoNumericColumns(nistPath);
            mode = readtable(modePath,'TextType','string');

            testCase.verifyEqual(height(mode),29);
            testCase.verifyGreaterThanOrEqual(size(nist,1),300);
            testCase.verifyGreaterThanOrEqual(min(mode.Wavelength_nm),min(nist(:,1)));
            testCase.verifyLessThanOrEqual(max(mode.Wavelength_nm),max(nist(:,1)));

            nearestDistance = arrayfun(@(w) min(abs(nist(:,1)-w)), ...
                mode.Wavelength_nm);
            testCase.verifyEqual(nearestDistance,zeros(29,1),'AbsTol',1e-12);
            testCase.verifyTrue(all(mode.MasterSource == ...
                "NIST_ASD_HgAr_20260729.lit"));
        end

        function datedNistMasterPreservesOriginalData(testCase)
            dated = testCase.readTwoNumericColumns(fullfile(testCase.Root, ...
                'reference_data', ...
                'NIST_ASD_HgAr_20260729.lit'));
            testCase.verifySize(dated,[322 2]);
            testCase.verifyEqual(dated(1,1),184.9499,'AbsTol',1e-12);
            testCase.verifyEqual(dated(end,1),2396.652,'AbsTol',1e-12);
            testCase.verifyTrue(isfile(fullfile(testCase.Root, ...
                'reference_data', ...
                'NIST_ASD_HgAr_20260729_Metadata.md')));
        end

        function nistMode01MatchesAllMasterWavelengthsExactly(testCase)
            masterPath = fullfile(testCase.Root,'reference_data', ...
                'NIST_ASD_HgAr_20260729.lit');
            modePath = fullfile(testCase.Root, ...
                'reference_data', ...
                'WCC4SM_NIST_ASD_HgAr_20260729_Mode01.csv');
            master = testCase.readTwoNumericColumns(masterPath);
            mode = readtable(modePath,'TextType','string');
            testCase.verifyEqual(height(mode),29);
            testCase.verifyTrue(all(mode.MasterSource == ...
                "NIST_ASD_HgAr_20260729.lit"));
            nearestDistance = arrayfun(@(w) min(abs(master(:,1)-w)), ...
                mode.Wavelength_nm);
            testCase.verifyEqual(nearestDistance,zeros(29,1),'AbsTol',1e-12);
            expectedID = compose("WL%.6f_O1",mode.Wavelength_nm);
            testCase.verifyEqual(mode.LineID,expectedID);
        end
    end

    methods (Static, Access=private)
        function data = readTwoNumericColumns(path)
            lines = readlines(path);
            data = zeros(0,2);
            for k = 1:numel(lines)
                fields = split(lines(k),{',',char(9)});
                if numel(fields) < 2
                    continue;
                end
                first = str2double(strtrim(fields(1)));
                second = str2double(strtrim(fields(2)));
                if isfinite(first) && isfinite(second)
                    data(end+1,:) = [first second]; %#ok<AGROW>
                end
            end
        end
    end
end
