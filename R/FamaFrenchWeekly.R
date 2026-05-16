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
#' Divide by 100 to convert to decimal returns before use in calculations.
#' For the monthly version of this dataset see \code{\link{FamaFrenchMonthly}}.
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
#' data("FamaFrenchWeekly")
#' class(FamaFrenchWeekly)        # "xts" "zoo"
#' dim(FamaFrenchWeekly)          # 4834 x 4
#' head(FamaFrenchWeekly)
#'
#' # Convert to decimal and extract the three equity factors
#' ff <- FamaFrenchWeekly[, c("mkt_rf", "smb", "hml")] / 100
#' rf <- FamaFrenchWeekly[, "rf"] / 100
#'
#' @seealso \code{\link{FamaFrenchMonthly}} for the lower-frequency
#'   (monthly, 1969-1998) companion dataset built from the same Kenneth French
#'   source. The two datasets are pedagogically complementary: the weekly
#'   version offers a much longer sample for time-series exercises, while the
#'   monthly version is convenient for low-frequency factor-model
#'   illustrations.
#'
#' @usage data("FamaFrenchWeekly")
#' @docType data
#' @keywords datasets time-series finance
"FamaFrenchWeekly"
