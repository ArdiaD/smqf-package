#' Most Diversified Portfolio
#'
#' Compute the weights of the most diversified portfolio (MDP) of Choueifaty
#' and Coignard (2008), which maximizes the diversification ratio
#' \deqn{DR(w) = \frac{w' \sigma}{\sqrt{w' \Sigma w}}\,,}
#' where \eqn{\sigma = (\sqrt{\Sigma_{11}}, \ldots, \sqrt{\Sigma_{dd}})'} is the
#' vector of asset volatilities. Without further constraints the solution is
#' available in closed form, \eqn{w \propto \Sigma^{-1} \sigma}, normalized to
#' sum to one.
#'
#' @param Sigma A \eqn{d \times d} covariance matrix. Must be symmetric and
#'   positive definite: the closed form requires an inverse, so a singular
#'   \code{Sigma} (for instance a sample covariance estimated from fewer
#'   observations than assets) is rejected rather than silently solved.
#' @param tol Numeric tolerance used to check symmetry and positive
#'   definiteness. Default \code{1e-8}.
#'
#' @details
#' The solution is \strong{unconstrained beyond the budget constraint}: weights
#' may be negative, and in large universes typically are, often substantially.
#' A long-only most diversified portfolio is a different object and requires a
#' constrained quadratic program; it is not what this function returns. Inspect
#' \code{sum(abs(w))} to see the gross exposure implied by the solution.
#'
#' The diversification ratio is scale invariant in \eqn{w}, so the
#' normalization \eqn{\sum_i w_i = 1} is a choice of representative and does not
#' change the portfolio.
#'
#' @return A named numeric vector of \eqn{d} portfolio weights summing to one.
#'   Names are taken from \code{dimnames(Sigma)} when available.
#'
#' @references
#' Choueifaty, Y., & Coignard, Y. (2008). Toward Maximum Diversification.
#' \emph{Journal of Portfolio Management}, 35(1), 40–51.
#'
#' @seealso \code{\link{f_efficient_frontier}}, \code{\link{f_ptf_max_U}}
#'
#' @examples
#' Sigma <- matrix(c(0.04, 0.01, 0.00,
#'                   0.01, 0.09, 0.02,
#'                   0.00, 0.02, 0.16), 3, 3,
#'                 dimnames = list(c("A", "B", "C"), c("A", "B", "C")))
#' w <- f_mdp(Sigma)
#' w
#' sum(w)
#'
#' # Diversification ratio of the MDP against the equally weighted portfolio
#' f_dr <- function(w, Sigma) {
#'   sum(w * sqrt(diag(Sigma))) / sqrt(drop(crossprod(w, Sigma %*% w)))
#' }
#' c(mdp = f_dr(w, Sigma), equal = f_dr(rep(1 / 3, 3), Sigma))
#'
#' @export
f_mdp <- function(Sigma, tol = 1e-8) {

  if (!is.matrix(Sigma) && !inherits(Sigma, "Matrix")) {
    Sigma <- try(as.matrix(Sigma), silent = TRUE)
    if (inherits(Sigma, "try-error")) {
      stop("`Sigma` must be a matrix or coercible to one.", call. = FALSE)
    }
  }
  Sigma <- as.matrix(Sigma)

  if (!is.numeric(Sigma)) {
    stop("`Sigma` must be numeric.", call. = FALSE)
  }
  d <- nrow(Sigma)
  if (d < 1L || ncol(Sigma) != d) {
    stop("`Sigma` must be a square matrix.", call. = FALSE)
  }
  if (!all(is.finite(Sigma))) {
    stop("`Sigma` must contain only finite values.", call. = FALSE)
  }
  if (max(abs(Sigma - t(Sigma))) > tol * max(1, max(abs(Sigma)))) {
    stop("`Sigma` must be symmetric.", call. = FALSE)
  }
  Sigma <- (Sigma + t(Sigma)) / 2

  ev <- eigen(Sigma, symmetric = TRUE, only.values = TRUE)$values
  if (min(ev) <= tol * max(1, max(ev))) {
    stop("`Sigma` must be positive definite; its smallest eigenvalue is ",
         format(min(ev), digits = 3),
         ". The most diversified portfolio has no closed form for a singular ",
         "covariance matrix - regularize it first (for example with a factor ",
         "or shrinkage estimator).", call. = FALSE)
  }

  sig <- sqrt(diag(Sigma))
  w   <- solve(Sigma, sig)
  s   <- sum(w)
  if (!is.finite(s) || abs(s) < .Machine$double.eps^0.5) {
    stop("The unnormalized weights sum to zero; the portfolio is not defined.",
         call. = FALSE)
  }
  w <- w / s

  nm <- colnames(Sigma)
  if (is.null(nm)) nm <- rownames(Sigma)
  if (!is.null(nm)) names(w) <- nm

  w
}
