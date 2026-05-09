test_that("f_normal_copula_pdf returns 1 at independence (Sigma = I)", {
  mu    <- c(0, 0)
  Sigma <- diag(2)
  # Independence copula: density = 1 everywhere in the interior
  expect_equal(as.numeric(f_normal_copula_pdf(c(0.5, 0.5), mu, Sigma)), 1, tolerance = 1e-10)
  expect_equal(as.numeric(f_normal_copula_pdf(c(0.3, 0.7), mu, Sigma)), 1, tolerance = 1e-10)
})

test_that("f_normal_copula_pdf is symmetric in u", {
  mu    <- c(0, 0)
  Sigma <- matrix(c(1, 0.6, 0.6, 1), 2, 2)
  u <- c(0.3, 0.7)
  expect_equal(as.numeric(f_normal_copula_pdf(u, mu, Sigma)),
               as.numeric(f_normal_copula_pdf(rev(u), mu, Sigma)),
               tolerance = 1e-10)
})

test_that("f_normal_copula_pdf is finite and positive", {
  mu    <- c(0, 0)
  Sigma <- matrix(c(1, 0.5, 0.5, 1), 2, 2)
  val   <- as.numeric(f_normal_copula_pdf(c(0.2, 0.8), mu, Sigma))
  expect_true(is.finite(val))
  expect_true(val > 0)
})

test_that("f_normal_copula_pdf: positive correlation raises density at concordant points", {
  mu     <- c(0, 0)
  S_pos  <- matrix(c(1, 0.8, 0.8, 1), 2, 2)
  S_indep <- diag(2)
  # At (0.8, 0.8) concordant with positive correlation, density > 1
  val_pos <- as.numeric(f_normal_copula_pdf(c(0.8, 0.8), mu, S_pos))
  val_ind <- as.numeric(f_normal_copula_pdf(c(0.8, 0.8), mu, S_indep))
  expect_true(val_pos > val_ind)
})
