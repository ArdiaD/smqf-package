# smqf: Statistical Methods for Quantitative Finance

`smqf` is an R package providing datasets and functions used in the 
book "Statistical Methods for Quantitative Finance" by Ardia (2026).

Please cite the package in publications!\
By using `smqf` you agree to the following rules:

-   You must cite the package as Ardia (2026). "Statistical Methods for Quantitative Finance".
-   You assume all risk for the use of `smqf`.

------------------------------------------------------------------------

## Installation

Install the released version of `smqf` from CRAN:

``` r
install.packages("smqf")
```

Or install the development version from GitHub:

``` r
# install.packages("pak") # if needed
pak::pak("ArdiaD/smqf-package")
```

## Usage

``` r
library(smqf)
data("FamaFrench")                               # one of 20 bundled datasets
f_clayton_copula_2d_pdf(c(0.5, 0.5), theta = 2)  # bivariate copula density
ef <- f_efficient_frontier(mu = c(0.08, 0.10, 0.12),
                           Sigma = diag(c(0.04, 0.09, 0.16)), n_ptf = 20)
```

See `?smqf` for the full index of functions and datasets, and
<https://github.com/ArdiaD/smqf-package> for development and issue tracking.
