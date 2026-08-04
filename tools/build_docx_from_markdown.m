function outputPaths = build_docx_from_markdown(sourcePaths)
%BUILD_DOCX_FROM_MARKDOWN Build maintainable DOCX copies of project Markdown.
% Supports headings, paragraphs, bullet/numbered items, fenced code and simple
% pipe-table text. Markdown remains the authoritative version-controlled source.

    arguments
        sourcePaths {mustBeText}
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
        outputPath = fullfile(folder,[stem '.docx']);
        document = Document(outputPath,'docx');
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
