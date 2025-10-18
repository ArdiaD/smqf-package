#' Daily Term Structure (1m–30y)
#'
#' A compact term–structure object holding daily yield curves across 11 standard
#' maturities from mid-2006 to late-2008. The object is a named list with the
#' observation dates, the maturity grid (in years), and a rates matrix
#' (rows = dates, columns = maturities).
#'
#' @format A list with three components:
#' \describe{
#'   \item{time}{Character vector of ISO-8601 calendar dates
#'               (e.g., \code{"2006-05-12"}). Length equals the number
#'               of rows in \code{rates}.}
#'   \item{tau}{Numeric vector of maturities in years:
#'              \code{c(1/12, 1/4, 1/2, 1, 2, 3, 5, 7, 10, 20, 30)}.}
#'   \item{rates}{Numeric matrix of annualized yields (percent, not decimals)
#'                with dimension \eqn{T \times 11}. Column names:
#'                \code{X1mo}, \code{X3mo}, \code{X6mo}, \code{X1yr},
#'                \code{X2yr}, \code{X3yr}, \code{X5yr}, \code{X7yr},
#'                \code{X10yr}, \code{X20yr}, \code{X30yr}.}
#' }
#'
#' @details
#' Dates run from \code{2006-05-12} to \code{2008-10-31} (about 622 business
#' days in this snapshot). Yields are curve levels for each maturity on each
#' date and can be used directly for fitting/parsing term-structure models
#' (e.g., Nelson–Siegel or Svensson), computing spreads (term, slope, butterfly),
#' or building zero curves.
#'
#' @examples
#' data("TermStructure")
#' str(TermStructure)
#'
#' # Convert 'time' to Date and build an xts for quick plotting
#' dts   <- as.Date(TermStructure$time)
#' y.mat <- TermStructure$rates
#' colnames(y.mat)
#'
#' # Example: 10Y vs 2Y term spread (in percentage points)
#' sprd_10y2y <- y.mat[, "X10yr"] - y.mat[, "X2yr"]
#' head(sprd_10y2y)
#'
#' # Example: maturity grid (years)
#' TermStructure$tau
#'
#' @usage data("TermStructure")
#' @docType data
#' @keywords datasets finance fixed-income term-structure time-series
"TermStructure"
