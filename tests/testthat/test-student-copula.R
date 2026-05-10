test_that("f_student_copula_pdf is finite and positive", {
  mu    <- c(0, 0)
  Sigma <- matrix(c(1, 0.5, 0.5, 1), 2, 2)
  val   <- as.numeric(f_student_copula_pdf(c(0.3, 0.7), mu, Sigma, nu = 5))
  expect_true(is.finite(val))
  expect_true(val > 0)
})

test_that("f_student_copula_pdf is symmetric in u", {
  mu    <- c(0, 0)
  Sigma <- matrix(c(1, 0.5, 0.5, 1), 2, 2)
  u     <- c(0.3, 0.7)
  expect_equal(
    as.numeric(f_student_copula_pdf(u, mu, Sigma, nu = 5)),
    as.numeric(f_student_copula_pdf(rev(u), mu, Sigma, nu = 5)),
    tolerance = 1e-10
  )
})

test_that("f_student_copula_pdf: tail density higher than Gaussian at extremes", {
  mu    <- c(0, 0)
  Sigma <- matrix(c(1, 0.5, 0.5, 1), 2, 2)
  u     <- c(0.99, 0.99)  # upper-tail point
  val_t <- as.numeric(f_student_copula_pdf(u, mu, Sigma, nu = 3))
  val_n <- as.numeric(f_normal_copula_pdf(u, mu, Sigma))
  # Student copula concentrates more mass in the tails
  expect_true(val_t > val_n)
})

test_that("input validation: nu <= 0 raises error", {
  mu <- c(0, 0); S <- diag(2)
  expect_error(f_student_copula_pdf(c(0.5, 0.5), mu, S, nu = 0),  "'nu'")
  expect_error(f_student_copula_pdf(c(0.5, 0.5), mu, S, nu = -1), "'nu'")
})

test_that("input validation: u outside (0,1) raises error", {
  mu <- c(0, 0); S <- diag(2)
  expect_error(f_student_copula_pdf(c(0, 0.5), mu, S, nu = 5), "'u'")
})

test_that("f_student_copula_pdf: larger nu approaches normal copula density", {
  mu    <- c(0, 0)
  Sigma <- matrix(c(1, 0.5, 0.5, 1), 2, 2)
  u     <- c(0.5, 0.5)
  val_t <- as.numeric(f_student_copula_pdf(u, mu, Sigma, nu = 200))
  val_n <- as.numeric(f_normal_copula_pdf(u, mu, Sigma))
  expect_equal(val_t, val_n, tolerance = 0.01)
})
