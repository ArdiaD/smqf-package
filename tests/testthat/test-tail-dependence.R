test_that("f_tail_dependence lower: perfect dependence gives lambda = 1", {
  x   <- seq(-3, 3, length.out = 200)
  out <- f_tail_dependence(x, x, alpha = 0.05)
  expect_equal(out$lambda, 1)
})

test_that("f_tail_dependence lower: lambda in [0, 1]", {
  set.seed(42)
  x   <- rnorm(5000)
  y   <- rnorm(5000)
  out <- f_tail_dependence(x, y, alpha = 0.05)
  expect_true(out$lambda >= 0 && out$lambda <= 1)
})

test_that("f_tail_dependence upper: perfect dependence gives lambda = 1", {
  x   <- seq(-3, 3, length.out = 200)
  out <- f_tail_dependence(x, x, alpha = 0.05, side = "upper")
  expect_equal(out$lambda, 1)
})

test_that("f_tail_dependence upper: lambda in [0, 1]", {
  set.seed(7)
  x   <- rnorm(500)
  y   <- 0.6 * x + sqrt(1 - 0.36) * rnorm(500)
  out <- f_tail_dependence(x, y, alpha = 0.05, side = "upper")
  expect_true(out$lambda >= 0 && out$lambda <= 1)
})

test_that("f_tail_dependence: default side is lower", {
  set.seed(1)
  x <- rnorm(200); y <- rnorm(200)
  expect_equal(f_tail_dependence(x, y, 0.1),
               f_tail_dependence(x, y, 0.1, side = "lower"))
})

test_that("f_tail_dependence: perfect anticorrelation gives lambda near 0 in upper tail", {
  x   <- seq(-3, 3, length.out = 500)
  out <- f_tail_dependence(x, -x, alpha = 0.05, side = "upper")
  expect_equal(out$lambda, 0)
})
