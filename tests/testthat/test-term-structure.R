test_that("f_NelsonSiegel: output length matches tau", {
  tau   <- c(1, 2, 5, 10, 20)
  gamma <- c(0.5, 0.3)
  beta  <- c(0.05, -0.02, 0.01)
  y     <- f_NelsonSiegel(tau, gamma, beta)
  expect_equal(length(y), length(tau))
  expect_true(all(is.finite(y)))
})

test_that("f_NelsonSiegel: long-run rate converges to beta[1]", {
  # As tau -> Inf, f1 -> 0 and f2 -> 0, so y -> beta[1]
  gamma <- c(0.5, 0.3)
  beta  <- c(0.05, -0.02, 0.01)
  y_long <- f_NelsonSiegel(1e6, gamma, beta)
  expect_equal(y_long, beta[1], tolerance = 1e-3)
})

test_that("f_NelsonSiegel: handles tau = 0 without NaN", {
  gamma <- c(0.5, 0.3)
  beta  <- c(0.05, -0.02, 0.01)
  y     <- f_NelsonSiegel(0, gamma, beta)
  expect_true(is.finite(y))
})

test_that("f_PowerSvensson: output length matches tau", {
  tau  <- c(1, 2, 5, 10)
  beta <- c(0.03, -0.01, 0.005, 0.002)
  y    <- f_PowerSvensson(tau, beta)
  expect_equal(length(y), length(tau))
  expect_true(all(is.finite(y)))
})

test_that("f_FitSqrtSvensson: returns numeric beta of length 4", {
  tau  <- c(1, 2, 5, 10, 20, 30)
  # Synthetic flat yield curve
  y    <- rep(0.04, length(tau))
  beta <- f_FitSqrtSvensson(tau, y)
  expect_equal(length(beta), 4)
  expect_true(all(is.finite(beta)))
})
