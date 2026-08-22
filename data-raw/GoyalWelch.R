## data-raw/GoyalWelch.R
##
## Provenance and contract harness for the GoyalWelch dataset.
##
## The shipped object was compiled from Amit Goyal's public "Predicting the
## Equity Premium" data library (the monthly sheet of the Updated Goyal-Welch
## workbook) together with standard fixed-income series. The original workbook
## is distributed as an Excel file whose column layout has changed between
## vintages, so rather than re-download it at build time this script does two
## things:
##
##   1. documents the vintage and the transformations applied, and
##   2. asserts every structural property the book and the help page rely on,
##      so that a re-import from a different vintage fails loudly instead of
##      silently shifting a column.
##
## Run with:  Rscript data-raw/GoyalWelch.R
##
## Vintage: monthly sheet, Dec 1979 - Dec 2018, retrieved 2024.
## Source:  https://sites.google.com/view/agoyal145
## Units:   tbl, AAA, BAA, lty are annualized decimals (0.1204 = 12.04%/yr).
##          Rfree, infl, ltr, corpr, svar are monthly decimals.
##          Index, D12, E12 are levels. b/m and ntis are ratios.

library(xts)
library(smqf)

data("GoyalWelch", package = "smqf")
x <- GoyalWelch

stopifnot(inherits(x, "xts"))
stopifnot(inherits(zoo::index(x), "yearmon"))

## ---- shape and layout ------------------------------------------------------
## The book selects predictors by name, but positional selection appears in the
## wild, so pin the order as well as the membership.
expected_cols <- c("Index", "D12", "E12", "b/m", "tbl", "AAA", "BAA", "lty",
                   "ntis", "Rfree", "infl", "ltr", "corpr", "svar", "csp")
stopifnot(identical(dim(x), c(469L, 15L)))
stopifnot(identical(colnames(x), expected_cols))
stopifnot(format(min(zoo::index(x))) == "Dec 1979")
stopifnot(format(max(zoo::index(x))) == "Dec 2018")
stopifnot(!is.unsorted(zoo::index(x)))
stopifnot(!anyDuplicated(zoo::index(x)))

## ---- the exact redundancy that breaks penalized regressions ----------------
## Rfree is tbl/12 to the last representable digit. Any design matrix holding
## both is rank deficient; glmnet will not tell you.
stopifnot(max(abs(as.numeric(x[, "tbl"]) / 12 -
                    as.numeric(x[, "Rfree"]))) == 0)

## ---- missing values --------------------------------------------------------
## csp (the Polk-Thompson-Vuolteenaho cross-sectional premium) stops at
## Dec 2002; everything else is complete.
stopifnot(sum(is.na(x)) == 192L)
stopifnot(sum(is.na(x[, "csp"])) == 192L)
stopifnot(!anyNA(x[, setdiff(expected_cols, "csp")]))
ok <- !is.na(x[, "csp"])
stopifnot(all(diff(which(ok)) == 1L))          # one contiguous block
stopifnot(format(zoo::index(x)[ok][1]) == "Dec 1979")
stopifnot(format(tail(zoo::index(x)[ok], 1)) == "Dec 2002")

## csp is NOT the corporate bond return spread. An earlier version of the help
## page said it was; these two series are on entirely different scales.
csp_rng <- range(as.numeric(x[ok, "csp"]))
dfr_rng <- range(as.numeric(x[, "corpr"]) - as.numeric(x[, "ltr"]))
stopifnot(diff(csp_rng) < 0.01, diff(dfr_rng) > 0.15)

## ---- units and plausibility ------------------------------------------------
stopifnot(all(x[, "Index"] > 0), all(x[, "D12"] > 0), all(x[, "E12"] > 0))
stopifnot(all(x[, "tbl"] >= 0), max(x[, "tbl"]) < 0.25)   # annualized decimal
stopifnot(max(abs(x[, "infl"])) < 0.05)                   # monthly decimal
stopifnot(all(x[, "svar"] >= 0))

## Anchor values, so a re-import that shifts a column by one row is caught.
stopifnot(abs(as.numeric(x[1, "Index"]) - 107.94) < 1e-8)
stopifnot(abs(as.numeric(x[469, "Index"]) - 2506.85) < 1e-8)
stopifnot(abs(as.numeric(x[1, "tbl"]) - 0.1204) < 1e-8)

## ---- the response used in Chapter 4 ---------------------------------------
ix  <- x[, "Index"]
erp <- (ix + x[, "D12"] / 12) / xts::lag.xts(ix, 1) - 1 - x[, "Rfree"]
erp <- erp[-1, ]
stopifnot(nrow(erp) == 468L)
stopifnot(abs(mean(erp) - 0.00629) < 5e-5)
stopifnot(abs(stats::sd(erp) - 0.04288) < 5e-5)

## ---- the non-redundant predictor set used in Chapter 4 --------------------
X <- merge(log(x[, "D12"]) - log(ix),
           log(x[, "E12"]) - log(ix),
           x[, "b/m"], x[, "ntis"], x[, "tbl"],
           x[, "lty"] - x[, "tbl"],
           x[, "ltr"],
           x[, "BAA"] - x[, "AAA"],
           x[, "corpr"] - x[, "ltr"],
           x[, "infl"], x[, "svar"])
colnames(X) <- c("dp", "ep", "bm", "ntis", "tbl", "tms",
                 "ltr", "dfy", "dfr", "infl", "svar")
Xm <- as.matrix(stats::na.omit(merge(erp, xts::lag.xts(X, 1)))[, -1])
stopifnot(nrow(Xm) == 468L, ncol(Xm) == 11L)
stopifnot(qr(Xm)$rank == 11L)                  # full rank, unlike tbl + Rfree

message("GoyalWelch: all contract checks passed (",
        nrow(x), " x ", ncol(x), ").")
