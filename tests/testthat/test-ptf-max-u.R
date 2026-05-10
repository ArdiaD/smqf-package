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

test_that("input validation: wrong M3 shape raises error", {
  N  <- 3
  M1 <- c(0.05, 0.08, 0.10)
  M2 <- diag(N)
  M3_bad <- array(0, dim = c(N, N, N))   # 3D array, not d x d^2 matrix
  M4_ok  <- matrix(0, N, N^3)
  expect_error(f_ptf_max_U(gamma = 1, w_max = 1, M1, M2, M3_bad, M4_ok), "'M3'")
})

test_that("input validation: wrong M4 shape raises error", {
  N  <- 3
  M1 <- c(0.05, 0.08, 0.10)
  M2 <- diag(N)
  M3_ok  <- matrix(0, N, N^2)
  M4_bad <- array(0, dim = c(N, N, N, N))  # 4D array, not d x d^3 matrix
  expect_error(f_ptf_max_U(gamma = 1, w_max = 1, M1, M2, M3_ok, M4_bad), "'M4'")
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
