## Resubmission
This is a resubmission of a new package. In the previous submission the
incoming checks flagged "Package in Depends field not imported from: 'xts'".
This is now resolved: the package imports `xts::as.xts` in its NAMESPACE, so
the `xts` dependency is registered for when the namespace is loaded but not
attached. `xts` remains in Depends because the market datasets are `xts`
objects and users work with them directly (mirroring the `qrmdata` package
from which several datasets are ported).

## Test environments
* Local macOS Tahoe 26.5, R version 4.5.2 (2025-10-31), R CMD check --as-cran
* Windows (win-builder), R release and R devel

## R CMD check results
0 errors | 0 warnings | 1 note

## Notes
* New submission.
* The DESCRIPTION is flagged for a possibly mis-spelled word, "Ardia", which is
  the author's surname.
* Several market datasets are ported from the GPL (>= 2)-licensed `qrmdata`
  package (Hofert, Hornik & McNeil) and are redistributed here under the same
  license. The original authors are credited in Authors@R as `ctb`/`cph`.
