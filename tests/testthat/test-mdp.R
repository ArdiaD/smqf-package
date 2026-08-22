## Tests for f_mdp().
##
## The most diversified portfolio has a closed form, w proportional to
## Sigma^{-1} sigma, which is only defined when Sigma is invertible. The
## interesting cases are therefore the rejections: Exercise 4.2 of the book
## hands this function a singular sample covariance on purpose.

make_sigma <- function(d = 5, seed = 42) {
  set.seed(seed)
  A <- matrix(stats::rnorm(d * d), d, d)
  S <- crossprod(A) / d + diag(0.1, d)
  dimnames(S) <- list(paste0("a", seq_len(d)), paste0("a", seq_len(d)))
  S
}

f_dr <- function(w, Sigma) {
  sum(w * sqrt(diag(Sigma))) / sqrt(drop(crossprod(w, Sigma %*% w)))
}

test_that("f_mdp returns budget-satisfying named weights", {
  S <- make_sigma()
  w <- f_mdp(S)
  expect_type(w, "double")
  expect_length(w, ncol(S))
  expect_named(w, colnames(S))
  expect_equal(sum(w), 1, tolerance = 1e-12)
  expect_true(all(is.finite(w)))
})

test_that("f_mdp maximizes the diversification ratio", {
  # The defining property. Perturbing the solution in any direction that keeps
  # the budget must not increase the diversification ratio.
  S <- make_sigma(d = 6, seed = 7)
  w <- f_mdp(S)
  dr_star <- f_dr(w, S)

  set.seed(11)
  for (i in 1:200) {
    d  <- stats::rnorm(length(w))
    d  <- d - mean(d)                      # keep sum(w) == 1
    wp <- w + 0.05 * d / sqrt(sum(d^2))
    expect_lte(f_dr(wp, S), dr_star + 1e-10)
  }
  # and it beats the equally weighted portfolio
  expect_gt(dr_star, f_dr(rep(1 / ncol(S), ncol(S)), S))
})

test_that("f_mdp matches the closed form and is scale invariant", {
  S <- make_sigma()
  w <- f_mdp(S)
  raw <- solve(S, sqrt(diag(S)))
  expect_equal(as.numeric(w), as.numeric(raw / sum(raw)), tolerance = 1e-12)
  # Scaling the covariance scales sigma and Sigma^{-1} inversely: same weights
  expect_equal(as.numeric(f_mdp(4 * S)), as.numeric(w), tolerance = 1e-10)
})

test_that("f_mdp is diagonal-consistent", {
  # With uncorrelated assets the closed form reduces to w_i proportional to
  # 1 / sigma_i: inverse-volatility weighting.
  s <- c(0.1, 0.2, 0.4, 0.05)
  S <- diag(s^2)
  w <- f_mdp(S)
  expect_equal(as.numeric(w), as.numeric((1 / s) / sum(1 / s)),
               tolerance = 1e-12)
})

test_that("f_mdp rejects a singular covariance rather than solving it", {
  # Exercise 4.2: 156 weekly observations for 487 constituents. The point of
  # the exercise is that the closed form does not exist here.
  set.seed(3)
  X <- matrix(stats::rnorm(20 * 30), 20, 30)   # n = 20 < p = 30
  S <- stats::cov(X)
  expect_error(f_mdp(S), "positive definite")
  expect_error(f_mdp(S), "singular")

  # An exactly collinear pair is caught too
  Y <- cbind(X[, 1:5], X[, 1])
  expect_error(f_mdp(stats::cov(Y)), "positive definite")
})

test_that("f_mdp validates its input", {
  expect_error(f_mdp("a"), "matrix|numeric")
  expect_error(f_mdp(matrix(1:6, 2, 3)), "square")
  S <- make_sigma()
  S_na <- S; S_na[1, 1] <- NA
  expect_error(f_mdp(S_na), "finite")
  S_asym <- S; S_asym[1, 2] <- S_asym[1, 2] + 1
  expect_error(f_mdp(S_asym), "symmetric")
})

test_that("f_mdp accepts an unnamed matrix and a data frame", {
  S <- make_sigma()
  dimnames(S) <- NULL
  w <- f_mdp(S)
  expect_null(names(w))
  expect_equal(sum(w), 1, tolerance = 1e-12)

  S2 <- make_sigma()
  w2 <- f_mdp(as.data.frame(S2))
  expect_equal(as.numeric(w2), as.numeric(f_mdp(S2)), tolerance = 1e-12)
})

test_that("f_mdp weights are unconstrained in sign", {
  # Documented behaviour, and the reason the book warns about gross exposure:
  # the closed form has no non-negativity constraint, so a strongly negative
  # correlation is enough to produce a short leg.
  S <- matrix(c( 1.0, -0.8, 0.6,
                -0.8,  1.0, 0.2,
                 0.6,  0.2, 2.0), 3, 3)
  w <- f_mdp(S)
  expect_equal(sum(w), 1, tolerance = 1e-12)
  expect_true(any(w < 0))
  expect_gt(sum(abs(w)), 1)   # gross exposure exceeds the budget
})
