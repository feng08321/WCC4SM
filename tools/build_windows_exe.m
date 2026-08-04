function outputFolder = build_windows_exe
%BUILD_WINDOWS_EXE Build WCC4SM as a Windows executable without an installer.
% The target computer must provide the matching MATLAB Runtime, or MATLAB.

    if ~ispc
        error('WCC4SM:WindowsBuildRequired', ...
            'The Windows executable must be built on Windows.');
    end
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
    sourceFolder = fullfile(projectRoot,'src');
    entryFile = fullfile(projectRoot,'WCC4SM_V0_9.m');
    outputFolder = fullfile(projectRoot,'build','WCC4SM_V0.9_Windows_x64');
    if isfolder(outputFolder), rmdir(outputFolder,'s'); end
    mkdir(outputFolder);

    addpath(sourceFolder);
    cleanup = onCleanup(@() rmpath(sourceFolder)); %#ok<NASGU>
    mcc('-e','-v','-d',outputFolder,entryFile);

    copyfile(fullfile(projectRoot,'docs'),fullfile(outputFolder,'docs'));
    copyfile(fullfile(projectRoot,'reference_data'), ...
        fullfile(outputFolder,'reference_data'));
    copyfile(fullfile(projectRoot,'LICENSE'),fullfile(outputFolder,'LICENSE'));
    copyfile(fullfile(projectRoot,'NOTICE'),fullfile(outputFolder,'NOTICE'));
    copyfile(fullfile(projectRoot,'README.md'),fullfile(outputFolder,'README.md'));
    fprintf('WCC4SM executable distribution created at:\n%s\n',outputFolder);
end
