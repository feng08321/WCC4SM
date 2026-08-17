classdef TestV092UiSupport < matlab.unittest.TestCase
    methods (Test)
        function sourceUsesV092EntryPoint(testCase)
            src = fileread(fullfile(fileparts(fileparts(mfilename('fullpath'))),'WCC4SM_V0_9_2.m'));
            testCase.verifySubstring(src,'function WCC4SM_V0_9_2');
        end
        function sourceProvidesFullSpectrumRangeControls(testCase)
            src = fileread(fullfile(fileparts(fileparts(mfilename('fullpath'))),'WCC4SM_V0_9_2.m'));
            testCase.verifySubstring(src,'fullViewStart');
            testCase.verifySubstring(src,'fullViewEnd');
            testCase.verifySubstring(src,'resetFullViewRange');
        end
        function sourceProvidesMatchingAnnotationToggle(testCase)
            src = fileread(fullfile(fileparts(fileparts(mfilename('fullpath'))),'WCC4SM_V0_9_2.m'));
            testCase.verifySubstring(src,'Show matching annotations');
            testCase.verifySubstring(src,'showMatchingCheck.Value');
        end
        function sourceDisablesTeXForSpectrumTitles(testCase)
            src = fileread(fullfile(fileparts(fileparts(mfilename('fullpath'))),'WCC4SM_V0_9_2.m'));
            testCase.verifySubstring(src,"title(axFull,ttl,'Interpreter','none')");
        end
    end
end
