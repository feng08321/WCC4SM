# WCC4SM

Wavelength Characterization and Calibration for Spectrometer (WCC4SM) is a
MATLAB application for spectrum preprocessing, peak characterization,
reference-line matching, wavelength calibration, model validation, calibrated
performance analysis, and complete analysis-session restoration.

## Versions

The current stable baseline is **WCC4SM V0.6.2** (Git tag `v0.6.2`). It makes
pixel-coordinate metadata visible in the GUI and every model export. V0.6.1
remains the previous rollback tag. Start V0.6.2 from MATLAB R2022a or later:

```matlab
WCC4SM_V0_6_2
```

V0.6.2 distinguishes two one-based pixel coordinate systems:

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
procedure is in `docs/V0_6_2_GUI_TEST.md`.

## Data and privacy

The repository contains measurement and reference assets required by regression
tests. Saved WCC4SM session files are excluded because they may contain operator,
instrument, path, and experiment metadata.

## Baseline policy

The `v0.6.1` Git tag is the immutable rollback baseline. Source snapshots from
older releases are retrieved from Git rather than kept as duplicate programs in
the active development tree.

## Documentation

Formal V0.6.2 documentation is maintained in `docs/` as reviewable Markdown
sources with generated DOCX copies:

- software architecture and technical design;
- operator user manual;
- input/output data-format specification;
- requirements–design–test traceability matrix.

Format-specific supporting specifications are also maintained in `docs/`.
See `docs/README.md` for the complete documentation map and regeneration
instructions. Numerical implementation modules are organized under `src/`,
while the two root-level MATLAB files remain the application and test entries.
