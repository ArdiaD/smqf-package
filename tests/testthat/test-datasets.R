## Tests for the six smqf datasets -------------------------------------------

# FamaFrench ----
test_that("FamaFrench loads with correct class and dimensions", {
  data("FamaFrench", package = "smqf")
  expect_s3_class(FamaFrench, "xts")
  expect_equal(ncol(FamaFrench), 4L)
  expect_equal(colnames(FamaFrench), c("mkt_rf", "smb", "hml", "rf"))
  expect_true(nrow(FamaFrench) > 4000L)
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
