#' Swiss Market Index (Daily, xts)
#'
#' Daily adjusted close prices of the Swiss Market Index (SMI) stock
#' index (ticker symbol \code{^SSMI}), from its first date of
#' availability on Yahoo Finance to 2015-12-30.
#'
#' @format An \code{xts} object with 6350 daily observations and a single
#' column \code{^SSMI} containing adjusted close prices in index points.
#' The time index spans from 1990-11-09 to 2015-12-30.
#'
#' @details
#' Originally distributed as \code{SMI} in the \strong{qrmdata} package
#' (Hofert, Hornik, & McNeil), ported into \pkg{smqf} so that the book's
#' examples remain reproducible without an extra dependency. The data is
#' redistributed here under the same GPL (\eqn{\ge 2}) license as
#' \strong{qrmdata}. Note: the \strong{MSGARCH} package ships a different
#' dataset also named \code{SMI} (SMI log-returns); to use that one, load
#' it explicitly with \code{data("SMI", package = "MSGARCH")}.
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
#' data("SMI")
#' class(SMI)        # "xts" "zoo"
#' dim(SMI)
#' head(SMI)
#'
#' @usage data("SMI")
#' @docType data
#' @keywords datasets time-series finance
"SMI"
