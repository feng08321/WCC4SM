# WCC4SM V0.9 documentation set

## Formal documents

| Document | Markdown source | DOCX |
|---|---|---|
| 软件架构与功能技术说明书 | `WCC4SM_V0.9_软件架构与功能技术说明书_V1.0.md` | matching `.docx` |
| 软件使用说明书 | `WCC4SM_V0.9_软件使用说明书_V1.1.md` | matching `.docx` and `.pdf` |
| 公开发布审计 | `V0_9_PUBLIC_RELEASE_AUDIT.md` | Markdown |
| 输入输出数据格式规范 | `WCC4SM_INPUT_OUTPUT_DATA_FORMATS_V1.md` | matching `.docx` |
| 需求—设计—测试追踪矩阵 | `WCC4SM_V0_9_REQUIREMENTS_TRACEABILITY_MATRIX.md` | matching `.docx` |

Markdown is the authoritative source for review and change tracking. DOCX
copies are generated delivery artifacts.

## Supporting specifications

- `WCC4SM_PIXEL_COORDINATE_SPEC_V1.md`
- `WCC4SM_CALIBRATION_MODEL_FORMAT_V1.md`
- `WCC4SM_SESSION_FORMAT_V1.md`
- `WCC4SM_Reference_Data_Model_V0_2F.txt`
- `TESTING.md`
- `V0_9_GUI_TEST.md`
- `WCC4SM_V0_6_2_ACCEPTANCE_REPORT.md`
- `WCC4SM_V0_9_ACCEPTANCE_REPORT.md`
- `WCC4SM_WINDOWS_EXE_BUILD_V1.md`

## Regenerate DOCX

MATLAB Report Generator is required. From the package root:

```matlab
addpath('tools');
sources = {
    fullfile('docs','WCC4SM_V0.9_软件架构与功能技术说明书_V1.0.md')
    fullfile('docs','WCC4SM_V0.9_软件使用说明书_V1.1.md')
    fullfile('docs','WCC4SM_INPUT_OUTPUT_DATA_FORMATS_V1.md')
    fullfile('docs','WCC4SM_V0_9_REQUIREMENTS_TRACEABILITY_MATRIX.md')
};
build_docx_from_markdown(sources);
```

After changing a Markdown source, regenerate the corresponding DOCX in the same
commit so both representations describe the same software version.

## User training medium

The formal user manual is the controlled reference for functions, terminology,
file formats and safety notes. Normal operator onboarding should use a separate
step-by-step teaching video that demonstrates the complete workflow with real
screen actions. Video scripts and recordings may evolve independently, but
must not contradict the accepted software version or this documentation set.

PDF manuals, standards and papers placed anywhere below this folder are listed
by the application's Help window. Only redistribute third-party PDFs when their
license or permission allows it; the WCC4SM Apache License 2.0 does not relicense
those documents.
