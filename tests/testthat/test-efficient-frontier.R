testthat::test_that("endpoints monotone and feasible", {
  set.seed(1)
  N <- 5
  mu <- runif(N, 0.05, 0.15)
  A <- matrix(rnorm(N*N), N); Sigma <- crossprod(A)/N
  ef <- f_efficient_frontier(mu, Sigma, n_ptf = 10)
  expect_equal(ef$expected_returns[1], min(ef$expected_returns))  # min-var has min return under long-only
  expect_equal(ef$expected_returns[10], max(mu))
  expect_true(all(ef$weights >= -1e-10))  # long-only (numerical tolerance)
})
