# Baseline
stopifnot(all.equal(f_clayton_copula_2d_pdf(c(0.5, 0.5), 2),
                    (1+2) * (0.25)^(-3) * ((0.5^-2 + 0.5^-2 - 1)^(-2 - 1/2))))

# Independence limit
stopifnot(all.equal(f_clayton_copula_2d_pdf(c(0.3, 0.7), 1e-16), 1, tol = 1e-12))

# Stability checks
f_clayton_copula_2d_pdf(c(1e-12, 1e-9), 20)  # should be finite, not NaN/Inf
