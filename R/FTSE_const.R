#' FTSE 100 Constituents (Daily, xts)
#'
#' Daily adjusted close prices for 98 constituents of the FTSE 100 stock
#' index as of 2016-01-03.
#'
#' @format An \code{xts} object with 7198 daily observations and 98
#' columns, one per constituent (e.g., \code{HSBA.L}, \code{BP.L},
#' \code{VOD.L}). The time index spans from 1988-05-03 to 2015-12-31.
#'
#' @section Missing values:
#' Most of the 163,821 \code{NA}s are leading: a constituent is \code{NA} on
#' every date before it first traded. But 4,634 of them occur \emph{after} a
#' series has started, spread over 96 of the 98 columns, so trimming the leading
#' block does not produce a complete matrix.
#'
#' Handle both cases explicitly. Two idioms cover most needs: restrict to the
#' columns that are complete over your window, as the book does with
#' \code{x <- x[, colSums(is.na(x)) == 0]} — over 2013–2015 this keeps 95 of the
#' 98 names — or estimate pairwise with
#' \code{stats::cov(x, use = "pairwise.complete.obs")} and project the result
#' onto the positive semidefinite cone. See \code{\link{EURSTX_const}}, where
#' interior \code{NA}s are far more common, and \code{\link{DJ_const}}, where
#' they are rare.
#'
#' @details
#' Originally distributed as \code{FTSE_const} in the \strong{qrmdata}
#' package (Hofert, Hornik, & McNeil), ported into \pkg{smqf} so that
#' the book's examples remain reproducible without an extra dependency. The
#' data is redistributed here under the same GPL (\eqn{\ge 2}) license as
#' \strong{qrmdata}.
#' Only 98 of the 100 constituents were available at the time of the
#' download.
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
#' data("FTSE_const")
#' class(FTSE_const)        # "xts" "zoo"
#' dim(FTSE_const)
#' head(colnames(FTSE_const))
#'
#' @usage data("FTSE_const")
#' @docType data
#' @keywords datasets time-series finance
"FTSE_const"
