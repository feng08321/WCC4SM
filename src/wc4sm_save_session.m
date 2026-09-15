function wc4sm_save_session(filePath,session)
%WC4SM_SAVE_SESSION Validate and save a WCC4SM session MAT file.

    arguments
        filePath {mustBeTextScalar}
        session (1,1) struct
    end
    filePath = char(filePath);
    [folder,~,extension] = fileparts(filePath);
    if isempty(extension)
        filePath = [filePath '.mat'];
    elseif ~strcmpi(extension,'.mat')
        error('WCC4SM:InvalidSessionExtension', ...
            'WCC4SM session files must use the .mat extension.');
    end
    if ~isempty(folder) && ~isfolder(folder)
        error('WCC4SM:SessionFolderNotFound', ...
            'Session target folder does not exist: %s',folder);
    end
    report = wc4sm_validate_session(session);
    if ~report.IsValid
        error('WCC4SM:InvalidSession', ...
            'Session validation failed: %s',strjoin(cellstr(report.Errors),' | '));
    end
    session.ModifiedAt = datetime('now');
    WCC4SMSession = session;
    save(filePath,'WCC4SMSession','-mat');
end
