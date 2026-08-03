# WCC4SM V0.5.4 calibrated-performance smoke test

1. Run `run_wc4sm_tests`; expect 26/26 passing.
2. Complete or import the same calibration workflow in V0.5.3 and V0.5.4.
3. Use the same confirmed peak dataset and calibration model.
4. Open Calibrated Performance and compare:
   - FWHM and ERW versus wavelength;
   - FWHM versus ERW fit and R-squared;
   - FWHM histogram, N, mean, median, STD and range;
   - pixel wavelength interval mean, minimum and maximum.
5. Test Auto full and Manual histogram ranges and several bin counts.
6. Use OPEN FIG and confirm that all four plots open normally.

Acceptance criterion: numerical results match V0.5.3 at floating-point
roundoff level, and plotting/interactions remain unchanged.
