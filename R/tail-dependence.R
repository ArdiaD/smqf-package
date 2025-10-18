#' Empirical Lower Tail Dependence and Exceedance Correlation
#'
#' Estimates the empirical lower tail‐dependence coefficient and the
#' exceedance correlation between two series at a given quantile threshold
#' \eqn{\alpha}.
#'
#' @param x Numeric vector of length \eqn{n}, first variable or return series.
#' @param y Numeric vector of length \eqn{n}, second variable or return series.
#' @param alpha Numeric scalar in \eqn{(0,1)}, the lower‐tail probability level
#'   (e.g. \code{0.01} for the 1\% lower tail).
#'
#' @return A list with components:
#' \describe{
#'   \item{\code{lambda}}{Empirical lower tail‐dependence coefficient:
#'     \deqn{\lambda_L = P(X < F_X^{-1}(\alpha),\; Y < F_Y^{-1}(\alpha)) \,/\,
#'                    P(X < F_X^{-1}(\alpha)\; \text{or}\; Y < F_Y^{-1}(\alpha)).}}
#'   \item{\code{excorr}}{Exceedance correlation between \code{x} and \code{y}
#'     in the joint lower tail (computed only if there are joint exceedances).}
#' }
#'
#' @details
#' The function classifies observations in the lower \eqn{\alpha}‐quantile of
#' each margin and computes:
#' \itemize{
#'   \item the proportion of simultaneous lower‐tail events relative to the
#'     union of lower‐tail events (\code{lambda}), and
#'   \item the sample correlation between the values of \code{x} and \code{y}
#'     for which both lie in their respective lower tails (\code{excorr}).
#' }
#' If no joint tail events are found, \code{lambda = 0} and
#' \code{excorr = NA}.
#'
#' @references
#' Joe, H. (1997). *Multivariate Models and Dependence Concepts*. Chapman & Hall.
#' Embrechts, P., McNeil, A. J., & Straumann, D. (2002). Correlation and dependence in risk management.
#' *Risk Management: Value at Risk and Beyond*. Cambridge University Press.
#'
#' @examples
#' set.seed(1)
#' x <- rnorm(1000)
#' y <- 0.7 * x + sqrt(1 - 0.7^2) * rnorm(1000)
#'
#' f_tail_dependence(x, y, alpha = 0.05)
#'
#' @importFrom stats cor quantile
#' @export
f_tail_dependence <- function(x, y, alpha) {

  idx_x <- x < stats::quantile(x, alpha)
  idx_y <- y < stats::quantile(y, alpha)

  sumx  <- sum(idx_x & idx_y)

  if (sumx > 0) {
    lambda <- sumx / sum(idx_x | idx_y)
    excorr <- stats::cor(x[idx_x & idx_y], y[idx_x & idx_y])
  } else {
    lambda <- 0
    excorr <- NA
  }

  out <- list(lambda = lambda,
              excorr = excorr)
  out
}
