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

test_that("input validation: alpha outside (0,1) raises error", {
  x <- rnorm(100); y <- rnorm(100)
  expect_error(f_tail_dependence(x, y, alpha = 0),   "'alpha'")
  expect_error(f_tail_dependence(x, y, alpha = 1),   "'alpha'")
  expect_error(f_tail_dependence(x, y, alpha = -0.1),"'alpha'")
  expect_error(f_tail_dependence(x, y, alpha = 1.1), "'alpha'")
})

test_that("input validation: length mismatch raises error", {
  expect_error(f_tail_dependence(rnorm(5), rnorm(6), alpha = 0.1), "'x' and 'y'")
})

test_that("input validation: non-numeric x or y raises error", {
  expect_error(f_tail_dependence("a", rnorm(5), alpha = 0.1), "'x'")
  expect_error(f_tail_dependence(rnorm(5), "b", alpha = 0.1), "'y'")
})
