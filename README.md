# WCC4SM

Wavelength Characterization and Calibration for Spectrometer (WCC4SM) is a
MATLAB application for spectrum preprocessing, peak characterization,
reference-line matching, wavelength calibration, model validation, calibrated
performance analysis, and complete analysis-session restoration.

## Versions

The current stable release is **WCC4SM V0.9.2** (Git tag `v0.9.2`). It includes the accepted
V0.6.2 calibration workflow, organized reference assets, Apache License 2.0,
PDF help, About information, and Windows EXE deployment support. The immutable
`v0.6.2` and `v0.6.1` tags remain rollback baselines. Start V0.9 from MATLAB
R2022a or later:

```matlab
WCC4SM_V0_9_2
```

V0.9 distinguishes two one-based pixel coordinate systems:

- **Full detector sequence** for uncalibrated instruments that expose every
  detector pixel.
- **Valid-pixel sequence** for instruments that output only their usable,
  cropped pixel sequence.

Calibration models record their coordinate mode and pixel domain. Explicitly
incompatible models are rejected instead of being silently shifted.

## Validation

Run the non-GUI regression suite from the package root:

```matlab
results = run_wc4sm_tests;
```

The regression suite currently has 41 tests. The V0.9.2 GUI acceptance
procedure is in `docs/V0_9_2_GUI_TEST.md`.

The first optimization-analysis layer is available as non-GUI MATLAB modules:
`wc4sm_analyze_model_order`, `wc4sm_analyze_add_one`, and
`wc4sm_plot_optimization_diagnostics`. These return complete iteration
histories for numerical review before integration into a dedicated GUI tab.

## License and contact

WCC4SM is licensed under the Apache License 2.0. Copyright 2026 Zheng Feng.
Project contact: `feng1214@126.com`. NewOptic is an unregistered personal
project label of Zheng Feng. See `LICENSE` and `NOTICE` for details.

## Windows executable

The optional Windows executable is built without an installer and without an
embedded MATLAB Runtime. The target computer must have MATLAB or the matching
MATLAB Runtime installed. From the package root, run:

```matlab
addpath('tools');
build_windows_exe
```

The generated `build/WCC4SM_V0.9_Windows_x64/` folder includes the executable
and external `docs/` and `reference_data/` directories. These external
directories remain replaceable so users can add PDF help documents and
reference assets.

## Data and privacy

The repository contains measurement and reference assets required by regression
tests. Saved WCC4SM session files are excluded because they may contain operator,
instrument, path, and experiment metadata.

## Baseline policy

The `v0.6.1` Git tag is the immutable rollback baseline. Source snapshots from
older releases are retrieved from Git rather than kept as duplicate programs in
the active development tree.

## Documentation

Formal V0.9 documentation is maintained in `docs/` as reviewable Markdown
sources with generated DOCX copies:

- software architecture and technical design;
- operator user manual;
- input/output data-format specification;
- requirements–design–test traceability matrix.

Format-specific supporting specifications are also maintained in `docs/`.
See `docs/README.md` for the complete documentation map and regeneration
instructions. Numerical implementation modules are organized under `src/`,
while the two root-level MATLAB files remain the application and test entries.
