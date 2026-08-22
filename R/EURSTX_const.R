#' Euro Stoxx 50 Constituents (Daily, xts)
#'
#' Daily adjusted close prices for the 50 constituents of the Euro Stoxx
#' 50 stock index as of 2016-01-03.
#'
#' @format An \code{xts} object with 4174 daily observations and 50
#' columns, one per constituent (e.g., \code{SAP.DE}, \code{BNP.PA},
#' \code{SAN.MC}). The time index spans from 2000-01-03 to 2015-12-31.
#'
#' @section Missing values:
#' Of the 8,270 \code{NA}s, 1,938 occur \emph{after} a series has started, and
#' every one of the 50 columns is affected. Trimming the leading block is
#' therefore \strong{not} enough to obtain a complete matrix.
#'
#' The interior \code{NA}s are mostly local trading holidays: the constituents
#' are listed on exchanges with different calendars (Paris, Frankfurt, Madrid,
#' Amsterdam, Milan, Brussels), so a day that is a holiday in one country still
#' appears in the index with \code{NA} for that country's shares. They span
#' 1,015 distinct dates, the largest being Good Friday 2011-04-22 and Easter
#' Monday 2011-04-25 (48 series each), Labour Day 2006-05-01 (46) and Christmas
#' 2009-12-25 (43). A few series also have long individual gaps, notably
#' \code{UL.PA} with 679 interior \code{NA}s.
#'
#' Consequently \code{stats::cov(x)} returns \code{NA}s on this dataset.
#' Use \code{use = "pairwise.complete.obs"} and project the result onto the
#' positive semidefinite cone with \code{as.matrix(Matrix::nearPD(S)$mat)}, or
#' restrict to rows with \code{rowSums(is.na(x)) == 0} for a single common
#' estimation window.
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
