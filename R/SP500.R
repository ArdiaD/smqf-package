#' S&P 500 Index (Daily, xts)
#'
#' Daily adjusted close prices of the Standard & Poor's 500 stock index
#' (ticker symbol \code{^GSPC}), from its first date of availability on
#' Yahoo Finance to 2015-12-31.
#'
#' @format An \code{xts} object with 16607 daily observations and a single
#' column \code{^GSPC} containing adjusted close prices in index points.
#' The time index spans from 1950-01-03 to 2015-12-31.
#'
#' @details
#' Originally distributed as \code{SP500} in the \strong{qrmdata} package
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
#' data("SP500")
#' class(SP500)        # "xts" "zoo"
#' dim(SP500)
#' head(SP500)
#'
#' @usage data("SP500")
#' @docType data
#' @keywords datasets time-series finance
"SP500"
