# WCC4SM

[![MATLAB CI](https://github.com/feng08321/WCC4SM/actions/workflows/matlab-ci.yml/badge.svg?branch=main)](https://github.com/feng08321/WCC4SM/actions/workflows/matlab-ci.yml)
[![MATLAB R2022a](https://img.shields.io/badge/MATLAB-R2022a-blue)](https://www.mathworks.com/)
[![Platform](https://img.shields.io/badge/platform-Windows-lightgrey)]()

Wavelength Characterization and Calibration for Spectrometer (WCC4SM) is a
MATLAB application for spectrum preprocessing, peak characterization,
reference-line matching, wavelength calibration, model validation, calibrated
performance analysis, and complete analysis-session restoration.

## Versions

The current paper-support release is **WCC4SM V1.1**. V1.1 keeps the V1.0
feature set and behavior while reorganizing the implementation: all shared
algorithms, state factories, built-in line libraries, and GUI utilities now
live as tested modules under `src/`, and the Hg-Ar reference data was
refreshed from the 2026-09-10 NIST ASD query. V1.0 introduced peak-position
difference diagnostics, peak-position cross validation, model-order and
influence analysis, rule-based subset design, window partitioning, and staged
backward Beam Search. Start it from MATLAB R2022a or later:

```matlab
WCC4SM_V1_0
```

Use `WCC4SM_V1_0` for new work. `WCC4SM_V0_9_3` and the older V0.9 / V0.9.2
entries are **frozen legacy snapshots** (marked LEGACY in their file headers):
they are kept only to reproduce prior workflows and results and are not
maintained. A release
tag should be created only after final regression and GUI acceptance.

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

The suite is discovered dynamically; the release criterion is that every
discovered test passes with no failed or incomplete result. The latest complete
regression run on 2026-09-15 passed all 145 tests. The current GUI
acceptance procedure is in
`docs/WCC4SM_V0.9.3_测试验证与验收说明_V1.0.md`.

The application includes dedicated workspaces for optimization, point
influence, Set Design, and peak-position cross validation. Cross validation
separates the peak-position definition used to calibrate a model from the
definition used during application, and reports the resulting mismatch matrix.

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

The generated `build/WCC4SM_V1.0_Windows_x64/` folder includes the executable
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

The V1.0 release note and the V0.9.3-derived authoritative algorithm manuals
are maintained in `docs/` as reviewable Markdown
sources. DOCX/PDF copies are generated only when a release requires them:

- software architecture and technical design;
- operator user manual;
- input/output data-format specification;
- requirements–design–test traceability matrix.

Format-specific supporting specifications are also maintained in `docs/`.
See `docs/README.md` for the complete documentation map and regeneration
instructions. Numerical implementation modules are organized under `src/`,
while the root-level MATLAB files provide the V1.0 application entry, retained
historical entries, and the regression-test entry.
