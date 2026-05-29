#' smqf: Statistical Methods for Quantitative Finance
#'
#' `smqf` is an R package providing datasets and functions used in the
#' book "Statistical Methods for Quantitative Finance" Ardia (2026).
#'
#' @section Datasets:
#' All datasets bundled with `smqf` are \strong{illustrative}: they are static
#' snapshots provided so that the book's examples remain reproducible, and some
#' have been modified for that purpose (e.g., `SP500_const` is thinned to weekly
#' frequency, and several series are truncated or re-indexed). They are
#' \strong{not} maintained data feeds and should not be relied upon for research
#' or production use.
#'
#' Index conventions: daily series (e.g., `SP500`, `FTSE`, `VIX`,
#' `TermStructure`) use a `Date` index; monthly series (`FungHsieh`,
#' `GoyalWelch`, `Fred`) use a `zoo::yearmon` index (a calendar month with no
#' day-of-month, so they merge by month and avoid first-/end-of-month
#' ambiguity); `FamaFrench` is a weekly series with a `Date` index.
#'
#' @section Acknowledgments:
#' The market datasets `SP500`, `SP500_const`, `DJ`, `DJ_const`, `FTSE`,
#' `FTSE_const`, `EURSTOXX`, `EURSTX_const`, `DAX`, `CAC`, `NIKKEI`, `SMI`,
#' `HSI`, `GOLD`, and `VIX` are redistributed from the **qrmdata** package by
#' Marius Hofert, Kurt Hornik, and Alexander J. McNeil under the same
#' GPL (\eqn{\ge 2}) license. The original data was collected by the qrmdata authors from
#' Yahoo Finance and FRED (via Quandl) on 2016-01-03. See
#' <https://CRAN.R-project.org/package=qrmdata> for the upstream package
#' and the individual dataset help pages for details.
#'
#' @references
#' David Ardia (2026). *Statistical Methods for Quantitative Finance*. CRC Press.
#'
#' Hofert, M., Hornik, K., & McNeil, A. J. *qrmdata: Data Sets for
#' Quantitative Risk Management Practice*.
#' <https://CRAN.R-project.org/package=qrmdata>.
#'
#' @author David Ardia
#'
#' @importFrom xts as.xts
#'
#' @name smqf
#' @keywords internal
"_PACKAGE"
