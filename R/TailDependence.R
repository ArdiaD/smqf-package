f_tail_dependence <- function(x, y, alpha) {
  # Calculate lower tail-dependence coefficient for two time series
  # INPUTS
  #  x        : [vector] (n x 1) 
  #  y        : [vector] (n x 1)
  #  alpha    : [scalar] threshold
  # OUTPUTS
  #  lambda   : [scalar] tail-dependence coefficient
  #  excorr   : [scalar] exceedance correlation

  # with alpha <- 0.01, the TRUEs of R are 62, while the TRUEs of Matlab are 61
  idx_x <- x < quantile(x, alpha)   
  idx_y <- y < quantile(y, alpha) 
    
  sumx  <- sum(idx_x & idx_y) 
  
  if (sumx > 0) {
    lambda <- sumx / sum(idx_x | idx_y)     
    excorr <- cor(x[idx_x & idx_y], y[idx_x & idx_y]) 
  } else {
    lambda <- 0 
    excorr <- NA 
  }
  
  out <- list(lambda = lambda, 
              excorr = excorr)
  out
}


