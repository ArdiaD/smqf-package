#' Gold Price (Daily, xts)
#'
#' Daily World Gold Council gold price in USD per troy ounce, from
#' 1970-01-01 to 2015-12-31.
#'
#' @format An \code{xts} object with 9691 daily observations and a single
#' column \code{GOLD} containing USD prices per troy ounce.
#'
#' @details
#' Originally distributed as \code{GOLD} in the \strong{qrmdata} package
#' (Hofert, Hornik, & McNeil), ported into \pkg{smqf} so that the book's
#' examples remain reproducible without an extra dependency. The data is
#' redistributed here under the same GPL (\eqn{\ge 2}) license as \strong{qrmdata}.
#'
#' @source
#' Federal Reserve Economic Data (FRED) via Quandl, downloaded on
#' 2016-01-03 with \code{qrmtools::get_data()}.
#'
#' @references
#' Hofert, M., Hornik, K., & McNeil, A. J. \emph{qrmdata: Data Sets for
#' Quantitative Risk Management Practice},
#' \url{https://CRAN.R-project.org/package=qrmdata}.
#'
#' @examples
#' data("GOLD")
#' class(GOLD)        # "xts" "zoo"
#' dim(GOLD)
#' head(GOLD)
#'
#' @usage data("GOLD")
#' @docType data
#' @keywords datasets time-series finance commodity
"GOLD"
