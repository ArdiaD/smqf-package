# ---------------------------------------------------------------------------
# data-raw/qrmdata-ports.R
#
# Provenance and contract for the fifteen market datasets ported from the
# qrmdata package (Hofert, Hornik & McNeil) into smqf, so that the book's
# examples run without an extra dependency.
#
# These objects are STATIC SNAPSHOTS, not maintained feeds. They were taken
# from qrmdata, which itself downloaded them from Yahoo Finance on 2016-01-03
# via qrmtools::get_data(). We deliberately do not re-download: Yahoo revises
# adjusted-close series retroactively for splits and dividends, so a fresh pull
# would silently change every number printed in the book.
#
# Run with:  source("data-raw/qrmdata-ports.R")
# ---------------------------------------------------------------------------

library(xts)
library(zoo)

# --- 1. Re-porting from qrmdata --------------------------------------------
#
# The port is a straight copy: same values, same index, same column names.
# Only the storage changed (xz compression, to fit the CRAN size limit).
# SP500_const is the exception -- see section 2.
#
# To rebuild from source, install qrmdata and run:
#
#   install.packages("qrmdata")
#   ports <- c("SP500", "DJ", "DJ_const", "FTSE", "FTSE_const", "EURSTOXX",
#              "EURSTX_const", "DAX", "CAC", "NIKKEI", "SMI", "HSI", "GOLD",
#              "VIX")
#   for (nm in ports) {
#     e <- new.env()
#     utils::data(list = nm, package = "qrmdata", envir = e)
#     assign(nm, get(nm, envir = e))
#     usethis::use_data(list = nm, overwrite = TRUE, compress = "xz")
#   }
#
# TODO(maintainer): record the qrmdata version used for the port. The datasets
# have been stable across qrmdata releases, but the version belongs in the
# provenance record.

# --- 2. SP500_const ---------------------------------------------------------
#
# qrmdata ships SP500_const at daily frequency, which exceeds the CRAN size
# limit once bundled with everything else. smqf stores the weekly series: the
# last available trading day of each week.
#
#   endofweek <- xts::endpoints(SP500_const_daily, on = "weeks")
#   SP500_const <- SP500_const_daily[endofweek, ]
#
# Weekly frequency is sufficient for the high-dimensional covariance and
# factor-model examples, where a three-year window already has more
# constituents than observations.

# --- 3. Contract ------------------------------------------------------------
# Shape, index and missing-value structure that the book depends on. These
# duplicate the assertions in tests/testthat/test-datasets.R on purpose: the
# tests protect the installed package, this function protects a rebuild.

n_interior_na <- function(x) {
  cd <- zoo::coredata(x)
  sum(vapply(seq_len(ncol(cd)), function(j) {
    v <- is.na(cd[, j])
    if (!any(v)) return(0L)
    first_ok <- which(!v)[1L]
    sum(v[first_ok:length(v)])
  }, integer(1)))
}

# name, rows, cols, first date, last date, total NA, interior NA
qrmdata_contract <- data.frame(
  name      = c("SP500", "DJ", "DJ_const", "FTSE", "FTSE_const", "EURSTOXX",
                "EURSTX_const", "DAX", "CAC", "NIKKEI", "SMI", "HSI", "GOLD",
                "VIX", "SP500_const"),
  nrow      = c(16607, 7797, 13595, 8333, 7198, 7445, 4174, 6355, 6549, 7880,
                6350, 7214, 9691, 6553, 2818),
  ncol      = c(1, 1, 30, 1, 98, 1, 50, 1, 1, 1, 1, 1, 1, 1, 505),
  first     = c("1950-01-03", "1985-01-29", "1962-01-02", "1984-01-03",
                "1988-05-03", "1986-12-31", "2000-01-03", "1990-11-26",
                "1990-03-01", "1984-01-04", "1990-11-09", "1986-12-31",
                "1970-01-01", "1990-01-02", "1962-01-05"),
  # Note the ragged end dates: the European and Japanese series stop a few
  # sessions before 2015-12-31 because their exchanges closed earlier.
  last      = c("2015-12-31", "2015-12-31", "2015-12-31", "2015-12-31",
                "2015-12-31", "2015-12-23", "2015-12-31", "2015-12-30",
                "2015-12-31", "2015-12-30", "2015-12-30", "2015-12-31",
                "2015-12-31", "2015-12-31", "2015-12-31"),
  na_total  = c(0, 0, 101285, 0, 163821, 0, 8270, 0, 0, 0, 0, 0, 0, 0, 754184),
  na_inner  = c(0, 0, 25, 0, 4634, 0, 1938, 0, 0, 0, 0, 0, 0, 0, 165),
  stringsAsFactors = FALSE
)

verify_qrmdata_ports <- function(contract = qrmdata_contract) {
  for (i in seq_len(nrow(contract))) {
    r <- contract[i, ]
    e <- new.env()
    utils::data(list = r$name, package = "smqf", envir = e)
    x <- get(r$name, envir = e)
    stopifnot(
      inherits(x, "xts"),
      nrow(x) == r$nrow,
      ncol(x) == r$ncol,
      format(min(zoo::index(x))) == r$first,
      format(max(zoo::index(x))) == r$last,
      sum(is.na(x)) == r$na_total,
      n_interior_na(x) == r$na_inner,
      all(zoo::coredata(x) > 0, na.rm = TRUE)
    )
  }
  message("qrmdata ports: all ", nrow(contract), " datasets match the contract.")
  invisible(TRUE)
}

if (requireNamespace("smqf", quietly = TRUE)) {
  verify_qrmdata_ports()
}
