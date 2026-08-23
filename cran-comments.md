## Update

This is a maintenance update of an already-published package (1.1-3 -> 1.1-7).
Versions 1.1-4 through 1.1-6 were development-only and were never submitted, so
the changes below cover everything since the release currently on CRAN.

### Bug fixes

* `f_normal_copula_pdf()` and `f_student_copula_pdf()` returned `NaN` or `Inf`
  for valid inputs in moderately high dimension. Both formed the density as
  `exp(log_num) / prod(fs)`: the numerator was computed in log space, but
  exponentiating it before dividing by the product of marginal densities
  reintroduced the range problem from the other side. On an identity `Sigma`,
  where the Gaussian copula density is exactly 1 everywhere, the function
  returned 1 up to `d = 200` and `NaN` from `d = 300`, because numerator and
  denominator both underflowed to zero. The whole ratio is now formed in log
  space and exponentiated once. Bivariate results are unchanged to 1.8e-15
  relative.

* `f_tail_dependence()` failed with the internal message "missing value where
  TRUE/FALSE needed" when `alpha` was `NA_real_` or `NaN`. `alpha` is now
  checked for finiteness before the range comparison.

### New features

* Both copula densities gain a `log` argument. In high dimension the density
  itself can exceed the double-precision range even when its logarithm is
  unremarkable, so `log = TRUE` is the safe form for likelihoods.

* New function `f_mdp()` (added in 1.1-6), the most diversified portfolio of
  Choueifaty and Coignard (2008).

* `f_efficient_frontier()` gains a `targets` argument (added in 1.1-6), so that
  frontiers computed from different inputs can share a target-return grid and
  be compared point by point.

* New function `f_mvsk_portfolio()` (added in 1.1-4), ported from the
  GPL-licensed `mvskPortfolios` package with the original authors credited in
  `Authors@R` as `ctb`/`cph`.

### Documentation

* The `Fred` help page contradicted itself: the Format section correctly
  described `DJI.Adjusted` as a one-month-ahead change in index points, while
  the title, description and Details still called it a monthly log-return. The
  data settle it (standard deviation 780, range -2211 to +1785), and the three
  "log-return" statements are removed.

* The `FungHsieh` help page now states plainly what its provenance can and
  cannot establish, rather than presenting inferred column semantics as
  verified.

* Five U+2212 MINUS SIGN characters in the `FungHsieh` `\format` section are
  replaced with ASCII hyphens. They broke the Rd -> PDF manual build with
  "Unicode character U+2212 not set up for use with LaTeX". This was latent in
  1.1-3 and is fixed here.

### Infrastructure

* `MASS` and `mvtnorm` are declared in `Suggests`; both are used by the test
  suite via `::`.

* Provenance and contract harnesses under `data-raw/` (not shipped) now cover
  all twenty datasets.

## Test environments

* Local macOS, R version 4.5.2 (2025-10-31), `R CMD check --as-cran`
  (including the PDF manual)
* Windows (win-builder), R release and R devel

## R CMD check results

0 errors | 0 warnings | 0 notes

## Notes

* The source URL for the Fung-Hsieh factors in `man/FungHsieh.Rd` has been
  updated. The previous address, `https://faculty.fuqua.duke.edu/~dah7/`,
  now returns `301 Moved Permanently` to the Fuqua faculty directory index,
  which carries none of the data. David Hsieh's Hedge Fund Data Library is
  live at `https://people.duke.edu/~dah7/HFRFData.htm` and that is what the
  documentation now cites.

* Earlier submissions were noted for a possibly mis-spelled word in
  DESCRIPTION, "Ardia", which is the author's surname. It did not arise in
  this round.

* Several market datasets are ported from the GPL (>= 2)-licensed `qrmdata`
  package (Hofert, Hornik & McNeil) and are redistributed here under the same
  license. The original authors are credited in `Authors@R` as `ctb`/`cph`.
  `f_mvsk_portfolio()` is likewise ported from the GPL-licensed
  `mvskPortfolios` package, with Cornilly and Boudt credited the same way.
