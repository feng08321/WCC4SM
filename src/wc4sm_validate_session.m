function report = wc4sm_validate_session(session)
%WC4SM_VALIDATE_SESSION Validate structure, consistency and traceability.
% Structural/data errors make IsValid false. Missing recommended provenance
% produces warnings but still permits saving a research session.

    errors = strings(0,1);
    warnings = strings(0,1);
    requiredTop = {'Application','FormatVersion','SoftwareVersion', ...
        'CreatedAt','ModifiedAt','Metadata','State'};
    if ~isstruct(session) || ~isscalar(session)
        errors(end+1) = "Session must be a scalar structure.";
        report = makeReport(errors,warnings);
        return;
    end
    missing = requiredTop(~isfield(session,requiredTop));
    if ~isempty(missing)
        errors(end+1) = "Missing top-level fields: " + strjoin(missing,', ');
        report = makeReport(errors,warnings);
        return;
    end
    if ~strcmp(char(string(session.Application)),'WCC4SM')
        errors(end+1) = "Application identifier must be WCC4SM.";
    end
    [major,versionOK] = parseMajorVersion(session.FormatVersion);
    if ~versionOK
        errors(end+1) = "FormatVersion is invalid.";
    elseif major ~= 1
        errors(end+1) = "Unsupported session format major version: " + ...
            string(session.FormatVersion);
    end
    if ~isstruct(session.Metadata) || ~isscalar(session.Metadata)
        errors(end+1) = "Metadata must be a scalar structure.";
    end
    if ~isstruct(session.State) || ~isscalar(session.State)
        errors(end+1) = "State must be a scalar structure.";
        report = makeReport(errors,warnings);
        return;
    end

    requiredState = {'Spectrum','Peaks','PeakDataset','ReferenceLines', ...
        'CalibrationPairs','InitialCalibration','FinalCalibration', ...
        'CalibrationModels','AppliedModel','AppliedModelName','UISettings'};
    missingState = requiredState(~isfield(session.State,requiredState));
    if ~isempty(missingState)
        errors(end+1) = "Missing state fields: " + strjoin(missingState,', ');
    end
    if isfield(session.State,'Spectrum') && isstruct(session.State.Spectrum) && ...
            isscalar(session.State.Spectrum) && ...
            ~isempty(fieldnames(session.State.Spectrum))
        errors = validateSpectrum(session.State.Spectrum,errors);
    end
    if isfield(session.State,'Peaks') && ~isempty(session.State.Peaks) && ...
            isfield(session.State.Peaks,'ID')
        ids = string({session.State.Peaks.ID});
        if numel(unique(ids)) ~= numel(ids)
            errors(end+1) = "Peak IDs must be unique.";
        end
    end
    modelNames = {'FinalCalibration','AppliedModel'};
    for k = 1:numel(modelNames)
        name = modelNames{k};
        if isfield(session.State,name) && isstruct(session.State.(name)) && ...
                isfield(session.State.(name),'valid') && session.State.(name).valid
            errors = validateCalibrationModel(session.State.(name),name,errors);
        end
    end

    if isstruct(session.Metadata) && isfield(session.Metadata,'ReferenceProvenance') && ...
            isstruct(session.Metadata.ReferenceProvenance)
        provenance = session.Metadata.ReferenceProvenance;
        recommended = {'MasterLibrary','Authority','WavelengthMedium','SelectionMode'};
        for k = 1:numel(recommended)
            name = recommended{k};
            if ~isfield(provenance,name) || strlength(string(provenance.(name))) == 0 || ...
                    (strcmp(name,'WavelengthMedium') && strcmpi(string(provenance.(name)),'Unspecified'))
                warnings(end+1) = "Reference provenance is incomplete: " + name; %#ok<AGROW>
            end
        end
    else
        warnings(end+1) = "Reference provenance is missing.";
    end
    report = makeReport(errors,warnings);
end

function errors = validateSpectrum(spectrum,errors)
    if ~isstruct(spectrum) || ~isscalar(spectrum)
        errors(end+1) = "Spectrum must be a scalar structure.";
        return;
    end
    required = {'raw','inputX','pixel','dark'};
    if ~all(isfield(spectrum,required))
        errors(end+1) = "Spectrum is missing raw, inputX, pixel or dark fields.";
        return;
    end
    n = numel(spectrum.raw);
    if n > 0 && (numel(spectrum.inputX) ~= n || numel(spectrum.pixel) ~= n)
        errors(end+1) = "Spectrum raw, inputX and pixel lengths must match.";
    end
    if ~isempty(spectrum.dark) && numel(spectrum.dark) ~= n
        errors(end+1) = "Dark spectrum length must match raw spectrum length.";
    end
    if any(~isfinite(spectrum.raw)) || any(~isfinite(spectrum.inputX)) || ...
            any(~isfinite(spectrum.pixel)) || any(~isfinite(spectrum.dark))
        errors(end+1) = "Spectrum arrays must contain finite values.";
    end
    if isfield(spectrum,'PixelCoordinateMode') && ...
            strlength(string(spectrum.PixelCoordinateMode)) > 0
        allowed = ["Full detector sequence","Valid-pixel sequence", ...
            "Legacy natural pixel sequence"];
        if ~any(strcmp(string(spectrum.PixelCoordinateMode),allowed))
            errors(end+1) = "Spectrum has an unsupported pixel coordinate mode.";
        end
    end
end

function errors = validateCalibrationModel(model,name,errors)
    required = {'Pixel','ReferenceWavelength','Coefficients','Mu'};
    if ~all(isfield(model,required))
        errors(end+1) = string(name) + " is missing required model fields.";
        return;
    end
    if numel(model.Pixel) ~= numel(model.ReferenceWavelength)
        errors(end+1) = string(name) + " pixel and wavelength lengths must match.";
    end
    if isempty(model.Coefficients) || numel(model.Mu) ~= 2 || ...
            any(~isfinite(model.Coefficients)) || any(~isfinite(model.Mu))
        errors(end+1) = string(name) + " has invalid coefficients or mu.";
    end
    if isfield(model,'PixelCoordinateMode') && ...
            strlength(string(model.PixelCoordinateMode)) > 0
        allowed = ["Full detector sequence","Valid-pixel sequence", ...
            "Legacy natural pixel sequence"];
        if ~any(strcmp(string(model.PixelCoordinateMode),allowed))
            errors(end+1) = string(name) + " has an unsupported pixel coordinate mode.";
        end
    end
    rangeFields = {'PixelFirst','PixelLast','CalibrationPixelFirst','CalibrationPixelLast'};
    if all(isfield(model,rangeFields)) && ...
            (model.PixelFirst > model.PixelLast || ...
             model.CalibrationPixelFirst > model.CalibrationPixelLast)
        errors(end+1) = string(name) + " has an invalid pixel coordinate range.";
    end
end

function [major,ok] = parseMajorVersion(version)
    token = regexp(char(string(version)),'^(\d+)(?:\.\d+)?$','tokens','once');
    ok = ~isempty(token);
    if ok, major = str2double(token{1}); else, major = NaN; end
end

function report = makeReport(errors,warnings)
    report = struct('IsValid',isempty(errors),'Errors',errors,'Warnings',warnings, ...
        'ErrorCount',numel(errors),'WarningCount',numel(warnings));
end
