function results = run_wc4sm_tests
%RUN_WC4SM_TESTS Run the WCC4SM non-GUI regression test suite.
% Run this file from the WCC4SM package root in MATLAB R2022a or later.

    packageRoot = fileparts(mfilename('fullpath'));
    testsFolder = fullfile(packageRoot,'tests');
    addpath(packageRoot,testsFolder);
    cleanup = onCleanup(@() rmpath(testsFolder)); %#ok<NASGU>

    suite = testsuite(testsFolder,'IncludeSubfolders',true);
    results = run(suite);
    disp(results);

    failed = results([results.Failed]);
    fprintf('\nWCC4SM tests: %d total, %d passed, %d failed, %d incomplete.\n', ...
        numel(results),sum([results.Passed]),sum([results.Failed]), ...
        sum([results.Incomplete]));
    if ~isempty(failed)
        error('WCC4SM:TestsFailed','%d WCC4SM test(s) failed.',numel(failed));
    end
end
