# WCC4SM V0.5.2 GUI smoke test

Run this after `run_wc4sm_tests` reports 14/14 passing.

1. Start `WCC4SM_V0_5_1` and load `Data/Spectrum_1_8ms_avg50.csv` as wavelength
   input with natural pixel start 0. Record the sample count and plot.
2. Load `Data/Spectrum_1_dark_8ms_avg50.csv`. Confirm that manual baseline is
   disabled and the corrected strong peak near 436.90 nm displays normally.
3. Clear the dark spectrum. Confirm that manual baseline becomes enabled.
4. Set a nonzero manual baseline and toggle negative-value clamping.
5. Repeat steps 1-4 in `WCC4SM_V0_5_2`.
6. With identical peak-detection settings, run detection in both versions and
   compare the detected peak count and principal peak locations.

Acceptance criteria: both versions have the same sample count, corrected
signal behavior, dark/manual-baseline exclusivity and peak-detection result.
