# WCC4SM V0.6.2 baseline acceptance report

- Acceptance date: 2026-08-04
- MATLAB baseline: R2022a
- Candidate branch: `agent/v062-pixel-metadata-cleanup`
- Candidate commit before acceptance record: `d107551`

## Automated verification

- MATLAB static parse: 0 syntax messages
- Non-GUI regression suite: 37 passed, 0 failed, 0 incomplete
- GUI initialization smoke test: passed

## Operator verification

The project operator completed a representative V0.6.2 GUI workflow and
reported no functional problems. Exported calibration data was inspected and
confirmed to contain the selected pixel-coordinate mode information.

The acceptance also relies on the previously completed V0.6.1 full-workflow
verification for spectrum/dark loading, peak review, reference pairing,
calibration fitting, LOO/model review, model application, calibrated performance
and session save/reload behavior.

## Baseline decision

V0.6.2 is accepted for merge to `main` and release as the next stable baseline.
Local `result/` experiment output is excluded from version control. Historical
source snapshots removed from the active tree remain recoverable from Git tag
`v0.6.1`.
