## Test environments
* Local macOS Tahoe 26.5, R version 4.5.2 (2025-10-31), R CMD check --as-cran
* Windows (win-builder), R release and R devel

## R CMD check results
0 errors | 0 warnings | 2 notes

## Notes
* New submission.
* Installed size is ~5 Mb, with ~4.5 Mb in `data/`. The package is a data
  companion to the book "Statistical Methods in Quantitative Finance"
  (Ardia, 2026, CRC Press); the datasets are required for the book's examples.
* "Package in Depends field not imported from: 'xts'". The market datasets are
  `xts` objects, so `xts` is in Depends to make its methods available to users
  working with the data; the package's own functions do not call `xts`. This
  mirrors the `qrmdata` package from which several datasets are ported.
* The DESCRIPTION may be flagged for possibly mis-spelled words; these are
  proper names and domain terms (e.g. author names, "qrmdata", copula terms).
* Several market datasets are ported from the GPL (>= 2)-licensed `qrmdata`
  package (Hofert, Hornik & McNeil) and are redistributed here under the same
  license. The original authors are credited in Authors@R as `ctb`/`cph`.
