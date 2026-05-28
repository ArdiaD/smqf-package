#' Fama–French Factors (Weekly, xts)
#'
#' Weekly time series of the three Fama–French equity risk factors and the
#' risk-free rate, as provided by Kenneth French's data library.
#' Values are expressed in \strong{percentage points} (e.g., \code{1.60} means
#' a return of 1.60\%).
#'
#' @format An \code{xts} object with 4\,834 weekly observations
#' (from 1926-07-02 to 2019-02-22) and 4 columns:
#' \describe{
#'   \item{mkt_rf}{Excess return on the market (market return minus risk-free
#'                 rate), in \%.}
#'   \item{smb}{Small-Minus-Big size factor return, in \%.}
#'   \item{hml}{High-Minus-Low value factor return, in \%.}
#'   \item{rf}{Risk-free rate (weekly), in \%.}
#' }
#'
#' @details
#' The time index is a weekly \code{Date}. Divide by 100 to convert to decimal
#' returns before use in calculations. To work at monthly frequency, downsample
#' with, for example, \code{FamaFrench[xts::endpoints(FamaFrench, "months"), ]}.
#'
#' @source
#' Kenneth R. French Data Library,
#' \url{https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html}.
#'
#' @references
#' Fama, E. F., & French, K. R. (1993). Common Risk Factors in the Returns on
#' Stocks and Bonds. \emph{Journal of Financial Economics}, 33(1), 3–56.
#'
#' @examples
#' data("FamaFrench")
#' class(FamaFrench)        # "xts" "zoo"
#' dim(FamaFrench)          # 4834 x 4
#' head(FamaFrench)
#'
#' # Convert to decimal and extract the three equity factors
#' ff <- FamaFrench[, c("mkt_rf", "smb", "hml")] / 100
#' rf <- FamaFrench[, "rf"] / 100
#'
#' @usage data("FamaFrench")
#' @docType data
#' @keywords datasets time-series finance
"FamaFrench"
