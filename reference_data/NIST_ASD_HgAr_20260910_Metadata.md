# NIST ASD Hg-Ar reference master — project version 20260910

## Identity

- Dataset file: `reference_data/NIST_ASD_HgAr_20260910.lit`
- Project data version: `20260910`
- Version basis: project download/curation date, not an official NIST ASD release number
- Authority: NIST Atomic Spectra Database (ASD)
- Source: https://physics.nist.gov/asd
- Species represented: Hg and Ar
- Wavelength unit: nm
- Data rows: 326
- Stored columns: wavelength, relative intensity, species

## Provenance

This master supersedes `NIST_ASD_HgAr_20260729.lit` (322 rows). It is the
20260729 master plus 4 additional weak Hg lines found by targeted NIST ASD
queries on 2026-09-10; no rows were removed or modified.

Added lines (wavelength nm, relative intensity, species):

| Wavelength | Intensity | Species | Rationale |
|---|---|---|---|
| 390.6371 | 40 | Hg | Matches a weak observed peak in the project test spectra |
| 567.581 | 600 | Hg | Matches a weak observed peak in the project test spectra |
| 612.327 | 3 | Hg | Matches a weak observed peak in the project test spectra |
| 671.634 | 600 | Hg | Matches a weak observed peak in the project test spectra |

With these additions the master essentially explains the complete calibration
set of the current project test data. The previous dated master is retained
for reproducibility.

The project currently does not retain enough information to prove whether every
row was exported as an observed wavelength or a Ritz wavelength. Values are
therefore described as retained NIST ASD values, without relabeling them as a
uniform Observed or Ritz dataset.

## Wavelength medium

NIST ASD's default wavelength convention is vacuum below 200 nm, standard air
from 200 nm through 2000 nm, and vacuum above 2000 nm. Because this master spans
approximately 184.95–2396.65 nm, its overall medium is mixed under that default
convention. WCC4SM's current 285–1100 nm working range lies entirely in the
standard-air portion.

Recommended session metadata:

- `Authority`: NIST
- `MasterLibrary`: NIST_ASD_HgAr_20260910.lit
- `MasterVersion`: 20260910
- `WavelengthMedium`: NIST ASD default mixed; working range 285–1100 nm is standard air

## Selection modes

Selection modes are instrument-family profiles. They choose usable lines from
a dated master according to wavelength range, sensitivity and resolution, but
do not define independent wavelength truth. Mode03
(`reference_data/WCC4SM_NIST_ASD_HgAr_Mode03_20260910.csv`) accompanies this
master. Earlier modes (Mode01/Mode02) remain bound to the 20260729 master.

## Modification policy

Do not silently edit this dated master. If NIST values, query choices or weak
line coverage change, create a newly dated master, metadata file, selection
modes and a difference report. Keep previous versions for reproducibility.
