# Internal helpers for portfolio moment calculations.
#
# These replace the PerformanceAnalytics:::portm* / :::derportm* internal
# functions so that smqf does not rely on non-exported symbols of another
# package (CRAN policy, see `?:::` and Writing R Extensions §1.1.3).
#
# Inputs M2, M3, M4 must be in the "matrix" (co-moment matrix) form as
# returned by PerformanceAnalytics::M2.MM(), M3.MM(), M4.MM():
#   M2  : d  x d   covariance matrix
#   M3  : d  x d^2 coskewness matrix
#   M4  : d  x d^3 cokurtosis matrix
#
# References:
#   Jondeau, E., Poon, S.-H., & Rockinger, M. (2007). Financial Modeling
#   Under Non-Gaussian Distributions. Springer.

# Portfolio second moment (variance): w' M2 w
.portm2 <- function(w, M2) {
  as.numeric(t(w) %*% M2 %*% w)
}

# Portfolio third moment (co-skewness): w' M3 (w x w)
.portm3 <- function(w, M3) {
  as.numeric(t(w) %*% M3 %*% kronecker(w, w))
}

# Portfolio fourth moment (co-kurtosis): w' M4 (w x w x w)
.portm4 <- function(w, M4) {
  as.numeric(t(w) %*% M4 %*% kronecker(kronecker(w, w), w))
}

# Gradient of portfolio second moment w.r.t. w: 2 M2 w
.derportm2 <- function(w, M2) {
  as.numeric(2 * M2 %*% w)
}

# Gradient of portfolio third moment w.r.t. w: 3 M3 (w x w)
.derportm3 <- function(w, M3) {
  as.numeric(3 * M3 %*% kronecker(w, w))
}

# Gradient of portfolio fourth moment w.r.t. w: 4 M4 (w x w x w)
.derportm4 <- function(w, M4) {
  as.numeric(4 * M4 %*% kronecker(kronecker(w, w), w))
}
