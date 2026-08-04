# WCC4SM session format 1.x

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

V0.6.1 and later sessions may include pixel-coordinate semantics in three
places:

- `State.UISettings.PixelCoordinateMode` preserves the selected GUI mode;
- `State.Spectrum.PixelCoordinateMode`, `PixelFirst` and `PixelLast` describe
  the loaded data sequence;
- final/applied models preserve `PixelCoordinateMode`, `PixelFirst`,
  `PixelLast`, `PixelCount`, `CalibrationPixelFirst` and
  `CalibrationPixelLast`.

Supported explicit modes are `Full detector sequence` and
`Valid-pixel sequence`. Older V0.6.0 sessions without these fields remain
loadable and are treated as legacy natural-pixel coordinates. Missing legacy
fields do not justify silently shifting polynomial coefficients.

The session format major version remains 1 because these fields are backward-
compatible additions. The current regression suite contains 37 tests.
