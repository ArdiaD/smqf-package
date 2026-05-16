#' Dow Jones Industrial Average Constituents (Daily, xts)
#'
#' Daily adjusted close prices for the 30 constituents of the Dow Jones
#' Industrial Average as of 2016-01-03.
#'
#' @format An \code{xts} object with 13595 daily observations and 30
#' columns, one per constituent (e.g., \code{AAPL}, \code{IBM},
#' \code{JPM}, \code{XOM}). Missing values appear before the first date
#' at which a given constituent was available. The time index spans
#' from 1962-01-02 to 2015-12-31.
#'
#' @details
#' Originally distributed as \code{DJ_const} in the \strong{qrmdata}
#' package (Hofert, Hornik, & McNeil), ported into \pkg{smqf} so that
#' the book's examples remain reproducible without an extra dependency. The
#' data is redistributed here under the same GPL (\eqn{\ge 2}) license as
#' \strong{qrmdata}.
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
#' data("DJ_const")
#' class(DJ_const)        # "xts" "zoo"
#' dim(DJ_const)
#' head(colnames(DJ_const))
#'
#' @usage data("DJ_const")
#' @docType data
#' @keywords datasets time-series finance
"DJ_const"
