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
* Monthly datasets (`FamaFrenchMonthly`, `FungHsieh`, `GoyalWelch`, `Fred`) are
  now indexed by `zoo::yearmon` instead of a first-of-month `Date`, so they
  merge by calendar month without first-/end-of-month ambiguity. To combine
  them with a `Date`-indexed series, coerce its index with `as.yearmon()`.
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
