#' Gumbel Copula CDF (2-Dimensional)
#'
#' Computes the bivariate Gumbel copula cumulative distribution function (CDF)
#' at \eqn{(u_1,u_2)} for dependence parameter \eqn{\theta \ge 1}.
#'
#' The Gumbel copula exhibits upper-tail dependence
#' \eqn{\lambda_U = 2 - 2^{1/\theta}} and no lower-tail dependence
#' (\eqn{\lambda_L = 0}). When \eqn{\theta = 1}, it reduces to the independence
#' copula with \eqn{C(u_1,u_2)=u_1 u_2}.
#'
#' @param u Numeric vector of length 2 with entries in \eqn{(0,1]}:
#'   the evaluation point \eqn{(u_1,u_2)}.
#' @param theta Numeric scalar, the Gumbel dependence parameter \eqn{\theta \ge 1}.
#'
#' @return A numeric scalar: \eqn{C(u_1,u_2;\theta)}.
#'
#' @details
#' The CDF is
#' \deqn{
#'   C(u_1,u_2;\theta)
#'   = \exp\!\left(
#'       -\left[(-\log u_1)^{\theta} + (-\log u_2)^{\theta}\right]^{1/\theta}
#'     \right), \qquad \theta \ge 1.
#' }
#'
#' @references
#' Joe, H. (1997). \emph{Multivariate Models and Dependence Concepts}. Chapman & Hall.
#' Nelsen, R. B. (2006). \emph{An Introduction to Copulas} (2nd ed.). Springer.
#'
#' @examples
#' f_gumbel_copula_2d_cdf(c(0.5, 0.8), theta = 2)
#' f_gumbel_copula_2d_cdf(c(0.7, 0.7), theta = 1)  # independence: ~0.49
#'
#' @seealso \code{\link{f_gumbel_copula_2d_pdf}}, \code{\link{f_clayton_copula_2d_pdf}},
#'   \code{\link{f_normal_copula_pdf}}, \code{\link{f_student_copula_pdf}}
#' @export
f_gumbel_copula_2d_cdf <- function(u, theta) {
  ## --- input validation ---
  if (!is.numeric(u) || length(u) != 2L || any(u <= 0) || any(u > 1))
    stop("'u' must be a numeric vector of length 2 with entries in (0, 1].",
         call. = FALSE)
  if (!is.numeric(theta) || length(theta) != 1L || !is.finite(theta) || theta < 1)
    stop("'theta' must be a finite numeric scalar >= 1.", call. = FALSE)
  ## --- end validation ---
  u1  <- u[1]
  u2  <- u[2]
  cdf <- exp(-((-log(u1))^theta + (-log(u2))^theta)^(theta^(-1)))
  cdf
}

#' Gumbel Copula PDF (2-Dimensional)
#'
#' Computes the bivariate Gumbel copula probability density function (PDF)
#' at \eqn{(u_1,u_2)} for dependence parameter \eqn{\theta \ge 1}.
#'
#' @param u Numeric vector of length 2 with entries in \eqn{(0,1]}:
#'   the evaluation point \eqn{(u_1,u_2)}.
#' @param theta Numeric scalar, the Gumbel dependence parameter \eqn{\theta \ge 1}.
#'
#' @return A numeric scalar: \eqn{c(u_1,u_2;\theta)}.
#'
#' @details
#' The PDF can be written as
#' \deqn{
#'   c(u_1,u_2;\theta)
#'   = C(u_1,u_2;\theta)\;
#'     \frac{ \{[-\log u_1]\;[-\log u_2]\}^{\theta-1} }{u_1 u_2}\;
#'     \left( (-\log u_1)^{\theta} + (-\log u_2)^{\theta} \right)^{1/\theta - 2}\;
#'     \left( \left\{ (-\log u_1)^{\theta} + (-\log u_2)^{\theta} \right\}^{1/\theta}
#'            + \theta - 1 \right).
#' }
#' When \eqn{\theta = 1}, \eqn{c(u_1,u_2;1) \equiv 1} (independence).
#'
#' @note Numerical stability may degrade as \eqn{u_i \to 0^+} (large \eqn{-\log u_i}).
#'
#' @references
#' Joe, H. (1997). \emph{Multivariate Models and Dependence Concepts}. Chapman & Hall.
#' Nelsen, R. B. (2006). \emph{An Introduction to Copulas} (2nd ed.). Springer.
#'
#' @examples
#' f_gumbel_copula_2d_pdf(c(0.5, 0.8), theta = 2)
#' f_gumbel_copula_2d_pdf(c(0.7, 0.7), theta = 1)  # independence: 1
#'
#' @seealso \code{\link{f_gumbel_copula_2d_cdf}}, \code{\link{f_clayton_copula_2d_pdf}},
#'   \code{\link{f_normal_copula_pdf}}, \code{\link{f_student_copula_pdf}}
#' @export
f_gumbel_copula_2d_pdf <- function(u, theta) {
  ## --- input validation ---
  if (!is.numeric(u) || length(u) != 2L || any(u <= 0) || any(u > 1))
    stop("'u' must be a numeric vector of length 2 with entries in (0, 1].",
         call. = FALSE)
  if (!is.numeric(theta) || length(theta) != 1L || !is.finite(theta) || theta < 1)
    stop("'theta' must be a finite numeric scalar >= 1.", call. = FALSE)
  ## --- end validation ---
  u1 <- u[1]
  u2 <- u[2]

  pdf <- f_gumbel_copula_2d_cdf(u, theta) * ((u1 * u2)^(-1)) *
    (((-log(u1)) * (-log(u2)))^(theta - 1))
  pdf <- pdf * (((-log(u1))^theta + (-log(u2))^theta)^(theta^(-1) - 2))
  pdf <- pdf * ((((-log(u1))^theta + (-log(u2))^theta)^(theta^(-1))) + theta - 1)
  pdf
}
