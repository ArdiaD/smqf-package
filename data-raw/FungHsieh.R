# ---------------------------------------------------------------------------
# data-raw/FungHsieh.R
#
# Reconstruction of the `FungHsieh` dataset shipped with smqf.
#
# STATUS: the assembly steps below are documented from the properties of the
# shipped object, but the original download URLs and vintage were not recorded
# when the snapshot was taken. The sections marked TODO must be completed by
# the maintainer before this script can rebuild the object from scratch.
# Until then, `verify_FungHsieh()` at the bottom is the operative contract:
# it pins every property the book and its exercises rely on, and will fail
# loudly if a future rebuild diverges.
#
# Run with:  source("data-raw/FungHsieh.R")
# ---------------------------------------------------------------------------

library(xts)
library(zoo)

# --- 1. Source series ------------------------------------------------------
#
# The object has 8 monthly columns, Jan 1994 - Dec 2016, all in PERCENTAGE
# POINTS. Two of them are changes in yields, not returns.
#
#   EMKT     equity market factor, % / month
#   RF       risk-free rate, % / month  (>= 0, max 0.56)
#   SS       size spread, small minus large, % / month
#   CST10Y   CHANGE in the 10y US Treasury constant-maturity yield, pp / month
#   BAA      CHANGE in the Moody's Baa credit spread, pp / month
#   PTFSBD   Fung-Hsieh primitive trend-following straddle, bond, % / month
#   PTFSCOM  ditto, commodity, % / month
#   PTFSFX   ditto, currency, % / month
#
# TODO(maintainer): record the exact provenance of each block.
#
#   PTFSBD / PTFSCOM / PTFSFX
#     David A. Hsieh's hedge-fund data library:
#     https://people.duke.edu/~dah7/HFRFData.htm
#     -> which file, and which download date?
#
#   CST10Y  FRED series DGS10 (or H.15), monthly, first difference.
#     -> confirm end-of-month vs monthly-average sampling before differencing.
#
#   BAA     FRED series BAA (or BAA10Y for the spread directly), first difference.
#     -> confirm whether the shipped column is the change in the Baa YIELD or
#        in the Baa-minus-10y SPREAD. The two differ materially.
#
#   EMKT / RF / SS
#     -> confirm the index pair behind SS. The Fung-Hsieh 7-factor model uses
#        Wilshire small cap minus large cap; a Russell 2000 minus S&P 500
#        construction is also common in the literature and would give a
#        visibly different series.
#
# fetch_ptfs  <- function() { ... }
# fetch_fred  <- function(series_id) { ... }
# fetch_equity<- function() { ... }

# --- 2. Assemble -----------------------------------------------------------
#
# build_FungHsieh <- function() {
#   ptfs   <- fetch_ptfs()
#   cst10y <- diff(fetch_fred("DGS10"))
#   baa    <- diff(fetch_fred("BAA"))
#   eq     <- fetch_equity()
#   out <- merge(eq$EMKT, eq$RF, eq$SS, cst10y, baa,
#                ptfs$PTFSBD, ptfs$PTFSCOM, ptfs$PTFSFX)
#   colnames(out) <- c("EMKT", "RF", "SS", "CST10Y", "BAA",
#                      "PTFSBD", "PTFSCOM", "PTFSFX")
#   out <- out["1994-01/2016-12"]
#   index(out) <- as.yearmon(index(out))   # month keys, no day-of-month
#   out
# }
#
# FungHsieh <- build_FungHsieh()
# stopifnot(verify_FungHsieh(FungHsieh))
# usethis::use_data(FungHsieh, overwrite = TRUE, compress = "xz")

# --- 3. Contract -----------------------------------------------------------
# Every property below is relied on by the book (Exercise 1.8 in particular,
# which merges these factors with PerformanceAnalytics::edhec -- a DECIMAL
# series, hence the /100 conversion) or by the package documentation.

verify_FungHsieh <- function(x) {
  stopifnot(
    inherits(x, "xts"),
    inherits(zoo::index(x), "yearmon"),
    identical(dim(x), c(276L, 8L)),
    identical(colnames(x),
              c("EMKT", "RF", "SS", "CST10Y", "BAA",
                "PTFSBD", "PTFSCOM", "PTFSFX")),
    !anyNA(x),
    !is.unsorted(zoo::index(x)),
    !anyDuplicated(zoo::index(x)),
    format(min(zoo::index(x))) == "Jan 1994",
    format(max(zoo::index(x))) == "Dec 2016"
  )

  z <- zoo::coredata(x)

  # Units: percentage points, not decimals and not basis points.
  stopifnot(
    all(z[, "RF"] >= 0),                       # a risk-free rate is non-negative
    max(z[, "RF"]) < 1,                        # < 1% per month, i.e. not bps
    abs(sd(z[, "EMKT"]) * sqrt(12) - 14.7) < 1 # ~14.7% annualized equity vol
  )

  # SS is a long-short spread, not a directional return.
  stopifnot(
    abs(mean(z[, "SS"])) < 0.5,
    abs(stats::cor(z[, "EMKT"], z[, "SS"])) < 0.3
  )

  # CST10Y and BAA are changes in yields: small, roughly centred, two-sided.
  for (nm in c("CST10Y", "BAA")) {
    stopifnot(abs(mean(z[, nm])) < 0.05,
              max(abs(z[, nm])) < 2,
              min(z[, nm]) < 0, max(z[, nm]) > 0)
  }

  # The PTFS straddles have negative means and large right tails.
  for (nm in c("PTFSBD", "PTFSCOM", "PTFSFX")) {
    stopifnot(mean(z[, nm]) < 0, sd(z[, nm]) > 10, max(z[, nm]) > 40)
  }

  invisible(TRUE)
}

# Check the object currently shipped.
if (requireNamespace("smqf", quietly = TRUE)) {
  local({
    e <- new.env()
    utils::data("FungHsieh", package = "smqf", envir = e)
    verify_FungHsieh(get("FungHsieh", envir = e))
    message("FungHsieh: shipped object satisfies the documented contract.")
  })
}
