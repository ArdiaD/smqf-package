#' Fung–Hsieh Factors (Monthly, xts)
#'
#' Monthly time series of commonly used Fung–Hsieh style and macro factors.
#' The object is an \code{xts} matrix indexed by month (class
#' \code{zoo::yearmon}) with the columns listed below. Typical use cases
#' include hedge-fund replication and factor attribution.
#'
#' @format An \code{xts} object with 276 monthly observations
#' (Jan 1994 to Dec 2016), indexed by \code{zoo::yearmon}, and 8 columns:
#' \describe{
#'   \item{EMKT}{Equity market factor (broad market return / excess return).}
#'   \item{RF}{Risk-free rate (monthly).}
#'   \item{SS}{Size or related equity style spread (e.g., small–minus–big).}
#'   \item{CST10Y}{Change in the 10-year U.S. Treasury constant-maturity yield.}
#'   \item{BAA}{Change in a BAA credit spread / yield (credit conditions).}
#'   \item{PTFSBD}{Fung–Hsieh trend-following factor: bond.}
#'   \item{PTFSCOM}{Fung–Hsieh trend-following factor: commodity.}
#'   \item{PTFSFX}{Fung–Hsieh trend-following factor: currency (FX).}
#' }
#'
#' @details
#' Columns are provided as in the original Fung–Hsieh factor construction.
#' Units may appear as percentage points or basis points depending on source/
#' vintage; treat the series consistently within your analysis. The time index
#' is of class \code{zoo::yearmon} (a calendar month with no day-of-month), so
#' the series aligns with other monthly data by month, irrespective of any
#' day-of-month convention.
#'
#' @source
#' Compiled from public factor sources commonly used in the Fung–Hsieh
#' literature
#' (e.g., Hsieh’s data library, FRED/H.15, and Fama–French style factors).
#' If you distribute the data, include a \code{data-raw/} script that reproduces
#' this object from original sources.
#'
#' @references
#' Fung, W., & Hsieh, D. A. (2004). Hedge Fund Benchmarks: A Risk-Based
#' Approach.
#' \emph{Financial Analysts Journal}, 60(5), 65–80.
#' Fung, W., & Hsieh, D. A. (2001). The Risk in Hedge Fund Strategies:
#' Theory and Evidence from Trend Followers. \emph{Review of Financial Studies}, 14(2), 313–341.
#'
#' @examples
#' data("FungHsieh")
#' class(FungHsieh)              # "xts" "zoo"
#' head(FungHsieh)
#' colnames(FungHsieh)
#' # Quick plot of the three PTFS factors
#' if (requireNamespace("zoo", quietly = TRUE)) {
#'   zoo::plot.zoo(FungHsieh[, c("PTFSBD", "PTFSCOM", "PTFSFX")], screens = 1, col = 1:3)
#' }
#'
#' @usage data("FungHsieh")
#' @docType data
#' @keywords datasets time-series finance
"FungHsieh"
