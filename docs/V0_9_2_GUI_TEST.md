# V0.9.2 GUI acceptance notes

1. Launch `WCC4SM_V0_9_2` and load a spectrum whose filename contains `_`.
   Confirm the full-spectrum title shows the underscore literally.
2. In **Data & Display**, edit **Start X** and **End X**, then click
   **RESET RANGE**. Confirm the full-spectrum plot follows the requested range.
3. Clear **Show detected peak markers** to inspect only the full curve. On the
   matching plot, clear **Show matching annotations** to hide paired markers
   and labels while retaining the curves.
4. Run `results = run_wc4sm_tests;` and confirm all 41 tests pass.
