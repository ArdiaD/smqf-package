#' Fama–French Factors (Monthly, xts)
#'
#' Monthly time series of the three Fama–French equity risk factors and the
#' risk-free rate, as provided by Kenneth French's data library.
#' Values are expressed in \strong{percentage points} (e.g., \code{-1.20}
#' means a return of \eqn{-1.20\%}).
#'
#' @format An \code{xts} object with 360 monthly observations
#' (from 1969-01-01 to 1998-12-01) and 4 columns:
#' \describe{
#'   \item{mkt_rf}{Excess return on the market (market return minus risk-free
#'                 rate), in \%.}
#'   \item{smb}{Small-Minus-Big size factor return, in \%.}
#'   \item{hml}{High-Minus-Low value factor return, in \%.}
#'   \item{rf}{Risk-free rate (monthly), in \%.}
#' }
#'
#' @details
#' The time index is set to the first calendar day of each month.
#' Divide by 100 to convert to decimal returns before use in calculations.
#' For the weekly version of this dataset see \code{\link{FamaFrenchWeekly}}.
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
#' data("FamaFrenchMonthly")
#' class(FamaFrenchMonthly)       # "xts" "zoo"
#' dim(FamaFrenchMonthly)         # 360 x 4
#' head(FamaFrenchMonthly)
#'
#' # Convert to decimal and extract the three equity factors
#' ff <- FamaFrenchMonthly[, c("mkt_rf", "smb", "hml")] / 100
#' rf <- FamaFrenchMonthly[, "rf"] / 100
#'
#' @seealso \code{\link{FamaFrenchWeekly}} for the higher-frequency
#'   (weekly, 1926-2019) companion dataset built from the same Kenneth French
#'   source. The two datasets are pedagogically complementary: the monthly
#'   version is convenient for low-frequency factor-model illustrations, while
#'   the weekly version offers a much longer sample for time-series exercises.
#'
#' @usage data("FamaFrenchMonthly")
#' @docType data
#' @keywords datasets time-series finance
"FamaFrenchMonthly"
