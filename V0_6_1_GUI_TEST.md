# WCC4SM V0.6.1 GUI acceptance test

1. Start `WCC4SM_V0_6_1` and verify that the header status is readable before
   and after loading a spectrum.
2. Select **Full detector sequence**, load an uncalibrated full-detector file,
   fit a model, and verify that the saved model records that mode and its pixel
   range.
3. Select **Valid-pixel sequence**, load a cropped effective-pixel file, fit a
   model, and verify that its local sequence starts at 1 and records that mode.
4. Try to apply either explicit model to data loaded in the other mode. Confirm
   that WCC4SM rejects it with a pixel-sequence mismatch rather than applying a
   shifted equation.
5. Open **OPEN SUBWINDOW SEARCH**. Change start/end pixels and verify that two
   dashed vertical lines update on the full-spectrum plot. Apply a wavelength
   model and verify that the lines remain at the corresponding spectral samples.
6. Close the subwindow dialog and verify that both guide lines disappear.
7. Verify that Calibration Fit no longer contains the duplicate combined
   residual-popup button, and that header **OPEN FIG** still opens the fit,
   residual and histogram plots.
8. Save and reload sessions created in both modes and confirm that their model
   mode and pixel ranges are restored.

Acceptance criterion: pixel-sequence semantics are explicit and preserved, no
model is silently applied across incompatible modes, and all display changes
behave without affecting the calibration results.
