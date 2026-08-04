function documents = wc4sm_list_pdf_documents(documentationRoot)
%WC4SM_LIST_PDF_DOCUMENTS Recursively list readable PDF help documents.

    documents = struct('Label',{},'Path',{});
    if ~(ischar(documentationRoot) || isstring(documentationRoot))
        error('WCC4SM:InvalidDocumentationRoot', ...
            'Documentation root must be a character vector or string scalar.');
    end
    documentationRoot = char(documentationRoot);
    if ~isfolder(documentationRoot)
        return;
    end

    entries = dir(fullfile(documentationRoot,'**','*'));
    entries = entries(~[entries.isdir]);
    if isempty(entries)
        return;
    end
    keep = false(size(entries));
    for index = 1:numel(entries)
        [~,~,extension] = fileparts(entries(index).name);
        keep(index) = strcmpi(extension,'.pdf');
    end
    entries = entries(keep);
    if isempty(entries)
        return;
    end

    labels = strings(numel(entries),1);
    paths = strings(numel(entries),1);
    rootPrefix = [char(java.io.File(documentationRoot).getCanonicalPath()) filesep];
    for index = 1:numel(entries)
        absolutePath = char(java.io.File(fullfile(entries(index).folder, ...
            entries(index).name)).getCanonicalPath());
        if ~startsWith(absolutePath,rootPrefix,'IgnoreCase',ispc)
            continue;
        end
        paths(index) = string(absolutePath);
        labels(index) = replace(extractAfter(string(absolutePath), ...
            strlength(string(rootPrefix))),filesep,' / ');
    end
    valid = strlength(paths)>0;
    labels = labels(valid); paths = paths(valid);
    [~,order] = sort(lower(labels));
    labels = labels(order); paths = paths(order);
    documents = struct('Label',cellstr(labels),'Path',cellstr(paths));
end
