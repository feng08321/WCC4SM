classdef TestGuiSmoke < matlab.unittest.TestCase
%TESTGUISMOKE Launch/close smoke tests for the WCC4SM_V1_0 GUI.
% Unlike TestV100UiSupport (source pattern matching), these tests actually
% start the application, verify that the main window and its core controls
% are created, and close everything cleanly. Requires a display-capable
% MATLAB session; the GUI entry must be on the MATLAB path.

    properties
        FiguresBefore
    end

    methods (TestClassSetup)
        function addProjectRootToPath(testCase)
            packageRoot = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture(packageRoot));
        end
    end

    methods (TestMethodSetup)
        function recordExistingFigures(testCase)
            testCase.FiguresBefore = findall(groot,'Type','figure');
        end
    end

    methods (TestMethodTeardown)
        function closeNewFigures(testCase)
            newFigs = setdiff(findall(groot,'Type','figure'),testCase.FiguresBefore);
            delete(newFigs(isvalid(newFigs)));
        end
    end

    methods (Test, TestTags = {'GUI'})
        function mainWindowLaunches(testCase)
            fig = launchGui(testCase);
            testCase.verifyTrue(isvalid(fig));
            testCase.verifyEqual(fig.Name,'WCC4SM V1.0 | Peak Analysis');
        end

        function mainWindowHasCoreComponents(testCase)
            fig = launchGui(testCase);
            % Note: use -isa (class inheritance) rather than Type matching —
            % in R2022a, findall(fig,'Type','uiaxes') returns 0 for UIAxes.
            testCase.verifyGreaterThanOrEqual( ...
                numel(findall(fig,'-isa','matlab.ui.control.UIAxes')),1, ...
                'Main window should contain at least one axes.');
            testCase.verifyGreaterThanOrEqual( ...
                numel(findall(fig,'-isa','matlab.ui.control.Table')),1, ...
                'Main window should contain at least one table.');
            testCase.verifyGreaterThanOrEqual( ...
                numel(findall(fig,'-isa','matlab.ui.control.Button')),5, ...
                'Main window should expose its workflow buttons.');
        end

        function windowClosesCleanly(testCase)
            fig = launchGui(testCase);
            delete(fig);
            drawnow;
            testCase.verifyFalse(isvalid(fig));
            testCase.verifyEmpty(findall(groot,'Type','figure', ...
                'Name','WCC4SM V1.0 | Peak Analysis'));
        end
    end

    methods (Access = private)
        function fig = launchGui(testCase)
            WCC4SM_V1_0;
            drawnow;
            newFigs = setdiff(findall(groot,'Type','figure'),testCase.FiguresBefore);
            newFigs = newFigs(isvalid(newFigs));
            testCase.assertNotEmpty(newFigs,'GUI launch created no figure.');
            testCase.assertEqual(numel(newFigs),1, ...
                'GUI launch should create exactly one window.');
            fig = newFigs(1);
        end
    end
end
