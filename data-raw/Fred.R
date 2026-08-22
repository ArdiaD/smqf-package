## data-raw/Fred.R
##
## Provenance and contract harness for the Fred dataset.
##
## Fred pairs 128 FRED-MD macroeconomic predictors with a one-month-ahead Dow
## Jones return in the SAME row: row t holds predictors observed at t and the
## return realized over t+1. That alignment is the whole point of the object,
## and it is also the one thing that cannot be seen by looking at the data --
## an off-by-one month would turn a prediction exercise into a look-ahead, and
## with only 60 rows the difference is invisible in any summary statistic.
##
## This script re-derives the response from its original source and checks it
## against the shipped column, so the alignment is auditable rather than
## asserted.
##
## Run with:  Rscript data-raw/Fred.R
## Set SMQF_FRED_ONLINE=1 to include the network-dependent checks.
##
## Vintage: Jan 2015 - Dec 2019, retrieved 2024.
## Sources: FRED-MD monthly vintage (McCracken & Ng), stationarity-transformed
##          and standardized; Dow Jones prices via quantmod::getSymbols("^DJI").

library(xts)
library(smqf)

data("Fred", package = "smqf")
x <- Fred

stopifnot(inherits(x, "xts"))
stopifnot(inherits(zoo::index(x), "yearmon"))

## ---- shape and layout ------------------------------------------------------
stopifnot(identical(dim(x), c(60L, 129L)))
stopifnot(identical(tail(colnames(x), 1L), "DJI.Adjusted"))
stopifnot(!anyDuplicated(colnames(x)))
stopifnot(format(min(zoo::index(x))) == "Jan 2015")
stopifnot(format(max(zoo::index(x))) == "Dec 2019")
stopifnot(!is.unsorted(zoo::index(x)))
stopifnot(!anyNA(x))

## ---- the regime the dataset exists to illustrate ---------------------------
p <- ncol(x) - 1L
n <- nrow(x)
stopifnot(p == 128L, n == 60L, p > n)   # genuinely high dimensional

## ---- predictor scales ------------------------------------------------------
## The predictors are transformed for stationarity but NOT rescaled: the column
## standard deviations span about eight orders of magnitude. An earlier version
## of the help page called them "standardised"; they are not. Anything fitted
## on this matrix must standardize internally.
X  <- x[, colnames(x) != "DJI.Adjusted"]
cs <- apply(X, 2, stats::sd)
stopifnot(all(cs > 0), all(is.finite(cs)))
stopifnot(max(cs) / min(cs) > 1e6)
stopifnot(sum(cs > 0.9 & cs < 1.1) < 5L)   # decidedly not unit variance

## ---- the response ----------------------------------------------------------
## DJI.Adjusted is the one-month-ahead change in the index LEVEL, in points --
## not a return. An earlier version of the help page called it a log-return.
## Pin the scale so the distinction cannot silently change.
y <- as.numeric(x[, "DJI.Adjusted"])
stopifnot(all(is.finite(y)))
stopifnot(max(abs(y)) > 100)            # points, not a return
stopifnot(abs(stats::sd(y) - 780.4) < 1)
stopifnot(abs(min(y) - (-2211)) < 1, abs(max(y) - 1784.9) < 1)

## ---- alignment: row t must carry the return realized over t+1 --------------
## Rebuilt from source. Skipped by default because it needs the network.
if (nzchar(Sys.getenv("SMQF_FRED_ONLINE")) &&
    requireNamespace("quantmod", quietly = TRUE)) {

  dji <- quantmod::getSymbols("^DJI", src = "yahoo", auto.assign = FALSE,
                              from = "2014-12-01", to = "2020-02-01")
  adj <- dji[, "DJI.Adjusted"]
  monthly <- adj[xts::endpoints(adj, on = "months"), ]
  ## The shipped response is a point CHANGE, so rebuild it the same way.
  rets <- as.numeric(monthly) - as.numeric(xts::lag.xts(monthly, 1))
  stamps <- zoo::as.yearmon(zoo::index(monthly))

  ## The change stamped at month m is realized over month m. If the dataset is
  ## aligned as documented, the value stored in row t (month m) equals the
  ## change of month m+1.
  want <- zoo::as.yearmon(zoo::index(x)) + 1 / 12
  idx  <- match(want, stamps)
  stopifnot(!anyNA(idx))
  reb  <- rets[idx]

  err <- max(abs(reb - y), na.rm = TRUE)
  message("Fred: rebuilt response differs from shipped by at most ",
          format(err, digits = 3))
  if (err > 1) {
    ## Report the contemporaneous alternative too, so a genuine misalignment
    ## is distinguishable from a vintage difference in the price series.
    idx0 <- match(zoo::as.yearmon(zoo::index(x)), stamps)
    err0 <- max(abs(rets[idx0] - y), na.rm = TRUE)
    stop("Fred: the shipped response does not match a one-month-ahead ",
         "return (error ", format(err, digits = 3), "). Contemporaneous ",
         "alignment gives ", format(err0, digits = 3),
         ". If the contemporaneous error is the smaller of the two, the ",
         "dataset is misaligned and the documentation is wrong.")
  }
} else {
  message("Fred: online alignment check skipped ",
          "(set SMQF_FRED_ONLINE=1 and install quantmod to run it).")
}

## ---- anchors ---------------------------------------------------------------
stopifnot(abs(as.numeric(x[1, "RPI"]) - 153.075) < 1e-3)
stopifnot(abs(as.numeric(x[2, "RPI"]) - 57.928) < 1e-3)

message("Fred: all offline contract checks passed (",
        nrow(x), " x ", ncol(x), ").")
