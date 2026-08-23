## Cross-checks of the copula densities against an independent implementation
## and against their own normalization.
##
## The four densities in this package are hand-derived. Nothing else in the
## suite would notice a wrong constant, a transposed parameter or a sign slip,
## because every other test only checks shape and monotonicity. These tests
## pin the numbers themselves.

skip_if_no_copula <- function() skip_if_not_installed("copula")

# ---- agreement with the copula package ------------------------------------

test_that("the Gaussian copula density matches copula::dCopula", {
  skip_if_no_copula()
  pts <- list(c(.1, .1), c(.5, .5), c(.9, .2), c(.05, .95), c(.99, .99))
  for (rho in c(-0.9, -0.5, -0.1, 0, 0.3, 0.7, 0.95)) {
    S  <- matrix(c(1, rho, rho, 1), 2)
    cc <- copula::normalCopula(rho, dim = 2)
    for (u in pts) {
      expect_equal(f_normal_copula_pdf(u, c(0, 0), S),
                   copula::dCopula(u, cc), tolerance = 1e-8,
                   info = paste("rho =", rho, "u =", toString(u)))
    }
  }
})

test_that("the Student-t copula density matches copula::dCopula", {
  skip_if_no_copula()
  pts <- list(c(.1, .1), c(.5, .5), c(.9, .2), c(.02, .98))
  for (rho in c(-0.5, 0, 0.5, 0.9)) {
    for (nu in c(3, 5, 10, 30)) {
      S  <- matrix(c(1, rho, rho, 1), 2)
      tc <- copula::tCopula(rho, dim = 2, df = nu)
      for (u in pts) {
        expect_equal(f_student_copula_pdf(u, c(0, 0), S, nu),
                     copula::dCopula(u, tc), tolerance = 1e-7,
                     info = paste("rho =", rho, "nu =", nu, "u =", toString(u)))
      }
    }
  }
})

test_that("the Clayton density matches copula::dCopula, on both scales", {
  skip_if_no_copula()
  pts <- list(c(.1, .1), c(.5, .5), c(.9, .2), c(.01, .99), c(.99, .99))
  for (th in c(0.1, 0.5, 1, 2, 5, 10)) {
    cc <- copula::claytonCopula(th, dim = 2)
    for (u in pts) {
      expect_equal(f_clayton_copula_2d_pdf(u, th),
                   copula::dCopula(u, cc), tolerance = 1e-7)
      expect_equal(f_clayton_copula_2d_pdf(u, th, log = TRUE),
                   copula::dCopula(u, cc, log = TRUE), tolerance = 1e-7)
    }
  }
})

test_that("the Gumbel density and cdf match copula::dCopula and pCopula", {
  skip_if_no_copula()
  pts <- list(c(.1, .1), c(.5, .5), c(.9, .2), c(.01, .99), c(.99, .99))
  for (th in c(1.01, 1.5, 2, 3, 8)) {
    gc <- copula::gumbelCopula(th, dim = 2)
    for (u in pts) {
      expect_equal(f_gumbel_copula_2d_pdf(u, th),
                   copula::dCopula(u, gc), tolerance = 1e-7)
      expect_equal(f_gumbel_copula_2d_cdf(u, th),
                   copula::pCopula(u, gc), tolerance = 1e-9)
    }
  }
})

# ---- normalization ---------------------------------------------------------
# A copula density integrates to one over the unit square. A wrong
# multiplicative constant would pass every shape test but fail this.

integrate_copula <- function(f, n = 70) {
  # Midpoint rule on the open square. The Archimedean densities diverge at the
  # corners, which is what sets the achievable accuracy.
  #
  # On the grid size: this helper dominated the whole test suite. It is called
  # twelve times, and at the former n = 220 that is 12 * 220^2 = 580,800 scalar
  # density evaluations, each one re-running the input validation (including an
  # eigen() on a 2x2 matrix). It accounted for 85% of the suite's runtime, and
  # for roughly four of the 4.6 minutes the tests took on win-builder.
  #
  # The midpoint rule converges as O(1/n^2), so dropping to n = 70 costs a
  # factor of ten in work and about a factor of ten in accuracy -- from a worst
  # case of 0.0021 to 0.0069, against tolerances that used to sit at 0.05. The
  # tolerances below are therefore *tightened* at the same time, to four times
  # the worst error actually observed across every parameter value used here.
  # The test is now both faster and stricter than before: at the old tolerance
  # of 0.05 a 3% error in a normalizing constant would have passed unnoticed.
  h <- 1 / n
  g <- seq(h / 2, 1 - h / 2, by = h)
  s <- 0
  for (u1 in g) for (u2 in g) s <- s + f(c(u1, u2))
  s * h^2
}

test_that("the elliptical copula densities integrate to one", {
  for (rho in c(-0.4, 0, 0.6)) {
    S <- matrix(c(1, rho, rho, 1), 2)
    expect_equal(integrate_copula(function(u) f_normal_copula_pdf(u, c(0, 0), S)),
                 1, tolerance = 0.002, info = paste("normal, rho =", rho))
    expect_equal(integrate_copula(function(u) f_student_copula_pdf(u, c(0, 0), S, 8)),
                 1, tolerance = 0.004, info = paste("student, rho =", rho))
  }
})

test_that("the Archimedean copula densities integrate to one", {
  # Looser than the elliptical cases because both densities diverge at a
  # corner, which the midpoint rule resolves poorly however fine the grid.
  for (th in c(0.5, 1, 2)) {
    expect_equal(integrate_copula(function(u) f_clayton_copula_2d_pdf(u, th)),
                 1, tolerance = 0.02, info = paste("clayton, theta =", th))
  }
  for (th in c(1.2, 2, 3)) {
    expect_equal(integrate_copula(function(u) f_gumbel_copula_2d_pdf(u, th)),
                 1, tolerance = 0.03, info = paste("gumbel, theta =", th))
  }
})

test_that("the independence cases reduce to a flat density", {
  expect_equal(f_normal_copula_pdf(c(.3, .7), c(0, 0), diag(2)), 1, tolerance = 1e-12)
  expect_equal(f_clayton_copula_2d_pdf(c(.3, .7), 0), 1)
  expect_equal(f_gumbel_copula_2d_pdf(c(.3, .7), 1), 1, tolerance = 1e-12)
  expect_equal(f_gumbel_copula_2d_cdf(c(.3, .7), 1), 0.21, tolerance = 1e-12)
})

# ---- invalid covariance matrices -------------------------------------------

test_that("the elliptical densities reject invalid covariance matrices", {
  u <- c(.3, .7); mu <- c(0, 0)
  asym  <- matrix(c(1, 0.8, 0.2, 1), 2)      # silently accepted before
  sing  <- matrix(c(1, 1, 1, 1), 2)          # returned Inf before
  indef <- matrix(c(1, 1.5, 1.5, 1), 2)      # returned NaN before
  negd  <- matrix(c(-1, 0, 0, 1), 2)

  for (f in list(function(S) f_normal_copula_pdf(u, mu, S),
                 function(S) f_student_copula_pdf(u, mu, S, 5))) {
    expect_error(f(asym),  "symmetric")
    expect_error(f(sing),  "positive definite")
    expect_error(f(indef), "positive definite")
    expect_error(f(negd),  "positive|symmetric")
    # the error must point the user somewhere useful
    expect_error(f(indef), "nearPD")
  }
})

test_that("a valid correlation matrix still works after the new guards", {
  S <- matrix(c(1, 0.5, 0.5, 1), 2)
  expect_silent(v <- f_normal_copula_pdf(c(.3, .7), c(0, 0), S))
  expect_true(is.finite(v) && v > 0)
  expect_silent(v <- f_student_copula_pdf(c(.3, .7), c(0, 0), S, 5))
  expect_true(is.finite(v) && v > 0)
})

# ---- f_display_copula grid contract ----------------------------------------

test_that("f_display_copula rejects grids touching the boundary", {
  f <- function(u) f_clayton_copula_2d_pdf(u, 2)
  expect_error(f_display_copula(f, seq(0, 1, length.out = 5),
                                seq(0.1, 0.9, length.out = 5), plot = FALSE),
               "strictly inside")
  expect_error(f_display_copula(f, seq(0.1, 0.9, length.out = 5),
                                seq(0, 1, length.out = 5), plot = FALSE),
               "strictly inside")
  z <- f_display_copula(f, seq(0.1, 0.9, length.out = 5),
                        seq(0.1, 0.9, length.out = 5), plot = FALSE)
  expect_equal(dim(z), c(5L, 5L))
  expect_true(all(is.finite(z)))
})
