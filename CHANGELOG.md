# Changelog

## Unreleased — reference asset cleanup

- Keeps `NIST_ASD_HgAr_20260729.lit` as the only confirmed NIST master and
  `WCC4SM_NIST_ASD_HgAr_20260729_Mode01.csv` as its Mode01 selection.
- Removes the unconfirmed master filename and two obsolete/intermediate mode
  CSV files from the active package.
- Updates tests and documentation so all 29 Mode01 wavelengths match the dated
  NIST master exactly.

## V0.6.2 — development

- Makes pixel-coordinate mode, data domain, and calibration domain visible in
  the final-fit summary and equation display.
- Adds pixel mode and domain columns to Model Comparison.
- Shows coordinate mode and domain in the applied-model status.
- Writes coordinate mode and domains to model equation TXT and residual CSV
  exports; MAT exports continue to preserve structured metadata.
- Ignores local `result/` analysis output.
- Removes duplicate historical source snapshots and obsolete intermediate
  documents from the active tree. They remain available from Git tag `v0.6.1`.

## V0.6.1 — stable baseline

- Added explicit full-detector and valid-pixel sequence modes.
- Added model coordinate metadata and mode-compatibility rejection.
- Added live weak-peak subwindow guides and corrected hidden-line redraw.
- Corrected pixel/wavelength axis refitting after coordinate switches.
- Passed 37 automated tests and complete operator GUI acceptance.

## V0.6.0

- Added complete save/load session workflows, provenance, validation, rollback,
  and view restoration.

## V0.5.2–V0.5.4

- Extracted spectrum preprocessing, calibration, validation, calibrated
  performance, and session-related numerical modules from the original GUI.

## V0.5.1 and earlier

- Established the initial peak-analysis and wavelength-calibration application
  and its published calibration regression baseline.
