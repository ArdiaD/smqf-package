test_that("f_clayton_copula_2d_pdf validates inputs", {
  expect_error(f_clayton_copula_2d_pdf(c(0.3, 0.4), theta = -1),
               "theta")
  expect_error(f_clayton_copula_2d_pdf(c(-0.1, 0.4), theta = 1),
               "u")
})

test_that("baseline value matches closed-form", {
  expect_equal(
    f_clayton_copula_2d_pdf(c(0.5, 0.5), 2),
    (1 + 2) * (0.25)^(-3) * ((0.5^-2 + 0.5^-2 - 1)^(-2 - 1/2))
  )
})

test_that("independence limit (theta -> 0) gives density 1", {
  expect_equal(f_clayton_copula_2d_pdf(c(0.3, 0.7), 1e-16), 1, tolerance = 1e-12)
})

test_that("extreme inputs are finite (no NaN/Inf)", {
  expect_true(is.finite(f_clayton_copula_2d_pdf(c(1e-12, 1e-9), 20)))
})
