# independence
stopifnot(all.equal(f_gumbel_copula_2d_cdf(c(0.7, 0.7), 1), 0.49, tol = 1e-14))
stopifnot(all.equal(f_gumbel_copula_2d_pdf(c(0.7, 0.7), 1), 1, tol = 1e-14))

# symmetry
u <- c(0.3, 0.8); k1 <- 2
stopifnot(all.equal(f_gumbel_copula_2d_cdf(u, k1), f_gumbel_copula_2d_cdf(rev(u), k1)))
stopifnot(all.equal(f_gumbel_copula_2d_pdf(u, k1),  f_gumbel_copula_2d_pdf(rev(u), k1)))

# basic bounds
stopifnot(f_gumbel_copula_2d_cdf(c(0.99, 0.99), 3) <= 0.99)  # CDF monotone
stopifnot(is.finite(f_gumbel_copula_2d_pdf(c(1e-8, 0.5), 5)))

