# WCC4SM calibration-model export format 1.0

Saving a final model creates three files with a common stem.

## MAT

The MAT file contains `CalibrationModel`, `CalibrationPairs` and
`ReferenceLines`. `CalibrationModel` includes coefficients, normalization,
fit/LOO statistics, calibration points, peak-position method and pixel metadata:

- `PixelCoordinateMode`
- `PixelFirst`, `PixelLast`, `PixelCount`
- `CalibrationPixelFirst`, `CalibrationPixelLast`

## Equation TXT

The human-readable TXT records the pixel mode, data/calibration domains,
natural-coordinate equation, normalized coefficients, normalization parameters
and fit/validation statistics.

## Residual CSV

The CSV repeats pixel mode and domains on every row so it remains self-
describing when separated from the MAT file. Remaining columns identify the
peak, fitted/reference wavelengths, fit residual, LOO residual and deletion
influence.

The polynomial must only be evaluated using the coordinate mode recorded in the
model. Matching numerical ranges alone do not establish compatibility.
