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

The M1mac additional-issues service reports the same failure, at the same line
and with the same assertion counts, under R-devel on aarch64-apple-darwin25.6.0
with Apple clang 21.0.0.

Every other flavour running 1.1-7 was OK. The failure is in the test rather
than in the package -- no exported function is involved -- and it is specific
to recent arm64 R builds rather than to macOS: the same machine reproduces it
under an R built for darwin23 and does not under one built for darwin20,
running the same operating system in both cases.

The failure has been reproduced exactly. Installing R 4.6.1 for
aarch64-apple-darwin23 alongside the R 4.5.2 (darwin20) build used previously,
and running the published 1.1-7 tarball under it, gives byte-for-byte the
report CRAN sent: the same test, the same line, the same message, and the same
`[ FAIL 1 | WARN 0 | SKIP 0 | PASS 1221 ]`. The same tarball passes under
R 4.5.2 on the same machine and the same operating system, so the
discriminating factor is the R build and its toolchain.

Instrumenting the reproduction identifies the point precisely: of the twenty
grid points, `solve.QP` refuses exactly one, `i = 20`. That is the last target,
`tg[20] = max(mu)`, whose only long-only solution is the vertex `e_argmax` -- a
degenerate corner of the feasible set. Every interior target solves, and so
does the unconstrained minimum-variance QP.

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
  wrapped. On both platforms measured, only the vertex is ever refused, so the
  wrapper is not needed for them; it is there because whether a given point is
  solvable is a property of the platform's linear algebra rather than of the
  package, and we have measured two platforms out of the thirteen CRAN runs. A
  point the solver declines is skipped, the points it solves must still agree
  with the package to 1e-6, and a guard requires at least 18 of the 20 points
  to have been solved so that a collapsed solver cannot pass silently.
* The unseeded draw is seeded, along with eleven others across
  `test-efficient-frontier.R`, `test-mvsk-portfolio.R` and
  `test-tail-dependence.R`.

This submission has been verified on the platform that reported the failure:
1.1-7 fails and 1.1-8 passes under R 4.6.1 on aarch64-apple-darwin23, with the
1.1-7 failure identical to the one CRAN reported.

The suite now returns 1228 passing assertions and no failures under every
initial RNG state tried (seeds 1, 23, 42, 99, 2026, 7777), with an identical
count in each case, and each file gives the same result run alone as in suite
order. Seeds 23, 42 and 99 are among those that reproduced the original failure
locally.

## Test environments

* Local macOS (aarch64-apple-darwin23), R 4.6.1 -- the platform that reported
  the failure. `R CMD check --as-cran` including the PDF manual: 2 NOTEs, no
  errors or warnings. The second NOTE is local only, "Skipping checking math
  rendering: package 'V8' unavailable".
* Local macOS (aarch64-apple-darwin20), R 4.5.2, `R CMD check --as-cran`
  including the PDF manual
* Windows (win-builder), R release 4.6.1 and R devel

## R CMD check results

0 errors | 0 warnings | 1 note

(2 notes on the darwin23 build, the second being the local absence of V8 noted
above.)

## Notes

* `Days since last update`. 1.1-7 was published on 2026-08-23 and the check
  failure above was reported against it the same day, with a fix-by date of
  2026-09-13. This submission exists only to clear that failure. We would
  otherwise not submit again so soon, and we have no further changes planned.

* Several market datasets are ported from the GPL (>= 2)-licensed `qrmdata`
  package (Hofert, Hornik & McNeil) and are redistributed here under the same
  license. The original authors are credited in `Authors@R` as `ctb`/`cph`.
  `f_mvsk_portfolio()` is likewise ported from the GPL-licensed
  `mvskPortfolios` package, with Cornilly and Boudt credited the same way.
