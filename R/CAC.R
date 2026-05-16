#' CAC 40 Index (Daily, xts)
#'
#' Daily adjusted close prices of the Cotation Assistée en Continu (CAC 40)
#' stock index (ticker symbol \code{^FCHI}), from its first date of
#' availability on Yahoo Finance to 2015-12-31.
#'
#' @format An \code{xts} object with 6549 daily observations and a single
#' column \code{^FCHI} containing adjusted close prices in index points.
#' The time index spans from 1990-03-01 to 2015-12-31.
#'
#' @details
#' Originally distributed as \code{CAC} in the \strong{qrmdata} package
#' (Hofert, Hornik, & McNeil), ported into \pkg{smqf} so that the book's
#' examples remain reproducible without an extra dependency. The data is
#' redistributed here under the same GPL (\eqn{\ge 2}) license as
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
#' data("CAC")
#' class(CAC)        # "xts" "zoo"
#' dim(CAC)
#' head(CAC)
#'
#' @usage data("CAC")
#' @docType data
#' @keywords datasets time-series finance
"CAC"
