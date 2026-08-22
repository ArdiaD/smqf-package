## Tests for f_portfolio_moments() and the internal .portm* / .derportm*
## helpers.
##
## These helpers carry more weight than their size suggests: they compute the
## objective and the analytic gradients of f_ptf_max_U() and of
## f_mvsk_portfolio(), and f_ptf_max_U() passes them to nloptr with
## check_derivatives = FALSE. Nothing else would notice a wrong constant.

make_data <- function(seed = 42, n = 400, d = 4) {
  set.seed(seed)
  L <- matrix(c(1, .3, .2, .1,
                .3, 1, .4, .2,
                .2, .4, 1, .3,
                .1, .2, .3, 1), d, d)
  matrix(stats::rt(n * d, df = 6), n, d) %*% chol(L)
}

test_that("the portfolio moments equal the sample moments of the portfolio", {
  skip_if_not_installed("PerformanceAnalytics")
  X <- make_data()
  w <- c(.4, .3, .2, .1)
  # Use the n-denominator second moment so all three are on the same footing:
  # M3.MM() and M4.MM() divide by n, whereas stats::cov() divides by n - 1.
  n  <- nrow(X)
  M2 <- stats::cov(X) * (n - 1) / n
  M3 <- PerformanceAnalytics::M3.MM(X)
  M4 <- PerformanceAnalytics::M4.MM(X)

  pm <- f_portfolio_moments(w, M2, M3, M4)
  rp <- as.numeric(X %*% w)
  c_rp <- rp - mean(rp)

  expect_equal(pm$m2, mean(c_rp^2), tolerance = 1e-12)
  expect_equal(pm$m3, mean(c_rp^3), tolerance = 1e-12)
  expect_equal(pm$m4, mean(c_rp^4), tolerance = 1e-12)
})

test_that("f_portfolio_moments returns only what it was asked for", {
  skip_if_not_installed("PerformanceAnalytics")
  X <- make_data(); w <- rep(0.25, 4)
  M2 <- stats::cov(X)
  M3 <- PerformanceAnalytics::M3.MM(X)

  out <- f_portfolio_moments(w, M2 = M2)
  expect_named(out, c("m2", "m3", "m4"))
  expect_true(is.numeric(out$m2))
  expect_null(out$m3)
  expect_null(out$m4)

  out <- f_portfolio_moments(w, M3 = M3)
  expect_null(out$m2)
  expect_true(is.numeric(out$m3))
})

test_that("f_portfolio_moments validates its inputs", {
  X <- make_data(); M2 <- stats::cov(X); w <- rep(0.25, 4)
  expect_error(f_portfolio_moments("a", M2), "numeric")
  expect_error(f_portfolio_moments(c(1, NA, 1, 1), M2), "finite")
  expect_error(f_portfolio_moments(w, M2 = diag(3)), "4 x 4")
  expect_error(f_portfolio_moments(w, M3 = diag(4)), "co-moment")
  expect_error(f_portfolio_moments(w, M4 = diag(4)), "co-moment")
})

test_that("the second moment is a quadratic form and scales accordingly", {
  X <- make_data(); M2 <- stats::cov(X)
  w <- c(.4, .3, .2, .1)
  expect_equal(f_portfolio_moments(w, M2)$m2,
               drop(crossprod(w, M2 %*% w)), tolerance = 1e-12)
  # homogeneous of degree 2, 3 and 4 respectively
  skip_if_not_installed("PerformanceAnalytics")
  M3 <- PerformanceAnalytics::M3.MM(X); M4 <- PerformanceAnalytics::M4.MM(X)
  a <- 2.5
  p1 <- f_portfolio_moments(w, M2, M3, M4)
  p2 <- f_portfolio_moments(a * w, M2, M3, M4)
  expect_equal(p2$m2, a^2 * p1$m2, tolerance = 1e-10)
  expect_equal(p2$m3, a^3 * p1$m3, tolerance = 1e-10)
  expect_equal(p2$m4, a^4 * p1$m4, tolerance = 1e-10)
})

test_that("the analytic gradients of the MVSK objective are correct", {
  skip_if_not_installed("PerformanceAnalytics")
  X <- make_data()
  M1 <- colMeans(X); M2 <- stats::cov(X)
  M3 <- PerformanceAnalytics::M3.MM(X); M4 <- PerformanceAnalytics::M4.MM(X)
  w  <- c(.4, .3, .2, .1)
  d  <- length(w)

  # f_ptf_max_U() hands these gradients to nloptr with check_derivatives =
  # FALSE, so a sign slip would never surface as an error -- only as a wrong
  # portfolio.
  for (gamma in c(1, 5, 10)) {
    f_val <- function(w) {
      p <- f_portfolio_moments(w, M2, M3, M4)
      -sum(w * M1) + gamma * p$m2 / 2 - gamma * (gamma + 1) * p$m3 / 6 +
        gamma * (gamma + 1) * (gamma + 2) * p$m4 / 24
    }
    g_ana <- -M1 +
      gamma * (2 * M2 %*% w) / 2 -
      gamma * (gamma + 1) * (3 * M3 %*% kronecker(w, w)) / 6 +
      gamma * (gamma + 1) * (gamma + 2) *
        (4 * M4 %*% kronecker(kronecker(w, w), w)) / 24

    h <- 1e-6
    g_num <- vapply(seq_len(d), function(i) {
      wp <- w; wm <- w; wp[i] <- wp[i] + h; wm[i] <- wm[i] - h
      (f_val(wp) - f_val(wm)) / (2 * h)
    }, numeric(1))

    expect_equal(as.numeric(g_ana), g_num, tolerance = 1e-5,
                 info = paste("gamma =", gamma))
  }
})

test_that("f_ptf_max_U rejects infeasible bounds and invalid moments", {
  skip_if_not_installed("PerformanceAnalytics")
  X <- make_data()
  M1 <- colMeans(X); M2 <- stats::cov(X)
  M3 <- PerformanceAnalytics::M3.MM(X); M4 <- PerformanceAnalytics::M4.MM(X)

  # d * w_max < 1: the budget cannot be met. Before, this reached nloptr and
  # failed there with "at least one element in x0 > ub".
  expect_error(f_ptf_max_U(1, 0.2, M1, M2, M3, M4), "infeasible")
  expect_error(f_ptf_max_U(1, 0.2, M1, M2, M3, M4), "w_max >=")
  # exactly feasible
  expect_silent(r <- f_ptf_max_U(1, 0.25, M1, M2, M3, M4))
  expect_equal(sum(r$w), 1, tolerance = 1e-6)

  M1_na <- M1; M1_na[1] <- NA
  expect_error(f_ptf_max_U(1, 0.5, M1_na, M2, M3, M4), "finite")
  M2_asym <- M2; M2_asym[1, 2] <- M2_asym[1, 2] + 1
  expect_error(f_ptf_max_U(1, 0.5, M1, M2_asym, M3, M4), "symmetric")
  M2_bad <- M2; M2_bad[1, 1] <- -1
  expect_error(f_ptf_max_U(1, 0.5, M1, M2_bad, M3, M4), "positive semidefinite")
})

test_that("f_ptf_max_U respects its constraints and reports its status", {
  skip_if_not_installed("PerformanceAnalytics")
  X <- make_data()
  M1 <- colMeans(X); M2 <- stats::cov(X)
  M3 <- PerformanceAnalytics::M3.MM(X); M4 <- PerformanceAnalytics::M4.MM(X)
  for (gamma in c(0, 1, 5, 10)) {
    r <- f_ptf_max_U(gamma, 0.5, M1, M2, M3, M4)
    expect_equal(sum(r$w), 1, tolerance = 1e-6)
    expect_true(all(r$w >= -1e-8))
    expect_true(all(r$w <= 0.5 + 1e-8))
    expect_true(r$status > 0 && !r$status %in% c(5L, 6L))
  }
})
