# WCC4SM regression test baseline

This test suite protects the numerical behavior of WCC4SM before the main
program is split into modules. It does not open the graphical application and
does not change any measurement or reference data.

## Run

Copy the complete package to a MATLAB-compatible computer, set the MATLAB
current folder to the package root, and run:

```matlab
results = run_wc4sm_tests;
```

The supported baseline is MATLAB R2022a or later. The current tests use base
MATLAB only; future peak-detection tests will also require Signal Processing
Toolbox.

## Current coverage

- Synthetic symmetric Gaussian peak position, centroid, FWHM and ERW.
- Linear-baseline removal, truncated windows and invalid coordinates.
- Published 17-point calibration regression case.
- Alignment and stable file characteristics of the measured and dark spectra.
- Consistency between the NIST Hg-Ar master and selection mode 01.
- Polynomial calibration, leave-one-out validation and model identity.
- Calibrated spectral-performance calculations.
- Versioned session validation, round-trip restoration and pixel-coordinate
  metadata preservation.

The current suite contains 37 non-GUI tests. GUI behavior is covered by the
version-specific acceptance procedure because file dialogs, interactive peak
review and figure editing require operator interaction.

The real-spectrum assertions are regression characteristics, not certified
instrument truth. In particular, the dark spectrum contains random noise, so
the tests intentionally verify aggregate and strong-peak properties instead of
locking every corrected sample.

## Files used by the real-data baseline

- `Data/Spectrum_1_8ms_avg50.csv`
- `Data/Spectrum_1_dark_8ms_avg50.csv`
- `reference_data/NIST_ASD_HgAr_20260729.lit`
- `reference_data/WCC4SM_NIST_ASD_HgAr_20260729_Mode01.csv`

The confirmed selection mode retains 29 useful lines from the dated NIST master.
Every mode wavelength is an exact value in that master, including 772.4207 nm,
and `MasterSource` identifies the master by relative filename.

## Interpreting results

- `Passed`: the protected behavior remains stable.
- `Failed`: save the full MATLAB diagnostic and send it back for review.
- `Incomplete`: usually indicates a MATLAB environment, path, or license issue.

Do not update expected values merely to make a failed test pass. First decide
whether the difference is an intended algorithm improvement, a data change, or
a regression. Approved baseline changes should be recorded in the ChangeLog.

Peak-location tolerances reflect the numerical method and sampling scale. They
must not demand machine-precision equality from interpolation on a finite dense
grid; the synthetic linear-baseline test currently protects center and centroid
to 0.001 pixel.
