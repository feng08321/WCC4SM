# WCC4SM V0.5.3 calibration smoke test

1. Run `run_wc4sm_tests`; expect 20/20 passing.
2. Open the same measured and dark spectra in V0.5.2 and V0.5.3.
3. Use the same confirmed peaks, reference library, selection mode, pair set,
   peak-position method and polynomial degree.
4. Fit the final calibration model in both versions.
5. Compare equation, normalized coefficients, point count, mean residual, STD,
   RMS, maximum absolute residual, LOO RMS, LOO maximum and maximum deletion
   influence.
6. Apply the models and compare the wavelength axis and calibrated-performance
   plots.
7. Export the V0.5.3 model and confirm MAT, residual CSV and equation TXT files
   are produced.

Acceptance criterion: numerical differences should be at floating-point roundoff
level only; point ordering and Peak IDs must remain aligned.
