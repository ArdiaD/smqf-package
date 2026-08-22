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
#' @param log Logical; if \code{TRUE} the log-density is returned. Defaults to
#'   \code{FALSE}. In high dimension the density itself may overflow or
#'   underflow the double-precision range even though its logarithm is
#'   perfectly well behaved, so \code{log = TRUE} is the safe choice for
#'   likelihoods.
#'
#' @return A numeric scalar: the value of the Gaussian copula density
#'   \eqn{c(u; \mu, \Sigma)} at the point \code{u}, or its logarithm when
#'   \code{log = TRUE}. The value is returned as a plain numeric scalar (not a
#'   \eqn{1 \times 1} matrix).
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
#' # The independence copula has density 1 everywhere, in any dimension
#' d <- 300
#' f_normal_copula_pdf(rep(0.99, d), rep(0, d), diag(d))
#'
#' @seealso \code{\link{f_student_copula_pdf}}, \code{\link{f_clayton_copula_2d_pdf}},
#'   \code{\link{f_gumbel_copula_2d_pdf}}
#' @importFrom stats qnorm dnorm
#' @importFrom pracma mldivide
#' @export
f_normal_copula_pdf <- function(u, mu, Sigma, log = FALSE) {

  ## --- input validation ---
  if (!is.numeric(u) || length(u) == 0L || any(!is.finite(u)) ||
      any(u <= 0) || any(u >= 1))
    stop("'u' must be a finite numeric vector with all entries in (0, 1).",
         call. = FALSE)
  N <- length(u)
  if (!is.numeric(mu) || length(mu) != N || any(!is.finite(mu)))
    stop("'mu' must be a finite numeric vector of the same length as 'u'.",
         call. = FALSE)
  if (!is.numeric(Sigma) || !is.matrix(Sigma) ||
      nrow(Sigma) != N || ncol(Sigma) != N || any(!is.finite(Sigma)))
    stop("'Sigma' must be a finite numeric ", N, " x ", N, " matrix.", call. = FALSE)
  if (!is.logical(log) || length(log) != 1L || is.na(log))
    stop("'log' must be TRUE or FALSE.", call. = FALSE)

  ## Sigma must be a genuine covariance matrix: symmetric and positive
  ## definite. Without this check an asymmetric matrix is silently accepted
  ## and returns a plausible number that corresponds to no valid copula, a
  ## singular one returns Inf, and an indefinite one returns NaN.
  scale_ <- max(1, max(abs(diag(Sigma))))
  if (max(abs(Sigma - t(Sigma))) > sqrt(.Machine$double.eps) * scale_)
    stop("'Sigma' must be symmetric.", call. = FALSE)
  if (any(diag(Sigma) <= 0))
    stop("'Sigma' must have strictly positive diagonal entries.", call. = FALSE)
  min_eig <- min(eigen(Sigma, symmetric = TRUE, only.values = TRUE)$values)
  if (min_eig <= sqrt(.Machine$double.eps) * scale_)
    stop(sprintf(paste0("'Sigma' must be positive definite (smallest eigenvalue %g). ",
                        "Project it first, e.g. as.matrix(Matrix::nearPD(Sigma)$mat)."),
                 min_eig), call. = FALSE)
  ## --- end validation ---

  s <- sqrt(diag(Sigma))

  x <- qnorm(p = u, mean = mu, sd = s)

  # The whole ratio is formed in log space and exponentiated once, at the end.
  # Doing it in two steps -- exp(log_num) / prod(fs) -- breaks down well inside
  # the range of dimensions this function accepts: at N = 300 both the
  # numerator and the product of marginals underflow to zero and the density
  # comes back as 0/0 = NaN, even for the identity matrix whose copula density
  # is exactly 1 everywhere. The logarithm of the same quantity is a modest
  # number at every dimension, so the ratio must be taken there.
  # base::log() is qualified throughout: the `log` argument shadows it here.
  log_num <- -0.5 * N * base::log(2 * pi) -
    0.5 * as.numeric(determinant(Sigma, logarithm = TRUE)$modulus) -
    0.5 * drop((x - mu) %*% pracma::mldivide(A = Sigma, B = (x - mu)))

  log_den <- sum(dnorm(x, mu, s, log = TRUE))

  log_F_U <- log_num - log_den

  if (log) log_F_U else exp(log_F_U)
}
