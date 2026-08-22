# smqf 1.1-7

## Bug fixes

* `f_normal_copula_pdf()` and `f_student_copula_pdf()` returned `NaN` or `Inf`
  for valid inputs in moderately high dimension. Both formed the density as
  `exp(log_num) / prod(fs)`: the numerator was computed in log space, but
  exponentiating it before dividing by the product of marginal densities
  reintroduced the range problem from the other side. On an identity `Sigma`,
  where the Gaussian copula density is exactly 1 everywhere, the function
  returned 1 up to `d = 200` and `NaN` from `d = 300`, because numerator and
  denominator both underflowed to zero. The whole ratio is now formed in log
  space and exponentiated once. Bivariate results are unchanged to 1.8e-15
  relative, so nothing that used these functions in two dimensions moves.

* `f_tail_dependence()` failed with the internal message "missing value where
  TRUE/FALSE needed" when `alpha` was `NA_real_` or `NaN`, because those are
  numeric scalars and reached the range comparison. `alpha` is now checked for
  finiteness first and the documented error message is raised.

## New features

* `f_normal_copula_pdf()` and `f_student_copula_pdf()` gain a `log` argument.
  In high dimension the density itself can exceed the double-precision range
  even when its logarithm is unremarkable -- the Student copula at
  `u = rep(0.99, 500)` has a log density of 937 against an `exp()` ceiling of
  710 -- so `log = TRUE` is the safe form for likelihoods.

## Documentation

* The `Fred` help page contradicted itself. The Format section correctly
  described `DJI.Adjusted` as a one-month-ahead change in index points, while
  the title, description and Details still called it a monthly log-return. The
  data settle it: the column has a standard deviation of 780 and ranges from
  -2211 to +1785. All three "log-return" statements are removed.

* The `FungHsieh` help page now states plainly what its provenance can and
  cannot establish. The original download URLs and vintages were not recorded,
  so `data-raw/FungHsieh.R` is a contract harness rather than a reconstruction
  script, and the column semantics are inferred rather than verified. Where the
  data corroborate an identification it is now said so explicitly -- `BAA`
  correlates -0.51 with `CST10Y` and -0.27 with `EMKT`, the signature of a
  credit spread change rather than a raw Baa yield change -- and where they do
  not, that is said too.

## Infrastructure

* `MASS` and `mvtnorm` are declared in `Suggests`. Both are used by the test
  suite via `::`, and `R CMD check --as-cran` reported "'::' imports not
  declared from: 'MASS' 'mvtnorm'". The check is now free of warnings.

* New provenance and contract harnesses `data-raw/FamaFrench.R` and
  `data-raw/TermStructure.R`, the last two of the twenty shipped datasets
  without one. The FamaFrench harness pins the end-of-week stamping convention,
  which is the property a naive re-import would silently shift by one week; the
  TermStructure harness pins the `tau` attribute and the maturity ordering,
  both of which are lost silently rather than loudly by a round trip through
  `as.matrix()`.

* Regression tests for the copula densities at `d` = 100, 200, 300 and 500, and
  for non-finite `alpha` in `f_tail_dependence()`.

* The `mvskPortfolios` source repository moved from `cdries/mvskPortfolios` to
  `c3jg/mvskPortfolios`; the attribution links in `f_mvsk_portfolio()` follow it.
  `R CMD check --as-cran` flagged the redirect.

# smqf 1.1-6

## New features

* New function `f_mdp()`, the most diversified portfolio of Choueifaty and
  Coignard (2008). It solves the closed form `w` proportional to
  `Sigma^{-1} sigma` and refuses a singular `Sigma` rather than returning a
  meaningless answer -- which is what Exercise 4.2 of the book relies on, since
  the whole point of that exercise is that the sample covariance of 487
  constituents estimated from 156 weekly observations cannot be inverted. The
  weights are unconstrained in sign; the help page documents the gross exposure
  this implies.

* `f_efficient_frontier()` gains a `targets` argument. Frontiers computed from
  different inputs otherwise use different target-return grids, so averaging
  them point by point mixes portfolios that target different returns. Supplying
  an explicit grid makes several frontiers directly comparable. Targets above
  the maximum attainable return are reported with status `"failed"` rather than
  silently clipped.

## Documentation

* `GoyalWelch`: the help page now states that `Rfree` is exactly `tbl / 12`.
  The two columns carry the same information, so at most one may enter a
  regression -- `lm()` detects the resulting rank deficiency and aliases one
  away, but penalized fitters such as `glmnet::glmnet()` do not, and split the
  effect arbitrarily between them. The units of `tbl`, `AAA`, `BAA` and `lty`
  are stated as annualized decimals, and `csp` is identified as the
  Polk-Thompson-Vuolteenaho cross-sectional premium (available to Dec 2002
  only, hence the 192 missing values) rather than the corporate bond return
  spread, which is `corpr - ltr`.

* `Fred`: the response column `DJI.Adjusted` is documented as a one-month-ahead
  change in the index *level*, in points, not as a log-return. The predictors
  are documented as transformed but **not** rescaled -- their standard
  deviations span some eight orders of magnitude -- so any penalized fit must
  standardize internally.

## Testing

* Contract tests added for `GoyalWelch` (shape, column order, the
  `Rfree == tbl / 12` identity, the missing-value structure and anchored
  values), for `SP500_const`, which had none, and for the two `DAX` slices that
  carry every numerical result of Chapter 5.

* `DJ` and `DAX` are now anchored numerically. Shape, dates and positivity were
  checked before, but any other positive series of the same dimensions would
  have passed them.

* Integration tests for the resampled-efficiency pipeline: that an explicit
  target grid makes two frontiers comparable point by point, that infeasible
  targets are reported rather than clipped, and that averaging by rank
  preserves the budget and the long-only constraint while giving up efficiency.

* New provenance harnesses `data-raw/GoyalWelch.R` and `data-raw/Fred.R`,
  which assert every structural property the book and the help pages depend on.

# smqf 1.1-5

## New features

* New function `f_mvsk_portfolio()`, a port of `mvskPortfolio()` from the
  **mvskPortfolios** package by Dries Cornilly and Kris Boudt, redistributed
  under the same GPL (>= 2) licence and with both authors added as contributors
  and copyright holders. Chapter 3 of the book previously required installing
  that package from GitHub; it now installs from CRAN alone. The algorithm is
  unchanged and reproduces the original bit for bit, but the internal calls to
  non-exported **PerformanceAnalytics** symbols have been replaced by this
  package's own helpers, the solver status is returned, and the inputs are
  validated. Co-moment matrices must be supplied in the matrix form
  (`as.mat = TRUE`).

* `f_clayton_copula_2d_pdf()` gains a `log` argument. The Clayton density
  diverges towards the lower corner, where only the log scale is representable;
  the function previously returned a silent zero there.

## Bug fixes

* `f_normal_copula_pdf()` and `f_student_copula_pdf()` now validate `Sigma`.
  An asymmetric matrix was silently accepted and returned a plausible number
  corresponding to no valid copula; a singular one returned `Inf` and an
  indefinite one `NaN`. All three are now errors, and the message points at
  `Matrix::nearPD()`.

* Both elliptical copula densities compute the determinant and the normalizing
  constant on the log scale. `det(Sigma)` underflows for large dimensions --
  it is already 9e-30 at N = 200 -- which turned the density into `Inf`. The
  densities are now finite well past N = 800.

* `f_ptf_max_U()` checks that `w_max >= 1/d` before optimizing. Bounds that
  cannot fund a full investment previously produced an opaque nloptr error
  ("at least one element in x0 > ub") for arguments the documentation allowed.
  It also validates that all four moment inputs are finite and that `M2` is
  symmetric and positive semidefinite.

* `f_ptf_max_U()` now warns on NLopt status 5 and 6. These are positive codes,
  so the previous `status < 0` test treated an exhausted evaluation budget as a
  success.

* `f_tail_dependence()` returns `NA` with a warning when the threshold selects
  no observation, instead of `0`. Two identical constant series were reported
  as having no tail dependence.

* `f_display_copula()` rejects grids touching 0 or 1. The densities are defined
  on the open square, and a boundary grid failed inside the user's callback with
  a message that pointed at the wrong place.

## Documentation

* `?FTSE_const` now describes the real structure of its missing values: 4,634
  of the 163,821 `NA`s occur after a series has started, across 96 of the 98
  columns, so trimming the leading block is not sufficient. This was the last
  of the three `*_const` datasets to carry the incorrect claim.

## Testing

* New `test-copula-reference.R` cross-checks all four copula densities against
  `copula::dCopula()` across a wide parameter range, verifies that each
  integrates to one over the unit square, and covers the invalid-matrix paths.
  Nothing in the suite previously pinned the numbers themselves.

* New `test-portfolio-moments.R` covers `f_portfolio_moments()`, which had no
  tests at all, and checks the analytic gradients of the MVSK objective against
  finite differences -- `f_ptf_max_U()` passes them to nloptr with
  `check_derivatives = FALSE`.

* New `test-mvsk-portfolio.R` covers the ported tilting routine.

* Dataset tests extended to the nine single-series indices (`DJ`, `FTSE`,
  `EURSTOXX`, `DAX`, `CAC`, `NIKKEI`, `SMI`, `HSI`, `GOLD`), none of which were
  loaded by any test, and to the weekly merge that Chapter 3 depends on.

* New `data-raw/qrmdata-ports.R` records the provenance of the fifteen ported
  market datasets and pins their contract.

# smqf 1.1-4

## Bug fixes

* `f_efficient_frontier()` now computes the maximum-return end point by solving
  the constrained QP (minimize variance subject to `mu'w = max(mu)`) instead of
  assigning weights by hand. Previously, when several assets tied for the
  highest expected return, weight was spread equally across them. That
  allocation is feasible but generally not variance-minimal, so the last
  frontier point could be strictly dominated: with `mu = c(.1, .2, .2)` and
  `Sigma = diag(c(1, 100, 1))` it returned `c(0, .5, .5)` (variance 25.25)
  where the optimum is `c(0, 1/101, 100/101)` (variance 0.99). Frontiers with a
  unique maximum are unaffected.

* When an interior QP fails to converge, `f_efficient_frontier()` no longer
  carries the previous portfolio's weights forward. Doing so returned a point
  that silently violated its own target return. Failed points are now `NA` and
  are flagged in the new `status` component.

## New features

* `f_efficient_frontier()` gains a `status` component (`"ok"` / `"failed"`) and
  the `frontier` data frame gains `target` and `status` columns, so a caller can
  check that every point met its target return.

* `f_efficient_frontier()` accepts any `Sigma` coercible with `as.matrix()`,
  notably the `dpoMatrix` returned by `Matrix::nearPD()$mat`, which previously
  raised an error.

* `f_efficient_frontier()` validates that `Sigma` is positive semidefinite and
  rejects it with an actionable message rather than relying on a warning from
  the solver. Asymmetric input warns and uses the symmetric part.

* `volatility` and `expected_returns` are now named, and the columns of
  `weights` labelled, consistently across the returned object.

## Documentation

* New `?extdata` help page for the raw files shipped under `inst/extdata`
  (`stocks.txt`, `stocks.csv`, `stocks.xlsx`, `prices.txt`), which were
  installed but undocumented. It records the weekly timestamp convention: the
  price stamped against a Tuesday is the close at the end of that calendar
  week.

* `?FamaFrench` now states that the index is stamped at the end of the week and
  warns that merging it with a week-start-stamped series and filling forward
  lags the factors by one week. It also notes that subsetting with
  `endpoints(x, "months")` selects the last weekly return of each month rather
  than compounding a monthly return.

* `?FungHsieh` now fixes the units definitively: all eight columns are in
  percentage points, with `CST10Y` and `BAA` being changes in yields rather
  than returns. The previous text left the choice between percentage points and
  basis points open, which matters when these factors are merged with the
  decimal `edhec` series. A maintainer note has been removed from the help
  page, and `data-raw/FungHsieh.R` now records the assembly steps and pins the
  dataset's contract.

* `?DJ_const` and `?EURSTX_const` now describe the real structure of their
  missing values. Both previously claimed that `NA`s occur only before a
  constituent's first observation; in fact `DJ_const` has 25 interior `NA`s and
  `EURSTX_const` has 1,938, spread over all 50 of its columns (mostly local
  trading holidays).

## Testing

* Dataset tests extended to `DJ_const`, `EURSTX_const`, `VIX`, `SP500` and the
  `extdata` files, none of which were previously loaded by the suite, and
  tightened for `FamaFrench` and `FungHsieh` to cover index class, exact date
  range, ordering, `NA` structure and units.

* `f_efficient_frontier()` is now cross-checked against an independent
  `quadprog::solve.QP` construction, with tests for target attainment, budget
  and long-only constraints, monotonicity, non-domination, tie handling and
  input validation.

# smqf 1.1-3

* Documentation maintenance release. Corrected the package title to
  "Statistical Methods for Quantitative Finance" (matching the companion
  book) throughout `DESCRIPTION`, the package-level help, `README.md`, and
  `inst/CITATION`.
* Clarified the `Fred` dataset documentation to describe the consolidated
  `xts` (128 predictor columns plus the `DJI.Adjusted` response column)
  rather than the former `list(X, y)` structure.
* No changes to data or to any exported function.

# smqf 1.1-2

* New dataset `SP500_const`: weekly adjusted close prices for the 505
  S&P 500 constituents (2015 membership, 1962–2015), ported from
  **qrmdata** and thinned to weekly frequency to respect the CRAN size
  limit. Supports the high-dimensional covariance / factor-model exercise
  where the number of constituents exceeds the number of observations.
* All datasets are now `xts` objects for a consistent interface. `Fred` is
  now a single `xts` (128 predictors plus the `DJI.Adjusted` response column)
  instead of a `list(X, y)`; `TermStructure` is now the rates `xts` with the
  maturity grid stored in `xts::xtsAttributes(TermStructure)$tau` instead of a
  `list(time, tau, rates)`.
* Monthly datasets (`FungHsieh`, `GoyalWelch`, `Fred`) are now indexed by
  `zoo::yearmon` instead of a first-of-month `Date`, so they merge by calendar
  month without first-/end-of-month ambiguity. To combine them with a
  `Date`-indexed series, coerce its index with `as.yearmon()`.
* `FamaFrenchWeekly` is renamed to `FamaFrench` (still weekly, `Date`-indexed).
  The unused `FamaFrenchMonthly` dataset has been removed.
* The package documentation now notes that all bundled datasets are
  illustrative (static snapshots for the book's examples, not maintained feeds).

# smqf 1.1-1

* Import `xts::as.xts` so the `xts` dependency is registered in the
  NAMESPACE (resolves the "package in Depends not imported from" note).

# smqf 1.1-0

* Initial CRAN release.
* Exported functions:
  - Portfolio optimisation: `f_efficient_frontier`, `f_ptf_max_U`,
    `f_portfolio_moments`.
  - Copula PDFs/CDFs: `f_normal_copula_pdf`, `f_student_copula_pdf`,
    `f_clayton_copula_2d_pdf`, `f_gumbel_copula_2d_pdf`, `f_gumbel_copula_2d_cdf`.
  - Copula visualisation: `f_display_copula`.
  - Tail risk: `f_tail_dependence`.
* Datasets: `FamaFrenchMonthly`, `FamaFrenchWeekly`, `Fred`, `FungHsieh`,
  `GoyalWelch`, `TermStructure`.
* Datasets ported from **qrmdata** (so the book no longer depends on that
  package): `SP500`, `DJ`, `DJ_const`, `FTSE`, `FTSE_const`, `EURSTOXX`,
  `EURSTX_const`, `DAX`, `CAC`, `NIKKEI`, `SMI`, `HSI`, `GOLD`, `VIX`.
