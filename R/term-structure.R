#' Nelson–Siegel (3-parameter) Yield Curve
#'
#' Computes spot rates using the 3-parameter Nelson–Siegel specification
#' with a single decay parameter \eqn{\gamma_1}.
#'
#' @param tau Numeric vector of maturities (in years).
#' @param gamma Numeric scalar (or length-\eqn{\ge 1} vector) giving the decay
#'   parameter \eqn{\gamma_1}. Only \code{gamma[1]} is used; passing a longer
#'   vector (e.g., the two-element \eqn{\gamma} from a Svensson fit) will trigger
#'   a warning and \code{gamma[2:]} are silently ignored.
#' @param beta Numeric vector of length 3, the NS loadings
#'   \eqn{(\beta_0,\beta_1,\beta_2)}.
#'
#' @return Numeric vector of spot rates \eqn{y(\tau)} for each \code{tau}.
#'
#' @details
#' With \eqn{\gamma_1>0}, the loadings are
#' \deqn{f_1(\tau)=\frac{1-e^{-\gamma_1\tau}}{\gamma_1\tau}, \quad
#'       f_2(\tau)=f_1(\tau)-e^{-\gamma_1\tau},}
#' and the curve is \eqn{y(\tau)=\beta_0+\beta_1 f_1(\tau)+\beta_2 f_2(\tau)}.
#' For \code{tau=0}, the function returns 0 (instead of \code{NaN}).
#'
#' @references
#' Nelson, C. R., & Siegel, A. F. (1987). Parsimonious Modeling of Yield Curves.
#' \emph{Journal of Business}, 60(4), 473–489.
#'
#' @examples
#' tau <- c(0, 0.5, 2, 5, 10)
#' f_NelsonSiegel(tau, gamma = c(1.2), beta = c(2, -1, 0.5))
#'
#' @export
f_NelsonSiegel <- function(tau, gamma, beta) {
  ### Adjusted Svensson function
  ###  INPUTS
  ###   tau   : [vector] (n x 1) maturities (in year)
  ###   beta  : [vector] (3 x 1)
  ###  OUTPUTS
  ###   y     : [vector] (n x 1) or spot rates (yields) corresponding to maturities tau

  if (length(gamma) > 1L)
    warning("f_NelsonSiegel uses only gamma[1]; gamma[2:] are ignored.",
            call. = FALSE)

  gamma1_tau <- gamma[1] * tau
  f1 <- (1 - exp(-gamma1_tau)) / gamma1_tau
  f2 <- f1 - exp(-gamma1_tau)

  y <- beta[1] + beta[2] * f1 + beta[3] * f2

  y[is.nan(y)] <- 0 #for tau=0, the rate is NaN, so assume y=0

  return(y)
}


#' Fit Adjusted Svensson on \eqn{\sqrt{y}} (Fixed Decays)
#'
#' Performs an OLS fit of the \emph{adjusted} Svensson curve to the square-root
#' of observed spot rates, using fixed decay parameters \eqn{\gamma_1,\gamma_2}
#' as suggested in de Pooter (2007).
#'
#' @param tau Numeric vector of maturities (years). Values \code{< 1e-4} are
#'   bumped to \code{1e-4} to avoid singularities at 0.
#' @param y Numeric vector of spot rates (same length as \code{tau}).
#'
#' @return Numeric vector \code{beta} of length 4 (the adjusted Svensson
#'   loadings) estimated by OLS on \eqn{\sqrt{y}}.
#'
#' @details
#' The regressors are
#' \deqn{f_1(\tau)=\frac{1-e^{-\gamma_1\tau}}{\gamma_1\tau}, \quad
#'       f_2(\tau)=f_1(\tau)-e^{-\gamma_1\tau}, \quad
#'       f_3(\tau)=\frac{1-e^{-\gamma_2\tau}}{\gamma_2\tau}-e^{-2\gamma_2\tau},}
#' with \eqn{\gamma_1 = 0.0609\times 12} and \eqn{\gamma_2 = \frac{1}{9.73}\times 12}
#' (monthly scaling, per de Pooter). The model fitted is
#' \eqn{\sqrt{y} = \beta_0 + \beta_1 f_1 + \beta_2 f_2 + \beta_3 f_3 + \varepsilon}.
#'
#' @references
#' de Pooter, M. (2007). \emph{Examining the Nelson–Siegel Class of Term
#' Structure Models}. Tinbergen Institute Discussion Paper.
#' Svensson, L. E. O. (1994). Estimating and Interpreting Forward Interest Rates.
#' \emph{IMF Working Paper}.
#'
#' @examples
#' set.seed(1)
#' tau <- c(0.25, 1, 2, 5, 10, 20, 30)
#' y   <- 0.02 + 0.01*exp(-tau) + rnorm(length(tau), sd = 0.001)
#' beta_hat <- f_FitSqrtSvensson(tau, y)
#' beta_hat
#'
#' @export
f_FitSqrtSvensson <- function(tau, y) {
  ## Fit ADJUSTED Svensson function on sqrt(y)
  #  INPUTS
  #   tau     : [vector] (n x 1) of maturities (wrt annual)
  #   y       : [vector] (n x 1) of spot interest rates (yields)
  #  OUTPUTS
  #   beta    : [vector] (4 x 1)
  #  REFERENCES
  #   o De Pooter, M. (2007), Examining the Nelson-Siegel Class of Term
  #     Structure Models, Tinbergen Institute Discussion Paper

  tau[tau < 1e-4] <- 1e-4

  gamma    <- numeric(2)
  gamma[1] <- 0.0609 * 12    # gamma_1 := 1 / lambda_1, where lambda_1 is 16.42  see Michiel de Pooter (2007)
  gamma[2] <- 1 / 9.73 * 12  # gamma_2 := 1 / lambda_2, where lambda_2 is 9.73  see Michiel de Pooter (2007)

  # OLS estimation
  n          <- length(tau)
  gamma1_tau <- gamma[1] * tau  # gamma is defined as 1 / lambda
  gamma2_tau <- gamma[2] * tau
  f1 <- (1 - exp(-gamma1_tau)) / gamma1_tau
  f2 <- f1 - exp(-gamma1_tau)
  f3 <- (1 - exp(-gamma2_tau)) / gamma2_tau - exp(-2 * gamma2_tau)  # adjusted Svensson term

  X    <- cbind(rep(1, n), f1, f2, f3)
  beta <- (solve(t(X) %*% X)) %*% (t(X) %*% sqrt(y))  # OLS: beta = inv(X'X) * X'y

  return(beta)
}


#' Adjusted Svensson Curve (Fixed Decays), Then Squared
#'
#' Evaluates the adjusted Svensson yield curve (using fixed \eqn{\gamma_1,\gamma_2}
#' per de Pooter) at maturities \code{tau}, with coefficients \code{beta}, and
#' then returns the \emph{squared} values \eqn{y(\tau)^2}.
#'
#' @param tau Numeric vector of maturities (years).
#' @param beta Numeric vector of length 4, adjusted Svensson coefficients
#'   \eqn{(\beta_0,\beta_1,\beta_2,\beta_3)} (e.g., as returned by
#'   \code{\link{f_FitSqrtSvensson}} but note that \code{f_FitSqrtSvensson}
#'   fits \eqn{\sqrt{y}}).
#'
#' @return Numeric vector of \eqn{y(\tau)^2}. For \code{tau = 0}, values
#'   producing \code{NaN} are replaced by 0.
#'
#' @details
#' Uses the same fixed decays as \code{\link{f_FitSqrtSvensson}}:
#' \eqn{\gamma_1 = 0.0609\times 12}, \eqn{\gamma_2 = (1/9.73)\times 12}, and
#' loadings
#' \deqn{f_1(\tau)=\frac{1-e^{-\gamma_1\tau}}{\gamma_1\tau},\;
#'       f_2(\tau)=f_1(\tau)-e^{-\gamma_1\tau},\;
#'       f_3(\tau)=\frac{1-e^{-\gamma_2\tau}}{\gamma_2\tau}-e^{-2\gamma_2\tau}.}
#'
#' @references
#' de Pooter, M. (2007). \emph{Examining the Nelson–Siegel Class of Term
#' Structure Models}. Tinbergen Institute Discussion Paper.
#'
#' @examples
#' tau <- seq(0, 30, by = 0.5)
#' beta <- c(0.02, -0.01, 0.015, -0.005)
#' y2 <- f_PowerSvensson(tau, beta)
#' head(y2)
#'
#' @seealso \code{\link{f_FitSqrtSvensson}}, \code{\link{f_NelsonSiegel}}
#' @export
f_PowerSvensson <- function(tau, beta) {
  ### Adjusted Svensson function
  ###  INPUTS
  ###   tau   : [vector] (n x 1) maturities (in year)
  ###   beta  : [vector] (4 x 1)
  ###  OUTPUTS
  ###   y     : [vector] (n x 1) squared spot rates corresponding to maturities tau

  gamma    <- numeric(2)
  gamma[1] <- 0.0609 * 12    # gamma_1 := 1 / lambda_1, where lambda_1 is 16.42  see Michiel de Pooter (2007)
  gamma[2] <- 1 / 9.73 * 12  # gamma_2 := 1 / lambda_2, where lambda_2 is 9.73  see Michiel de Pooter (2007)

  gamma1_tau <- gamma[1] * tau
  gamma2_tau <- gamma[2] * tau
  f1 <- (1 - exp(-gamma1_tau)) / gamma1_tau
  f2 <- f1 - exp(-gamma1_tau)
  f3 <- (1 - exp(-gamma2_tau)) / gamma2_tau - exp(-2 * gamma2_tau)  # adjusted Svensson term

  y           <- beta[1] + beta[2] * f1 + beta[3] * f2 + beta[4] * f3
  y[is.nan(y)] <- 0   # for tau=0, the rate is NaN, so assume y=0
  y           <- y^2  # take the power

  return(y)
}

