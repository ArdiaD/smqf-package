#' CBOE Volatility Index VIX (Daily, xts)
#'
#' Daily close values of the Chicago Board Options Exchange (CBOE)
#' volatility index VIX (ticker symbol \code{^VIX}), from its first date
#' of availability on Yahoo Finance to 2015-12-31.
#'
#' @format An \code{xts} object with 6553 daily observations and a single
#' column \code{^VIX} containing the VIX level in percent
#' (annualized implied volatility). The time index spans from
#' 1990-01-02 to 2015-12-31.
#'
#' @details
#' Originally distributed as \code{VIX} in the \strong{qrmdata} package
#' (Hofert, Hornik, & McNeil), ported into \pkg{smqf} so that the book's
#' examples remain reproducible without an extra dependency. The data is
#' redistributed here under the same GPL (\eqn{\ge 2}) license as \strong{qrmdata}. The VIX is
#' typically used as a market-based measure of volatility, expressed in
#' percent.
#'
#' @source
#' Yahoo Finance, downloaded on 2016-01-03 via \code{qrmtools::get_data()}.
#'
#' @references
#' Hofert, M., Hornik, K., & McNeil, A. J. \emph{qrmdata: Data Sets for
#' Quantitative Risk Management Practice},
#' \url{https://CRAN.R-project.org/package=qrmdata}.
#'
#' @examples
#' data("VIX")
#' class(VIX)        # "xts" "zoo"
#' dim(VIX)
#' head(VIX)
#'
#' @usage data("VIX")
#' @docType data
#' @keywords datasets time-series finance volatility
"VIX"
