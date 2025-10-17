f_ewma_vol <- function(rets, history, lambda, type) {
  ### Exponentially weighted moving average
  # NOTE
  #    Recent data should be on bottom of the vector matrix, e.g.
  #    Oct 2012
  #    Nov 2012
  #    Dec 2012
  #    Jan 2013
  #    Default half-life decay solves: exp(-lambda * T/2) = 1/2
  #    The largets the lambda, the more weight have recent observations
  
  size <- dim(rets)
  r <- size[1]
  c <- size[2]
  
  Ewma_ <- function(rets, lambda, r, c, type) {
    
    if (type == 'Riskmetrics') {
      w <- (1 - lambda) / (1 - lambda^r) * lambda ** seq(0,r-1,1)
    } else if (type == 'Meucci') {
      w <- exp(-lambda * (r - seq(r,1,-1)))
      w <- w / sum(w)  
    } else 
    stop('Weights type not well defined')
    
    w   <- w[length(w):1]                # flipud(w)
    w   <- kronecker(matrix(1, 1, c), w) # repmat(w, 1, c)
    vol <- sqrt(apply(w*(rets^2), 2, sum))
    return(vol)
  }

  if (!history) {     
    vol. <- Ewma_(rets, lambda, r, c, type)
  return(vol.)
  } 
  else if (history == TRUE) {
    vol_ <- matrix(NA, r, c)
    for (t in 1:r) {
    vol_[t, ] <- Ewma_(rets[1:t, ], lambda, t, c, type)
    }
    return(vol_)
  }
  else
    stop("History not correctly specified", call. = FALSE)
}
