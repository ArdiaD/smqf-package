# ---------------------------------------------------------------------------
# data-raw/TermStructure.R
#
# Provenance and contract harness for the `TermStructure` dataset.
#
# The object holds daily U.S. Treasury constant-maturity yields at eleven
# tenors, imported once from the Treasury's public yield-curve series and
# shipped as a static snapshot. As with the other ports, we deliberately do not
# re-download at build time.
#
# Two properties carry the whole meaning of the object and neither is visible
# in a summary statistic, which is why this file exists.
#
#   1. The maturities are attached as an xts *attribute*, not as data. Chapter 4
#      reads them back with xts::xtsAttributes(TermStructure)$tau to place the
#      principal components on a maturity axis. Attributes are the first thing
#      lost by an innocent-looking round trip through as.matrix() or a re-save,
#      and their loss is silent: `$tau` on an object without them returns NULL,
#      and NULL flows into a plot as an empty axis rather than an error.
#
#   2. The columns are in increasing maturity order, and the PCA interpretation
#      in Chapter 4 -- level, slope, curvature -- depends on that ordering. A
#      re-import that sorted the columns alphabetically would put X10yr between
#      X1yr and X1mo and turn the second component into noise, while every
#      dimension check still passed.
#
# Run with:  source("data-raw/TermStructure.R")
# ---------------------------------------------------------------------------

## ---- source ---------------------------------------------------------------
## U.S. Department of the Treasury, Daily Treasury Par Yield Curve Rates.
##   units:   percent per annum (not decimals, not basis points)
##   tenors:  1mo 3mo 6mo 1yr 2yr 3yr 5yr 7yr 10yr 20yr 30yr
##   vintage: the snapshot spans 2006-05-12 to 2008-10-31, i.e. the run-up to
##            and the first weeks of the financial crisis, which is what makes
##            it a useful illustration of a curve that both shifts and twists.

suppressPackageStartupMessages({
  stopifnot(requireNamespace("xts", quietly = TRUE),
            requireNamespace("zoo", quietly = TRUE))
})

verify_TermStructure <- function() {
  e <- new.env()
  utils::data("TermStructure", package = "smqf", envir = e)
  x <- get("TermStructure", envir = e)

  ## ---- shape and layout ---------------------------------------------------
  cols <- c("X1mo", "X3mo", "X6mo", "X1yr", "X2yr", "X3yr",
            "X5yr", "X7yr", "X10yr", "X20yr", "X30yr")
  stopifnot(
    inherits(x, "xts"),
    nrow(x) == 622L,
    ncol(x) == 11L,
    identical(colnames(x), cols),
    sum(is.na(x)) == 0L
  )

  ## ---- span ---------------------------------------------------------------
  idx <- zoo::index(x)
  stopifnot(
    format(min(idx)) == "2006-05-12",
    format(max(idx)) == "2008-10-31",
    !is.unsorted(idx),
    !anyDuplicated(idx)
  )

  ## ---- the tau attribute --------------------------------------------------
  ## This is the assertion the file exists for.
  tau <- xts::xtsAttributes(x)$tau
  stopifnot(
    !is.null(tau),
    is.numeric(tau),
    length(tau) == ncol(x),
    !is.unsorted(tau),
    ## maturities in YEARS: one month is 1/12, not 1 and not 30
    abs(tau[1] - 1 / 12) < 1e-9,
    abs(tau[2] - 0.25)   < 1e-9,
    abs(tau[length(tau)] - 30) < 1e-9
  )
  ## the attribute must agree with the column names it labels
  from_names <- c(1 / 12, 0.25, 0.5, 1, 2, 3, 5, 7, 10, 20, 30)
  stopifnot(max(abs(tau - from_names)) < 1e-9)

  ## ---- units: percent per annum -------------------------------------------
  ## Yields of 0.03 to 5.44 are percent. In decimals the same curve would run
  ## 0.0003 to 0.054, and every principal component in Chapter 4 would be
  ## rescaled by 100 without any diagnostic changing.
  v <- zoo::coredata(x)
  stopifnot(
    min(v) > 0,
    abs(min(v) - 0.03) < 1e-9,
    abs(max(v) - 5.44) < 1e-9
  )

  ## ---- the curve is a curve -----------------------------------------------
  ## Over this sample the curve is usually but not always upward sloping: the
  ## 2006-2007 inversion is a real feature of these data and part of why the
  ## slope component is interesting. Pin that it happens, and roughly how often,
  ## so a re-import that silently reordered or resampled would be caught.
  inverted <- v[, "X10yr"] < v[, "X3mo"]
  stopifnot(
    any(inverted),
    sum(inverted) > 100L, sum(inverted) < 400L,
    all(zoo::index(x)[inverted] < as.Date("2008-01-01"))
  )

  message("TermStructure: all contract checks passed (",
          nrow(x), " x ", ncol(x), ", tau ", tau[1], " to ", tau[length(tau)],
          " years, ", sum(inverted), " inverted days).")
  invisible(TRUE)
}

if (requireNamespace("smqf", quietly = TRUE)) {
  verify_TermStructure()
}
