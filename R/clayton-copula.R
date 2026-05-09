#' Clayton Copula PDF (2-Dimensional)
#'
#' Computes the value of the bivariate Clayton copula probability density
#' function (PDF) at a specified point \eqn{(u_1, u_2)} for a given dependence
#' parameter \eqn{\theta}.
#'
#' The Clayton copula is an Archimedean copula with lower-tail dependence
#' \eqn{\lambda_L = 2^{-1/\theta}} and no upper-tail dependence (\eqn{\lambda_U = 0}).
#' When \eqn{\theta = 0}, the copula reduces to the independence copula,
#' whose PDF equals 1 for all \eqn{(u_1, u_2) \in [0,1]^2}.
#'
#' @param u Numeric vector of length 2, containing values in the interval
#'   \eqn{[0, 1]} representing the evaluation point \eqn{(u_1, u_2)}.
#' @param theta Numeric scalar giving the dependence parameter
#'   (\eqn{\theta > 0}). Values near zero approximate independence.
#'
#' @return A numeric value corresponding to the Clayton copula PDF evaluated
#'   at the specified point.
#'
#' @details
#' The PDF is given by:
#' \deqn{
#'   c(u_1, u_2; \theta)
#'   = (1 + \theta)\,(u_1 u_2)^{-(1 + \theta)}\,
#'     \left(u_1^{-\theta} + u_2^{-\theta} - 1\right)^{-2 - 1/\theta}.
#' }
#'
#' Numerical computation may lose precision for large \eqn{\theta} (typically
#' above about 34).
#'
#' @references
#' - Joe, H. (1997). \emph{Multivariate Models and Dependence Concepts}. Chapman & Hall.
#' - Patton, A. (2006). Modelling Asymmetric Exchange Rate Dependence.
#'   \emph{International Economic Review}, 47(2), 527–556.
#'
#' @examples
#' # Example: Evaluate Clayton copula PDF at (u1, u2) = (0.5, 0.5)
#' f_clayton_copula_2d_pdf(c(0.5, 0.5), theta = 2)
#'
#' @seealso \code{\link{f_gumbel_copula_2d_pdf}}, \code{\link{f_normal_copula_pdf}},
#'   \code{\link{f_student_copula_pdf}}
#' @export
f_clayton_copula_2d_pdf <- function(u, theta) {
  # Validate inputs
  if (!is.numeric(u) || length(u) != 2L || any(!is.finite(u))) {
    stop("`u` must be a numeric vector of length 2 with finite values.", call. = FALSE)
  }
  if (any(u <= 0) || any(u > 1)) {
    stop("`u` must lie in (0, 1].", call. = FALSE)
  }
  if (!is.numeric(theta) || length(theta) != 1L || !is.finite(theta)) {
    stop("`theta` must be a finite numeric scalar.", call. = FALSE)
  }
  if (theta < 0) {
    stop("`theta` must be >= 0. (Clayton requires nonnegative dependence.)", call. = FALSE)
  }

  # Independence limit: theta -> 0 => density = 1
  if (theta <= 1e-10) return(1.0)

  u1 <- u[1]; u2 <- u[2]

  # Work in log-domain for stability:
  # log c = log(1+θ) - (1+θ)(log u1 + log u2) + (-2 - 1/θ) * log(u1^{-θ} + u2^{-θ} - 1)
  lu1 <- log(u1)
  lu2 <- log(u2)

  # la = -θ log u1, lb = -θ log u2  (always >= 0 because u in (0,1])
  la <- -theta * lu1
  lb <- -theta * lu2

  # Stable log(u1^{-θ} + u2^{-θ} - 1) using a max-trick (log-sum-exp with a -1 term)
  m <- max(la, lb, 0)  # include 0 since we subtract 1 => exp(0) term
  # s = exp(la) + exp(lb) - 1 = exp(m) * (exp(la-m) + exp(lb-m) - exp(-m))
  inner <- exp(la - m) + exp(lb - m) - exp(-m)

  # Guard against numerical negativity due to rounding
  if (inner <= 0) {
    # If this triggers, inputs are at machine extremes; return ~0 density
    return(0.0)
  }

  log_s <- m + log(inner)

  log_c <- log1p(theta) - (1 + theta) * (lu1 + lu2) + (-2 - 1 / theta) * log_s

  # Convert back to density
  c_val <- exp(log_c)

  # Finite guard (just in case)
  if (!is.finite(c_val)) c_val <- 0.0

  c_val
}
