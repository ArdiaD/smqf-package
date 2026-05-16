#' Empirical Tail Dependence and Exceedance Correlation
#'
#' Estimates the empirical tail‐dependence coefficient and the
#' exceedance correlation between two series at a given quantile threshold
#' \eqn{\alpha} for either the lower or upper tail.
#'
#' @param x Numeric vector of length \eqn{n}, first variable or return series.
#' @param y Numeric vector of length \eqn{n}, second variable or return series.
#' @param alpha Numeric scalar in \eqn{(0,1)}, the tail probability level
#'   (e.g. \code{0.05} for the 5\% tail).
#' @param side Character string, either \code{"lower"} (default) or
#'   \code{"upper"}, indicating which tail to analyse.
#'   \code{"lower"} conditions on \eqn{X < F_X^{-1}(\alpha)};
#'   \code{"upper"} conditions on \eqn{X > F_X^{-1}(1 - \alpha)}.
#'
#' @return A list with components:
#' \describe{
#'   \item{\code{lambda}}{Empirical tail‐dependence coefficient.
#'     For \code{side = "lower"}:
#'     \deqn{\hat{\lambda}_L
#'       = \frac{\#\{X < q_\alpha^X \text{ and } Y < q_\alpha^Y\}}
#'              {\#\{X < q_\alpha^X\}}.}
#'     For \code{side = "upper"}:
#'     \deqn{\hat{\lambda}_U
#'       = \frac{\#\{X > q_{1-\alpha}^X \text{ and } Y > q_{1-\alpha}^Y\}}
#'              {\#\{X > q_{1-\alpha}^X\}}.}}
#'   \item{\code{excorr}}{Exceedance correlation between \code{x} and \code{y}
#'     in the joint tail (computed only if there are joint exceedances).}
#' }
#'
#' @details
#' The function classifies observations in the \eqn{\alpha}‐quantile tail of
#' each margin and computes:
#' \itemize{
#'   \item the standard empirical tail‐dependence coefficient: the
#'     proportion of joint tail events \emph{conditional on} \code{x}
#'     being in its tail (\code{lambda}), and
#'   \item the sample correlation between the values of \code{x} and \code{y}
#'     for which both lie in their respective tails (\code{excorr}).
#' }
#' If no joint tail events are found, \code{lambda = 0} and
#' \code{excorr = NA}. If fewer than two joint-tail observations are available,
#' \code{excorr} is also \code{NA} (the sample correlation is undefined).
#' When the joint-tail subset is degenerate (e.g., \code{x} and \code{y} are
#' identical so that the subset has zero variance), \code{\link[stats]{cor}}
#' returns \code{NA} with a warning.
#'
#' @references
#' Joe, H. (1997). \emph{Multivariate Models and Dependence Concepts}. Chapman & Hall.
#' Embrechts, P., McNeil, A. J., & Straumann, D. (2002). Correlation and
#' dependence in risk management.
#' \emph{Risk Management: Value at Risk and Beyond}. Cambridge University Press.
#'
#' @examples
#' set.seed(1)
#' x <- rnorm(1000)
#' y <- 0.7 * x + sqrt(1 - 0.7^2) * rnorm(1000)
#'
#' f_tail_dependence(x, y, alpha = 0.05)
#' f_tail_dependence(x, y, alpha = 0.05, side = "upper")
#'
#' @seealso \code{\link{f_efficient_frontier}}
#' @importFrom stats cor quantile
#' @export
f_tail_dependence <- function(x, y, alpha, side = c("lower", "upper")) {

  ## --- input validation ---
  if (!is.numeric(x) || length(x) == 0L)
    stop("'x' must be a non-empty numeric vector.", call. = FALSE)
  if (!is.numeric(y) || length(y) == 0L)
    stop("'y' must be a non-empty numeric vector.", call. = FALSE)
  if (length(x) != length(y))
    stop("'x' and 'y' must have the same length.", call. = FALSE)
  if (!is.numeric(alpha) || length(alpha) != 1L ||
      alpha <= 0 || alpha >= 1)
    stop("'alpha' must be a numeric scalar in (0, 1).", call. = FALSE)
  ## --- end validation ---

  side <- match.arg(side)

  if (side == "lower") {
    idx_x <- x < stats::quantile(x, alpha)
    idx_y <- y < stats::quantile(y, alpha)
  } else {
    idx_x <- x > stats::quantile(x, 1 - alpha)
    idx_y <- y > stats::quantile(y, 1 - alpha)
  }

  sumx  <- sum(idx_x & idx_y)
  nx    <- sum(idx_x)

  lambda <- if (nx > 0) sumx / nx else 0
  if (sumx >= 2) {
    excorr <- stats::cor(x[idx_x & idx_y], y[idx_x & idx_y])
  } else {
    # cor() is undefined for fewer than two joint-tail observations.
    excorr <- NA
  }

  out <- list(lambda = lambda,
              excorr = excorr)
  out
}
