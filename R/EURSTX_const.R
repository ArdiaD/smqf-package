#' Euro Stoxx 50 Constituents (Daily, xts)
#'
#' Daily adjusted close prices for the 50 constituents of the Euro Stoxx
#' 50 stock index as of 2016-01-03.
#'
#' @format An \code{xts} object with 4174 daily observations and 50
#' columns, one per constituent (e.g., \code{SAP.DE}, \code{BNP.PA},
#' \code{SAN.MC}). Missing values appear before the first date at which
#' a given constituent was available. The time index spans from
#' 2000-01-03 to 2015-12-31.
#'
#' @details
#' Originally distributed as \code{EURSTX_const} in the \strong{qrmdata}
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
#' data("EURSTX_const")
#' class(EURSTX_const)        # "xts" "zoo"
#' dim(EURSTX_const)
#' head(colnames(EURSTX_const))
#'
#' @usage data("EURSTX_const")
#' @docType data
#' @keywords datasets time-series finance
"EURSTX_const"
