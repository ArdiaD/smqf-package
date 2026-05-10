test_that("endpoints monotone and feasible", {
  set.seed(1)
  N <- 5
  mu <- runif(N, 0.05, 0.15)
  A <- matrix(rnorm(N*N), N); Sigma <- crossprod(A)/N
  ef <- f_efficient_frontier(mu, Sigma, n_ptf = 10)
  expect_equal(ef$expected_returns[1], min(ef$expected_returns))  # min-var has min return under long-only
  expect_equal(ef$expected_returns[10], max(mu))
  expect_true(all(ef$weights >= -1e-10))  # long-only (numerical tolerance)
})

test_that("return list contains all five components", {
  set.seed(2)
  N <- 3
  mu <- runif(N, 0.04, 0.12)
  A <- matrix(rnorm(N*N), N); Sigma <- crossprod(A)/N
  ef <- f_efficient_frontier(mu, Sigma, n_ptf = 5)
  expect_named(ef, c("weights", "volatility", "expected_returns", "frontier", "targets"),
               ignore.order = TRUE)
})

test_that("weights sum to 1 for every portfolio", {
  set.seed(3)
  N <- 4
  mu <- runif(N, 0.05, 0.15)
  A <- matrix(rnorm(N*N), N); Sigma <- crossprod(A)/N
  ef <- f_efficient_frontier(mu, Sigma, n_ptf = 8)
  # weights is N x n_ptf; column sums must equal 1
  col_sums <- colSums(ef$weights)
  expect_true(all(abs(col_sums - 1) < 1e-6))
})

test_that("n_ptf = 2 edge case returns correct number of portfolios", {
  N <- 3
  mu <- c(0.06, 0.09, 0.12)
  Sigma <- diag(c(0.04, 0.09, 0.16))
  ef <- f_efficient_frontier(mu, Sigma, n_ptf = 2)
  # weights is N x n_ptf; ncol should be 2
  expect_equal(ncol(ef$weights), 2)
})

test_that("error on non-numeric mu", {
  expect_error(f_efficient_frontier(mu = "a", Sigma = diag(2), n_ptf = 5))
})

test_that("volatility is non-negative", {
  set.seed(5)
  N <- 4
  mu <- runif(N, 0.05, 0.15)
  A <- matrix(rnorm(N*N), N); Sigma <- crossprod(A)/N
  ef <- f_efficient_frontier(mu, Sigma, n_ptf = 6)
  expect_true(all(ef$volatility >= 0))
})

test_that("f_efficient_frontier validates inputs", {
  d <- 3
  mu <- rep(0.01, d)
  Sigma <- diag(d)
  expect_error(f_efficient_frontier(mu, Sigma, n_ptf = 1), "n_ptf")
  expect_error(f_efficient_frontier(mu, diag(d) * Inf, n_ptf = 10), "finite")
})
