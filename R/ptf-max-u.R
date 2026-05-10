#' Maximize Truncated MVSK Utility with Box & Budget Constraints
#'
#' Solves for portfolio weights that (approximately) maximize expected utility
#' using a fourth-order moment expansion in mean–variance–skewness–kurtosis
#' (MVSK). The problem is solved via SLSQP with the constraints
#' \eqn{\sum_i w_i = 1} and \eqn{0 \le w_i \le w_max}.
#'
#' The objective implemented is the negative of the truncated MVSK utility
#' series, so minimizing it is equivalent to maximizing the utility:
#' \deqn{
#' \text{EU}(w) \approx
#' \mu_p - \frac{\gamma}{2}\sigma_p^2
#' + \frac{\gamma(\gamma+1)}{6}\,S_p
#' - \frac{\gamma(\gamma+1)(\gamma+2)}{24}\,K_p,
#' }
#' where \eqn{\mu_p, \sigma_p^2, S_p, K_p} are the portfolio's first four
#' centralized moments and \eqn{\gamma \ge 0} is a risk-aversion parameter.
#'
#' @param gamma Non-negative numeric scalar risk-aversion parameter.
#' @param w_max Numeric scalar in \eqn{(0,1]} giving the per-asset upper
#'   bound: \eqn{0 \le w_i \le w_max}.
#' @param M1 Numeric vector of expected returns (length \eqn{d}).
#' @param M2 Numeric \eqn{d \times d} covariance matrix.
#' @param M3 Numeric \eqn{d \times d^2} co-moment matrix, as returned by
#'   \code{PerformanceAnalytics::M3.MM()}.
#' @param M4 Numeric \eqn{d \times d^3} co-moment matrix, as returned by
#'   \code{PerformanceAnalytics::M4.MM()}.
#'
#' @return A list with:
#' \describe{
#'   \item{\code{w}}{Numeric vector of optimal portfolio weights (length \eqn{d}).}
#'   \item{\code{EU}}{Scalar: value of the (approximate) expected utility at \code{w} (sign-corrected).}
#' }
#'
#' @details
#' The equality constraint is enforced via \code{eval_g_eq} and box constraints
#' via \code{lb}/\code{ub}. Gradients are supplied analytically using
#' internal helper functions `.derportm2`, `.derportm3`, and `.derportm4` defined
#' in `portfolio-moments.R`.
#'
#' @section Implementation note:
#' Portfolio moment calculations (\code{portm2/3/4} and their gradients) are
#' performed by internal helpers in \file{R/portfolio-moments.R}, vendored
#' from the standard kronecker-product formulas (Jondeau et al., 2007).
#' \code{M3} and \code{M4} must be co-moment matrices (\eqn{d \times d^2}
#' and \eqn{d \times d^3}), not higher-dimensional arrays.
#'
#' @references
#' Jondeau, E., Poon, S.-H., & Rockinger, M. (2007). \emph{Financial Modeling
#' Under Non-Gaussian Distributions}.
#' Harvey, C. R., Liechty, J. C., Liechty, M. W., & Müller, P. (2010). Portfolio
#' selection with higher moments.
#'
#' @examples
#' set.seed(1)
#' d <- 3
#' M1 <- c(0.06, 0.08, 0.07)
#' A  <- matrix(rnorm(d*d), d); M2 <- crossprod(A)/d
#' M3 <- matrix(0, d, d^2)
#' M4 <- matrix(0, d, d^3)
#' res <- f_ptf_max_U(gamma = 5, w_max = 0.8, M1, M2, M3, M4)
#' res$w; res$EU
#'
#' @importFrom nloptr nloptr
#' @export
f_ptf_max_U <- function(gamma, w_max, M1, M2, M3, M4) {

  ## --- input validation ---
  if (!is.numeric(gamma) || length(gamma) != 1L || gamma < 0)
    stop("'gamma' must be a non-negative numeric scalar.", call. = FALSE)
  if (!is.numeric(w_max) || length(w_max) != 1L ||
      w_max <= 0 || w_max > 1)
    stop("'w_max' must be a numeric scalar in (0, 1].", call. = FALSE)
  if (!is.numeric(M1) || length(M1) == 0L)
    stop("'M1' must be a non-empty numeric vector.", call. = FALSE)
  d <- length(M1)
  if (!is.numeric(M2) || !is.matrix(M2) ||
      nrow(M2) != d || ncol(M2) != d)
    stop("'M2' must be a numeric ", d, " x ", d, " matrix.", call. = FALSE)
  if (!is.numeric(M3) || !is.matrix(M3) ||
      nrow(M3) != d || ncol(M3) != d^2)
    stop("'M3' must be a numeric ", d, " x ", d^2,
         " co-moment matrix.", call. = FALSE)
  if (!is.numeric(M4) || !is.matrix(M4) ||
      nrow(M4) != d || ncol(M4) != d^3)
    stop("'M4' must be a numeric ", d, " x ", d^3,
         " co-moment matrix.", call. = FALSE)
  ## --- end validation ---

  d <- length(M1)

  f_eq <- function(w) {
    obj <- sum(w) - 1
    gr  <- rep(1, d)
    out <- list("constraints" = obj,
                "jacobian" = gr)
    out
  }

  f_obj <- function(w) {
    mom1 <- sum(w * M1)
    mom2 <- .portm2(w, M2)
    mom3 <- .portm3(w, M3)
    mom4 <- .portm4(w, M4)
    obj <- -mom1 + gamma * mom2 / 2 - gamma * (gamma + 1) * mom3 / 6 + gamma * (gamma + 1) * (gamma + 2) * mom4 / 24

    momsgrad2 <- .derportm2(w, M2)
    momsgrad3 <- .derportm3(w, M3)
    momsgrad4 <- .derportm4(w, M4)
    gr <- -M1 + gamma * momsgrad2 / 2 - gamma * (gamma + 1) * momsgrad3 / 6 + gamma * (gamma + 1) * (gamma + 2) * momsgrad4 / 24

    out <- list("objective" = obj,
                "gradient" = gr)
    out
  }

  lb <- rep(0, d)
  ub <- rep(w_max, d)

  sol <- nloptr::nloptr(x0 = rep(1/d, d),
                        eval_f = f_obj,
                        lb = lb, ub = ub,
                        eval_g_eq = f_eq,
                        opts = list(algorithm = "NLOPT_LD_SLSQP",
                                    maxeval = 10000,
                                    print_level = 0,
                                    check_derivatives = FALSE))
  wopt <- sol$solution
  EU   <- -sol$objective

  out <- list("w" = wopt,
              "EU" = EU)
  out
}
