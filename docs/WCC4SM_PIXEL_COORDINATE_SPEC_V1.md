# WCC4SM pixel-coordinate specification 1.0

WCC4SM separates MATLAB array indices from the pixel coordinate used by a
wavelength-calibration equation. MATLAB array indices are implementation details
and always start at 1. User-visible pixel sequences also start at 1, but have
two different physical meanings.

## Full detector sequence

Use `Full detector sequence` when an uncalibrated instrument exposes every
detector pixel. Polynomial coefficients use that complete one-based detector
sequence.

## Valid-pixel sequence

Use `Valid-pixel sequence` when instrument firmware outputs only its cropped,
usable samples. Pixel 1 is the first sample of that valid sequence, not
necessarily the first physical detector element.

The two modes may have the same numerical starting value but are not
interchangeable. WCC4SM rejects application of a model carrying one explicit
mode to data carrying the other. It does not infer an offset or silently modify
coefficients.

Each new model records its mode, complete data domain, sample count and fitted
calibration-point domain. Legacy models without this metadata remain readable
but cannot provide the same traceability guarantee.
