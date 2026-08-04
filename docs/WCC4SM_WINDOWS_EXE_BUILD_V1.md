# WCC4SM Windows EXE build and deployment

## Scope

WCC4SM is distributed as a standalone Windows executable folder, not as an
installer. MATLAB Runtime is not bundled. The target computer must already have
MATLAB or the MATLAB Runtime release compatible with the MATLAB release used to
build the executable.

## Build prerequisites

- Windows build computer.
- MATLAB R2022a or later.
- MATLAB Compiler with a usable license.
- Signal Processing Toolbox and other products reported by the compiler's
  generated `requiredMCRProducts.txt`.

## Build command

From the repository root:

```matlab
addpath('tools');
outputFolder = build_windows_exe;
```

The script uses `mcc -e` to create a Windows GUI executable without a console
window. It recreates `build/windows/` on each build and then copies the external
runtime assets:

```text
build/windows/
├── WCC4SM_V0_6_2.exe
├── docs/
├── reference_data/
├── LICENSE
├── NOTICE
├── README.md
├── readme.txt
└── requiredMCRProducts.txt
```

## Deployment

Copy the complete `build/windows/` folder to the target computer. Do not copy
only the EXE: Help PDFs and reference assets are intentionally external so they
can be reviewed and updated without recompiling the application.

For a build produced by MATLAB R2022a, install the corresponding R2022a MATLAB
Runtime when the target computer does not have a compatible MATLAB installation.
The first launch can be slower while MATLAB Runtime initializes its component
cache.

## Release verification

Before distribution:

1. Run `run_wc4sm_tests` in the source checkout.
2. Build the EXE from a clean `build/windows/` folder.
3. Start the EXE and confirm the main WCC4SM window opens and responds.
4. Open Help, refresh the PDF list and read a PDF from `docs/`.
5. Load the confirmed reference master from `reference_data/`.
6. Exercise spectrum import, session save/load and all result exports.
7. Repeat the test on a separate computer that has MATLAB Runtime but not
   MATLAB, because the development machine is not a sufficient deployment test.

## Licensing boundary

WCC4SM source and project-authored documentation are licensed under Apache
License 2.0. MATLAB, MATLAB Runtime, reference datasets and third-party PDFs
retain their own terms. Only distribute standards, papers or other PDFs when
their license or written permission permits redistribution.
