f_NelsonSiegel <- function (tau, gamma, beta) {
  ### Adjusted Svensson function
  ###  INPUTS  
  ###   tau   : [vector] (n x 1) maturities (in year)
  ###   beta  : [vector] (3 x 1)
  ###  OUTPUTS 
  ###   y     : [vector] (n x 1) or spot rates (yields) corresponding to maturities tau
  
  gamma1_tau <- gamma[1] * tau 
  f1 <- (1 - exp(-gamma1_tau)) / gamma1_tau 
  f2 <- f1 - exp(-gamma1_tau) 
  
  y <- beta[1] + beta[2] * f1 + beta[3] * f2 
  
  y[is.nan(y)] <- 0 #for tau=0, the rate is NaN, so assume y=0
  
  return(y)
}


f_FitSqrtSvensson = function (tau, y) {
  ## Fit ADJUSTED Svensson function on sqrt(y)
  #  INPUTS   
  #   tau     : [vector] (n x 1) of maturities (wrt annual)
  #   y       : [vector] (n x 1) of sport interet rates (yields)
  #  OUTPUTS
  #   gamma   : [vector] (2 x 1)
  #   beta    : [vector] (4 x 1) 
  #  REFERENCES
  #   o De Pooter, M. (2007), Examining the Nelson-Siegel Class of Term
  #     Structure Models, Tinbergen Institute Discussion Paper
  
  ## Inputs
  # tau = tau(:) 
  # y   = y(:) 
  tau[tau < 1e-4] = 1e-4 
  
  ## 
  gamma = rep(NaN, 2)
  gamma[1] = 0.0609 * 12    # gamma_1 := 1 / lambda_1, where lambda_1 is 16.42  see Michiel de Pooter (2007)
  gamma[2] = 1 / 9.73 * 12  # gamma_2 := 1 / lambda_2, where lambda_2 is 9.73  see Michiel de Pooter (2007)
  
  # OLS estimation
  n = prod(dim(tau))
  gamma1_tau = gamma[1] * tau  # gamma is defined as 1 / lambda
  gamma2_tau = gamma[2] * tau 
  f1 = (1 - exp(-gamma1_tau)) / gamma1_tau 
  f2 = f1 - exp(-gamma1_tau) 
  f3 = (1 - exp(-gamma2_tau)) / gamma2_tau - exp(-2 * gamma2_tau)  # this is the adjusted Svensson term
  
  X = cbind(rep(1,n), f1, f2, f3)
  
  beta = ( solve(t(X) %*% X) ) %*% (t(X) %*% sqrt(y))           # OLS estimate => beta = inv(x'x) * X'y
  
  return(beta)
}

f_PowerSvensson = function (tau, beta) {
  ### Adjusted Svensson function
  ###  INPUTS  
  ###   tau   : [vector] (n x 1) maturities (in year)
  ###   gamma : [vector] (2 x 1)
  ###   beta  : [vector] (4 x 1)
  ###  OUTPUTS 
  ###   y     : [vector] (n x 1) or spot rates (yields) corresponding to maturities tau
  
  gamma = rep(NaN, 2)
  gamma[1] = 0.0609 * 12    # gamma_1 := 1 / lambda_1, where lambda_1 is 16.42  see Michiel de Pooter (2007)
  gamma[2] = 1 / 9.73 * 12  # gamm
  
  gamma1_tau = gamma[1] * tau 
  gamma2_tau = gamma[2] * tau 
  f1 = (1 - exp(-gamma1_tau)) / gamma1_tau 
  f2 = f1 - exp(-gamma1_tau) 
  f3 = (1 - exp(-gamma2_tau)) / gamma2_tau - exp(-2 * gamma2_tau)  # this is the adjusted Svensson term
  
  y = beta[1] + beta[2] * f1 + beta[3] * f2 + beta[4] * f3 
  y[is.nan(y)] = 0  #for tau=0, the rate is NaN, so assume y=0
  y = y^2           # take the power
  
  return(y)
}
