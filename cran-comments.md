## Update
This is a maintenance update of an already-published package
(1.1-2 -> 1.1-3). It corrects the package title to "Statistical Methods for
Quantitative Finance" (to match the companion book) and updates the `Fred`
dataset documentation to describe its consolidated `xts` structure (the
`DJI.Adjusted` response column). There are no changes to the data or to any
exported function.

## Test environments
* Local macOS, R version 4.5.2 (2025-10-31), R CMD check --as-cran
* Windows (win-builder), R release and R devel

## R CMD check results
0 errors | 0 warnings | 1 note

## Notes
* The DESCRIPTION is flagged for a possibly mis-spelled word, "Ardia", which is
  the author's surname.
* Several market datasets are ported from the GPL (>= 2)-licensed `qrmdata`
  package (Hofert, Hornik & McNeil) and are redistributed here under the same
  license. The original authors are credited in Authors@R as `ctb`/`cph`.
