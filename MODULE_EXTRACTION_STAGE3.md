# WCC4SM stage-3 calibration modules

This stage adds candidate calibration modules without modifying
`WCC4SM_V0_5_2.m`.

## New modules

- `wc4sm_fit_calibration`: sorted polynomial fitting, natural-pixel equation,
  residual statistics and model assembly.
- `wc4sm_validate_calibration_loo`: leave-one-out residual and maximum deletion
  influence over an explicit evaluation pixel range.

## Preserved numerical definitions

- Residual = reference wavelength - fitted wavelength.
- STD uses MATLAB's sample standard deviation (`std`).
- RMS = square root of the mean squared residual.
- Every LOO model uses the same polynomial degree as the full model.
- Deletion influence is the maximum absolute wavelength difference between the
  full and deleted-point models over the supplied evaluation pixels.
- Fitting requires at least `degree + 2` calibration points, matching V0.5.2.

## Validation

`TestCalibrationModules` adds six tests: exact synthetic cubic recovery, both
published peak-position cases, independent LOO replication, peak-ID sorting and
invalid-input rejection. `run_wc4sm_tests` should therefore increase from 14 to
20 tests. V0.5.2 remains the operational GUI baseline until all 20 pass.
