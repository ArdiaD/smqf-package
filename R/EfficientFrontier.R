f_efficient_frontier <- function(mu, Sigma, n_ptf) {
  ### Compute the efficient frontier
  # INPUTS
  #  mu    : [vector] (N x 1) expected returns
  #  Sigma : [matrix] (N x N) covariance matrix
  #  n_ptf  : [scalar] number of portfolios to consider on the efficient froniter
  # OUTPUTS
  #  mu_   : [vector] (n_ptf x 1) expected returns of portfolios
  #  vol_  : [vector] (n_ptf x 1) volatilities of portfolios
  #  w_    : [matrix] (N x n_ptf) composition of portfolios
  require("pracma")
  
  # Ensure Sigma is symmetric
  Sigma <- (Sigma + t(Sigma)) * 0.5
  N     <- length(mu)
  
  # Minimum variance portfolio
  FirstDegree  <- rep(0, N)
  SecondDegree <- 2 * Sigma
  
  # Sum of weights is one
  Aeq <- rep(1, N)
  beq <- 1
  # No-short constraint
  A  <- -diag(1, N)
  b  <- rep(0, N)
  # Starting point is equally-weighted portfolio
  w0 <- rep(1, N) / N
  
  Res <- pracma::quadprog(C = SecondDegree,
                          d = FirstDegree,
                          A = A,
                          b = b,
                          Aeq = Aeq,
                          beq = beq)
  MinVol_Weights <- Res$xmin
  exitflag <- Res$eflag
  
  if (exitflag != 1) {
    stop('Non convergence of quadprog')
  }
  
  MinVol_Return <- as.numeric(t(MinVol_Weights) %*% mu)
  
  # Maximum return portfolio
  MaxRet_Return <- max(mu)
  MaxRet_Index  <- which(mu == MaxRet_Return)
  
  MaxRet_Weights <- rep(0, N)
  MaxRet_Weights[MaxRet_Index] <- 1.0
  
  # initialization
  vol_ <- rep(NA, n_ptf)
  mu_  <- rep(NA, n_ptf)
  w_   <- matrix(NA, N, n_ptf)
  
  # min vol portfolio
  w_[, 1] <- MinVol_Weights
  vol_[1] <- sqrt((t(MinVol_Weights) %*% Sigma) %*% MinVol_Weights)
  mu_[1]  <- t(MinVol_Weights) %*% mu
  
  # max ret portfolio
  w_ [, n_ptf] <- MaxRet_Weights
  vol_[n_ptf]  <- sqrt((t(MaxRet_Weights) %*% Sigma) %*% MaxRet_Weights)
  mu_ [n_ptf]  <- t(MaxRet_Weights) %*% mu
  
  # compute the n_ptf compositions and risk-return coordinates of 
  # the optimal allocations relative to each slice
  Step <- (MaxRet_Return - MinVol_Return) / (n_ptf - 1)
  TargetReturns <- seq(from = MinVol_Return, 
                       to = MaxRet_Return, 
                       by = Step)
  
  # iterate over the various portfolio
  for (i in 2:(n_ptf - 1)) {
    # determine least risky portfolio for given expected return
    Aeq <- t(cbind(rep(1, N), mu))
    beq <- rbind(1, TargetReturns[i])
    res <- pracma::quadprog(C = SecondDegree,
                            d = FirstDegree,
                            A = A,
                            b = b,
                            Aeq = Aeq,
                            beq = beq)
    w <- res$xmin
    exitflag <- res$eflag
    
    if (exitflag != 1) {
      stop('Non convergence of quadprog', call. = FALSE)
    }
    
    w_[, i] <- w
    vol_[i] <- sqrt((t(w) %*% Sigma) %*% w)
    mu_[i]  <- t(w) %*% mu
  }
  
  out <- list(
    weights = w_,
    volatility = vol_,
    expected_returns = mu_
  )
  
  out
}

