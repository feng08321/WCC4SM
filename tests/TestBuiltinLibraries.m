classdef TestBuiltinLibraries < matlab.unittest.TestCase
    % Pin the built-in Hg-Ar reference libraries now stored under
    % reference_data/ and loaded through wc4sm_load_builtin_library.
    % Counts, landmark wavelengths and checksums protect against accidental
    % data-file edits; the libraries are the single source of truth shared
    % with the Python port.

    methods (Test)
        function basicLibraryContent(testCase)
            L = wc4sm_load_builtin_library("basic");
            testCase.verifyTrue(L.loaded);
            testCase.verifyEqual(L.source,'Built-in Hg-Ar Basic 21');
            testCase.verifyEqual(numel(L.wavelength),21);
            testCase.verifyEqual(L.wavelength(1),296.73);
            testCase.verifyEqual(L.wavelength(end),1013.98);
            % Landmark lines and intensities from the legacy inline library
            testCase.verifyEqual(L.intensity(L.wavelength==546.07),2258.4);
            testCase.verifyEqual(L.intensity(L.wavelength==404.66),767);
            testCase.verifyEqual(sum(L.wavelength),14045.7161,'AbsTol',1e-4);
            testCase.verifyEqual(sum(L.intensity),4314.1,'AbsTol',1e-10);
            testCase.verifyTrue(all(L.order==1));
            testCase.verifyTrue(all(L.enabled));
            testCase.verifyEqual(L.effective,L.wavelength);
        end

        function paper24LibraryContent(testCase)
            L = wc4sm_load_builtin_library("paper24");
            testCase.verifyTrue(L.loaded);
            testCase.verifyEqual(L.source,'Paper Table 1 Hg-Ar 24 measured peaks');
            testCase.verifyEqual(numel(L.wavelength),24);
            testCase.verifyEqual(L.wavelength(1),313.16);
            testCase.verifyEqual(L.wavelength(end),1013.98);
            testCase.verifyTrue(ismember(435.72,L.wavelength));
            testCase.verifyTrue(ismember(578.01,L.wavelength));
            testCase.verifyEqual(sum(L.wavelength),16874.40,'AbsTol',1e-4);
            testCase.verifyTrue(all(L.intensity==1));
        end

        function nimLibraryContent(testCase)
            L = wc4sm_load_builtin_library("nim");
            testCase.verifyTrue(L.loaded);
            testCase.verifyEqual(L.source,'NIM Hg-Ar Certificate 34 GXcl2025-02617');
            testCase.verifyEqual(numel(L.wavelength),34);
            testCase.verifyEqual(L.wavelength(1),253.65);
            testCase.verifyEqual(L.wavelength(end),1047.04);
            testCase.verifyTrue(ismember(546.06,L.wavelength));
            testCase.verifyEqual(sum(L.wavelength),22947.64,'AbsTol',1e-4);
            testCase.verifyTrue(all(L.intensity==1));
        end

        function sortedAscending(testCase)
            for name = ["basic","paper24","nim"]
                L = wc4sm_load_builtin_library(name);
                testCase.verifyTrue(issorted(L.effective), ...
                    name + " effective wavelengths must be sorted ascending");
                testCase.verifyEqual(numel(unique(L.effective)), ...
                    numel(L.effective), name + " wavelengths must be unique");
            end
        end

        function invalidNameRejected(testCase)
            testCase.verifyError(@()wc4sm_load_builtin_library("unknown"), ...
                'MATLAB:validators:mustBeMember');
        end
    end
end
