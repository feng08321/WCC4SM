# WCC4SM V0.6.0 session restoration test

1. Run `run_wc4sm_tests`; expect 33/33 passing.
2. Start V0.6.0 and complete a representative workflow through final-model
   fitting, LOO review, model application and calibrated performance.
3. Click SAVE SESSION. Fill operator/instrument fields and record NIST as the
   authority, the NIST master filename, Air or Vacuum wavelength medium, and the
   selection-mode filename/version.
4. Close V0.6.0 completely and start it again.
5. Click LOAD SESSION and select the saved MAT file.
6. Verify spectrum/dark state, peak counts and confirmations, reference lines,
   pairs, final/model-history/applied model, residuals, LOO values and wavelength
   axis.
7. Refresh Calibrated Performance and compare the four plots with the pre-save
   state.
8. Modify one pair or model setting, refit, and save a second session.
9. Load an unrelated MAT file and confirm that an error appears while the current
   valid session remains unchanged.

Acceptance criterion: the restored session can continue analysis without
repeating data loading, peak confirmation or reference pairing.
