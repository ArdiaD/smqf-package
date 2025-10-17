f_solvePortfolio <- function (p, w0, m1, M2, M3, M4, lb, ub, lin_eq, lin_eqC, nlin_eq, 
          lin_ieq, lin_ieqC, nlin_ieq, options, param) 
{
  if (!("maxeval" %in% names(options))) 
    options$maxeval = 10000
  if (!("check_derivatives" %in% names(options))) 
    options$check_derivatives = FALSE
  if (!("print_level" %in% names(options))) 
    options$print_level = 0
  options$algorithm <- "NLOPT_LD_SLSQP"
  g_eq <- function(w) {
    cts <- jac <- NULL
    if (!is.null(lin_eq)) {
      cts <- lin_eq %*% w - lin_eqC
      jac <- lin_eq
    }
    if (!is.null(nlin_eq)) {
      nlin_eq_res <- nlin_eq(w)
      cts <- c(cts, nlin_eq_res$constraints)
      jac <- rbind(jac, nlin_eq_res$jacobian)
    }
    list(constraints = cts, jacobian = jac)
  }
  g_ineq <- function(w) {
    cts <- jac <- NULL
    if (!is.null(lin_ieq)) {
      cts <- lin_ieq %*% w - lin_ieqC
      jac <- lin_ieq
    }
    if (!is.null(nlin_ieq)) {
      nlin_ieq_res <- nlin_ieq(w)
      cts <- c(cts, nlin_ieq_res$constraints)
      jac <- rbind(jac, nlin_ieq_res$jacobian)
    }
    list(constraints = cts, jacobian = jac)
  }
  fn <- mvskPortfolios:::get_href(w0, m1, M2, M3, M4, param)
  w00 <- rep(1/p, p)
  sol <- nloptr::nloptr(x0 = w00, eval_f = fn, lb = lb, ub = ub, 
                        eval_g_eq = g_eq, eval_g_ineq = g_ineq, opts = options)
  sol$solution
}

f_solveMVSKPortfolio <- function (p, w0, g, m1, M2, M3, M4, indmom, lb, ub, lin_eq, lin_eqC, 
          nlin_eq, lin_ieq, lin_ieqC, nlin_ieq, options, href, kappa, 
          relative, param, mompref) 
{
  if (!("maxeval" %in% names(options))) 
    options$maxeval = 10000
  if (!("check_derivatives" %in% names(options))) 
    options$check_derivatives = FALSE
  if (!("print_level" %in% names(options))) 
    options$print_level = 0
  options$algorithm <- "NLOPT_LD_SLSQP"
  g_eq <- function(x) {
    w <- x[-1]
    cts <- jac <- NULL
    if (!is.null(lin_eq)) {
      cts <- lin_eq %*% w - lin_eqC
      jac <- lin_eq
    }
    if (!is.null(nlin_eq)) {
      nlin_eq_res <- nlin_eq(w)
      cts <- c(cts, nlin_eq_res$constraints)
      jac <- rbind(jac, nlin_eq_res$jacobian)
    }
    if (!is.null(cts)) 
      jac <- cbind(0, jac)
    list(constraints = cts, jacobian = jac)
  }
  if (is.null(href)) {
    objw0 <- NULL
    fn <- function(w) NULL
  }
  else {
    if (is.function(href)) {
      fn <- href
    }
    else {
      if (href == "TEvol" && !("wref" %in% names(param))) 
        param <- list(wref = w0)
      fn <- mvskPortfolios:::get_href(href, m1, M2, M3, M4, param)
    }
    fn0 <- fn(w0)$objective
    if (relative) 
      objw0 <- (1 + sign(fn0) * kappa) * fn0
    else objw0 <- (fn0 + kappa)
  }
  mw0 <- f_getmom(indmom, w0, m1, M2, M3, M4)
  if (is.null(mompref)) 
    sgm <- c(-1, 1, -1, 1)[indmom]
  else sgm <- -mompref
  g_ineq <- function(x) {
    delta <- x[1]
    w <- x[-1]
    objRtemp <- fn(w)
    if (is.numeric(g)) {
      gf <- delta * g
      gfgr <- g
    }
    else {
      gtmp <- g(delta)
      gf <- gtmp$objective
      gfgr <- gtmp$gradient
    }
    mw <- f_getmom(indmom, w, m1, M2, M3, M4)
    obj <- sgm * (mw - mw0) + gf
    obj <- c(obj, objRtemp$objective - objw0)
    momgr <- f_getmomgr(indmom, w, m1, M2, M3, M4)
    momgr <- rbind(cbind(gfgr, momgr * sgm), c(0, objRtemp$gradient))
    cts <- jac <- NULL
    if (!is.null(lin_ieq)) {
      cts <- lin_ieq %*% w - lin_ieqC
      jac <- lin_ieq
    }
    if (!is.null(nlin_ieq)) {
      nlin_ieq_res <- nlin_ieq(w)
      cts <- c(cts, nlin_ieq_res$constraints)
      jac <- rbind(jac, nlin_ieq_res$jacobian)
    }
    if (!is.null(jac)) 
      jac <- cbind(0, jac)
    cts <- c(obj, cts)
    jac <- rbind(momgr, jac)[1:length(cts), ]
    list(constraints = cts, jacobian = jac)
  }
  fobj <- function(x) {
    obj <- -x[1]
    gr <- rep(0, length(x))
    gr[1] <- -1
    list(objective = obj, gradient = gr)
  }
  sol <- nloptr::nloptr(x0 = c(0, w0), eval_f = fobj, lb = c(-1, 
                                                             lb), ub = c(1, ub), eval_g_eq = g_eq, eval_g_ineq = g_ineq, 
                        opts = options)
  wopt <- sol$solution[-1]
  delta <- sol$solution[1]
  moms <- f_getmom(indmom, wopt, m1, M2, M3, M4)
  constr <- sol$eval_g_ineq(sol$solution)$constraints
  list(w = wopt, delta = delta, moms = moms, constr = constr)
}

f_getmom <- function(indmom, w, m1, M2, M3, M4) 
{
  moms <- NULL
  if (indmom[1]) 
    moms <- c(moms, sum(w * m1))
  if (indmom[2]) 
    moms <- c(moms, PerformanceAnalytics:::portm2(w, M2))
  if (indmom[3]) 
    moms <- c(moms, PerformanceAnalytics:::portm3(w, M3))
  if (indmom[4]) 
    moms <- c(moms, PerformanceAnalytics:::portm4(w, M4))
  moms
}

f_getmomgr <- function (indmom, w, m1, M2, M3, M4) 
{
  momsgr <- matrix(NA, nrow = 4, ncol = length(w))
  if (indmom[1]) 
    momsgr[1, ] <- m1
  if (indmom[2]) 
    momsgr[2, ] <- PerformanceAnalytics:::derportm2(w, M2)
  if (indmom[3]) 
    momsgr[3, ] <- PerformanceAnalytics:::derportm3(w, M3)
  if (indmom[4]) 
    momsgr[4, ] <- PerformanceAnalytics:::derportm4(w, M4)
  momsgr <- momsgr[indmom, ]
  momsgr
}


f_mvskPortfolio <- function (m1 = NULL, M2 = NULL, M3 = NULL, M4 = NULL, w0 = NULL, 
          g = NULL, lb = NULL, ub = NULL, lin_eq = NULL, lin_eqC = NULL, 
          nlin_eq = NULL, lin_ieq = NULL, lin_ieqC = NULL, nlin_ieq = NULL, 
          href = NULL, kappa = NULL, relative = FALSE, param = NULL, 
          options = list(), mompref = NULL) 
{
  
  p <- nrow(M2)
  if (is.null(lin_eq) || is.null(lin_eqC)) {
    lin_eq <- matrix(1, nrow = 1, ncol = p)
    lin_eqC <- 1
  }
  if (is.null(lb)) 
    lb <- rep(0, p)
  if (is.null(ub)) 
    ub <- rep(1, p)
  if (is.null(w0)) 
    w0 <- rep(1/p, p)
  if (!is.numeric(w0)) {
    w0 <- f_solvePortfolio(p, w0, m1, M2, M3, M4, lb, ub, lin_eq, 
                         lin_eqC, nlin_eq, lin_ieq, lin_ieqC, nlin_ieq, options, 
                         param)
  }
  indmom <- !c(is.null(m1), is.null(M2), is.null(M3), is.null(M4))
  if (is.null(g)) 
    g <- abs(f_getmom(indmom, w0, m1, M2, M3, M4))
  if (is.character(g) && g[1] %in% c("mvsk", "vsk")) {
    g <- abs(f_getmom(indmom, w0, m1, M2, M3, M4))
    if (indmom[1]) 
      g[1] <- 0
  }
  if (is.null(href)) {
    effport <- f_solveMVSKPortfolio(p, w0, g, m1, M2, M3, M4, 
                                  indmom, lb, ub, lin_eq, lin_eqC, nlin_eq, lin_ieq, 
                                  lin_ieqC, nlin_ieq, options, NULL, 0, FALSE, NULL, 
                                  mompref)
  }
  else {
    wopt <- matrix(NA, nrow = length(kappa), ncol = p)
    delta <- rep(NA, length(kappa))
    moms <- matrix(NA, nrow = length(kappa), ncol = sum(indmom))
    constr <- NULL
    if (is.null(kappa)) 
      kappa <- 0
    for (ii in 1:length(kappa)) {
      effport <- f_solveMVSKPortfolio(p, w0, g, m1, M2, M3, 
                                    M4, indmom, lb, ub, lin_eq, lin_eqC, nlin_eq, 
                                    lin_ieq, lin_ieqC, nlin_ieq, options, href, kappa[ii], 
                                    relative, param, mompref)
      wopt[ii, ] <- effport$w
      delta[ii] <- effport$delta
      moms[ii, ] <- effport$moms
      constr <- rbind(constr, effport$constr)
    }
    effport <- list(w = wopt, delta = delta, moms = moms, 
                    constr = constr)
  }
  effport
}
