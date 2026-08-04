# WCC4SM V0.9 GUI acceptance test

1. Start `WCC4SM_V0_9` and repeat the complete accepted calibration workflow.
2. Confirm the combined V0.9 title fits, every top-toolbar button label is
   complete, and the status area uses the application background with dark text.
3. Load the confirmed NIST master and confirm every Intensity and Order cell is
   displayed as an integer without inconsistent `.0000` suffixes.
4. Fit a model in **Full detector sequence** mode and verify that the final-fit
   summary, equation display, Model Comparison table, and applied-model status
   all show the mode and pixel domain.
5. Export the model and verify that MAT, residual CSV, and equation TXT all
   identify the full-detector mode and its data/calibration domains.
6. Repeat steps 4-5 in **Valid-pixel sequence** mode.
7. Save and reload the session and verify that the mode remains visible and the
   model can be applied to a matching spectrum.
8. Verify that a model from the other explicit mode is rejected.
9. Recheck subwindow guide replacement and pixel/wavelength axis switching.
10. Open Help, refresh the PDF list, read a real PDF and verify the About text.

Acceptance criterion: coordinate semantics are visible without inspecting MAT
internals, all three model exports agree, the release-candidate header and
reference table display consistently, and the accepted numerical behavior
remains unchanged.
