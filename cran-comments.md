## Update

This is a test-only fix for the check failure reported on 1.1-7
(1.1-7 -> 1.1-8). No user-facing code, documentation or data has changed.

### The failure

`r-release-macos-arm64` reported:

    checking tests ... ERROR
    -- Error ('test-efficient-frontier.R:105:5'):
       matches quadprog::solve.QP, the construction used in the book --
    Error in quadprog::solve.QP(...): constraints are inconsistent, no solution!
    [ FAIL 1 | WARN 0 | SKIP 0 | PASS 1221 ]

Every other flavour running 1.1-7 was OK. The failure is genuinely specific to
that platform, and it is in the test rather than in the package: no exported
function is involved.

The cause is the target grid, which ended at exactly `max(mu)`. The only
long-only portfolio attaining that return is the vertex `e_argmax`, a
degenerate corner of the feasible set where `quadprog::solve.QP` may report
inconsistent constraints instead of returning the vertex, depending on the
platform's linear algebra. The assertion counts confirm the input was the same
on both machines: CRAN's 1221 passes plus the four assertions the aborted test
never reached equal the 1225 seen locally. `solve.QP` succeeds on
aarch64-apple-darwin20 with R 4.5.2 and fails on aarch64-apple-darwin23 with
R 4.6.1 for that identical input.

A second, independent fragility sat behind it: the expected-return vector was
drawn with `runif()` and never seeded, because the helper that builds the
covariance matrix calls `set.seed()` inside itself and so did not cover that
draw. That did not cause this failure, but it left the input to a
known-fragile construction unpredictable — roughly half of all seeds produce a
vector that fails the same way locally.

### The fix

* The maximum-return end point is no longer passed to `quadprog::solve.QP`. It
  is asserted against its analytic value, the vertex, which the package reaches
  exactly through `pracma::quadprog` with an explicit feasibility check — a
  stronger assertion than the one `solve.QP` was being asked to satisfy.
* Interior targets still go to `solve.QP`, which is the point of the test, but
  wrapped. We could not reproduce the failure on the machine fixing it, and
  neither report says which grid point failed, so excluding only the vertex
  would be a guess. A point the solver declines is skipped, the points it
  solves must still agree with the package to 1e-6, and a guard requires at
  least 18 of the 20 points to have been solved so that a collapsed solver
  cannot pass silently.
* The unseeded draw is seeded, along with eleven others across
  `test-efficient-frontier.R`, `test-mvsk-portfolio.R` and
  `test-tail-dependence.R`.

We are aware this fix is verified by construction rather than by reproduction:
the package is unable to reach the failing code path on any machine available
to us. The structure above is intended to be correct whichever grid point the
solver refuses.

The suite now returns 1228 passing assertions and no failures under every
initial RNG state tried (seeds 1, 23, 42, 99, 2026, 7777), with an identical
count in each case, and each file gives the same result run alone as in suite
order. Seeds 23, 42 and 99 are among those that reproduced the original failure
locally.

## Test environments

* Local macOS (aarch64-apple-darwin20), R 4.5.2, `R CMD check --as-cran`
  including the PDF manual
* Windows (win-builder), R devel

## R CMD check results

0 errors | 0 warnings | 1 note

## Notes

* `Days since last update: 0`. 1.1-7 was published on 2026-08-23 and the check
  failure above was reported against it the same day, with a fix-by date of
  2026-09-13. This submission exists only to clear that failure. We would
  otherwise not submit again so soon, and we have no further changes planned.

* Several market datasets are ported from the GPL (>= 2)-licensed `qrmdata`
  package (Hofert, Hornik & McNeil) and are redistributed here under the same
  license. The original authors are credited in `Authors@R` as `ctb`/`cph`.
  `f_mvsk_portfolio()` is likewise ported from the GPL-licensed
  `mvskPortfolios` package, with Cornilly and Boudt credited the same way.
