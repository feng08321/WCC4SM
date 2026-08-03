# WCC4SM test baseline

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

## Coverage in the first baseline

- Synthetic symmetric Gaussian peak position, centroid, FWHM and ERW.
- Linear-baseline removal, truncated windows and invalid coordinates.
- Published 17-point calibration regression case.
- Alignment and stable file characteristics of the measured and dark spectra.
- Consistency between the NIST Hg-Ar master and selection mode 01.

The real-spectrum assertions are regression characteristics, not certified
instrument truth. In particular, the dark spectrum contains random noise, so
the tests intentionally verify aggregate and strong-peak properties instead of
locking every corrected sample.

## Files used by the real-data baseline

- `Data/Spectrum_1_8ms_avg50.csv`
- `Data/Spectrum_1_dark_8ms_avg50.csv`
- `NIST_HgAr_comparison_c..lit`
- `WC4SM_reference_selection_mode01.csv`

The selection mode is expected to retain 29 useful lines from the much larger
NIST library. Its `MasterSource` column contains an old absolute path and is
treated as provenance text only; tests and future code must not use it to find
the master library.

One known reference-data boundary is deliberately recorded by the tests:
selection wavelength 772.4000 nm is 0.0207 nm from the nearest NIST wavelength
772.4207 nm. It is just outside the application's documented 0.02 nm matching
tolerance, so the present application may match only 28 of the 29 mode rows.
This should be resolved as a reference-data decision, not hidden by a loose
test tolerance.

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
