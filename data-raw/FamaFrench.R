# ---------------------------------------------------------------------------
# data-raw/FamaFrench.R
#
# Provenance and contract harness for the `FamaFrench` dataset.
#
# The object is the weekly Fama-French three-factor file from Kenneth French's
# data library (F-F_Research_Data_Factors_weekly), imported once and shipped as
# a static snapshot. As with the qrmdata ports, we deliberately do not
# re-download at build time: French's library is periodically revised, and a
# fresh pull would silently change every regression printed in Chapters 1 and 4.
#
# The property that actually matters here cannot be seen in any summary
# statistic, and it is the reason this file exists. The weekly factor
# observations are stamped at the *end* of their week, while the book's weekly
# prices are stamped at the *start*. Aligning the two by naive date matching
# produces a regression of returns on the factors of the following week -- not
# a noisier regression, a different and wrong one. The checks below pin the
# stamping convention so that a re-import from a different vintage fails loudly
# instead of quietly shifting the alignment by one week.
#
# Run with:  source("data-raw/FamaFrench.R")
# ---------------------------------------------------------------------------

## ---- source ---------------------------------------------------------------
## https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html
##   file:    F-F_Research_Data_Factors_weekly.zip
##   columns: Mkt-RF, SMB, HML, RF  -> renamed mkt_rf, smb, hml, rf
##   units:   percent per week, NOT decimals (see the contract below)
##   vintage: the snapshot ends 2019-02-22; the library has been revised since,
##            so a fresh download will not reproduce this object exactly.

suppressPackageStartupMessages({
  stopifnot(requireNamespace("xts", quietly = TRUE),
            requireNamespace("zoo", quietly = TRUE))
})

verify_FamaFrench <- function() {
  e <- new.env()
  utils::data("FamaFrench", package = "smqf", envir = e)
  x <- get("FamaFrench", envir = e)

  ## ---- shape and layout ---------------------------------------------------
  stopifnot(
    inherits(x, "xts"),
    nrow(x) == 4834L,
    ncol(x) == 4L,
    identical(colnames(x), c("mkt_rf", "smb", "hml", "rf")),
    sum(is.na(x)) == 0L
  )

  ## ---- span ---------------------------------------------------------------
  idx <- zoo::index(x)
  stopifnot(
    format(min(idx)) == "1926-07-02",
    format(max(idx)) == "2019-02-22",
    !is.unsorted(idx),
    !anyDuplicated(idx)
  )

  ## ---- units: percent, not decimals ---------------------------------------
  ## A weekly market excess return has a standard deviation near 2.4 in percent
  ## and near 0.024 in decimals. Getting this wrong scales every regression
  ## coefficient in Chapter 4 by 100 without changing any t-statistic, so it is
  ## invisible in the diagnostics and must be asserted here.
  sds <- apply(zoo::coredata(x), 2, stats::sd)
  stopifnot(
    abs(sds[["mkt_rf"]] - 2.4463) < 5e-3,
    abs(sds[["smb"]]    - 1.2550) < 5e-3,
    abs(sds[["hml"]]    - 1.4312) < 5e-3,
    abs(sds[["rf"]]     - 0.0630) < 5e-3
  )
  ## The risk-free weekly rate is very nearly non-negative, but not entirely:
  ## 60 of the 4834 weeks carry a small negative rate. They are not scattered
  ## noise, which is what makes them worth pinning -- 34 fall in the 1930s and
  ## 21 in the 1940s, when Treasury bills traded at negative yields, and the
  ## remaining 5 are consecutive weeks of July 2011, during the debt-ceiling
  ## episode. This is a property of the data and not an import error, so the
  ## contract records it rather than forbidding it. What it does forbid is a
  ## rate outside the plausible band, which is how a units or sign error would
  ## show up.
  rf <- zoo::coredata(x)[, "rf"]
  neg <- rf < 0
  stopifnot(
    sum(neg) == 60L,
    min(rf) > -0.02,
    max(rf) < 0.4,
    sum(neg & idx < as.Date("1950-01-01")) == 55L,
    identical(format(range(idx[neg & idx > as.Date("2000-01-01")])),
              c("2011-07-01", "2011-07-29"))
  )

  ## ---- the stamping convention --------------------------------------------
  ## This is the assertion the file exists for. From 1953 onwards the exchange
  ## week ends on Friday and the factor rows are stamped on that Friday. Before
  ## the 1952 abolition of Saturday trading the week ended on Saturday, and the
  ## early rows are stamped accordingly. Any re-import that shifts the stamp to
  ## the start of the week will trip this.
  wd <- as.POSIXlt(idx)$wday          # 0 = Sunday ... 6 = Saturday
  early <- idx < as.Date("1953-01-01")
  stopifnot(
    ## the modern history is stamped on Fridays, overwhelmingly
    mean(wd[!early] == 5L) > 0.95,
    ## the early history contains Saturday stamps, which the modern one does not
    any(wd[early] == 6L),
    all(wd[!early] != 6L)
  )

  message("FamaFrench: all contract checks passed (",
          nrow(x), " x ", ncol(x), ", ",
          format(min(idx)), " to ", format(max(idx)), ").")
  invisible(TRUE)
}

if (requireNamespace("smqf", quietly = TRUE)) {
  verify_FamaFrench()
}
