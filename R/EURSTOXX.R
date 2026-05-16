#' Euro Stoxx 50 Index (Daily, xts)
#'
#' Daily adjusted close prices of the Euro Stoxx 50 stock index
#' (ticker symbol \code{^STOXX50E}), from its first date of availability
#' on Yahoo Finance to 2015-12-23.
#'
#' @format An \code{xts} object with 7445 daily observations and a single
#' column \code{^STOXX50E} containing adjusted close prices in index
#' points. The time index spans from 1986-12-31 to 2015-12-23.
#'
#' @details
#' Originally distributed as \code{EURSTOXX} in the \strong{qrmdata}
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
#' data("EURSTOXX")
#' class(EURSTOXX)        # "xts" "zoo"
#' dim(EURSTOXX)
#' head(EURSTOXX)
#'
#' @usage data("EURSTOXX")
#' @docType data
#' @keywords datasets time-series finance
"EURSTOXX"
