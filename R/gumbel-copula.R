#' Gumbel Copula CDF (2-Dimensional)
#'
#' Computes the bivariate Gumbel copula cumulative distribution function (CDF)
#' at \eqn{(u_1,u_2)} for dependence parameter \eqn{\theta} (here `k1`).
#'
#' The Gumbel copula exhibits upper-tail dependence
#' \eqn{\lambda_U = 2 - 2^{1/\theta}} and no lower-tail dependence
#' (\eqn{\lambda_L = 0}). When \eqn{\theta = 1}, it reduces to the independence
#' copula with \eqn{C(u_1,u_2)=u_1 u_2}.
#'
#' @param u Numeric vector of length 2 with entries in \eqn{(0,1]}:
#'   the evaluation point \eqn{(u_1,u_2)}.
#' @param k1 Numeric scalar, the Gumbel dependence parameter \eqn{\theta \ge 1}.
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
#' Joe, H. (1997). *Multivariate Models and Dependence Concepts*. Chapman & Hall.
#' Nelsen, R. B. (2006). *An Introduction to Copulas* (2nd ed.). Springer.
#'
#' @examples
#' f_gumbel_copula_2d_cdf(c(0.5, 0.8), k1 = 2)
#' f_gumbel_copula_2d_cdf(c(0.7, 0.7), k1 = 1)  # independence: ~0.49
#'
#' @export
f_gumbel_copula_2d_cdf <- function(u, k1) {
  u1  <- u[1]
  u2  <- u[2]
  cdf <- exp(-((-log(u1))^k1 + (-log(u2))^k1)^(k1^(-1)))
  cdf
}

#' Gumbel Copula PDF (2-Dimensional)
#'
#' Computes the bivariate Gumbel copula probability density function (PDF)
#' at \eqn{(u_1,u_2)} for dependence parameter \eqn{\theta} (here `k1`).
#'
#' @param u Numeric vector of length 2 with entries in \eqn{(0,1]}:
#'   the evaluation point \eqn{(u_1,u_2)}.
#' @param k1 Numeric scalar, the Gumbel dependence parameter \eqn{\theta \ge 1}.
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
#' Joe, H. (1997). *Multivariate Models and Dependence Concepts*. Chapman & Hall.
#' Nelsen, R. B. (2006). *An Introduction to Copulas* (2nd ed.). Springer.
#'
#' @examples
#' f_gumbel_copula_2d_pdf(c(0.5, 0.8), k1 = 2)
#' f_gumbel_copula_2d_pdf(c(0.7, 0.7), k1 = 1)  # independence: 1
#'
#' @export
f_gumbel_copula_2d_pdf <- function(u, k1) {
  u1 <- u[1]
  u2 <- u[2]

  pdf <- f_gumbel_copula_2d_cdf(u, k1) * ((u1 * u2)^(-1)) *
    (((-log(u1)) * (-log(u2)))^(k1 - 1))
  pdf <- pdf * (((-log(u1))^k1 + (-log(u2))^k1)^(k1^(-1) - 2))
  pdf <- pdf * ((((-log(u1))^k1 + (-log(u2))^k1)^(k1^(-1))) + k1 - 1)
  pdf
}
