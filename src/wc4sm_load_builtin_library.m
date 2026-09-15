function L = wc4sm_load_builtin_library(name)
%WC4SM_LOAD_BUILTIN_LIBRARY Load a built-in Hg-Ar reference line library.
%   L = WC4SM_LOAD_BUILTIN_LIBRARY(name) returns the line-library structure
%   for one of the built-in libraries:
%     "basic"   - Built-in Hg-Ar Basic 21 (experience-screened, 300-1050 nm)
%     "paper24" - Paper Table 1 Hg-Ar 24 measured peaks (2019 paper)
%     "nim"     - NIM Hg-Ar Certificate 34 GXcl2025-02617
%   Library data live in reference_data/*.lit so the MATLAB GUI and the
%   Python port share a single source of truth. The parsing rules match the
%   external .lit import path of the GUI.

    arguments
        name (1,1) string {mustBeMember(name,["basic","paper24","nim"])}
    end

    switch name
        case "basic"
            file = 'Builtin_HgAr_Basic21.lit';
            source = 'Built-in Hg-Ar Basic 21';
        case "paper24"
            file = 'Builtin_HgAr_Paper24.lit';
            source = 'Paper Table 1 Hg-Ar 24 measured peaks';
        case "nim"
            file = 'Builtin_HgAr_NIM34.lit';
            source = 'NIM Hg-Ar Certificate 34 GXcl2025-02617';
    end

    packageRoot = fileparts(fileparts(mfilename('fullpath')));
    path = fullfile(packageRoot,'reference_data',file);
    if ~isfile(path)
        error('WCC4SM:BuiltinLibraryMissing', ...
            'Built-in library file not found: %s',path);
    end

    M = readmatrix(path,'FileType','text');
    M = M(~all(isnan(M),2),:);
    M = M(:,~all(isnan(M),1));
    if size(M,2) < 2
        error('WCC4SM:BuiltinLibraryFormat', ...
            'Built-in library file requires wavelength and intensity columns: %s',path);
    end
    w = M(:,1);
    inten = M(:,2);
    if size(M,2) >= 3, ord = M(:,3); else, ord = ones(size(w)); end
    good = isfinite(w) & isfinite(inten) & isfinite(ord) & w>0 & ord>=1;
    w = w(good); inten = inten(good); ord = round(ord(good));
    if numel(w) < 2
        error('WCC4SM:BuiltinLibraryEmpty', ...
            'Built-in library has fewer than two valid lines: %s',path);
    end
    [~,ix] = sort(w.*ord);
    w = w(ix); inten = inten(ix); ord = ord(ix);

    L = wc4sm_empty_line_library();
    L.wavelength = w(:);
    L.intensity = inten(:);
    L.order = ord(:);
    L.effective = L.wavelength.*L.order;
    L.enabled = true(size(L.wavelength));
    L.source = source;
    L.loaded = true;
end
