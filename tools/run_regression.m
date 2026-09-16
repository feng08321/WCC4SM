function results = run_regression()
%RUN_REGRESSION Run the full WCC4SM computation regression suite.
%   Runs every test under tests/ EXCEPT those tagged 'GUI'. The GUI smoke
%   tests create uifigure windows and are unstable when interleaved with
%   computation tests in a single batch process, so they are isolated and
%   run separately via run_gui_smoke.m (its own MATLAB invocation).
%
%   Usage (from the package root, in a fresh MATLAB session):
%     addpath('src','tools');
%     results = run_regression();   % errors if any test fails

    packageRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(packageRoot,'src'));

    suite = matlab.unittest.TestSuite.fromFolder( ...
        fullfile(packageRoot,'tests'), 'IncludingSubfolders', true);
    % Exclude GUI-tagged tests; they run in a separate process.
    suite = suite.selectIf(~matlab.unittest.selectors.HasTag('GUI'));

    results = suite.run();
    passed = nnz([results.Passed]);
    failed = nnz([results.Failed]);
    fprintf('REGRESSION passed=%d failed=%d total=%d\n', ...
        passed, failed, numel(results));
    assertSuccess(results);
end
