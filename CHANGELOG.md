# Changelog

## Unreleased

## V1.1 — 2026-09-15

- Refactoring (tech-debt batch D1-E): moved the fourteen file-level utility functions from the bottom of `WCC4SM_V1_0.m` into shared `src/` modules: `wc4sm_colors` (plot palette), `wc4sm_style_axes`, `wc4sm_section_label`, `wc4sm_format_value`, `wc4sm_short_name`, `wc4sm_number_or_nan`, `wc4sm_logical_text`, `wc4sm_clean_matrix`, `wc4sm_poly_normalized_to_natural`, `wc4sm_format_calibration_equation`, `wc4sm_robust_upper_limit`, `wc4sm_min_or_nan`, `wc4sm_max_or_nan`, and `wc4sm_remove_calibration_pair`. The GUI file now contains only the main function and its nested callbacks; behavior is pinned by the new `TestGuiUtilityModules` suite (11 cases). No behavior change.
- Refactoring (tech-debt batch D1-D): extracted the initial-mapping pipeline from the `WCC4SM_V1_0` GUI file into `src/`: `wc4sm_match_ordered_sequence` (dynamic-programming monotonic peak-to-reference alignment), `wc4sm_build_initial_model` (anchor-based provisional polynomial), and `wc4sm_evaluate_wavelength_model` (normalized-polynomial evaluation used at 33 GUI call sites). Covered by the new `TestInitialMappingModules` suite (8 cases). No behavior change.
- Refactoring (tech-debt batch D1-C): moved the three hard-coded built-in Hg-Ar line libraries (Basic 21, Paper Table 1 24-peak, NIM certificate 34) out of the `WCC4SM_V1_0` GUI file into data files under `reference_data/` (`Builtin_HgAr_Basic21.lit`, `Builtin_HgAr_Paper24.lit`, `Builtin_HgAr_NIM34.lit`), loaded via the new `wc4sm_load_builtin_library` module. Library source labels are unchanged so sessions remain compatible; contents are pinned by the new `TestBuiltinLibraries` suite (5 cases). No behavior change.
- Refactoring (tech-debt batch D1-B): removed the dead inline `leaveOneOutDiagnostics` subfunction from `WCC4SM_V1_0`; the GUI already routes all leave-one-out diagnostics through `wc4sm_validate_calibration_loo`. No behavior change.
- Refactoring (tech-debt batch D1-A): extracted the twelve inline state-structure factories from the `WCC4SM_V1_0` GUI file into reusable `src/wc4sm_empty_*` modules (data, reference, line library, peaks, local candidates, peak dataset, calibration pairs, mapping candidates, initial model, final model, calibration models) plus `wc4sm_make_calibration_pair`. All GUI call sites now use the shared modules; field layouts are pinned by the new `TestEmptyStateFactories` suite (12 cases). No behavior change.
- Standardized the 8x8 peak-shape gallery by removing all per-axis tick marks and adding compact Peak ID plus center-wavelength titles (falling back to center pixel without an applied model).
- Extended the wavelength-dependence workspace with selectable Direct/Interpolated/Centroid difference fitting and an all-peak-plot filter for the current calibration set only.
- Added a reversible, analysis-only `Show` exclusion in the all-peak difference table. Manually rejected saturated or otherwise invalid peaks remain traceable in the table, are omitted from both paper-analysis plots, do not modify the calibration set, and persist in Session files.
- Added a Calibrated Performance subview for paper-oriented peak-position wavelength-dependence analysis: a three-series all-detected-peak difference plot, a matched-benchmark Centroid-minus-FWHM-center plot with optional degree 1--3 normalized polynomial fit, synchronized point highlighting, reversible per-row fit exclusion, Session persistence, CSV export, and OPEN FIG support.
- Added peak-position cross-validation overview tabs for simultaneous 2x3 display of all six mismatch metrics, 2x2 display of the four application residual series for the selected calibration row, and a heatmap-aligned 4x4 array of all residual histograms. OPEN FIG preserves each overview as one editable tiled figure.
- Added peak-position cross-validation training-set selection from all matched pairs, the current final model, the selected Model Comparison model, or the selected Set Design candidate. Full fit can now train on a small subset and evaluate on the full matched pool, while LOO remains a training-set leave-one-out diagnostic; Session state and CSV exports preserve the selected source and Train/Eval counts.
- Documentation: established the WCC4SM V1.0 Technical Documentation Baseline — four canonical documents under `docs/`: `WCC4SM_ARCHITECTURE.md` (layers, 67-module src map, data flow), `WCC4SM_METHOD_SPECIFICATION.md` (math definitions for preprocessing, HDR, D/I/F/C peak positions, calibration, LOO, Gap, Influence, Compatibility, cross-validation), `WCC4SM_DATA_DICTIONARY.md` (state-structure fields, ID rules, status enums, file-format index, State five-domain grouping blueprint), and `WCC4SM_VALIDATION.md` (145-test inventory, benchmark cases, known limitations). `docs/README.md` indexes the baseline.
- Documentation (E1): added `reference_data/README.md` provenance index and `NIST_ASD_HgAr_20260910_Metadata.md` for the current 326-row master (20260729 master + 4 weak Hg lines at 390.6371/567.581/612.327/671.634 nm, none removed), closing the provenance gap left by the 2026-09-10 data refresh.
- Documentation (E2): the user workflow manual now explicitly explains why the GUI offers 5 peak-position definitions while the paper compares 4 (Gaussian fit is conditional and excluded from the 4x4 cross-definition matrix).
- Normalization (C2): the three legacy entry points (`WCC4SM_V0_9_3.m`, `WCC4SM_V0_9.m`, `WCC4SM_V0_9_2.m`) now carry explicit LEGACY header comments (frozen, not maintained, use `WCC4SM_V1_0` for new work). They stay in the package root because they resolve `src/`, `reference_data/`, and `docs/` relative to their own location; README and the architecture baseline document this constraint. No behavior change.
- Code quality (C3): established a zero-warning `checkcode` baseline for all 67 `src/` modules — removed 8 stale `%#ok` pragmas, deleted a dead `deleted` assignment in `wc4sm_analyze_point_influence`, dropped redundant initializers in `wc4sm_partition_subset_windows`, and added a justified suppression for the bounded display-only concatenation in `wc4sm_fit_calibration`. New release gate: `tools/check_src_code_quality.m` errors when any src module reports a message. Full regression: 145/145.
- Testing (D1): added `tests/TestGuiSmoke.m` — the first test that launches the real `WCC4SM_V1_0` app and verifies window creation, core controls (66 axes / 20 tables / 102 buttons), and clean close. GUI tests are tagged `GUI` and isolated from the computation suite: `tools/run_regression.m` runs the 145 computation cases (excludes GUI), `tools/run_gui_smoke.m` runs the 3 GUI cases in a separate MATLAB session. Note: uifigure launch is unstable in headless batch on the Zhaoxin online PC (intermittent heap corruption), so GUI smoke is intended for interactive sessions with a display; the computation regression is unaffected.
- CI (D2): added GitHub Actions workflow `.github/workflows/matlab-ci.yml` running `run_regression.m` on push/PR to main (windows-latest, MATLAB R2022a to match the validated reference environment). First run green. README now shows CI/version/platform badges.
- Documentation (D3): added the current formal acceptance doc `docs/WCC4SM_V1.0_测试验证与验收说明_V1.0.md` (two-step automated testing, GUI acceptance covering the V1.0 additions — 8x8 gallery, Calibrated Performance subview, paper peak-difference workspace, cross-validation overview tabs, Gaussian-fit 5th definition — Session/export checks, release criteria, acceptance-record template). It supersedes the V0.9.3 acceptance doc, which is retained as historical with a superseded notice. `docs/README.md` index updated.
- Preparation (C1): added `src/wc4sm_empty_state.m`, the five-domain master state factory (`State.Data/Peaks/Calibration/Design/UI`) that the State-grouping refactor migrates toward. `tests/TestEmptyStateFactories.m` gains 4 cases pinning the domain layout, library loading, and defaults. A usage-site scan of the GUI (~62 closure variables, ~2147 references) informs the per-domain batch sizing.
- Refactor (C1 batch 1/5 — UI domain): migrated 24 scattered UI closure variables (~342 references) into `State.UI.*` — table/axes selections, axis and view modes, and session/file bookkeeping now live in the grouped state struct built by the new `src/wc4sm_empty_state_ui.m` sub-factory. The master factory `wc4sm_empty_state.m` now composes this UI sub-factory. The color palette `C` is kept as a local read-only alias of `State.UI.Colors` (full migration deferred because `C` also appears inside string literals such as 'D-C px'). No behavior change: mtree parse 0 errors, computation regression 149/149, TestV100UiSupport + TestEmptyStateFactories 33/33, checkcode baseline 69 modules zero messages. `TestV100UiSupport` source patterns updated to the new names.
- Refactor (C1 batch 2/5 — Data domain): migrated the 7 data closure variables (`D`, `R`, `L`, `Lbasic`, `Lpaper`, `Lnim`, `Lexternal`; 236 code references) into `State.Data.*` — measured spectrum, external reference spectrum, and the four line-library slots now live in the grouped state struct built by the new `src/wc4sm_empty_state_data.m` sub-factory (composed by `wc4sm_empty_state.m`). Because `D`/`R`/`L` also appear inside string literals (e.g. 'D-C px', 'D RMS', '\D' regex patterns, 'R^2' labels), replacement used a context-aware tokenizer that skips strings, comments, and dot-prefixed field access instead of a blind word-boundary regex. Session save/load field names are unchanged. No behavior change: mtree parse 0 errors; regression and checkcode results recorded at commit time.

## V1.0 — 2026-09-08

- Promoted the paper-support application to the `WCC4SM_V1_0` entry and retained earlier entries for reproducibility.
- Added a full-size 8x8 detected-peak subwindow gallery. Up to 63 detected peaks occupy the first 63 cells and the final cell remains blank for the current dataset; yellow-filled point-line traces use blue outlines for matched benchmark peaks and red outlines for peaks not selected into the benchmark set.
- The gallery follows the main Pixel/Wavelength axis state, redraws after batch analysis or model-axis changes, and opens as one editable 8x8 MATLAB figure.
- Expanded the paper peak-difference workspace with a right-side two-table dataset manager, reversible temporary fit deletion, confirmed calibration-pair deletion, safe restoration from archived reference pairings, three independent upper-plot series toggles, repeat-click highlight clearing, and lower-plot views of outside-set, calibration, and temporary-deletion points with +/-2 and +/-3 residual-STD bands.

## V0.9.3 — 2026-09-01

- Optimized peak-position cross validation by fitting once per calibration-method row (and once per held-out row sample for LOO), then reusing each model across all application-method columns; the result now reports calibration fit count and elapsed time.
- Added a guarded cross-validation run state: the run and related controls are disabled during calculation, a modal indeterminate progress dialog blocks duplicate interaction, and cleanup restores the controls after success, failure, or interruption.
- Added a four-by-four peak-position cross-validation workspace that separates calibration and application peak definitions, supports Full fit and LOO, common-intersection and pairwise-available pools, RMSE/Bias/STD/P95/MAX/Slope matrices, selected-cell or diagonal residual inspection, CSV export, OPEN FIG, and Session persistence.
- Added an explicit V0.9.3 application entry while retaining V0.9.2 as a compatibility wrapper, and updated the About dialog and authoritative documentation set.
- Added a full-size, four-chart Peak Position Differences subview: one shared difference-series selector synchronizes the trend and configurable distribution histogram; a selectable no-fit or degree 1/2/3 direct peak-position mapping runs from FWHM center to Direct, Centroid, or Interpolated position; and an independently configurable mapping-fit residual histogram completes the view. Scatter plots use normal-size solid markers, with pixel/nm modes, data tips, OPEN FIG support, Session-persisted display settings, and migration of earlier fit-target values.
- Unified polynomial-degree controls at an upper limit of 20, made the influence scan maximum user-configurable, and constrained actual scans by the sample counts required for LOO and nested deletion LOO.
- Changed full-set model-order Fit/LOO plots to logarithmic Y axes and added across-order influence plus full/deleted-model Fit/LOO diagnostic curves.
- Added point-deleted model LOO RMSE and pooled deletion Fit/LOO RMSE summaries while keeping dimensionless RMS influence explicitly separate.
- Fixed Point Influence order plots to enforce logarithmic axes and made OPEN FIG follow the active Per-point, Across orders, or Set replacement subview without opening empty legacy axes.
- Restored the dedicated two-curve Full Fit versus LOO order view, while retaining separate four-curve deletion-stability and influence-statistics views.
- Added signed Full-set and pooled point-deleted generalization gaps (LOO RMSE minus Fit RMSE) to the order table and a dedicated order-scan plot.
- Added the first-stage Window Partition workspace with equal-wavelength and equal-cumulative-influence rules, deterministic discrete cut indices, window statistics, linked residual/influence plots, Session persistence and CSV export; no representative samples are selected automatically.
- Reorganized the V0.9.3 documentation into authoritative user-workflow, algorithm-and-metric, software-architecture, and test-acceptance manuals, with a revised documentation index and explicit links to the Set Design specialist guide.
- Added centroid-center symmetry recommendations with configurable pixel threshold and symmetry-recommended benchmark pool filtering.
- Added fixed full-benchmark RMSE Add-One validation and RMSE-thresholded seed replacement recommendations.
- Added Fit/LOO/All matched residual modes and reset scale control in Model Comparison.
- Added an independent Set Design workspace with influence-ranked deterministic subset generators, fixed full-pool scoring, dual-threshold epsilon cover, and manually confirmed one-layer-at-a-time backward Beam Search.
- Confirmed Set Design candidates can be sent to Add-One or explicitly refitted with full LOO diagnostics before manual addition to Model Comparison.
- Added a selected-subset member table, an in-app parameter guide, full Set Design/Beam session persistence, and MAT/CSV exports for pools, candidate metrics, memberships, and Beam layers.


- Replaced exhaustive `C(n,5)` seed-combination ranking with five-round, one-for-one seed replacement validation based on the manually selected five-point seed set.
- Each replacement candidate is compared with the original seed set on the same fixed non-seed validation pool and reports the RMSE change.
## V0.9.2 — 2026-08-17

- Adds Start X, End X and Reset Range controls for the full-spectrum view.
- Adds a matching-annotation visibility toggle while retaining detected-peak marker control.
- Displays imported filenames literally so underscores are not interpreted as subscripts.
- Resets the full-spectrum range when loading data or switching coordinate axes.
- Adds four source-level regression checks for the new UI support.

## V0.9 — 2026-08-04

- Keeps `NIST_ASD_HgAr_20260729.lit` as the only confirmed NIST master and
  `WCC4SM_NIST_ASD_HgAr_20260729_Mode01.csv` as its Mode01 selection.
- Removes the unconfirmed master filename and two obsolete/intermediate mode
  CSV files from the active package.
- Updates tests and documentation so all 29 Mode01 wavelengths match the dated
  NIST master exactly.
- Organizes the confirmed master, Mode01 and metadata under `reference_data/`,
  with the Avantes example under `reference_data/examples/`.
- Opens the reference-master file chooser in `reference_data/` by default.
- Keeps only the application and regression-test MATLAB entries at repository
  root; moves implementation modules to `src/`, test spectra to `test_data/`,
  and supporting specifications and acceptance records to `docs/`.
- Adds Apache License 2.0 licensing, project attribution and an About dialog.
- Adds a Help window that recursively lists PDFs under `docs/`, refreshes the
  list and opens the selected document with the system PDF reader.
- Adds a Windows EXE build script that does not bundle MATLAB Runtime or create
  an installer, while preserving external `docs/` and `reference_data/` folders.
- Consolidates the header title and version to free space for full toolbar
  labels, and uses the application background with dark status text.
- Displays reference intensity and diffraction order as integers; the confirmed
  NIST master already stores integer intensity values and remains unchanged.

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
