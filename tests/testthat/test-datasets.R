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
test_that("Fred loads as an xts with predictors and response", {
  data("Fred", package = "smqf")
  expect_s3_class(Fred, "xts")
  expect_equal(dim(Fred), c(60L, 129L))
  expect_equal(tail(colnames(Fred), 1L), "DJI.Adjusted")
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
test_that("TermStructure loads as an xts with a tau attribute", {
  data("TermStructure", package = "smqf")
  expect_s3_class(TermStructure, "xts")
  expect_equal(dim(TermStructure), c(622L, 11L))
  tau <- xts::xtsAttributes(TermStructure)$tau
  expect_equal(length(tau), ncol(TermStructure))
})
