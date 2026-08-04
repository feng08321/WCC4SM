# WCC4SM V0.9 release acceptance report

- Acceptance date: 2026-08-04
- MATLAB baseline: R2022a
- MATLAB Compiler: 8.4 (R2022a)
- Candidate pull request: `#3`
- Candidate commit before this acceptance record: `6537787`

## Automated and build verification

- Non-GUI regression suite: 37 passed, 0 failed, 0 incomplete.
- Confirmed NIST master: 322 integer intensity values; Mode01 retains 29 exact
  master wavelengths.
- Reference-table formatting: Intensity and Order are verified as integer
  display strings without decimal suffixes.
- V0.9 GUI initialization: passed.
- Combined title and OPEN FIG, SAVE SESSION, LOAD SESSION and HELP controls:
  present and visually inspected without clipping.
- Toolbar/status background and dark status text: visually inspected.
- PDF discovery and empty-state behavior: passed.
- Apache License 2.0: exact match with the official ASF text.
- Windows EXE build without installer or bundled Runtime: passed.
- Compiled V0.9 main window startup and responsiveness: passed.

## Operator verification

The project owner, Zheng Feng, completed the full EXE functional workflow and
reported no functional problems. The owner separately verified the PDF Help and
About features, then verified the final V0.9 header layout, toolbar labels,
colors and reference intensity display after the release-candidate fixes.

## Release decision

WCC4SM V0.9 is accepted as the stable open-source research release. PR #3 may
be merged to `main`; the merge commit may be tagged `v0.9` and used to create a
GitHub Release. The release asset should be the complete version-specific
Windows folder compressed as a ZIP. MATLAB Runtime is intentionally excluded.
