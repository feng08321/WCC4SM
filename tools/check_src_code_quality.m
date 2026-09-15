function check_src_code_quality()
%CHECK_SRC_CODE_QUALITY Zero-warning checkcode baseline for src/ modules.
%   Runs checkcode (-id) on every src/wc4sm_*.m module and errors when any
%   message is reported. The baseline is zero warnings: fix the code, or add
%   a justified %#ok<SUPPRESS> pragma with a comment when a message is a
%   deliberate design choice. Run before every release tag (see
%   docs/WCC4SM_VALIDATION.md).

    packageRoot = fileparts(fileparts(mfilename('fullpath')));
    files = dir(fullfile(packageRoot,'src','wc4sm_*.m'));
    total = 0;
    for k = 1:numel(files)
        info = checkcode(fullfile(files(k).folder,files(k).name),'-id');
        for i = 1:numel(info)
            total = total + 1;
            fprintf('%s:%d [%s] %s\n',files(k).name,info(i).line, ...
                info(i).id,info(i).message);
        end
    end
    if total > 0
        error('WCC4SM:CodeQualityBaseline', ...
            'checkcode reported %d message(s) in src/ (zero-warning baseline).',total);
    end
    fprintf('checkcode baseline OK: %d src modules, zero messages.\n',numel(files));
end
