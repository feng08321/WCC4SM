function [session,report] = wc4sm_load_session(filePath)
%WC4SM_LOAD_SESSION Load and validate a WCC4SM session MAT file.

    arguments
        filePath {mustBeTextScalar}
    end
    filePath = char(filePath);
    if ~isfile(filePath)
        error('WCC4SM:FileNotFound','Session file does not exist: %s',filePath);
    end
    content = load(filePath,'-mat');
    if ~isfield(content,'WCC4SMSession')
        error('WCC4SM:SessionVariableMissing', ...
            'MAT file does not contain WCC4SMSession.');
    end
    session = content.WCC4SMSession;
    report = wc4sm_validate_session(session);
    if ~report.IsValid
        error('WCC4SM:InvalidSession', ...
            'Loaded session is invalid: %s',strjoin(cellstr(report.Errors),' | '));
    end
end
