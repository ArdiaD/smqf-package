#' Multivariate Normal Copula PDF
#'
#' Computes the probability density function (PDF) of the Gaussian (normal)
#' copula at a specified point \eqn{u \in [0,1]^N}, given mean vector
#' \eqn{\mu} and covariance matrix \eqn{\Sigma} of the underlying multivariate
#' normal distribution.
#'
#' @param u Numeric vector of length \eqn{N} with entries in \eqn{(0,1)}:
#'   the copula evaluation point.
#' @param mu Numeric vector of length \eqn{N}, the mean of the corresponding
#'   multivariate normal distribution (usually zeros for a copula).
#' @param Sigma Numeric positive-definite \eqn{N \times N} covariance matrix.
#'
#' @return A numeric scalar: the value of the Gaussian copula density
#'   \eqn{c(u; \mu, \Sigma)} at the point \code{u}. The value is returned
#'   as a plain numeric scalar (not a \eqn{1 \times 1} matrix).
#'
#' @details
#' The Gaussian copula density is
#' \deqn{
#'   c(u; \mu, \Sigma)
#'   = \frac{
#'       \phi_N\!\left( \Phi^{-1}(u); \mu, \Sigma \right)
#'     }{
#'       \prod_{i=1}^N \phi_1\!\left( \Phi^{-1}(u_i); \mu_i, \sigma_i^2 \right)
#'     },
#' }
#' where \eqn{\phi_N} and \eqn{\phi_1} are multivariate and univariate normal
#' densities respectively, and \eqn{\Phi^{-1}} denotes the inverse normal CDF
#' applied componentwise. The resulting function is a valid copula density on
#' the unit hypercube \eqn{[0,1]^N}.
#'
#' Typically, the copula is defined for \eqn{\mu = 0} and correlation matrix
#' \eqn{R}, but the implementation here generalizes to arbitrary mean and
#' covariance.
#'
#' @references
#' Joe, H. (1997). *Multivariate Models and Dependence Concepts.* Chapman &
#' Hall.
#' Nelsen, R. B. (2006). *An Introduction to Copulas* (2nd ed.). Springer.
#' McNeil, A. J., Frey, R., & Embrechts, P. (2015). *Quantitative Risk
#' Management.* Princeton University Press.
#'
#' @examples
#' # Example: 2D Gaussian copula
#' Sigma <- matrix(c(1, 0.7, 0.7, 1), 2, 2)
#' mu <- c(0, 0)
#' f_normal_copula_pdf(c(0.5, 0.8), mu, Sigma)
#'
#' # Compare with independence (Sigma = I)
#' f_normal_copula_pdf(c(0.5, 0.8), mu, diag(2))
#'
#' @seealso \code{\link{f_student_copula_pdf}}, \code{\link{f_clayton_copula_2d_pdf}},
#'   \code{\link{f_gumbel_copula_2d_pdf}}
#' @importFrom stats qnorm dnorm
#' @importFrom pracma mldivide
#' @export
f_normal_copula_pdf <- function(u, mu, Sigma) {

  ## --- input validation ---
  if (!is.numeric(u) || length(u) == 0L || any(u <= 0) || any(u >= 1))
    stop("'u' must be a numeric vector with all entries in (0, 1).",
         call. = FALSE)
  N <- length(u)
  if (!is.numeric(mu) || length(mu) != N || any(!is.finite(mu)))
    stop("'mu' must be a finite numeric vector of the same length as 'u'.",
         call. = FALSE)
  if (!is.numeric(Sigma) || !is.matrix(Sigma) ||
      nrow(Sigma) != N || ncol(Sigma) != N || any(!is.finite(Sigma)))
    stop("'Sigma' must be a finite numeric ", N, " x ", N, " matrix.", call. = FALSE)
  ## --- end validation ---

  s <- sqrt(diag(Sigma))

  x <- qnorm(p = u, mean = mu, sd = s)

  Numerator <- (2 * pi)^(-N / 2) *
    (det(Sigma))^(-0.5) *
    exp(-0.5 * drop((x - mu) %*% pracma::mldivide(A = Sigma, B = (x - mu))))

  fs <- dnorm(x, mu, s)
  Denominator <- prod(fs)

  F_U <- Numerator / Denominator

  F_U
}
