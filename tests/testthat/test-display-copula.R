test_that("f_display_copula validates inputs", {
  expect_error(f_display_copula("not_a_function", 1:10, 1:10),
               "function")
  expect_error(f_display_copula(function(u) u, numeric(0), 1:10),
               "non-empty")
  expect_error(f_display_copula(function(u) u, 1:10, numeric(0)),
               "non-empty")
})

test_that("f_display_copula returns a finite matrix", {
  my_grid <- seq(0.1, 0.9, by = 0.1)
  my_copula <- function(u) prod(u)  # independence copula
  result <- f_display_copula(my_copula, my_grid, my_grid, plot = FALSE)
  expect_true(is.matrix(result))
  expect_equal(nrow(result), length(my_grid))
  expect_equal(ncol(result), length(my_grid))
  expect_true(all(is.finite(result)))
})
