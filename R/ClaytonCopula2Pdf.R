f_clayton_copula_2d_pdf <- function (u, theta) {
  # Computes the value of the Clayton copula pdf at a specified point
  # INPUTS
  #  u     : [vectpr] 
  #  theta : [parameter]
  # NOTE 
  #  o Code by Andrew Patton
  #  o only works numerically for k1<=34 or so. 
  #  o when theta = 0 this copula converges to the "independence
  #    copula", which needs to be computed separately. (this copula pdf takes
  #    the value of 1 for all (u,v) in [0,1]x[0,1]
  #    lower tail dep = 2^(-1/theta) for Clayton's copula
  #    upper tail dep = 0
  
  u1 <- u[1]
  u2 <- u[2]
  
  pdf <- (1 + theta) * (u1 * u2)^(-theta-1)*(u1^(-theta) + u2^(-theta)-1)^(-2-theta^(-1))
  
  pdf
}             
