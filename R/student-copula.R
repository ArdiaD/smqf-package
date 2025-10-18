#' Multivariate Student-t Copula PDF
#'
#' Computes the probability density function (PDF) of the multivariate
#' Student-\eqn{t} copula at a specified point \eqn{u \in [0,1]^N}, given
#' location vector \eqn{\mu}, scatter matrix \eqn{\Sigma}, and degrees of freedom
#' \eqn{\nu}.
#'
#' @param u Numeric vector of length \eqn{N} with entries in \eqn{(0,1)}:
#'   the evaluation point in the copula’s domain.
#' @param mu Numeric vector of length \eqn{N}, the location (mean) vector of the
#'   underlying multivariate Student-\eqn{t} distribution.
#' @param Sigma Numeric \eqn{N \times N} positive-definite scatter matrix.
#'   Typically a correlation matrix when defining a copula.
#' @param nu Positive numeric scalar: degrees of freedom of the Student-\eqn{t}
#'   distribution (\eqn{\nu > 0}).
#'
#' @return A numeric scalar: the value of the Student-\eqn{t} copula density
#'   \eqn{c(u; \mu, \Sigma, \nu)} at \code{u}.
#'
#' @details
#' The multivariate Student-\eqn{t} copula density is given by
#' \deqn{
#'   c(u; \mu, \Sigma, \nu)
#'   = \frac{
#'     t_N\!\left(t_{\nu}^{-1}(u); \mu, \Sigma, \nu \right)
#'   }{
#'     \prod_{i=1}^N t_1\!\left(t_{\nu}^{-1}(u_i); \mu_i, \sigma_i^2, \nu \right)
#'   },
#' }
#' where \eqn{t_N} and \eqn{t_1} denote the multivariate and univariate Student-\eqn{t}
#' densities, respectively, and \eqn{t_{\nu}^{-1}} is the quantile function of
#' the univariate Student-\eqn{t} with \eqn{\nu} degrees of freedom.
#'
#' For \eqn{\nu \to \infty}, this copula converges to the Gaussian copula.
#'
#' @references
#' Demarta, S., & McNeil, A. J. (2005). The t Copula and Related Copulas.
#' *International Statistical Review*, 73(1), 111–129.
#' Joe, H. (1997). *Multivariate Models and Dependence Concepts*. Chapman & Hall.
#' Nelsen, R. B. (2006). *An Introduction to Copulas* (2nd ed.). Springer.
#'
#' @examples
#' # Example: 2D t-copula density
#' mu <- c(0, 0)
#' Sigma <- matrix(c(1, 0.7, 0.7, 1), 2, 2)
#' f_student_copula_pdf(c(0.6, 0.8), mu, Sigma, nu = 5)
#'
#' # Compare to Gaussian copula (nu large)
#' f_student_copula_pdf(c(0.6, 0.8), mu, Sigma, nu = 100)
#'
#' @importFrom stats qt dt
#' @importFrom pracma mldivide
#' @export
f_student_copula_pdf <- function (u, mu, Sigma, nu) {
  # Pdf of the copula of the Student t distribution at the generic point u in the unit hypercube
  # INPUTS
  #   u     : [vector] (J x 1) grade
  #   Mu    : [vector] (N x 1) mean
  #   Sigma : [matrix] (N x N) scatter
  #   nu    : [scalar] degrees of freedom
  # OUTPUTS
  #   F_U   : [vector] (J x 1) PDF

  N <- length(u)
  s <- sqrt(diag(Sigma))

  x <- mu + s * qt(p = u, df = nu)

  z2 <- (x - mu) %*% pracma::mldivide(Sigma, (x - mu))
  K  <- (nu * pi)^(-N / 2) * gamma((nu + N) / 2) / gamma(nu / 2) * ((det(Sigma))^(-0.5))
  Numerator <- K * (1 + z2 / nu)^(-(nu + N) / 2)

  fs <- dt((x - mu) / s, nu) / s
  Denominator <- prod(fs)

  F_U <- Numerator / Denominator

  F_U
}
