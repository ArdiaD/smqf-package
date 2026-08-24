## Tests for f_efficient_frontier -------------------------------------------
##
## The book (Chapter 1) builds the same frontier by hand with
## quadprog::solve.QP and asserts that the two agree. These tests pin that
## agreement, plus the invariants a frontier must satisfy: budget, long-only,
## target attainment, monotonicity and non-domination.

psd_cov <- function(N, seed) {
  set.seed(seed)
  A <- matrix(stats::rnorm(N * N), N)
  crossprod(A) / N
}

# ---- structure -------------------------------------------------------------

test_that("return list contains all six components", {
  set.seed(101)
  ef <- f_efficient_frontier(runif(3, .04, .12), psd_cov(3, 2), n_ptf = 5)
  expect_named(ef,
               c("weights", "volatility", "expected_returns",
                 "frontier", "targets", "status"),
               ignore.order = TRUE)
  expect_s3_class(ef$frontier, "data.frame")
  expect_named(ef$frontier,
               c("point", "expected_return", "volatility", "target", "status"))
})

test_that("outputs are consistently named", {
  mu <- c(A = 0.05, B = 0.08, C = 0.11)
  ef <- f_efficient_frontier(mu, diag(3) * 0.02, n_ptf = 4)
  expect_equal(rownames(ef$weights), c("A", "B", "C"))
  expect_equal(colnames(ef$weights), paste0("ptf", 1:4))
  expect_equal(names(ef$volatility), paste0("ptf", 1:4))
  expect_equal(names(ef$expected_returns), paste0("ptf", 1:4))
})

test_that("n_ptf = 2 edge case returns exactly two portfolios", {
  ef <- f_efficient_frontier(c(0.06, 0.09, 0.12), diag(c(.04, .09, .16)), n_ptf = 2)
  expect_equal(ncol(ef$weights), 2L)
  expect_length(ef$volatility, 2L)
  expect_true(all(ef$status == "ok"))
})

# ---- frontier invariants ---------------------------------------------------

test_that("every portfolio is fully invested and long-only", {
  set.seed(102)
  ef <- f_efficient_frontier(runif(4, .05, .15), psd_cov(4, 3), n_ptf = 8)
  expect_true(all(abs(colSums(ef$weights) - 1) < 1e-6))
  expect_true(all(ef$weights >= -1e-10))
})

test_that("interior portfolios attain their target return", {
  set.seed(103)
  mu <- runif(5, .05, .15)
  ef <- f_efficient_frontier(mu, psd_cov(5, 11), n_ptf = 12)
  ok <- ef$status == "ok"
  expect_true(all(ok))
  # expected_returns must reproduce the target grid, not merely be monotone
  expect_equal(unname(ef$expected_returns[ok]), ef$targets[ok], tolerance = 1e-8)
  # and must be recomputable from the weights themselves
  expect_equal(unname(ef$expected_returns),
               as.numeric(crossprod(ef$weights, mu)), tolerance = 1e-10)
})

test_that("volatility is consistent with the weights and Sigma", {
  set.seed(104)
  mu <- runif(4, .05, .15); Sigma <- psd_cov(4, 7)
  ef <- f_efficient_frontier(mu, Sigma, n_ptf = 9)
  manual <- apply(ef$weights, 2, function(w) sqrt(drop(crossprod(w, Sigma %*% w))))
  expect_equal(unname(ef$volatility), unname(manual), tolerance = 1e-10)
  expect_true(all(ef$volatility >= 0))
})

test_that("expected returns and volatility increase along the frontier", {
  set.seed(105)
  ef <- f_efficient_frontier(runif(5, .05, .15), psd_cov(5, 13), n_ptf = 15)
  expect_false(is.unsorted(ef$expected_returns))
  expect_false(is.unsorted(ef$volatility))   # upper branch only: no dominated point
})

test_that("the minimum-variance portfolio really is minimum variance", {
  # Seeded before the draw, not after: the set.seed(99) below covers the
  # comparison portfolios but not `mu`, which would otherwise inherit whatever
  # stream the previous test left behind.
  set.seed(106)
  mu <- runif(4, .05, .15); Sigma <- psd_cov(4, 17)
  ef <- f_efficient_frontier(mu, Sigma, n_ptf = 10)
  v1 <- ef$volatility[[1]]
  # random feasible long-only portfolios cannot beat it
  set.seed(99)
  for (i in 1:200) {
    w <- stats::runif(4); w <- w / sum(w)
    expect_gte(sqrt(drop(crossprod(w, Sigma %*% w))), v1 - 1e-8)
  }
})

# ---- agreement with an independent QP solver (the book's construction) ------

test_that("matches quadprog::solve.QP, the construction used in the book", {
  skip_if_not_installed("quadprog")
  # The seed is not decoration. Without it `mu` came from whatever RNG state
  # the preceding test happened to leave -- psd_cov() sets the seed *inside*
  # itself, so it does not cover the runif() on this line. Roughly half of all
  # seeds produce a `mu` for which the last target below is unsolvable here.
  #
  # That is not, however, what broke on CRAN. r-release-macos-arm64 reported
  #
  #   Error in quadprog::solve.QP(...): constraints are inconsistent,
  #   no solution!
  #
  # on the *same* `mu` this machine solves without complaint: its 1221 passes
  # plus the four assertions the aborted test never reached equal the 1225 seen
  # locally, so the stream was identical. solve.QP succeeds on
  # aarch64-apple-darwin20 / R 4.5.2 and fails on aarch64-apple-darwin23 /
  # R 4.6.1 for that input. The degenerate vertex handled below is the real
  # cause; the seed closes an independent hole.
  set.seed(2026)
  mu <- runif(5, .002, .006); Sigma <- psd_cov(5, 23) / 1000
  n <- 20
  ef <- f_efficient_frontier(mu, Sigma, n_ptf = n)

  N <- 5
  w_mv <- quadprog::solve.QP(Sigma, rep(0, N),
                             cbind(rep(1, N), diag(N)),
                             c(1, rep(0, N)), meq = 1)$solution
  tg <- seq(sum(mu * w_mv), max(mu), length.out = n)
  W <- matrix(NA_real_, N, n)
  W[, 1] <- w_mv

  # The last target, tg[n], is exactly max(mu). The only long-only portfolio
  # attaining it is the vertex e_argmax -- a degenerate corner of the feasible
  # set, and the point where solve.QP refuses on every input that fails here.
  # It is asserted against its analytic value instead, which is a stronger
  # claim than the one solve.QP was being asked to satisfy, and one the package
  # meets exactly through pracma::quadprog with an explicit feasibility check.
  W[, n] <- as.numeric(seq_len(N) == which.max(mu))

  # The interior targets are the actual cross-check. They are wrapped rather
  # than called bare, and the reason is worth stating: the failure this test is
  # being fixed for could not be reproduced on the machine fixing it. Locally
  # only i == n ever fails, on about half of all seeds; on CRAN's
  # aarch64-apple-darwin23 and on the M1mac service's darwin25 it failed for an
  # input this machine solves without complaint, and neither reports which i.
  # Excluding only the vertex would therefore be a guess. Whether solve.QP can
  # solve a given point is a property of the platform's linear algebra, not of
  # the package, so a point it declines is skipped and the ones it solves must
  # still agree. `solved` records which, so a platform where the solver
  # collapsed entirely cannot masquerade as a pass.
  solved <- rep(FALSE, n)
  solved[c(1, n)] <- TRUE
  for (i in 2:(n - 1)) {
    w <- tryCatch(
      quadprog::solve.QP(
        Sigma, rep(0, N),
        cbind(rep(1, N), matrix(mu, ncol = 1), diag(N)),
        c(1, tg[i], rep(0, N)), meq = 2)$solution,
      error = function(e) NULL)
    if (!is.null(w)) { W[, i] <- w; solved[i] <- TRUE }
  }
  # the cross-check must remain a cross-check
  expect_gte(sum(solved), n - 2L)

  vol <- apply(W[, solved, drop = FALSE], 2,
               function(w) sqrt(drop(crossprod(w, Sigma %*% w))))

  expect_equal(unname(ef$weights[, solved, drop = FALSE]),
               W[, solved, drop = FALSE], tolerance = 1e-6)
  expect_equal(unname(ef$volatility[solved]), vol, tolerance = 1e-8)
  expect_equal(unname(ef$expected_returns[solved]),
               as.numeric(crossprod(W[, solved, drop = FALSE], mu)),
               tolerance = 1e-8)
  expect_equal(ef$targets, tg, tolerance = 1e-10)
  # the maximum-return end point is the vertex, not an interior mix
  expect_equal(max(ef$weights[, n]), 1, tolerance = 1e-8)
  # and the package solved every point, whatever solve.QP managed
  expect_true(all(ef$status == "ok"))
})

# ---- ties for the maximum expected return ----------------------------------

test_that("ties at max(mu) are resolved by minimizing variance, not equal weights", {
  # Assets 2 and 3 both return 0.2. Equal weighting gives variance 25.25 and
  # asset 3 alone gives 1; the variance-minimal mix is c(0, 1/101, 100/101).
  ef <- f_efficient_frontier(c(0.1, 0.2, 0.2), diag(c(1, 100, 1)), n_ptf = 5)
  w_end <- ef$weights[, 5]
  expect_equal(unname(w_end), c(0, 1 / 101, 100 / 101), tolerance = 1e-6)
  expect_equal(sum(w_end), 1, tolerance = 1e-8)
  expect_lt(ef$volatility[[5]], 1)          # beats the pure-asset-3 solution
  expect_lt(ef$volatility[[5]], sqrt(25.25))# and the equal-weight one
})

test_that("a tied end point is not dominated and does not break monotonicity", {
  ef <- f_efficient_frontier(c(0.1, 0.2, 0.2), diag(c(1, 100, 1)), n_ptf = 6)
  expect_false(is.unsorted(ef$volatility))
  expect_equal(unname(ef$expected_returns[6]), 0.2, tolerance = 1e-8)
})

test_that("a unique max(mu) still gives the pure corner portfolio", {
  ef <- f_efficient_frontier(c(0.05, 0.09, 0.20), diag(c(.04, .09, .16)), n_ptf = 6)
  expect_equal(unname(ef$weights[, 6]), c(0, 0, 1), tolerance = 1e-6)
})

# ---- input validation ------------------------------------------------------

test_that("f_efficient_frontier validates mu, Sigma and n_ptf", {
  d <- 3; mu <- rep(0.01, d)
  expect_error(f_efficient_frontier("a", diag(2), 5), "mu")
  expect_error(f_efficient_frontier(c(1, NA), diag(2), 5), "finite")
  expect_error(f_efficient_frontier(mu, diag(d), n_ptf = 1), "n_ptf")
  expect_error(f_efficient_frontier(mu, diag(d), n_ptf = 2.5), "n_ptf")
  expect_error(f_efficient_frontier(mu, diag(d) * Inf, n_ptf = 10), "finite")
  expect_error(f_efficient_frontier(mu, diag(d + 1), n_ptf = 10), "matching")
})

test_that("a non-PSD Sigma is rejected with an actionable message", {
  bad <- matrix(c(1, 2, 2, 1), 2)          # eigenvalues 3 and -1
  expect_error(f_efficient_frontier(c(.05, .09), bad, n_ptf = 4),
               "positive semidefinite")
  expect_error(f_efficient_frontier(c(.05, .09), bad, n_ptf = 4),
               "nearPD")
})

test_that("Sigma objects coercible to a matrix are accepted", {
  skip_if_not_installed("Matrix")
  S <- matrix(c(1, .99, -.99, .99, 1, .99, -.99, .99, 1), 3)
  np <- Matrix::nearPD(S)$mat               # a 'dpoMatrix', not a base matrix
  expect_false(is.matrix(np))
  expect_no_error(f_efficient_frontier(c(.05, .07, .09), np, n_ptf = 4))
  # and gives the same answer as the explicitly coerced version
  a <- f_efficient_frontier(c(.05, .07, .09), np, n_ptf = 4)
  b <- f_efficient_frontier(c(.05, .07, .09), as.matrix(np), n_ptf = 4)
  expect_equal(a$volatility, b$volatility)
})

test_that("an asymmetric Sigma warns but uses the symmetric part", {
  S <- diag(c(.04, .09)); S[1, 2] <- 0.01   # S[2,1] stays 0
  expect_warning(ef <- f_efficient_frontier(c(.05, .09), S, n_ptf = 4),
                 "not symmetric")
  expect_true(all(ef$status == "ok"))
})

test_that("status is reported for every point", {
  set.seed(107)
  ef <- f_efficient_frontier(runif(4, .05, .15), psd_cov(4, 31), n_ptf = 7)
  expect_length(ef$status, 7L)
  expect_true(all(ef$status %in% c("ok", "failed")))
  expect_equal(ef$frontier$status, ef$status)
  # failed points must be NA everywhere, never a neighbour's weights
  bad <- ef$status == "failed"
  expect_true(all(is.na(ef$volatility[bad])))
  expect_true(all(is.na(ef$weights[, bad, drop = FALSE])))
})

# ---- integration: the Chapter 5 resampled-efficiency pipeline --------------
# The function is well covered in isolation above, but a correct API can still
# be driven incorrectly. These tests pin the two properties the chapter's
# Michaud construction relies on.

test_that("an explicit target grid makes two frontiers comparable point by point", {
  set.seed(11)
  N  <- 5
  M  <- matrix(stats::rnorm(N * N), N)
  S  <- crossprod(M) / N + diag(0.05, N)
  m1 <- c(0.05, 0.07, 0.09, 0.06, 0.08)
  m2 <- m1 + c(0.004, -0.003, 0.002, 0.001, -0.002)

  grid <- seq(0.062, 0.078, length.out = 7)
  e1 <- f_efficient_frontier(m1, S, targets = grid)
  e2 <- f_efficient_frontier(m2, S, targets = grid)

  # Every solved point sits exactly on its requested target
  ok1 <- e1$status == "ok"; ok2 <- e2$status == "ok"
  expect_equal(e1$expected_returns[ok1], grid[ok1],
               tolerance = 1e-6, ignore_attr = TRUE)
  expect_equal(e2$expected_returns[ok2], grid[ok2],
               tolerance = 1e-6, ignore_attr = TRUE)
  # ... which is what the default grid does NOT give
  d1 <- f_efficient_frontier(m1, S, n_ptf = 7)
  d2 <- f_efficient_frontier(m2, S, n_ptf = 7)
  expect_false(isTRUE(all.equal(d1$targets, d2$targets)))
})

test_that("infeasible targets are reported, never silently clipped", {
  set.seed(12)
  N <- 4
  M <- matrix(stats::rnorm(N * N), N)
  S <- crossprod(M) / N + diag(0.05, N)
  m <- c(0.05, 0.06, 0.07, 0.08)
  # 0.20 is far above max(mu) = 0.08 and cannot be reached long-only
  ef <- suppressWarnings(f_efficient_frontier(m, S, targets = c(0.06, 0.07, 0.20)))
  expect_equal(ef$status, c("ok", "ok", "failed"))
  expect_true(all(is.na(ef$weights[, 3])))
  expect_true(is.na(ef$volatility[3]))
  # The reached returns are the requested ones, not a clipped maximum
  expect_equal(unname(ef$expected_returns[1:2]), c(0.06, 0.07), tolerance = 1e-6)
})

test_that("the resampled-efficiency pipeline aggregates by rank and is dominated", {
  skip_if_not_installed("mvtnorm")
  set.seed(1234)
  N     <- 4
  n_obs <- 250
  n_sim <- 30
  n_ptf <- 10
  M     <- matrix(stats::rnorm(N * N), N)
  Sigma <- crossprod(M) / N + diag(0.05, N)
  mu    <- c(0.05, 0.06, 0.07, 0.08)

  w  <- array(NA_real_, c(N, n_ptf, n_sim))
  tg <- matrix(NA_real_, n_sim, n_ptf)
  for (i in seq_len(n_sim)) {
    x  <- mvtnorm::rmvnorm(n_obs, mean = mu, sigma = Sigma)
    ef <- f_efficient_frontier(colMeans(x), stats::cov(x), n_ptf = n_ptf)
    expect_true(all(ef$status == "ok"))
    w[, , i]  <- ef$weights
    tg[i, ]   <- ef$targets
  }

  # Michaud matches by rank, and the targets behind a rank genuinely differ
  expect_gt(max(apply(tg, 2, stats::sd)), 0)

  av_w <- apply(w, c(1, 2), mean)
  expect_equal(colSums(av_w), rep(1, n_ptf), tolerance = 1e-8)
  expect_true(all(av_w >= -1e-8))   # averaging preserves the long-only budget

  # ... but not efficiency: every averaged point is dominated in sample
  av_vol <- apply(av_w, 2, function(x) sqrt(drop(crossprod(x, Sigma %*% x))))
  av_mu  <- as.numeric(crossprod(mu, av_w))
  fine   <- f_efficient_frontier(mu, Sigma, n_ptf = 200)
  ref    <- stats::approx(fine$expected_returns, fine$volatility,
                          xout = av_mu, rule = 2)$y
  expect_true(all(av_vol - ref > -1e-10))
  expect_gt(max(av_vol - ref), 0)
})
