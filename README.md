# WCC4SM

Wavelength Characterization and Calibration for Spectrometer (WCC4SM) is a
MATLAB application for spectrum preprocessing, peak characterization,
reference-line matching, wavelength calibration, model validation, calibrated
performance analysis, and complete analysis-session restoration.

## Versions

The published stable baseline is **WCC4SM V0.6.1** (Git tag `v0.6.1`). The
current development line is **V0.6.2**, which makes pixel-coordinate metadata
visible in the GUI and every model export. Start the development version from
MATLAB R2022a or later with:

```matlab
WCC4SM_V0_6_2
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

The regression suite currently has 37 tests. The current GUI acceptance
procedure is in `V0_6_2_GUI_TEST.md`.

## Data and privacy

The repository contains measurement and reference assets required by regression
tests. Saved WCC4SM session files are excluded because they may contain operator,
instrument, path, and experiment metadata.

## Baseline policy

The `v0.6.1` Git tag is the immutable rollback baseline. Source snapshots from
older releases are retrieved from Git rather than kept as duplicate programs in
the active development tree.
