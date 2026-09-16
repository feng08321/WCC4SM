function results = run_gui_smoke()
%RUN_GUI_SMOKE Run only the GUI smoke tests (tagged 'GUI').
%   These tests launch the real WCC4SM_V1_0 uifigure app. They must run in
%   their own MATLAB invocation, separate from the computation regression
%   suite (run_regression.m), because creating uifigure windows in the same
%   batch process as computation tests can destabilize MATLAB.
%
%   IMPORTANT — environment: uifigure (CEF/embedded browser) is unstable
%   when created in a headless -batch/-nodesktop session on some machines
%   (observed heap corruption on the Zhaoxin KX-6000G online PC). Run this
%   in an INTERACTIVE MATLAB session with a display (e.g. the offline
%   development desktop used for GUI acceptance), not in a headless batch.
%
%   Usage (from the package root, in an interactive MATLAB session):
%     addpath('src','tools');
%     results = run_gui_smoke();   % errors if any test fails

    packageRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(packageRoot,'src'));

    suite = matlab.unittest.TestSuite.fromFolder( ...
        fullfile(packageRoot,'tests'), 'IncludingSubfolders', true);
    suite = suite.selectIf(matlab.unittest.selectors.HasTag('GUI'));

    if isempty(suite)
        error('run_gui_smoke:NoGUITests', ...
            'No tests tagged ''GUI'' were found under tests/.');
    end

    results = suite.run();
    passed = nnz([results.Passed]);
    failed = nnz([results.Failed]);
    fprintf('GUI-SMOKE passed=%d failed=%d total=%d\n', ...
        passed, failed, numel(results));
    assertSuccess(results);
end
