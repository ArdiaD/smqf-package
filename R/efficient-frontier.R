#' Compute a Long-Only Mean–Variance Efficient Frontier
#'
#' Solves a sequence of quadratic programs to trace the long-only,
#' fully-invested Markowitz efficient frontier between the minimum-variance
#' portfolio and the maximum-return (corner) portfolio.
#'
#' Portfolios are obtained by minimizing variance for a grid of target returns
#' under the constraints \eqn{\sum_i w_i = 1} and \eqn{w_i \ge 0}.
#'
#' @param mu Numeric vector of length \eqn{N}: expected asset returns.
#' @param Sigma Numeric \eqn{N \times N} covariance matrix. Only the symmetric
#'   part is used internally.
#' @param n_ptf Integer \eqn{\ge 2}: number of portfolios along the frontier
#'   (including the minimum-variance and maximum-return portfolios).
#'
#' @return A list with components:
#' \describe{
#'   \item{weights}{Numeric matrix \eqn{N \times n_ptf}: portfolio weights.}
#'   \item{volatility}{Numeric length-\eqn{n_ptf}: portfolio standard deviations.}
#'   \item{expected_returns}{Numeric length-\eqn{n_ptf}: portfolio expected returns.}
#' }
#'
#' @details
#' Each QP solves
#' \deqn{
#'   \min_{w}\; w^\top \Sigma\, w \quad
#'   \text{s.t. } \mathbf{1}^\top w = 1,\; w \ge 0
#' }
#' and, for interior points on the frontier, additionally
#' \deqn{\mu^\top w = \mu^\star,}
#' where \eqn{\mu^\star} spans a linear grid between the min-variance portfolio
#' return and the single-asset maximum-return portfolio.
#'
#' Requires \pkg{pracma} for \code{quadprog}. Numerical issues can arise if
#' \code{Sigma} is not positive semidefinite or if target returns are infeasible
#' under the long-only constraint.
#'
#' @references
#' Markowitz, H. (1952). Portfolio Selection. \emph{Journal of Finance}, 7(1), 77–91.
#'
#' @seealso \code{\link[pracma]{quadprog}}
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
#'
#' @importFrom pracma quadprog
#' @export
# f_efficient_frontier <- function(mu, Sigma, n_ptf) {
#   ### Compute the efficient frontier
#   # INPUTS
#   #  mu    : [vector] (N x 1) expected returns
#   #  Sigma : [matrix] (N x N) covariance matrix
#   #  n_ptf  : [scalar] number of portfolios to consider on the efficient froniter
#   # OUTPUTS
#   #  mu_   : [vector] (n_ptf x 1) expected returns of portfolios
#   #  vol_  : [vector] (n_ptf x 1) volatilities of portfolios
#   #  w_    : [matrix] (N x n_ptf) composition of portfolios
#
#   # Ensure Sigma is symmetric
#   Sigma <- (Sigma + t(Sigma)) * 0.5
#   N     <- length(mu)
#
#   # Minimum variance portfolio
#   FirstDegree  <- rep(0, N)
#   SecondDegree <- 2 * Sigma
#
#   # Sum of weights is one
#   Aeq <- rep(1, N)
#   beq <- 1
#   # No-short constraint
#   A  <- -diag(1, N)
#   b  <- rep(0, N)
#   # Starting point is equally-weighted portfolio
#   w0 <- rep(1, N) / N
#
#   Res <- pracma::quadprog(C = SecondDegree,
#                           d = FirstDegree,
#                           A = A,
#                           b = b,
#                           Aeq = Aeq,
#                           beq = beq)
#   MinVol_Weights <- Res$xmin
#   exitflag <- Res$eflag
#
#   if (exitflag != 1) {
#     stop('Non convergence of quadprog')
#   }
#
#   MinVol_Return <- as.numeric(t(MinVol_Weights) %*% mu)
#
#   # Maximum return portfolio
#   MaxRet_Return <- max(mu)
#   MaxRet_Index  <- which(mu == MaxRet_Return)
#
#   MaxRet_Weights <- rep(0, N)
#   MaxRet_Weights[MaxRet_Index] <- 1.0
#
#   # initialization
#   vol_ <- rep(NA, n_ptf)
#   mu_  <- rep(NA, n_ptf)
#   w_   <- matrix(NA, N, n_ptf)
#
#   # min vol portfolio
#   w_[, 1] <- MinVol_Weights
#   vol_[1] <- sqrt((t(MinVol_Weights) %*% Sigma) %*% MinVol_Weights)
#   mu_[1]  <- t(MinVol_Weights) %*% mu
#
#   # max ret portfolio
#   w_[, n_ptf] <- MaxRet_Weights
#   vol_[n_ptf] <- sqrt((t(MaxRet_Weights) %*% Sigma) %*% MaxRet_Weights)
#   mu_[n_ptf]  <- t(MaxRet_Weights) %*% mu
#
#   # compute the n_ptf compositions and risk-return coordinates of
#   # the optimal allocations relative to each slice
#   Step <- (MaxRet_Return - MinVol_Return) / (n_ptf - 1)
#   TargetReturns <- seq(from = MinVol_Return,
#                        to = MaxRet_Return,
#                        by = Step)
#
#   # iterate over the various portfolio
#   for (i in 2:(n_ptf - 1)) {
#     # determine least risky portfolio for given expected return
#     Aeq <- t(cbind(rep(1, N), mu))
#     beq <- rbind(1, TargetReturns[i])
#     res <- pracma::quadprog(C = SecondDegree,
#                             d = FirstDegree,
#                             A = A,
#                             b = b,
#                             Aeq = Aeq,
#                             beq = beq)
#     w <- res$xmin
#     exitflag <- res$eflag
#
#     if (exitflag != 1) {
#       stop('Non convergence of quadprog', call. = FALSE)
#     }
#
#     w_[, i] <- w
#     vol_[i] <- sqrt((t(w) %*% Sigma) %*% w)
#     mu_[i]  <- t(w) %*% mu
#   }
#
#   out <- list(
#     weights = w_,
#     volatility = vol_,
#     expected_returns = mu_
#   )
#
#   out
# }
#
f_efficient_frontier <- function(mu, Sigma, n_ptf) {
  # ---- validate -------------------------------------------------------------
  if (!is.numeric(mu) || any(!is.finite(mu)))
    stop("`mu` must be a finite numeric vector.", call. = FALSE)
  if (!is.matrix(Sigma) || nrow(Sigma) != length(mu) || ncol(Sigma) != length(mu)) {
    stop("`Sigma` must be an N x N matrix matching length(mu).", call. = FALSE)
  }
  if (!is.numeric(n_ptf) || length(n_ptf) != 1L || n_ptf < 2) {
    stop("`n_ptf` must be an integer >= 2.", call. = FALSE)
  }
  N <- length(mu)

  # Force symmetry (cheap & safe). Optional: PSD projection could be added if needed.
  Sigma <- 0.5 * (Sigma + t(Sigma))

  # Build QP pieces (pracma::quadprog minimizes (1/2)x'C x + d'x)
  FirstDegree  <- rep(0, N)
  SecondDegree <- 2 * Sigma # so that objective is w' Σ w

  # Constraints: sum(w)=1 and w >= 0 (i.e., -I w <= 0 for pracma form A w <= b)
  Aeq <- rep(1, N)
  beq <- 1
  A   <- -diag(1, N)
  b   <- rep(0, N)

  # ---- endpoints ------------------------------------------------------------
  # Minimum-variance (no target-return equality)
  res_min <- pracma::quadprog(C = SecondDegree,
                              d = FirstDegree,
                              A = A, b = b,
                              Aeq = Aeq, beq = beq)
  if (res_min$eflag != 1)
    stop("Minimum-variance QP did not converge.", call. = FALSE)
  w_min <- res_min$xmin
  mu_min <- as.numeric(crossprod(w_min, mu))
  sig2_min <- drop(crossprod(w_min, Sigma %*% w_min))

  # Maximum-return (long-only): put weight on all assets tying for max(mu)
  max_mu <- max(mu)
  idx_max <- which(mu == max_mu)
  w_max <- rep(0, N); w_max[idx_max] <- 1 / length(idx_max)
  mu_max <- max_mu
  sig2_max <- drop(crossprod(w_max, Sigma %*% w_max))

  # ---- preallocate ----------------------------------------------------------
  vol_ <- rep(NA_real_, n_ptf)
  mu_  <- rep(NA_real_, n_ptf)
  w_   <- matrix(NA_real_, nrow = N, ncol = n_ptf,
                 dimnames = list(if (!is.null(names(mu)))
                   names(mu) else NULL, NULL))

  # Endpoints
  w_[, 1]        <- w_min
  mu_[1]         <- mu_min
  vol_[1]        <- sqrt(max(sig2_min, 0))  # guard tiny negatives
  w_[, n_ptf]    <- w_max
  mu_[n_ptf]     <- mu_max
  vol_[n_ptf]    <- sqrt(max(sig2_max, 0))

  # Target return grid (inclusive endpoints; avoids floating drift)
  targets <- seq(from = mu_min, to = mu_max, length.out = n_ptf)

  # ---- interior solves ------------------------------------------------------
  if (n_ptf > 2) {
    # Build equality rows once; each interior problem adds the mu target row
    for (i in 2:(n_ptf - 1)) {
      Aeq2 <- rbind(Aeq, mu)   # 2 x N
      beq2 <- c(1, targets[i])

      res <- tryCatch(
        pracma::quadprog(C = SecondDegree,
                         d = FirstDegree,
                         A = A, b = b,
                         Aeq = Aeq2, beq = beq2),
        error = function(e) NULL
      )

      if (!is.null(res) && res$eflag == 1 && all(is.finite(res$xmin))) {
        w_i <- res$xmin
      } else {
        # If infeasible or failed, fall back to previous feasible solution (monotone frontier)
        w_i <- w_[, i - 1, drop = FALSE]
        warning(sprintf("QP did not converge at target %g; carrying forward
                        previous weights.", targets[i]), call. = FALSE)
      }

      w_[, i] <- w_i
      mu_[i]  <- as.numeric(crossprod(w_i, mu))
      sig2_i  <- drop(crossprod(w_i, Sigma %*% w_i))
      vol_[i] <- sqrt(max(sig2_i, 0))
    }
  }

  frontier <- data.frame(
    point = seq_len(n_ptf),
    expected_return = as.numeric(mu_),
    volatility = as.numeric(vol_)
  )

  list(
    weights = w_,
    volatility = vol_,
    expected_returns = mu_,
    frontier = frontier,
    targets = targets
  )
}

