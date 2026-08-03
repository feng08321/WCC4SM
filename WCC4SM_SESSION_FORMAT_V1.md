# WCC4SM session format 1.0

The MAT file contains one top-level variable named `WCC4SMSession`.

Top-level fields record application identity, format/software versions, created
and modified timestamps, metadata and workflow state. State contains spectrum,
detected peaks, confirmed peak snapshots, reference lines, calibration pairs,
initial/final models, model history, applied model and UI settings.

Reference provenance is independent of the selected line subset and records:

- master library filename and version;
- authority/source, such as NIST, Avantes or a national metrology institute;
- air/vacuum wavelength medium;
- selection mode filename and version;
- free-form traceability notes.

Missing recommended provenance generates validation warnings rather than making
an otherwise useful research session unsavable. Structural inconsistency,
length mismatch, invalid model fields and unsupported major format versions are
errors.

The stage-5 implementation is side-by-side only and does not modify
`WCC4SM_V0_5_4.m`. Seven tests increase the suite from 26 to 33 tests. GUI
integration should begin only after all 33 pass on the target MATLAB computer.
