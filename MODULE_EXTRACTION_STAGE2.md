# WCC4SM stage-2 side-by-side modules

This stage adds candidate modules without modifying or connecting them to
`WCC4SM_V0_5_1.m`. The existing application remains the operational baseline.

## New modules

- `wc4sm_read_spectrum_file`: reads one- or two-column spectra and creates the
  current spectrum data structure without accessing UI controls.
- `wc4sm_read_dark_spectrum`: reads one- or two-column dark spectra and aligns
  two-column data to measured coordinates using linear interpolation.
- `wc4sm_preprocess_spectrum`: performs mutually exclusive dark/manual-baseline
  subtraction, optional negative clamping, and normalization.

## Compatibility contract

The modules intentionally reproduce these V0.5.1 rules:

1. A measured X column must be strictly increasing.
2. One-column dark data must match the measured sample count.
3. Two-column dark data must cover the full measured X range.
4. Active dark data override the manual constant baseline.
5. Negative clamping occurs after subtraction.
6. Normalization divides by the corrected maximum when it is positive;
   otherwise it returns zeros.

## Validation before integration

Run `run_wc4sm_tests`. The new `TestSpectrumPreprocessingModules` class is
discovered automatically, increasing the suite from 8 to 14 tests. Integration
into the GUI should be considered only after all 14 pass on the target MATLAB
computer and the current application still loads and subtracts the example
spectra correctly in a manual smoke test.
