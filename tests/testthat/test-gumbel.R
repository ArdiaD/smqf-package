test_that("independence limit: CDF is product of marginals", {
  expect_equal(f_gumbel_copula_2d_cdf(c(0.7, 0.7), 1), 0.49, tolerance = 1e-14)
})

test_that("independence limit: PDF equals 1", {
  expect_equal(f_gumbel_copula_2d_pdf(c(0.7, 0.7), 1), 1, tolerance = 1e-14)
})

test_that("CDF is symmetric in its arguments", {
  u <- c(0.3, 0.8); theta <- 2
  expect_equal(
    f_gumbel_copula_2d_cdf(u, theta),
    f_gumbel_copula_2d_cdf(rev(u), theta)
  )
})

test_that("PDF is symmetric in its arguments", {
  u <- c(0.3, 0.8); theta <- 2
  expect_equal(
    f_gumbel_copula_2d_pdf(u, theta),
    f_gumbel_copula_2d_pdf(rev(u), theta)
  )
})

test_that("CDF does not exceed smaller marginal", {
  expect_true(f_gumbel_copula_2d_cdf(c(0.99, 0.99), 3) <= 0.99)
})

test_that("PDF is finite at extreme grid point", {
  expect_true(is.finite(f_gumbel_copula_2d_pdf(c(1e-8, 0.5), 5)))
})

test_that("input validation: u outside (0,1] raises error", {
  expect_error(f_gumbel_copula_2d_cdf(c(0, 0.5), 2), "'u'")
  expect_error(f_gumbel_copula_2d_cdf(c(1.1, 0.5), 2), "'u'")
  expect_error(f_gumbel_copula_2d_pdf(c(-0.1, 0.5), 2), "'u'")
})

test_that("input validation: theta < 1 raises error", {
  expect_error(f_gumbel_copula_2d_cdf(c(0.5, 0.5), 0.5), "'theta'")
  expect_error(f_gumbel_copula_2d_pdf(c(0.5, 0.5), 0), "'theta'")
})
