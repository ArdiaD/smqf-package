## Tests for the smqf datasets ----------------------------------------------
##
## Every dataset used by Chapter 1 and its exercises is pinned here: class and
## class of the index, exact dimensions and column names, ordering and
## uniqueness of the time index, the documented structure of the missing
## values, and the documented units. A silent change in any of these breaks
## the book, so it should break the test suite first.

get_data <- function(nm) {
  e <- new.env()
  utils::data(list = nm, package = "smqf", envir = e)
  get(nm, envir = e)
}

expect_clean_index <- function(x) {
  idx <- zoo::index(x)
  expect_false(is.unsorted(idx))
  expect_equal(anyDuplicated(idx), 0L)
  expect_false(anyNA(idx))
}

# Number of NAs that appear after a column's first observation.
n_interior_na <- function(x) {
  cd <- zoo::coredata(x)
  sum(vapply(seq_len(ncol(cd)), function(j) {
    v <- is.na(cd[, j])
    if (!any(v)) return(0L)
    first_ok <- which(!v)[1L]
    sum(v[first_ok:length(v)])
  }, integer(1)))
}

# ---- FamaFrench (Chapter 1, Section "Measure exposures") -------------------

test_that("FamaFrench has the documented shape, index and units", {
  x <- get_data("FamaFrench")
  expect_s3_class(x, "xts")
  expect_s3_class(zoo::index(x), "Date")
  expect_equal(dim(x), c(4834L, 4L))
  expect_equal(colnames(x), c("mkt_rf", "smb", "hml", "rf"))
  expect_clean_index(x)
  expect_equal(format(min(zoo::index(x))), "1926-07-02")
  expect_equal(format(max(zoo::index(x))), "2019-02-22")
  expect_false(anyNA(x))

  # Percentage points, not decimals: weekly equity vol is ~2%, not ~0.02.
  z <- zoo::coredata(x)
  expect_gt(sd(z[, "mkt_rf"]), 1)
  expect_lt(sd(z[, "mkt_rf"]), 5)
  expect_lt(max(z[, "rf"]), 1)
  # rf dips slightly below zero in 60 Depression-era weeks (1933 and 1938),
  # with a minimum of -0.016%. That is in the source data, not a defect, but
  # it rules out a blanket non-negativity assumption.
  expect_gt(min(z[, "rf"]), -0.05)
  expect_equal(sum(z[, "rf"] < 0), 60L)
})

test_that("FamaFrench is stamped at the end of the week", {
  x <- get_data("FamaFrench")
  idx <- zoo::index(x["2017-01-01/2018-12-31"])
  # 104 weekly observations over the two years used in Chapter 1
  expect_length(idx, 104L)
  # Spacing is 7 days apart from holiday shifts, which pull a stamp back to
  # the Thursday (the two here are the eves of Good Friday 2017 and 2018).
  expect_true(all(diff(as.numeric(idx)) %in% 6:8))
  expect_setequal(unique(weekdays(idx)),
                  weekdays(as.Date(c("2017-01-06", "2017-04-13"))))
  expect_equal(sum(weekdays(idx) != weekdays(as.Date("2017-01-06"))), 2L)
})

test_that("FamaFrench stamps the early history on Saturdays", {
  x <- get_data("FamaFrench")
  wd <- weekdays(zoo::index(x))
  fri <- weekdays(as.Date("2017-01-06")); sat <- weekdays(as.Date("2017-01-07"))
  # Saturday trading sessions ran into the 1950s, so the end-of-week stamp is
  # a Saturday for roughly a quarter of the sample. Any code that assumes a
  # Friday stamp throughout will silently mis-handle the early decades.
  expect_equal(sum(wd == sat), 1158L)
  expect_equal(sum(wd == fri), 3535L)
  expect_true(all(wd[zoo::index(x) > as.Date("1960-01-01")] != sat))
})

# ---- FungHsieh (Exercise 1.8) ---------------------------------------------

test_that("FungHsieh has the documented shape, index and units", {
  x <- get_data("FungHsieh")
  expect_s3_class(x, "xts")
  expect_s3_class(zoo::index(x), "yearmon")
  expect_equal(dim(x), c(276L, 8L))
  expect_equal(colnames(x),
               c("EMKT", "RF", "SS", "CST10Y", "BAA",
                 "PTFSBD", "PTFSCOM", "PTFSFX"))
  expect_clean_index(x)
  expect_equal(format(min(zoo::index(x))), "Jan 1994")
  expect_equal(format(max(zoo::index(x))), "Dec 2016")
  expect_false(anyNA(x))

  z <- zoo::coredata(x)
  # Percentage points. Exercise 1.8 merges these with the DECIMAL `edhec`
  # series, so this factor of 100 is load-bearing.
  expect_true(all(z[, "RF"] >= 0))
  expect_lt(max(z[, "RF"]), 1)
  expect_equal(sd(z[, "EMKT"]) * sqrt(12), 14.7, tolerance = 0.1)
  # SS is a long-short spread, not a directional return
  expect_lt(abs(mean(z[, "SS"])), 0.5)
  expect_lt(abs(stats::cor(z[, "EMKT"], z[, "SS"])), 0.3)
  # CST10Y and BAA are changes in yields, in percentage points
  for (nm in c("CST10Y", "BAA")) {
    expect_lt(abs(mean(z[, nm])), 0.05)
    expect_lt(max(abs(z[, nm])), 2)
  }
  # PTFS straddles: negative mean, fat right tail
  for (nm in c("PTFSBD", "PTFSCOM", "PTFSFX")) {
    expect_lt(mean(z[, nm]), 0)
    expect_gt(sd(z[, nm]), 10)
  }
})

# ---- DJ_const (Exercises 1.2, 1.5, 1.6, 1.7) ------------------------------

test_that("DJ_const has the documented shape and index", {
  x <- get_data("DJ_const")
  expect_s3_class(x, "xts")
  expect_s3_class(zoo::index(x), "Date")
  expect_equal(dim(x), c(13595L, 30L))
  expect_clean_index(x)
  expect_equal(format(min(zoo::index(x))), "1962-01-02")
  expect_equal(format(max(zoo::index(x))), "2015-12-31")
  expect_true(all(c("AAPL", "IBM", "JPM", "XOM", "CAT") %in% colnames(x)))
  expect_true(all(zoo::coredata(x) > 0, na.rm = TRUE))
})

test_that("DJ_const missing values match the documentation", {
  x <- get_data("DJ_const")
  expect_equal(sum(is.na(x)), 101285L)
  # Documented: mostly leading, but 25 interior NAs remain after a series
  # has started, so trimming the leading block is not sufficient.
  expect_equal(n_interior_na(x), 25L)
})

# ---- EURSTX_const (Exercise 1.9) ------------------------------------------

test_that("EURSTX_const has the documented shape and index", {
  x <- get_data("EURSTX_const")
  expect_s3_class(x, "xts")
  expect_s3_class(zoo::index(x), "Date")
  expect_equal(dim(x), c(4174L, 50L))
  expect_clean_index(x)
  expect_equal(format(min(zoo::index(x))), "2000-01-03")
  expect_equal(format(max(zoo::index(x))), "2015-12-31")
  expect_true(all(zoo::coredata(x) > 0, na.rm = TRUE))
})

test_that("EURSTX_const has interior NAs in every column", {
  x <- get_data("EURSTX_const")
  expect_equal(sum(is.na(x)), 8270L)
  # 1,938 interior NAs spread over all 50 columns: local trading holidays.
  # This is why cov() returns NA and Exercise 1.9 needs pairwise-complete
  # estimation plus a PSD projection.
  expect_equal(n_interior_na(x), 1938L)
  expect_true(anyNA(stats::cov(zoo::coredata(x))))
  expect_false(anyNA(stats::cov(zoo::coredata(x), use = "pairwise.complete.obs")))
})

# ---- VIX and SP500 (Exercise 1.10) ----------------------------------------

test_that("VIX has the documented shape, index and column name", {
  x <- get_data("VIX")
  expect_s3_class(x, "xts")
  expect_s3_class(zoo::index(x), "Date")
  expect_equal(dim(x), c(6553L, 1L))
  expect_equal(colnames(x), "^VIX")   # non-syntactic: needs backticks
  expect_clean_index(x)
  expect_equal(format(min(zoo::index(x))), "1990-01-02")
  expect_equal(format(max(zoo::index(x))), "2015-12-31")
  expect_false(anyNA(x))
  # Volatility index in percent, annualized
  expect_gt(min(x), 5); expect_lt(max(x), 90)
})

test_that("SP500 has the documented shape, index and column name", {
  x <- get_data("SP500")
  expect_s3_class(x, "xts")
  expect_s3_class(zoo::index(x), "Date")
  expect_equal(dim(x), c(16607L, 1L))
  expect_equal(colnames(x), "^GSPC")
  expect_clean_index(x)
  expect_equal(format(min(zoo::index(x))), "1950-01-03")
  expect_equal(format(max(zoo::index(x))), "2015-12-31")
  expect_false(anyNA(x))
  expect_true(all(zoo::coredata(x) > 0))

  # Anchor the snapshot itself, not just its shape: Chapter 2 fits a Student-t
  # and an NIG to the 2000-2007 window and quotes the results in prose, and the
  # Bayesian example counts up-days in January 2015. Another positive series of
  # the same dimensions would pass every check above and change all of them.
  expect_equal(round(as.numeric(x["2000-01-03"]), 2), 1455.22)
  expect_equal(round(as.numeric(x["2015-01-23"]), 2), 2051.82)
  expect_equal(mean(x["1999-12-31/2007-12-31"]), 1213.247, tolerance = 1e-6)
})

test_that("VIX and SP500 align exactly over the Exercise 1.10 window", {
  v <- get_data("VIX"); s <- get_data("SP500")
  w <- "2010-01-01/2015-12-31"
  expect_identical(zoo::index(v[w]), zoo::index(s[w]))
  m <- merge(v[w], s[w])
  expect_false(anyNA(m))
  # merge() mangles the non-syntactic names; the exercise must account for it
  expect_equal(colnames(m), c("X.VIX", "X.GSPC"))
})

# ---- FTSE_const and FTSE (Chapter 2, heuristic optimization) --------------

test_that("FTSE_const has the documented shape and index", {
  x <- get_data("FTSE_const")
  expect_s3_class(x, "xts")
  expect_s3_class(zoo::index(x), "Date")
  expect_equal(dim(x), c(7198L, 98L))
  expect_clean_index(x)
  expect_equal(format(min(zoo::index(x))), "1988-05-03")
  expect_equal(format(max(zoo::index(x))), "2015-12-31")
  expect_true(all(grepl("\\.L$", colnames(x))))     # London tickers
  expect_true(all(zoo::coredata(x) > 0, na.rm = TRUE))
})

test_that("FTSE_const missing values match the documentation", {
  x <- get_data("FTSE_const")
  expect_equal(sum(is.na(x)), 163821L)
  # Documented: mostly leading, but 4,634 interior NAs across 96 columns, so
  # dropping the leading block is not sufficient.
  expect_equal(n_interior_na(x), 4634L)
})

test_that("FTSE_const yields the 95 complete names used in Chapter 2", {
  x <- get_data("FTSE_const")
  w <- x["2013/"]
  expect_equal(nrow(w), 781L)
  # The chapter filters on complete price history over the window; the count
  # drives every covariance and every heuristic result in that section.
  expect_equal(sum(colSums(is.na(w)) == 0), 95L)
  expect_false(anyNA(w[, colSums(is.na(w)) == 0]))
})

test_that("FTSE has the documented shape, index and column name", {
  x <- get_data("FTSE")
  expect_s3_class(x, "xts")
  expect_s3_class(zoo::index(x), "Date")
  expect_equal(dim(x), c(8333L, 1L))
  expect_equal(colnames(x), "^FTSE")
  expect_clean_index(x)
  expect_equal(format(min(zoo::index(x))), "1984-01-03")
  expect_equal(format(max(zoo::index(x))), "2015-12-31")
  expect_false(anyNA(x))
  expect_true(all(zoo::coredata(x) > 0))
})

# ---- other datasets -------------------------------------------------------

test_that("Fred loads as an xts with predictors and response", {
  x <- get_data("Fred")
  expect_s3_class(x, "xts")
  expect_equal(dim(x), c(60L, 129L))
  expect_equal(tail(colnames(x), 1L), "DJI.Adjusted")
  expect_clean_index(x)
  expect_false(anyNA(x))
  # The regime the dataset exists to illustrate
  expect_gt(ncol(x) - 1L, nrow(x))
})

test_that("Fred's response is a point change, not a return", {
  # The help page once described this column as a log-return. It is the
  # one-month-ahead change in the index level, in points, and Your Turn 4.7
  # depends on the reader being told so.
  x <- get_data("Fred")
  y <- as.numeric(x[, "DJI.Adjusted"])
  expect_gt(max(abs(y)), 100)
  expect_equal(stats::sd(y), 780.4, tolerance = 1e-3)
  expect_equal(range(y), c(-2211, 1784.922), tolerance = 1e-3)
})

test_that("Fred's predictors are not rescaled", {
  # Column scales span about eight orders of magnitude, so any penalized fit
  # must standardize internally.
  x  <- get_data("Fred")
  cs <- apply(x[, colnames(x) != "DJI.Adjusted"], 2, stats::sd)
  expect_true(all(cs > 0))
  expect_gt(max(cs) / min(cs), 1e6)
  expect_lt(sum(cs > 0.9 & cs < 1.1), 5L)
})

test_that("SP500_const has the documented shape and index", {
  # Exercise 4.2 rests on this dataset and nothing pinned it.
  x <- get_data("SP500_const")
  expect_s3_class(x, "xts")
  expect_s3_class(zoo::index(x), "Date")
  expect_equal(dim(x), c(2818L, 505L))
  expect_equal(format(min(zoo::index(x))), "1962-01-05")
  expect_equal(format(max(zoo::index(x))), "2015-12-31")
  expect_clean_index(x)
})

test_that("the Exercise 4.2 slice reproduces the p > n regime", {
  skip_if_not_installed("PerformanceAnalytics")
  x  <- get_data("SP500_const")
  pr <- x["2013/2015"]
  pr <- pr[xts::endpoints(pr, on = "weeks"), ]
  r  <- PerformanceAnalytics::CalculateReturns(pr, method = "discrete")[-1, ]
  r  <- r[, colSums(is.na(r)) == 0]
  # These three numbers are quoted verbatim in the solution.
  expect_equal(nrow(r), 156L)
  expect_equal(ncol(r), 487L)
  expect_equal(qr(stats::cov(r))$rank, 155L)
  expect_gt(ncol(r), nrow(r))
})

test_that("GoyalWelch has the documented shape, layout and span", {
  x <- get_data("GoyalWelch")
  expect_s3_class(x, "xts")
  expect_s3_class(zoo::index(x), "yearmon")
  expect_equal(dim(x), c(469L, 15L))
  # Column order is pinned, not just membership: positional selection such as
  # GoyalWelch[, 2:14] appears in the wild and would change meaning silently.
  expect_equal(colnames(x),
               c("Index", "D12", "E12", "b/m", "tbl", "AAA", "BAA", "lty",
                 "ntis", "Rfree", "infl", "ltr", "corpr", "svar", "csp"))
  expect_equal(format(min(zoo::index(x))), "Dec 1979")
  expect_equal(format(max(zoo::index(x))), "Dec 2018")
  expect_clean_index(x)
})

test_that("GoyalWelch Rfree is exactly tbl / 12", {
  # This is the redundancy that makes any design holding both columns rank
  # deficient. lm() reports NA for the aliased coefficient; glmnet does not,
  # and splits the effect arbitrarily between the two. Chapter 4 relies on
  # this being caught here rather than in a reader's regression.
  x <- get_data("GoyalWelch")
  expect_identical(as.numeric(x[, "tbl"]) / 12, as.numeric(x[, "Rfree"]))
})

test_that("GoyalWelch missing values match the documentation", {
  x <- get_data("GoyalWelch")
  # csp (the Polk-Thompson-Vuolteenaho cross-sectional premium) stops at
  # Dec 2002; every other column is complete.
  expect_equal(sum(is.na(x)), 192L)
  expect_equal(sum(is.na(x[, "csp"])), 192L)
  expect_false(anyNA(x[, setdiff(colnames(x), "csp")]))
  ok <- !is.na(x[, "csp"])
  expect_true(all(diff(which(ok)) == 1L))
  expect_equal(format(tail(zoo::index(x)[ok], 1)), "Dec 2002")
  # csp is NOT corpr - ltr: the two live on different scales.
  dfr <- as.numeric(x[, "corpr"]) - as.numeric(x[, "ltr"])
  expect_lt(diff(range(as.numeric(x[ok, "csp"]))), 0.01)
  expect_gt(diff(range(dfr)), 0.15)
})

test_that("GoyalWelch units and anchors are stable", {
  x <- get_data("GoyalWelch")
  # tbl and the bond yields are annualized decimals, not monthly rates
  expect_true(all(x[, "tbl"] >= 0))
  expect_lt(max(x[, "tbl"]), 0.25)
  expect_lt(max(abs(x[, "infl"])), 0.05)
  expect_true(all(x[, "Index"] > 0))
  expect_equal(as.numeric(x[1, "Index"]), 107.94, tolerance = 1e-8)
  expect_equal(as.numeric(x[469, "Index"]), 2506.85, tolerance = 1e-8)
})

test_that("the Chapter 4 equity premium and design matrix are reproducible", {
  x   <- get_data("GoyalWelch")
  ix  <- x[, "Index"]
  erp <- (ix + x[, "D12"] / 12) / xts::lag.xts(ix, 1) - 1 - x[, "Rfree"]
  erp <- erp[-1, ]
  expect_equal(nrow(erp), 468L)
  expect_equal(as.numeric(mean(erp)), 0.006289, tolerance = 1e-3)
  expect_equal(stats::sd(as.numeric(erp)), 0.042875, tolerance = 1e-3)

  X <- merge(log(x[, "D12"]) - log(ix), log(x[, "E12"]) - log(ix),
             x[, "b/m"], x[, "ntis"], x[, "tbl"],
             x[, "lty"] - x[, "tbl"], x[, "ltr"],
             x[, "BAA"] - x[, "AAA"], x[, "corpr"] - x[, "ltr"],
             x[, "infl"], x[, "svar"])
  Xm <- as.matrix(stats::na.omit(merge(erp, xts::lag.xts(X, 1)))[, -1])
  expect_equal(dim(Xm), c(468L, 11L))
  # Full rank, unlike the tbl + Rfree design the chapter warns about
  expect_equal(qr(Xm)$rank, 11L)
})

test_that("TermStructure loads as an xts with a tau attribute", {
  x <- get_data("TermStructure")
  expect_s3_class(x, "xts")
  expect_equal(dim(x), c(622L, 11L))
  tau <- xts::xtsAttributes(x)$tau
  expect_length(tau, ncol(x))
  expect_false(is.unsorted(tau))
  expect_clean_index(x)
})

# ---- single-series international indices (Chapter 3) ----------------------
# SP500 is pinned above; these seven carry the multivariate examples of
# Chapter 3 and were previously loaded by no test at all. The end dates are
# ragged on purpose: the European and Japanese exchanges closed a few sessions
# before 2015-12-31.

test_that("the single-series indices match their documented shape and span", {
  contract <- data.frame(
    name  = c("DJ", "FTSE", "EURSTOXX", "DAX", "CAC", "NIKKEI", "SMI", "HSI",
              "GOLD"),
    nrow  = c(7797L, 8333L, 7445L, 6355L, 6549L, 7880L, 6350L, 7214L, 9691L),
    first = c("1985-01-29", "1984-01-03", "1986-12-31", "1990-11-26",
              "1990-03-01", "1984-01-04", "1990-11-09", "1986-12-31",
              "1970-01-01"),
    last  = c("2015-12-31", "2015-12-31", "2015-12-23", "2015-12-30",
              "2015-12-31", "2015-12-30", "2015-12-30", "2015-12-31",
              "2015-12-31"),
    stringsAsFactors = FALSE
  )
  for (i in seq_len(nrow(contract))) {
    r <- contract[i, ]
    x <- get_data(r$name)
    expect_s3_class(x, "xts")
    expect_s3_class(zoo::index(x), "Date")
    expect_equal(dim(x), c(r$nrow, 1L), info = r$name)
    expect_equal(format(min(zoo::index(x))), r$first, info = r$name)
    expect_equal(format(max(zoo::index(x))), r$last, info = r$name)
    expect_clean_index(x)
    expect_false(anyNA(x), info = r$name)
    expect_true(all(zoo::coredata(x) > 0), info = r$name)
  }
})

test_that("DJ and DAX are anchored numerically, not just by shape", {
  # Shape, dates and positivity are checked by the contract table above, but
  # any other positive series of the same shape would pass those. Pin actual
  # values so a substituted or re-scaled series fails loudly.
  # The series are stored at single precision, so pin them to about seven
  # significant figures rather than to the last bit.
  dj <- get_data("DJ")
  expect_equal(as.numeric(dj[1]), 1292.619995, tolerance = 1e-6)
  expect_equal(as.numeric(dj[nrow(dj)]), 17425.029297, tolerance = 1e-6)
  expect_equal(sum(as.numeric(dj)), 63612839.43, tolerance = 1e-7)

  dax <- get_data("DAX")
  expect_equal(as.numeric(dax[1]), 1443.199951, tolerance = 1e-6)
  expect_equal(as.numeric(dax[nrow(dax)]), 10743.009766, tolerance = 1e-6)
  expect_equal(sum(as.numeric(dax)), 32450037.45, tolerance = 1e-7)
})

test_that("the Chapter 5 DAX slices match their documented shape", {
  # Every MLE, bootstrap and GARCH number in Chapter 5 rests on one of these
  # two windows. Neither was pinned by any test.
  x <- get_data("DAX")

  # Slice 1: the Student-t MLE and bootstrap example
  w1 <- x["2012-01/2015-12"]
  expect_equal(nrow(w1), 1016L)
  expect_equal(format(min(zoo::index(w1))), "2012-01-03")
  expect_equal(format(max(zoo::index(w1))), "2015-12-30")
  expect_false(anyNA(w1))
  r1 <- 100 * diff(log(as.numeric(w1)))
  expect_equal(length(r1), 1015L)

  # Slice 2: the rugarch example
  r2 <- 100 * as.numeric(diff(log(x))[2:1001])
  expect_length(r2, 1000L)
  expect_false(anyNA(r2))
  d2 <- zoo::index(x)[2:1001]
  expect_equal(format(min(d2)), "1990-11-27")
  expect_equal(format(max(d2)), "1994-11-25")
})

test_that("the Chapter 5 Student-t fit is reproducible", {
  skip_if_not_installed("MASS")
  x    <- get_data("DAX")
  rets <- 100 * diff(log(as.numeric(x["2012-01/2015-12"])))
  fit  <- suppressWarnings(MASS::fitdistr(rets, densfun = "t"))
  # Anchored with tolerance: the chapter quotes nu close to 4.6 and the
  # agreement between asymptotic and bootstrap standard errors depends on it.
  expect_equal(unname(fit$estimate["df"]), 4.639, tolerance = 1e-3)
  expect_equal(unname(fit$estimate["s"]), 0.9124, tolerance = 1e-3)
  expect_true(unname(fit$sd["df"]) > 0.5 && unname(fit$sd["df"]) < 1.2)
})

test_that("the Chapter 3 merge yields the documented 299 weekly returns", {
  skip_if_not_installed("PerformanceAnalytics")
  ind <- merge(get_data("SP500"), get_data("FTSE"),
               get_data("EURSTOXX"), get_data("NIKKEI"))
  ind <- ind[xts::endpoints(ind, on = "weeks"), ]
  r   <- PerformanceAnalytics::CalculateReturns(ind, method = "discrete")
  r   <- r[rowSums(is.na(r)) == 0, ]
  r   <- r["2001-01-01/2007-12-31"]

  # The count drives the MLE, the comoments and the tail-dependence estimate.
  expect_equal(nrow(r), 299L)
  expect_equal(format(min(zoo::index(r))), "2001-01-05")
  expect_equal(format(max(zoo::index(r))), "2007-12-14")

  # Every retained return spans exactly one week, even though the retained
  # series itself is not contiguous: when a market is closed, that week and
  # the next are both dropped, so gaps of 21, 28 and 35 days appear between
  # consecutive observations.
  gaps <- as.numeric(diff(zoo::index(r)))
  expect_true(all(gaps %in% c(7, 21, 28, 35)))
  expect_equal(sum(gaps == 7), 268L)
})

# ---- raw files shipped for the Chapter 1 import examples ------------------

test_that("the extdata files ship and match the documented format", {
  for (f in c("stocks.txt", "stocks.csv", "stocks.xlsx", "prices.txt")) {
    expect_true(nzchar(system.file("extdata", f, package = "smqf")),
                info = paste("missing extdata file:", f))
  }

  stocks <- read.table(system.file("extdata", "stocks.txt", package = "smqf"),
                       header = TRUE)
  expect_equal(dim(stocks), c(574L, 6L))
  expect_equal(names(stocks), c("Date", "AAPL", "AXP", "BA", "CAT", "CSCO"))
  expect_false(anyNA(stocks))

  d <- as.Date(stocks$Date)
  expect_equal(format(min(d)), "2008-01-01")
  expect_equal(format(max(d)), "2018-12-25")
  # All Tuesdays, exactly seven days apart: the week-start stamping documented
  # in ?extdata, which must be reconciled with FamaFrench's Friday stamps.
  expect_length(unique(weekdays(d)), 1L)
  expect_true(all(diff(as.numeric(d)) == 7))

  csv <- read.csv(system.file("extdata", "stocks.csv", package = "smqf"))
  expect_equal(csv, stocks, tolerance = 1e-12)
})
