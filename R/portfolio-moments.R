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

#' Portfolio Co-Moments (Variance, Co-Skewness, Co-Kurtosis)
#'
#' Compute the portfolio's centred 2nd, 3rd and 4th moments
#' (variance, co-skewness, co-kurtosis) from the asset-level
#' co-moment matrices and a weight vector.
#'
#' @param w Numeric vector of length \eqn{d} of portfolio weights.
#' @param M2 Optional \eqn{d \times d} covariance matrix of the assets
#'   (as returned by \code{PerformanceAnalytics::M2.MM()}). If
#'   \code{NULL}, the second moment is not computed.
#' @param M3 Optional \eqn{d \times d^2} co-skewness matrix
#'   (\code{PerformanceAnalytics::M3.MM()}). If \code{NULL}, the third
#'   moment is not computed.
#' @param M4 Optional \eqn{d \times d^3} co-kurtosis matrix
#'   (\code{PerformanceAnalytics::M4.MM()}). If \code{NULL}, the fourth
#'   moment is not computed.
#'
#' @details
#' The three quantities are defined as
#' \deqn{m_2(w) = w' M_2 w, \quad
#'       m_3(w) = w' M_3 (w \otimes w), \quad
#'       m_4(w) = w' M_4 (w \otimes w \otimes w),}
#' where \eqn{\otimes} denotes the Kronecker product. These are the
#' building blocks of the mean-variance-skewness-kurtosis (MVSK)
#' framework of Jondeau, Poon and Rockinger (2007).
#'
#' The function is a thin, exported wrapper around the package's
#' internal helpers \code{.portm2}, \code{.portm3}, \code{.portm4}
#' (which themselves replace the unexported
#' \code{PerformanceAnalytics:::portm*} family). It exists so the
#' textbook can demonstrate co-moment computation without reaching
#' into non-exported symbols of the package via \code{:::}.
#'
#' @return A named list with components \code{m2}, \code{m3}, \code{m4}
#' (\code{NULL} for any component whose corresponding co-moment matrix
#' was not supplied).
#'
#' @references
#' Jondeau, E., Poon, S.-H., & Rockinger, M. (2007). \emph{Financial
#' Modeling Under Non-Gaussian Distributions}. Springer.
#'
#' @examples
#' set.seed(1)
#' R  <- matrix(rnorm(200 * 4), 200, 4)
#' d  <- ncol(R)
#' M2 <- cov(R)
#' w  <- rep(1 / d, d)
#' # Variance of the equal-weighted portfolio:
#' f_portfolio_moments(w, M2 = M2)$m2
#'
#' # Co-skewness / co-kurtosis matrices in d x d^2 / d x d^3 form (e.g. from
#' # PerformanceAnalytics::M3.MM() / M4.MM()) can be passed as M3, M4.
#'
#' @export
f_portfolio_moments <- function(w, M2 = NULL, M3 = NULL, M4 = NULL) {
  stopifnot(is.numeric(w))
  list(
    m2 = if (!is.null(M2)) .portm2(w, M2) else NULL,
    m3 = if (!is.null(M3)) .portm3(w, M3) else NULL,
    m4 = if (!is.null(M4)) .portm4(w, M4) else NULL
  )
}
