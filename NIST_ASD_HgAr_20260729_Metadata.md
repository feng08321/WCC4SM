# NIST ASD Hg-Ar reference master — project version 20260729

## Identity

- Dataset file: `NIST_ASD_HgAr_20260729.lit`
- Project data version: `20260729`
- Version basis: project download/curation date, not an official NIST ASD release number
- Authority: NIST Atomic Spectra Database (ASD)
- Source: https://physics.nist.gov/asd
- Species represented: Hg and Ar
- Wavelength unit: nm
- Data rows: 322
- Stored columns: wavelength, relative intensity, species

## Provenance

The project master was assembled from strong Hg/Ar line data downloaded from
NIST ASD and supplemented with several weaker lines found by additional NIST ASD
queries. The dated file is a byte-for-byte preservation of the previous project
file `NIST_HgAr_comparison_c..lit`; the old file is retained for audit history.

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
- `MasterLibrary`: NIST_ASD_HgAr_20260729.lit
- `MasterVersion`: 20260729
- `WavelengthMedium`: NIST ASD default mixed; working range 285–1100 nm is standard air

## Selection modes

Selection modes are instrument-family profiles. They choose usable lines from
this master according to wavelength range, sensitivity and resolution, but do
not define independent wavelength truth. Each mode must use exact wavelength
values present in this dated master and identify this master by relative
filename. Mode01 is `WCC4SM_NIST_ASD_HgAr_20260729_Mode01.csv`.

## Modification policy

Do not silently edit this dated master. If NIST values, query choices or weak
line coverage change, create a newly dated master, metadata file, selection
modes and a difference report. Keep previous versions for reproducibility.
