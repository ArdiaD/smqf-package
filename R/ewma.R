#' Exponentially Weighted Moving-Average (EWMA) Volatility
#'
#' Computes EWMA volatility column-wise for a return matrix using either
#' RiskMetrics or Meucci weighting. Recent observations receive higher weight.
#'
#' @param rets Numeric matrix or data frame of returns with \emph{older rows on top
#'   and most recent rows at the bottom}. Dimensions \eqn{r \times c} where \eqn{r}
#'   is the number of observations and \eqn{c} the number of series.
#' @param history Logical. If \code{FALSE}, returns the EWMA volatility using all
#'   available rows. If \code{TRUE}, returns the full history (rolling) of EWMA
#'   volatilities computed at each time \eqn{t=1,\dots,r}.
#' @param lambda Numeric decay parameter. Larger values put more weight on recent
#'   observations. See Details for half-life mapping.
#' @param type Character string selecting the weights:
#'   \itemize{
#'     \item \code{"Riskmetrics"}: \eqn{w_t \propto \lambda^{t-1}}, normalized over \eqn{r}.
#'     \item \code{"Meucci"}: \eqn{w_t \propto e^{-\lambda (r-t)}}, normalized to sum to 1.
#'   }
#'
#' @return If \code{history = FALSE}, a numeric vector of length \eqn{c} with the
#'   EWMA volatility for each column. If \code{history = TRUE}, a numeric matrix
#'   of dimension \eqn{r \times c} where row \eqn{t} contains the EWMA volatility
#'   computed from rows \code{1:t}.
#'
#' @details
#' Let \eqn{r_{t,j}} be returns for series \eqn{j}. Given normalized weights
#' \eqn{w_t \ge 0} with \eqn{\sum_t w_t = 1}, the EWMA volatility is
#' \deqn{\sigma_j = \sqrt{\sum_{t} w_t\, r_{t,j}^2}.}
#'
#' \strong{Half-life:} If the weight decays by half after \eqn{H} periods,
#' \eqn{\lambda} relates to \eqn{H} as follows:
#' \itemize{
#'   \item RiskMetrics (geometric decay): \eqn{\lambda = 2^{-1/H}}.
#'   \item Meucci (continuous decay): \eqn{\lambda = 2 \ln(2) / H} when using the
#'         convention \eqn{e^{-\lambda\,H/2}=1/2}.
#' }
#'
#' @examples
#' set.seed(1)
#' X <- matrix(rnorm(250 * 3, sd = 0.01), ncol = 3)  # 250 days, 3 assets
#' # One-shot EWMA vol with RiskMetrics lambda ~ 0.94
#' f_ewma_vol(X, history = FALSE, lambda = 0.94, type = "Riskmetrics")
#' # Rolling EWMA volatilities (Meucci)
#' V <- f_ewma_vol(X, history = TRUE, lambda = 0.1, type = "Meucci")
#' dim(V)  # 250 x 3
#'
#' @references
#' J.P. Morgan/Reuters (1996). \emph{RiskMetrics—Technical Document}.
#' Meucci, A. (2007). \emph{Risk and Asset Allocation}. Springer.
#'
#' @export
f_ewma_vol <- function(rets, history, lambda, type) {
  ### Exponentially weighted moving average
  # NOTE
  #    Recent data should be on bottom of the vector matrix, e.g.
  #    Oct 2012
  #    Nov 2012
  #    Dec 2012
  #    Jan 2013
  #    Default half-life decay solves: exp(-lambda * T/2) = 1/2
  #    The largets the lambda, the more weight have recent observations

  size <- dim(rets)
  r <- size[1]
  c <- size[2]

  Ewma_ <- function(rets, lambda, r, c, type) {

    if (type == 'Riskmetrics') {
      w <- (1 - lambda) / (1 - lambda^r) * lambda ** seq(0, r - 1, 1)
    } else if (type == 'Meucci') {
      w <- exp(-lambda * (r - seq(r, 1, -1)))
      w <- w / sum(w)
    } else
      stop('Weights type not well defined')

    w   <- w[length(w):1]                # flipud(w)
    w   <- kronecker(matrix(1, 1, c), w) # repmat(w, 1, c)
    vol <- sqrt(apply(w * (rets^2), 2, sum))
    return(vol)
  }

  if (!history) {
    vol. <- Ewma_(rets, lambda, r, c, type)
    return(vol.)
  }
  else if (history == TRUE) {
    vol_ <- matrix(NA, r, c)
    for (t in 1:r) {
      vol_[t, ] <- Ewma_(rets[1:t, ], lambda, t, c, type)
    }
    return(vol_)
  }
  else
    stop("History not correctly specified", call. = FALSE)
}
