# WCC4SM

Wavelength Characterization and Calibration for Spectrometer (WCC4SM) is a
MATLAB application for spectrum preprocessing, peak characterization,
reference-line matching, wavelength calibration, model validation, calibrated
performance analysis, and complete analysis-session restoration.

## Stable baseline

The current stable baseline is **WCC4SM V0.6.1**. Start it from MATLAB R2022a
or later with:

```matlab
WCC4SM_V0_6_1
```

V0.6.1 distinguishes two one-based pixel coordinate systems:

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

The V0.6.1 baseline has 37 regression tests. GUI acceptance procedures are in
`V0_6_0_SESSION_GUI_TEST.md` and `V0_6_1_GUI_TEST.md`.

## Data and privacy

The repository contains measurement and reference assets required by regression
tests. Saved WCC4SM session files are excluded because they may contain operator,
instrument, path, and experiment metadata.

## Baseline policy

`WCC4SM_V0_6_1.m` is the frozen stable baseline. Subsequent development should
use a new version file or a dedicated development branch.
