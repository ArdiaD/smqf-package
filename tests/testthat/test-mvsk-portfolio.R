## Tests for f_mvsk_portfolio(), the port of mvskPortfolios::mvskPortfolio().

make_moments <- function(seed = 7, n = 300, d = 4) {
  set.seed(seed)
  X <- matrix(stats::rt(n * d, df = 8), n, d) %*%
    chol(matrix(c(1, .3, .2, .1, .3, 1, .4, .2,
                  .2, .4, 1, .3, .1, .2, .3, 1), d, d))
  list(m1 = colMeans(X), M2 = stats::cov(X),
       M3 = PerformanceAnalytics::M3.MM(X),
       M4 = PerformanceAnalytics::M4.MM(X))
}

test_that("tilting returns the documented structure and respects the budget", {
  skip_if_not_installed("PerformanceAnalytics")
  m <- make_moments()
  kap <- c(0, 0.005, 0.01)
  res <- f_mvsk_portfolio(M2 = m$M2, M3 = m$M3, M4 = m$M4,
                          w0 = "DR", g = "vsk", href = "DR", kappa = kap)
  expect_named(res, c("weights", "delta", "moms", "constr", "status"),
               ignore.order = TRUE)
  expect_equal(dim(res$weights), c(length(kap), 4L))
  expect_length(res$delta, length(kap))
  expect_true(all(abs(rowSums(res$weights) - 1) < 1e-6))
  expect_true(all(res$weights >= -1e-8))
  expect_true(all(res$status > 0 & !res$status %in% c(5L, 6L)))
})

test_that("delta is non-decreasing in kappa and near zero at kappa = 0", {
  skip_if_not_installed("PerformanceAnalytics")
  m <- make_moments()
  res <- f_mvsk_portfolio(M2 = m$M2, M3 = m$M3, M4 = m$M4, w0 = "DR",
                          g = "vsk", href = "DR",
                          kappa = c(0, 0.001, 0.0025, 0.005, 0.01))
  # A wider margin never shrinks the feasible set, so delta cannot decrease.
  # It need not increase strictly, which is why this is not expect_true(diff > 0).
  expect_false(is.unsorted(res$delta))
  expect_lt(abs(res$delta[1]), 1e-4)   # zero up to solver tolerance
})

test_that("a numeric reference portfolio is accepted and column names survive", {
  skip_if_not_installed("PerformanceAnalytics")
  m <- make_moments()
  colnames(m$M2) <- rownames(m$M2) <- paste0("A", 1:4)
  w0 <- rep(0.25, 4)
  res <- f_mvsk_portfolio(M2 = m$M2, M3 = m$M3, M4 = m$M4, w0 = w0,
                          g = "vsk", href = "DR", kappa = c(0, 0.01))
  expect_equal(colnames(res$weights), paste0("A", 1:4))
  expect_true(all(abs(rowSums(res$weights) - 1) < 1e-6))
})

test_that("f_mvsk_portfolio validates its inputs", {
  skip_if_not_installed("PerformanceAnalytics")
  m <- make_moments()
  expect_error(f_mvsk_portfolio(M2 = NULL), "square numeric covariance")
  expect_error(f_mvsk_portfolio(M2 = diag(4)[, 1:3]), "square")
  bad <- m$M2; bad[1, 2] <- bad[1, 2] + 1
  expect_error(f_mvsk_portfolio(M2 = bad, M3 = m$M3, M4 = m$M4), "symmetric")
  nafied <- m$M2; nafied[1, 1] <- NA
  expect_error(f_mvsk_portfolio(M2 = nafied), "finite")
  # the compact (as.mat = FALSE) co-moment form is not accepted
  M3v <- PerformanceAnalytics::M3.MM(matrix(stats::rnorm(400), 100, 4),
                                     as.mat = FALSE)
  expect_error(f_mvsk_portfolio(M2 = m$M2, M3 = M3v), "as.mat = TRUE")
  # upper bounds that cannot fund a full investment
  expect_error(f_mvsk_portfolio(M2 = m$M2, M3 = m$M3, M4 = m$M4,
                                ub = rep(0.2, 4)), "infeasible")
})

test_that("an unknown reference criterion is rejected by name", {
  skip_if_not_installed("PerformanceAnalytics")
  m <- make_moments()
  expect_error(f_mvsk_portfolio(M2 = m$M2, M3 = m$M3, M4 = m$M4, w0 = "NOPE"),
               "not a valid reference function")
})
