# WCC4SM stage-4 calibrated-performance module

This stage adds `wc4sm_calculate_calibrated_performance` without modifying
`WCC4SM_V0_5_3.m`.

The pure calculation module returns calibrated peak-center wavelength, FWHM,
ERW, their relation and summary statistics, plus wavelength per pixel and its
statistics. Plotting and histogram display controls remain UI responsibilities.

Preserved definitions:

- FWHM maps the left and right half-height coordinates separately and subtracts
  the resulting wavelengths.
- ERW integrates nonnegative dense peak signal in calibrated wavelength
  coordinates and divides by interpolated peak height.
- Pixel wavelength interval is the difference between consecutive calibrated
  pixel wavelengths; only finite positive intervals enter summary statistics.
- Peak outputs are sorted by calibrated center while `SourceIndex` retains the
  mapping to input peak results.

`TestCalibratedPerformanceModule` adds six tests, increasing the suite from 20
to 26 tests. V0.5.3 remains the operational GUI baseline until all 26 pass.
