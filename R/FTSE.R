#' FTSE 100 Index (Daily, xts)
#'
#' Daily adjusted close prices of the FTSE 100 stock index
#' (ticker symbol \code{^FTSE}), from its first date of availability on
#' Yahoo Finance to 2015-12-31.
#'
#' @format An \code{xts} object with 8333 daily observations and a single
#' column \code{^FTSE} containing adjusted close prices in index points.
#' The time index spans from 1984-01-03 to 2015-12-31.
#'
#' @details
#' Originally distributed as \code{FTSE} in the \strong{qrmdata} package
#' (Hofert, Hornik, & McNeil), ported into \pkg{smqf} so that the book's
#' examples remain reproducible without an extra dependency. The data is
#' redistributed here under the same GPL (\eqn{\ge 2}) license as \strong{qrmdata}.
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
#' data("FTSE")
#' class(FTSE)        # "xts" "zoo"
#' dim(FTSE)
#' head(FTSE)
#'
#' @usage data("FTSE")
#' @docType data
#' @keywords datasets time-series finance
"FTSE"
