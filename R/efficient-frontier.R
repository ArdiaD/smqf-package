#' Compute a Long-Only Mean–Variance Efficient Frontier
#'
#' Solves a sequence of quadratic programs to trace the long-only,
#' fully-invested Markowitz efficient frontier between the minimum-variance
#' portfolio and the maximum-return portfolio.
#'
#' Portfolios are obtained by minimizing variance for a grid of target returns
#' under the constraints \eqn{\sum_i w_i = 1} and \eqn{w_i \ge 0}.
#'
#' @param mu Numeric vector of length \eqn{N}: expected asset returns.
#' @param Sigma Numeric \eqn{N \times N} covariance matrix. Objects that are
#'   not base matrices (for instance the \code{dpoMatrix} returned by
#'   \code{Matrix::nearPD()$mat}) are coerced with \code{as.matrix()}. Only the
#'   symmetric part is used internally.
#' @param targets Optional numeric vector of target returns, sorted increasingly.
#'   When supplied, the frontier is solved at exactly these targets instead of
#'   the default grid, and \code{n_ptf} must be omitted or equal to
#'   \code{length(targets)}. This is what makes several frontiers comparable:
#'   frontiers computed on different inputs otherwise use different grids, and
#'   averaging them point by point mixes portfolios that target different
#'   returns. Targets above the maximum attainable return are reported with
#'   status \code{"failed"} rather than silently clipped.
#' @param n_ptf Integer \eqn{\ge 2}: number of portfolios along the frontier
#'   (including the minimum-variance and maximum-return portfolios).
#'
#' @return A list with components:
#' \describe{
#'   \item{weights}{Numeric matrix \eqn{N \times n_ptf}: portfolio weights.
#'     Rows are named after \code{mu} when it carries names; columns are
#'     labelled \code{ptf1}, \code{ptf2}, ... Columns of failed solves are
#'     \code{NA}.}
#'   \item{volatility}{Named numeric of length \eqn{n_ptf}: portfolio standard
#'     deviations, \code{NA} where the solve failed.}
#'   \item{expected_returns}{Named numeric of length \eqn{n_ptf}: portfolio
#'     expected returns, \code{NA} where the solve failed.}
#'   \item{frontier}{Data frame with columns \code{point} (integer index),
#'     \code{expected_return}, \code{volatility}, \code{target} and
#'     \code{status} for each frontier portfolio.}
#'   \item{targets}{Numeric vector of length \eqn{n_ptf}: the target-return grid
#'     used to trace the frontier.}
#'   \item{status}{Character vector of length \eqn{n_ptf}: \code{"ok"} for a
#'     solved point, \code{"failed"} otherwise.}
#' }
#'
#' @details
#' Each QP solves
#' \deqn{
#'   \min_{w}\; w^\top \Sigma\, w \quad
#'   \text{s.t. } \mathbf{1}^\top w = 1,\; w \ge 0
#' }
#' and, for every point beyond the minimum-variance portfolio, additionally
#' \deqn{\mu^\top w = \mu^\star,}
#' where \eqn{\mu^\star} spans a linear grid between the min-variance portfolio
#' return and \eqn{\max(\mu)}.
#'
#' The maximum-return end point is obtained from the same constrained QP rather
#' than by assigning weights by hand. This matters when several assets tie for
#' \code{max(mu)}: spreading weight equally across them is feasible but
#' generally not variance-minimal, so the resulting portfolio can be strictly
#' dominated and would not lie on the frontier.
#'
#' \code{Sigma} is checked for symmetry and positive semidefiniteness. A matrix
#' whose smallest eigenvalue falls clearly below zero is rejected rather than
#' silently repaired; project it first, for example with
#' \code{as.matrix(Matrix::nearPD(Sigma)$mat)}.
#'
#' If a QP fails to converge, the corresponding point is returned as \code{NA}
#' with \code{status == "failed"} and a warning, instead of being filled with a
#' neighbouring solution that does not meet its target return.
#'
#' Requires \pkg{pracma} for \code{quadprog}.
#'
#' @references
#' Markowitz, H. (1952). Portfolio Selection. \emph{Journal of Finance}, 7(1), 77–91.
#'
#' @seealso \code{\link{f_ptf_max_U}}, \code{\link{f_portfolio_moments}},
#'   \code{\link[pracma]{quadprog}}
#'
#' @examples
#' set.seed(1)
#' N <- 4
#' mu <- c(0.08, 0.10, 0.12, 0.09)
#' M  <- matrix(rnorm(N*N), N); Sigma <- crossprod(M) / N  # PSD covariance
#' ef <- f_efficient_frontier(mu, Sigma, n_ptf = 20)
#' # Inspect end points
#' ef$expected_returns[c(1, 20)]
#' ef$volatility[c(1, 20)]
#' all(ef$status == "ok")
#'
#' # Ties for the maximum expected return are resolved by minimizing variance,
#' # not by equal weighting: assets 2 and 3 both reach 0.2, and the variance-
#' # minimal mix is c(0, 1/101, 100/101) with variance 100/101, well below the
#' # 25.25 of an equal split and below the 1 of asset 3 on its own.
#' ef_tie <- f_efficient_frontier(mu = c(0.1, 0.2, 0.2),
#'                                Sigma = diag(c(1, 100, 1)), n_ptf = 5)
#' ef_tie$weights[, 5]
#'
#' # A common target grid makes two frontiers comparable point by point
#' mu2 <- mu + c(0.01, -0.01, 0.00, 0.02)
#' grid <- seq(0.095, 0.105, length.out = 5)
#' e1 <- f_efficient_frontier(mu,  Sigma, targets = grid)
#' e2 <- f_efficient_frontier(mu2, Sigma, targets = grid)
#' # Same targets, so the two weight vectors at point 3 are directly comparable
#' cbind(e1$weights[, 3], e2$weights[, 3])
#'
#' @importFrom pracma quadprog
#' @export
f_efficient_frontier <- function(mu, Sigma, n_ptf, targets = NULL) {
  # ---- validate mu ----------------------------------------------------------
  if (!is.numeric(mu) || length(mu) < 1L || any(!is.finite(mu)))
    stop("'mu' must be a finite numeric vector.", call. = FALSE)
  N <- length(mu)

  # ---- validate / coerce Sigma ----------------------------------------------
  # Accept anything coercible to a base matrix, notably the 'dpoMatrix'
  # returned by Matrix::nearPD()$mat, which is_not_ a base matrix.
  if (!is.matrix(Sigma)) {
    Sigma <- tryCatch(as.matrix(Sigma), error = function(e) NULL)
    if (is.null(Sigma) || !is.matrix(Sigma))
      stop("'Sigma' must be an N x N matrix, or coercible to one with as.matrix().",
           call. = FALSE)
  }
  if (!is.numeric(Sigma))
    stop("'Sigma' must be numeric.", call. = FALSE)
  if (nrow(Sigma) != N || ncol(Sigma) != N)
    stop("'Sigma' must be an N x N matrix matching length(mu).", call. = FALSE)
  if (any(!is.finite(Sigma)))
    stop("'Sigma' must contain only finite values.", call. = FALSE)

  if (is.null(targets)) {
    if (!is.numeric(n_ptf) || length(n_ptf) != 1L || !is.finite(n_ptf) ||
        n_ptf < 2 || n_ptf != as.integer(n_ptf)) {
      stop("'n_ptf' must be an integer >= 2.", call. = FALSE)
    }
    n_ptf <- as.integer(n_ptf)
  } else {
    if (!is.numeric(targets) || length(targets) < 1L || any(!is.finite(targets)))
      stop("'targets' must be a finite numeric vector.", call. = FALSE)
    if (is.unsorted(targets))
      stop("'targets' must be sorted in increasing order.", call. = FALSE)
    if (!missing(n_ptf) && !is.null(n_ptf) && length(targets) != n_ptf)
      stop("'n_ptf' must equal length(targets) when 'targets' is supplied.",
           call. = FALSE)
    n_ptf <- length(targets)
  }

  # Symmetrize, then verify positive semidefiniteness explicitly.
  asym <- max(abs(Sigma - t(Sigma)))
  scale_ <- max(1, max(abs(diag(Sigma))))
  if (asym > sqrt(.Machine$double.eps) * scale_) {
    warning(sprintf("'Sigma' is not symmetric (max asymmetry %g); using its symmetric part.",
                    asym), call. = FALSE)
  }
  Sigma <- 0.5 * (Sigma + t(Sigma))

  min_eig <- min(eigen(Sigma, symmetric = TRUE, only.values = TRUE)$values)
  psd_tol <- sqrt(.Machine$double.eps) * scale_
  if (min_eig < -psd_tol) {
    stop(sprintf(paste0("'Sigma' is not positive semidefinite (smallest eigenvalue %g). ",
                        "Project it first, e.g. as.matrix(Matrix::nearPD(Sigma)$mat)."),
                 min_eig), call. = FALSE)
  }

  # ---- QP pieces ------------------------------------------------------------
  # pracma::quadprog minimizes (1/2) x'C x + d'x, subject to A x <= b, Aeq x = beq
  FirstDegree  <- rep(0, N)
  SecondDegree <- 2 * Sigma          # so that the objective is w' Sigma w
  Aeq_budget   <- rep(1, N)          # sum(w) = 1
  A            <- -diag(1, N)        # -w <= 0, i.e. w >= 0
  b            <- rep(0, N)

  # Solve min w'Sigma w s.t. sum(w) = 1, w >= 0 and, optionally, mu'w = target.
  # Returns NULL if no solution satisfying the constraints could be obtained.
  feas_tol <- 1e-6
  solve_point <- function(target = NULL) {
    if (is.null(target)) {
      Aeq <- Aeq_budget; beq <- 1
    } else {
      Aeq <- rbind(Aeq_budget, mu); beq <- c(1, target)
    }
    # pracma may emit informational warnings (e.g. on conditioning) while still
    # returning a valid solution, so warnings are muffled rather than treated
    # as failures; feasibility is checked explicitly below instead.
    res <- tryCatch(
      withCallingHandlers(
        pracma::quadprog(C = SecondDegree, d = FirstDegree,
                         A = A, b = b, Aeq = Aeq, beq = beq),
        warning = function(w) invokeRestart("muffleWarning")
      ),
      error = function(e) NULL
    )
    if (is.null(res) || !isTRUE(res$eflag == 1) || any(!is.finite(res$xmin)))
      return(NULL)

    w <- as.numeric(res$xmin)
    w[w < 0 & w > -feas_tol] <- 0          # clamp round-off at the boundary
    if (any(w < 0)) return(NULL)
    s <- sum(w)
    if (!is.finite(s) || abs(s - 1) > feas_tol) return(NULL)
    w <- w / s
    if (!is.null(target) &&
        abs(as.numeric(crossprod(w, mu)) - target) > feas_tol * max(1, abs(target)))
      return(NULL)
    w
  }

  # ---- end points -----------------------------------------------------------
  w_min <- solve_point(NULL)
  if (is.null(w_min))
    stop("Minimum-variance QP did not converge.", call. = FALSE)
  mu_min <- as.numeric(crossprod(w_min, mu))
  user_targets <- !is.null(targets)

  # Maximum-return end point.
  mu_max  <- max(mu)
  idx_max <- which(mu == mu_max)
  if (length(idx_max) == 1L) {
    # A unique maximum leaves a single feasible fully-invested long-only
    # portfolio, so there is nothing to optimize and no QP to solve.
    w_max <- rep(0, N)
    w_max[idx_max] <- 1
  } else {
    # With ties, the maximum-return face has positive dimension: pick the
    # variance-minimal point on it rather than spreading weight equally, which
    # would generally be dominated.
    w_max <- solve_point(mu_max)
    if (is.null(w_max)) {
      w_max <- rep(0, N)
      w_max[idx_max] <- 1 / length(idx_max)
      warning("Maximum-return QP did not converge across tied assets; ",
              "using the equally weighted allocation, which need not be ",
              "variance-minimal.", call. = FALSE)
    }
  }

  # ---- allocate -------------------------------------------------------------
  ptf_names <- paste0("ptf", seq_len(n_ptf))
  vol_   <- stats::setNames(rep(NA_real_, n_ptf), ptf_names)
  mu_    <- stats::setNames(rep(NA_real_, n_ptf), ptf_names)
  status <- rep("ok", n_ptf)
  w_     <- matrix(NA_real_, nrow = N, ncol = n_ptf,
                   dimnames = list(names(mu), ptf_names))

  vol_of <- function(w) sqrt(max(drop(crossprod(w, Sigma %*% w)), 0))

  if (!user_targets) {
    # Default grid: from the minimum-variance return to the maximum available
    # return. The two end points are already solved, so copy them in.
    targets     <- seq(from = mu_min, to = mu_max, length.out = n_ptf)
    w_[, 1]     <- w_min
    mu_[1]      <- mu_min
    vol_[1]     <- vol_of(w_min)
    w_[, n_ptf] <- w_max
    mu_[n_ptf]  <- as.numeric(crossprod(w_max, mu))
    vol_[n_ptf] <- vol_of(w_max)
    interior <- if (n_ptf > 2) 2:(n_ptf - 1) else integer(0)
  } else {
    # A caller-supplied grid: every point is solved the same way, and targets
    # outside [mu_min, mu_max] are infeasible and reported as such.
    interior <- seq_len(n_ptf)
  }

  # ---- solve the remaining points -------------------------------------------
  failed <- integer(0)
  for (i in interior) {
    w_i <- if (user_targets && targets[i] > mu_max + feas_tol) NULL else
      solve_point(targets[i])
    if (is.null(w_i)) {
      # Do not carry a neighbouring solution forward: it would not meet
      # targets[i] and would silently misrepresent the frontier.
      status[i] <- "failed"
      failed <- c(failed, i)
      next
    }
    w_[, i] <- w_i
    mu_[i]  <- as.numeric(crossprod(w_i, mu))
    vol_[i] <- vol_of(w_i)
  }
  if (length(failed)) {
    warning(sprintf("QP did not converge at %d target return(s) (points %s); returned as NA.",
                    length(failed), paste(failed, collapse = ", ")),
            call. = FALSE)
  }

  frontier <- data.frame(
    point           = seq_len(n_ptf),
    expected_return = as.numeric(mu_),
    volatility      = as.numeric(vol_),
    target          = as.numeric(targets),
    status          = status,
    stringsAsFactors = FALSE
  )

  list(
    weights          = w_,
    volatility       = vol_,
    expected_returns = mu_,
    frontier         = frontier,
    targets          = targets,
    status           = status
  )
}
