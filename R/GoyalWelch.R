#' Goyal–Welch Predictive Variables (Monthly, U.S.)
#'
#' Monthly time series of equity predictors and bond/credit variables commonly
#' used in return predictability studies following Goyal & Welch (2008).
#' Stored as an \code{xts} object with a monthly \code{Date} index (UTC).
#'
#' @format An \code{xts} object with monthly observations (1980–2018 in this
#'   snapshot) and 15 variables:
#' \describe{
#'   \item{Index}{Broad U.S. equity price index level (e.g., S&P 500).}
#'   \item{D12}{Trailing 12-month cash dividends on the index (level).}
#'   \item{E12}{Trailing 12-month earnings on the index (level).}
#'   \item{b/m}{Aggregate book-to-market ratio.}
#'   \item{tbl}{3-month Treasury bill rate (monthly).}
#'   \item{AAA}{Moody’s AAA corporate bond yield.}
#'   \item{BAA}{Moody’s BAA corporate bond yield.}
#'   \item{lty}{Long-term government bond yield.}
#'   \item{ntis}{Net equity expansion: shares issued less repurchases scaled by
#'               total equity (a supply measure).}
#'   \item{Rfree}{Risk-free rate (monthly).}
#'   \item{infl}{Inflation (monthly change in price level).}
#'   \item{ltr}{Long-term government bond total return (monthly).}
#'   \item{corpr}{Corporate bond total return (monthly).}
#'   \item{svar}{Stock market variance proxy (e.g., rolling sum of daily
#'               squared returns).}
#'   \item{csp}{Corporate bond \emph{return} spread: \code{corpr - ltr}.}
#' }
#'
#' @details
#' This object mirrors the variables used in
#' Goyal & Welch (2008) and subsequent updates. From these levels you can form
#' the standard ratios used in the literature, for example
#' \code{dp = log(D12/Index)}, \code{ep = log(E12/Index)},
#' \code{dfy = BAA - AAA}, and \code{tms = lty - tbl}.
#'
#' @source
#' Compiled from the public Goyal–Welch data library (predictable stock returns)
#' and standard fixed-income sources (e.g., FRED). If you distribute this data,
#' include a \code{data-raw/} script that reproduces the object from originals.
#'
#' @references
#' Goyal, A., & Welch, I. (2008). A Comprehensive Look at The Empirical
#' Performance of Equity Premium Prediction. \emph{Review of Financial Studies},
#' 21(4), 1455–1508.
#'
#' @examples
#' data("GoyalWelch")
#' class(GoyalWelch)         # "xts" "zoo"
#' head(GoyalWelch)
#'
#' # Construct common predictors:
#' dp  <- log(GoyalWelch[,"D12"]  / GoyalWelch[,"Index"])  # dividend–price
#' ep  <- log(GoyalWelch[,"E12"]  / GoyalWelch[,"Index"])  # earnings–price
#' dfy <- GoyalWelch[,"BAA"] - GoyalWelch[,"AAA"]          # default yield spread
#' tms <- GoyalWelch[,"lty"] - GoyalWelch[,"tbl"]          # term spread
#'
#' @usage data("GoyalWelch")
#' @docType data
#' @keywords datasets time-series finance
"GoyalWelch"
