function outputPaths = build_docx_from_markdown(sourcePaths,outputFormat)
%BUILD_DOCX_FROM_MARKDOWN Build maintainable DOCX or PDF copies of Markdown.
% Supports headings, paragraphs, bullet/numbered items, fenced code, images and
% simple pipe-table text. Markdown remains the authoritative version-controlled
% source.

    arguments
        sourcePaths {mustBeText}
        outputFormat (1,1) string {mustBeMember(outputFormat,["docx","pdf"])} = "docx"
    end

    import mlreportgen.dom.*
    sourcePaths = cellstr(string(sourcePaths));
    outputPaths = cell(size(sourcePaths));
    for fileIndex = 1:numel(sourcePaths)
        sourcePath = sourcePaths{fileIndex};
        if ~isfile(sourcePath)
            error('WCC4SM:DocumentationSourceMissing', ...
                'Documentation source does not exist: %s',sourcePath);
        end
        [folder,stem] = fileparts(sourcePath);
        outputPath = fullfile(folder,[stem '.' char(outputFormat)]);
        document = Document(outputPath,char(outputFormat));
        open(document);
        lines = splitlines(string(fileread(sourcePath)));
        inCode = false;
        codeLines = strings(0,1);
        for lineIndex = 1:numel(lines)
            line = erase(lines(lineIndex),char(13));
            if startsWith(strtrim(line),"```")
                if inCode
                    appendCodeBlock(document,codeLines);
                    codeLines = strings(0,1);
                end
                inCode = ~inCode;
                continue;
            end
            if inCode
                codeLines(end+1,1) = line; %#ok<AGROW>
                continue;
            end
            imageToken = regexp(char(strtrim(line)), ...
                '^!\[([^\]]*)\]\(([^)]+)\)$','tokens','once');
            if ~isempty(imageToken)
                appendImage(document,sourcePath,imageToken{2},imageToken{1});
                continue;
            end
            heading = regexp(char(line),'^(#{1,6})\s+(.+)$','tokens','once');
            if ~isempty(heading)
                level = min(4,numel(heading{1}));
                item = Heading(level,cleanInline(heading{2}));
                item.Style = {FontFamily('Microsoft YaHei')};
                append(document,item);
                continue;
            end
            trimmed = strtrim(line);
            if strlength(trimmed)==0
                append(document,Paragraph(''));
                continue;
            end
            if ~isempty(regexp(char(trimmed),'^[-*]\s+','once'))
                value = regexprep(char(trimmed),'^[-*]\s+','');
                appendStyledParagraph(document,['• ' cleanInline(value)],true);
            elseif ~isempty(regexp(char(trimmed),'^\d+\.\s+','once'))
                appendStyledParagraph(document,cleanInline(char(trimmed)),true);
            elseif startsWith(trimmed,"|")
                appendTableLine(document,char(trimmed));
            else
                appendStyledParagraph(document,cleanInline(char(trimmed)),false);
            end
        end
        if inCode && ~isempty(codeLines),appendCodeBlock(document,codeLines);end
        close(document);
        outputPaths{fileIndex} = outputPath;
    end
end

function appendImage(document,sourcePath,imageReference,caption)
    import mlreportgen.dom.*
    [sourceFolder,~,~] = fileparts(sourcePath);
    imagePath = char(string(imageReference));
    if ~isfile(imagePath)
        imagePath = fullfile(sourceFolder,imagePath);
    end
    if ~isfile(imagePath)
        error('WCC4SM:DocumentationImageMissing', ...
            'Documentation image does not exist: %s',imageReference);
    end
    info = imfinfo(imagePath);
    widthCm = 16;
    heightCm = widthCm * double(info.Height) / double(info.Width);
    item = Image(imagePath);
    item.Width = sprintf('%.2fcm',widthCm);
    item.Height = sprintf('%.2fcm',heightCm);
    imageParagraph = Paragraph();
    imageParagraph.Style = {HAlign('center'), ...
        OuterMargin('0cm','0cm','0.15cm','0.05cm')};
    append(imageParagraph,item);
    append(document,imageParagraph);
    if ~isempty(strtrim(caption))
        captionParagraph = Paragraph(cleanInline(caption));
        captionParagraph.Style = {FontFamily('Microsoft YaHei'), ...
            FontSize('9pt'),Italic(true),HAlign('center'), ...
            OuterMargin('0cm','0cm','0cm','0.3cm')};
        append(document,captionParagraph);
    end
end

function appendStyledParagraph(document,value,isList)
    import mlreportgen.dom.*
    paragraph = Paragraph(value);
    paragraph.Style = {FontFamily('Microsoft YaHei'),FontSize('10.5pt')};
    if isList,paragraph.Style{end+1}=OuterMargin('0.6cm','0cm','0cm','0cm');end
    append(document,paragraph);
end

function appendCodeBlock(document,lines)
    import mlreportgen.dom.*
    paragraph = Paragraph(strjoin(cellstr(lines),newline));
    paragraph.Style = {FontFamily('Consolas'),FontSize('9pt'), ...
        BackgroundColor('#F2F2F2'),OuterMargin('0.5cm','0.5cm','0cm','0cm')};
    append(document,paragraph);
end

function appendTableLine(document,value)
    import mlreportgen.dom.*
    paragraph = Paragraph(cleanInline(value));
    paragraph.Style = {FontFamily('Consolas'),FontSize('8.5pt')};
    append(document,paragraph);
end

function value = cleanInline(value)
    value = regexprep(char(value),'\*\*([^*]+)\*\*','$1');
    value = regexprep(value,'`([^`]+)`','$1');
    value = strrep(value,'  ',' ');
end
