# smqf 1.1-0

* Initial CRAN release.
* Exported functions:
  - Portfolio optimisation: `f_efficient_frontier`, `f_ptf_max_U`.
  - Copula PDFs/CDFs: `f_normal_copula_pdf`, `f_student_copula_pdf`,
    `f_clayton_copula_2d_pdf`, `f_gumbel_copula_2d_pdf`, `f_gumbel_copula_2d_cdf`.
  - Copula visualisation: `f_display_copula`.
  - Tail risk: `f_tail_dependence`.
  - Volatility: `f_ewma_vol`.
  - Plotting: `f_plot_pairs`.
  - Term structure: `f_NelsonSiegel`, `f_FitSqrtSvensson`, `f_PowerSvensson`.
* Datasets: `FungHsieh`, `GoyalWelch`, `TermStructure`.
* Datasets ported from **qrmdata** (so the book no longer depends on that
  package): `SP500`, `DJ`, `DJ_const`, `FTSE`, `FTSE_const`, `EURSTOXX`,
  `EURSTX_const`, `DAX`, `CAC`, `NIKKEI`, `SMI`, `HSI`, `GOLD`, `VIX`.
