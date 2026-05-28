# smqf 1.2-0

* New dataset `SP500_const`: weekly adjusted close prices for the 505
  S&P 500 constituents (2015 membership, 1962–2015), ported from
  **qrmdata** and thinned to weekly frequency to respect the CRAN size
  limit. Supports the high-dimensional covariance / factor-model exercise
  where the number of constituents exceeds the number of observations.

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
