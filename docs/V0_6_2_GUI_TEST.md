# WCC4SM V0.6.2 GUI acceptance test

1. Start `WCC4SM_V0_6_2` and repeat the complete V0.6.1 calibration workflow.
2. Fit a model in **Full detector sequence** mode and verify that the final-fit
   summary, equation display, Model Comparison table, and applied-model status
   all show the mode and pixel domain.
3. Export the model and verify that MAT, residual CSV, and equation TXT all
   identify the full-detector mode and its data/calibration domains.
4. Repeat steps 2–3 in **Valid-pixel sequence** mode.
5. Save and reload the session and verify that the mode remains visible and the
   model can be applied to a matching spectrum.
6. Verify that a model from the other explicit mode is rejected.
7. Recheck subwindow guide replacement and pixel/wavelength axis switching.

Acceptance criterion: coordinate semantics are visible without inspecting MAT
internals, all three model exports agree, and V0.6.1 numerical behavior remains
unchanged.
