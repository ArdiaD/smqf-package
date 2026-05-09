test_that("f_ewma_vol Riskmetrics: returns positive volatilities, length = n assets", {
  set.seed(1)
  rets <- matrix(rnorm(100 * 2, sd = 0.01), nrow = 100, ncol = 2)
  vol  <- f_ewma_vol(rets, history = FALSE, lambda = 0.94, type = "Riskmetrics")
  expect_equal(length(vol), 2)
  expect_true(all(vol > 0))
  expect_true(all(is.finite(vol)))
})

test_that("f_ewma_vol Meucci: returns positive volatilities", {
  set.seed(2)
  rets <- matrix(rnorm(100 * 3, sd = 0.02), nrow = 100, ncol = 3)
  vol  <- f_ewma_vol(rets, history = FALSE, lambda = 0.1, type = "Meucci")
  expect_equal(length(vol), 3)
  expect_true(all(vol > 0))
})

test_that("f_ewma_vol: constant returns give constant vol", {
  r    <- 0.01
  rets <- matrix(rep(r, 50), nrow = 50, ncol = 1)
  vol  <- f_ewma_vol(rets, history = FALSE, lambda = 0.94, type = "Riskmetrics")
  expect_equal(vol, r, tolerance = 1e-10)
})

test_that("f_ewma_vol history=TRUE returns matrix with correct dimensions", {
  set.seed(3)
  rets <- matrix(rnorm(60 * 2, sd = 0.01), nrow = 60, ncol = 2)
  vol  <- f_ewma_vol(rets, history = TRUE, lambda = 0.94, type = "Riskmetrics")
  expect_equal(dim(vol), c(60L, 2L))
  expect_true(all(is.finite(vol)))
})
