## Tests for the six smqf datasets -------------------------------------------

# FamaFrenchWeekly ----
test_that("FamaFrenchWeekly loads with correct class and dimensions", {
  data("FamaFrenchWeekly", package = "smqf")
  expect_s3_class(FamaFrenchWeekly, "xts")
  expect_equal(ncol(FamaFrenchWeekly), 4L)
  expect_equal(colnames(FamaFrenchWeekly), c("mkt_rf", "smb", "hml", "rf"))
  expect_true(nrow(FamaFrenchWeekly) > 4000L)
})

# FamaFrenchMonthly ----
test_that("FamaFrenchMonthly loads with correct class and dimensions", {
  data("FamaFrenchMonthly", package = "smqf")
  expect_s3_class(FamaFrenchMonthly, "xts")
  expect_equal(ncol(FamaFrenchMonthly), 4L)
  expect_equal(colnames(FamaFrenchMonthly), c("mkt_rf", "smb", "hml", "rf"))
  expect_equal(nrow(FamaFrenchMonthly), 360L)
})

# Fred ----
test_that("Fred loads as a list with X and y components", {
  data("Fred", package = "smqf")
  expect_type(Fred, "list")
  expect_named(Fred, c("X", "y"))
  expect_equal(dim(Fred$X), c(60L, 128L))
  expect_equal(dim(Fred$y), c(60L, 1L))
  expect_equal(colnames(Fred$y), "DJI.Adjusted")
})

# FungHsieh ----
test_that("FungHsieh loads with correct class and dimensions", {
  data("FungHsieh", package = "smqf")
  expect_s3_class(FungHsieh, "xts")
  expect_equal(ncol(FungHsieh), 8L)
  expect_true(nrow(FungHsieh) > 200L)
})

# GoyalWelch ----
test_that("GoyalWelch loads with correct class", {
  data("GoyalWelch", package = "smqf")
  expect_s3_class(GoyalWelch, "xts")
  expect_true(ncol(GoyalWelch) > 0L)
  expect_true(nrow(GoyalWelch) > 0L)
})

# TermStructure ----
test_that("TermStructure loads as a list with time, tau, rates", {
  data("TermStructure", package = "smqf")
  expect_type(TermStructure, "list")
  expect_true(all(c("time", "tau", "rates") %in% names(TermStructure)))
  expect_equal(length(TermStructure$time), nrow(TermStructure$rates))
  expect_equal(length(TermStructure$tau),  ncol(TermStructure$rates))
})
