#' Fung–Hsieh Factors (Monthly, xts)
#'
#' Monthly time series of commonly used Fung–Hsieh style and macro factors.
#' The object is an \code{xts} matrix indexed by month (class
#' \code{zoo::yearmon}) with the columns listed below. Typical use cases
#' include hedge-fund replication and factor attribution.
#'
#' @format An \code{xts} object with 276 monthly observations
#' (Jan 1994 to Dec 2016), indexed by \code{zoo::yearmon}, and 8 columns.
#'
#' \strong{All columns are expressed in percentage points}, never in basis
#' points or decimals. Divide by 100 before combining them with decimal return
#' series such as \code{PerformanceAnalytics::edhec}.
#'
#' \describe{
#'   \item{EMKT}{Equity market factor, \% per month. Mean 0.62, sd 4.24
#'     (14.7\% annualized).}
#'   \item{RF}{Risk-free rate, \% per month. Always non-negative; maximum 0.56,
#'     i.e. 6.7\% annualized.}
#'   \item{SS}{Size spread (small minus large), \% per month. Mean 0.05,
#'     sd 3.26, correlation with \code{EMKT} of 0.08 — the near-zero mean and
#'     low market correlation confirm a long–short spread rather than a
#'     directional return.}
#'   \item{CST10Y}{\emph{Change} in the 10-year U.S. Treasury constant-maturity
#'     yield, in percentage points per month (range −1.11 to 0.65). Not a
#'     return.}
#'   \item{BAA}{\emph{Change} in the Moody's Baa credit spread, in percentage
#'     points per month (range −0.99 to 1.45). Not a return.}
#'   \item{PTFSBD}{Fung–Hsieh primitive trend-following straddle: bond, \% per
#'     month. Mean −1.67, sd 15.23.}
#'   \item{PTFSCOM}{Fung–Hsieh primitive trend-following straddle: commodity,
#'     \% per month. Mean −0.55, sd 14.28.}
#'   \item{PTFSFX}{Fung–Hsieh primitive trend-following straddle: currency,
#'     \% per month. Mean −0.85, sd 19.48.}
#' }
#'
#' @details
#' The three \code{PTFS*} series are lookback-straddle returns. They are
#' strongly right-skewed with large positive tails (up to +89.8\% in a single
#' month) and negative means, which is the expected signature of a long-option
#' payoff, not a data error.
#'
#' Two of the eight columns — \code{CST10Y} and \code{BAA} — are changes in
#' yields rather than returns. Do not rescale them as if they were returns, and
#' interpret their loadings as sensitivities per percentage point of yield
#' change.
#'
#' The time index is of class \code{zoo::yearmon} (a calendar month with no
#' day-of-month), so the series aligns with other monthly data by month,
#' irrespective of any day-of-month convention. To merge with a
#' \code{Date}-indexed series, coerce its index with \code{as.yearmon()}.
#'
#' @section Provenance:
#' This object is a static snapshot compiled for the book's examples, not a
#' maintained feed. The reconstruction script lives in \code{data-raw/FungHsieh.R}.
#' The exact index pair underlying \code{SS} and the precise vintage of the
#' credit-spread series depend on the source used; confirm them against
#' \code{data-raw/FungHsieh.R} before drawing conclusions that hinge on the
#' definition of a particular factor.
#'
#' @source
#' Compiled from public factor sources commonly used in the Fung–Hsieh
#' literature: David A. Hsieh's hedge-fund data library
#' (\url{https://faculty.fuqua.duke.edu/~dah7/HFRFData.htm}) for the
#' \code{PTFS*} straddle factors, and FRED/H.15 for the yield and credit
#' series. See \code{data-raw/FungHsieh.R} for the assembly steps.
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
