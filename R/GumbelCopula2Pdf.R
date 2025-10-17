f_gumbel_copula_2d_pdf <- function (u, k1) {
  # Computes the value of the Gumbel copula pdf at a specified point
  # 
  # INPUTS:	U, a Tx1 vector (or a scalar) of F(X[t])
  #				V, a Tx1 vector (or a scalat) of G(Y[t])
  #				K, a Tx1 vector (or a scalar) of kappas
  #
  # Monday, 7 May, 2001.
  # Andrew Patton
  
  u1 <- u[1]
  u2 <- u[2]
  
  pdf <- f_gumbel_copula_2d_cdf(u, k1)*((u1*u2)^(-1))*(((-log(u1))*(-log(u2)))^(k1-1))
  pdf <- pdf * (((-log(u1))^k1 + (-log(u2))^k1)^(k1^(-1)-2))
  pdf <- pdf * ((((-log(u1))^k1 + (-log(u2))^k1)^(k1^(-1))) + k1 - 1)
  pdf
}

f_gumbel_copula_2d_cdf <- function (u, k1) {
  # Computes the value of the Gumbel copula cdf at a specified point
  # 
  # INPUTS:	U, a Tx1 vector (or a scalar) of F(X[t])
  #				  V, a Tx1 vector (or a scalat) of G(Y[t])
  #				  K, a Tx1 vector (or a scalar) of kappas
  #
  
  u1  <- u[1]
  u2  <- u[2]
  cdf <- exp(-((-log(u1))^k1 + (-log(u2))^k1)^(k1^(-1)))
  
  cdf 
}