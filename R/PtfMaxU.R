
f_ptf_max_U <- function(gamma, w_max, M1, M2, M3, M4) {
  
  library("nloptr")
  
  d <- length(M1)
  
  f_eq <- function(w) {
    obj <- sum(w) - 1
    gr  <- rep(1, d)
    out <- list("constraints" = obj, 
                "jacobian" = gr)
    out
  }
  
  f_obj <- function(w) {
    mom1 <- sum(w * M1)
    mom2 <- PerformanceAnalytics:::portm2(w, M2)
    mom3 <- PerformanceAnalytics:::portm3(w, M3)
    mom4 <- PerformanceAnalytics:::portm4(w, M4)
    obj <- -mom1 + gamma * mom2 / 2 - gamma * (gamma + 1) * mom3 / 6 + gamma * (gamma + 1) * (gamma + 2) * mom4 / 24
    
    momsgrad1 <- M1
    momsgrad2 <- PerformanceAnalytics:::derportm2(w, M2)
    momsgrad3 <- PerformanceAnalytics:::derportm3(w, M3)
    momsgrad4 <- PerformanceAnalytics:::derportm4(w, M4)
    gr <- -M1 + gamma * momsgrad2 / 2 - gamma * (gamma + 1) * momsgrad3 / 6 + gamma * (gamma + 1) * (gamma + 2) * momsgrad4 / 24
    
    out <- list("objective" = obj, 
                "gradient" = gr)
    out
  }
  
  lb <- rep(0, d)
  ub <- rep(w_max, d)
  
  sol <- nloptr::nloptr(x0 = rep(1/d, d), 
                        eval_f = f_obj, 
                        lb = lb, ub = ub,
                        eval_g_eq = f_eq, 
                        opts = list(algorithm = "NLOPT_LD_SLSQP", 
                                    maxeval = 10000,
                                    print_level = 0, 
                                    check_derivatives = FALSE))
  wopt <- sol$solution
  EU   <- -sol$objective
  
  out <- list("w" = wopt, 
              "EU" = EU)
  out
}
