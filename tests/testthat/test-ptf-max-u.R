test_that("f_ptf_max_U returns valid weights summing to 1", {
  set.seed(1)
  N  <- 4
  mu <- c(0.05, 0.08, 0.10, 0.12)
  A  <- matrix(rnorm(N * N), N); Sigma <- crossprod(A) / N
  M1 <- mu
  M2 <- Sigma
  M3 <- PerformanceAnalytics::M3.MM(matrix(rnorm(200 * N), 200, N))
  M4 <- PerformanceAnalytics::M4.MM(matrix(rnorm(200 * N), 200, N))

  out <- f_ptf_max_U(gamma = 2, w_max = 1, M1 = M1, M2 = M2, M3 = M3, M4 = M4)

  expect_equal(length(out$w), N)
  expect_equal(sum(out$w), 1, tolerance = 1e-6)
  expect_true(all(out$w >= -1e-8))
  expect_true(is.numeric(out$EU))
  expect_true(is.finite(out$EU))
})

test_that("f_ptf_max_U respects w_max constraint", {
  set.seed(2)
  N  <- 3
  mu <- c(0.06, 0.09, 0.12)
  A  <- matrix(rnorm(N * N), N); Sigma <- crossprod(A) / N
  M1 <- mu
  M2 <- Sigma
  M3 <- PerformanceAnalytics::M3.MM(matrix(rnorm(200 * N), 200, N))
  M4 <- PerformanceAnalytics::M4.MM(matrix(rnorm(200 * N), 200, N))

  w_max <- 0.5
  out   <- f_ptf_max_U(gamma = 1, w_max = w_max, M1 = M1, M2 = M2, M3 = M3, M4 = M4)
  expect_true(all(out$w <= w_max + 1e-6))
})
