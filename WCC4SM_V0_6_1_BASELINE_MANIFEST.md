# WCC4SM V0.6.1 baseline manifest

- Baseline date: 2026-08-03
- Entry point: `WCC4SM_V0_6_1.m`
- Supported MATLAB baseline: R2022a or later
- Session format major version: 1
- Automated validation: 37 passed, 0 failed, 0 incomplete
- Manual validation: complete application workflow and V0.6.1 guide-line fix
  confirmed by the project operator

## Baseline scope

The baseline contains the versioned GUI programs, extracted numerical and
session modules, regression tests, test data, reference-line assets, change
logs, GUI acceptance procedures, and existing technical/user documentation.

The following local artifacts are intentionally excluded from version control:

- saved WCC4SM session MAT files;
- MATLAB logs, autosave, temporary, and backup files;
- editor-specific state;
- local timestamped test notes.

## Stability rule

`WCC4SM_V0_6_1.m` and its accepted test expectations are frozen. Corrections or
new behavior must begin in a later version and retain V0.6.1 as the rollback
baseline.
