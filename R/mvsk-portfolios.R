#' Solve a Portfolio Given Linear/Nonlinear Constraints
#'
#' Wrapper around \pkg{nloptr} (SLSQP) that solves for portfolio weights under
#' bound, linear, and optional nonlinear equality/inequality constraints for a
#' user-chosen objective (mean–variance–skewness–kurtosis, tracking error, etc.).
#'
#' @param p Integer, number of assets.
#' @param w0 Numeric vector of length \code{p} used by the objective (e.g., a
#'   reference portfolio). Not used as the optimizer's initial guess (a
#'   1/\code{p} vector is used internally).
#' @param m1,M2,M3,M4 First through fourth (co)moments used by the objective
#'   function (vector, matrix, 3-tensor, 4-tensor respectively), as required.
#' @param lb,ub Numeric length-\code{p} lower/upper bounds on weights.
#' @param lin_eq Matrix of linear equality constraint rows (each row is a
#'   constraint on \code{w}); \code{lin_eqC} is the right-hand side vector.
#' @param lin_eqC Numeric vector for \code{lin_eq}.
#' @param nlin_eq Function returning a list with components \code{constraints}
#'   and \code{jacobian} for nonlinear equalities in \code{w}; may be \code{NULL}.
#' @param lin_ieq,lin_ieqC Analogous objects for linear \emph{inequalities}
#'   (left side minus right side \eqn{\le 0}).
#' @param nlin_ieq Function returning a list with \code{constraints} and
#'   \code{jacobian} for nonlinear inequalities; may be \code{NULL}.
#' @param options Named list of \pkg{nloptr} options. Defaults are filled for
#'   \code{maxeval}, \code{check_derivatives}, \code{print_level}, and the
#'   algorithm \code{"NLOPT_LD_SLSQP"}.
#' @param param List of extra parameters passed to the objective factory
#'   \code{mvskPortfolios:::get_href()}.
#'
#' @details
#' The objective function is built via \code{mvskPortfolios:::get_href(w0, m1, M2, M3, M4, param)}
#' and must return a list with \code{objective} and \code{gradient}.
#' Equality constraints are stacked (linear then nonlinear), likewise for
#' inequalities. Internally the initial guess is the equally-weighted vector.
#'
#' @return Numeric vector of optimal weights of length \code{p}.
#'
#' @examples
#' \dontrun{
#' p <- 4; mu <- c(0.08,0.1,0.12,0.09)
#' set.seed(1); A <- matrix(rnorm(p*p), p); Sigma <- crossprod(A)/p
#' # Dummy moments beyond variance just to match the signature:
#' M3 <- array(0, dim = c(p,p,p)); M4 <- array(0, dim = c(p,p,p,p))
#' w <- f_solvePortfolio(
#'   p = p, w0 = rep(1/p,p), m1 = mu, M2 = Sigma, M3 = M3, M4 = M4,
#'   lb = rep(0,p), ub = rep(1,p),
#'   lin_eq = matrix(1,1,p), lin_eqC = 1,
#'   nlin_eq = NULL, lin_ieq = NULL, lin_ieqC = NULL, nlin_ieq = NULL,
#'   options = list()
#' )
#' }
#'
#' @importFrom nloptr nloptr
#' @export
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

#' Solve an MVSK Portfolio with Relative Objective and Moment Targets
#'
#' Maximizes a scalar slack \eqn{\delta} subject to:
#' \enumerate{
#'   \item Moment improvements relative to a baseline \eqn{w_0} (on a selected
#'   subset of mean/variance/skewness/kurtosis), and
#'   \item A user-specified risk/utility objective \code{href} relative to a
#'   tolerance level built from \code{kappa} and the baseline objective.
#' }
#' Linear and nonlinear constraints (equality/inequality) on weights are allowed.
#'
#' @param p Integer, number of assets.
#' @param w0 Numeric baseline weights used in constraints/objective.
#' @param g Either a numeric vector of moment targets (same length as
#'   \code{sum(indmom)}) multiplied by \eqn{\delta}, or a function of
#'   \code{delta} returning \code{list(objective, gradient)}.
#' @param m1,M2,M3,M4 See \code{\link{f_getmom}}.
#' @param indmom Logical length-4 vector indicating which moments are enforced
#'   (mean, variance, skewness, kurtosis).
#' @param lb,ub Bounds on weights; \code{lin_eq}, \code{lin_eqC}, \code{nlin_eq},
#'   \code{lin_ieq}, \code{lin_ieqC}, \code{nlin_ieq} constraint objects as in
#'   \code{\link{f_solvePortfolio}}.
#' @param options \pkg{nloptr} options list (SLSQP is used).
#' @param href Either a function \code{w -> list(objective, gradient)} or a
#'   string understood by \code{mvskPortfolios:::get_href()} (e.g., "TEvol").
#' @param kappa Numeric scalar shaping the tolerance vs. baseline objective.
#' @param relative Logical; if \code{TRUE}, scales baseline objective by
#'   \eqn{(1 + \mathrm{sign}(f(w_0))\,\kappa)}, else uses \eqn{f(w_0) + \kappa}.
#' @param param List of extra arguments forwarded to \code{get_href()}.
#' @param mompref Optional numeric length-4 vector setting the signs/directions
#'   of improvement for the selected moments (overrides defaults).
#'
#' @details
#' The decision vector is \code{x <- c(delta, w)}. The objective is
#' \eqn{\max \delta}. Inequalities include (i) moment targets relative to
#' \eqn{w_0} with signs \code{sgm} and (ii) the relative objective threshold
#' \eqn{f(w) - f(w_0; \kappa) \le 0}. Gradients are supplied analytically via
#' \code{\link{f_getmomgr}} and the objective's gradient.
#'
#' @return A list with components:
#' \describe{
#'   \item{w}{Optimal weights vector.}
#'   \item{delta}{Optimal slack scalar.}
#'   \item{moms}{Selected moments at the solution.}
#'   \item{constr}{Vector of inequality constraint values at the solution.}
#' }
#'
#' @seealso \code{\link{f_getmom}}, \code{\link{f_getmomgr}}, \code{\link{f_mvskPortfolio}}
#'
#' @importFrom nloptr nloptr
#' @export
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

#' Compute Selected Portfolio Moments
#'
#' Returns a vector consisting of any subset of mean, variance, skewness, and
#' kurtosis of the portfolio defined by weights \code{w}, given the corresponding
#' moment inputs.
#'
#' @param indmom Logical length-4 vector indicating which moments to include
#'   (order: mean, variance, skewness, kurtosis).
#' @param w Numeric weights vector.
#' @param m1,M2,M3,M4 First through fourth (co)moments (as required by the
#'   selected \code{indmom} entries).
#'
#' @return Numeric vector of length \code{sum(indmom)} containing the requested
#'   moments in order.
#'
#' @note This implementation calls internal functions from
#'   \pkg{PerformanceAnalytics} (\code{portm2}, \code{portm3}, \code{portm4})
#'   via the triple-colon operator; for CRAN packages you should prefer exported
#'   APIs or provide in-package equivalents.
#'
#' @examples
#' \dontrun{
#' indmom <- c(TRUE, TRUE, FALSE, FALSE)
#' m <- f_getmom(indmom, w = c(0.5,0.5), m1 = c(0.1,0.08),
#'               M2 = matrix(c(0.04,0.01,0.01,0.09),2), M3 = NULL, M4 = NULL)
#' }
#'
#' @export
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

#' Gradients of Selected Portfolio Moments
#'
#' Computes gradients with respect to weights for any subset of mean, variance,
#' skewness, and kurtosis, stacked by rows.
#'
#' @inheritParams f_getmom
#'
#' @return Numeric matrix with \code{sum(indmom)} rows and \code{length(w)} columns.
#'
#' @note Uses internal \pkg{PerformanceAnalytics} functions
#'   \code{derportm2}, \code{derportm3}, \code{derportm4} via the triple-colon
#'   operator; see the Note in \code{\link{f_getmom}}.
#'
#' @examples
#' \dontrun{
#' indmom <- c(TRUE, TRUE, FALSE, FALSE)
#' G <- f_getmomgr(indmom, w = c(0.5,0.5), m1 = c(0.1,0.08),
#'                 M2 = matrix(c(0.04,0.01,0.01,0.09),2), M3 = NULL, M4 = NULL)
#' }
#'
#' @export
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

#' MVSK Portfolio Front-end (Mean–Variance–Skewness–Kurtosis)
#'
#' User-facing convenience function that sets defaults (bounds, full-investment
#' constraint) and calls the appropriate solver to obtain a single MVSK
#' portfolio or a path over a grid of \code{kappa} values when an additional
#' reference objective \code{href} is supplied.
#'
#' @param m1,M2,M3,M4 Moment inputs (see \code{\link{f_getmom}}). At least one
#'   must be non-\code{NULL}.
#' @param w0 Baseline weights. If \emph{numeric}, used directly; if not numeric
#'   (e.g., a string spec), a preliminary solve via \code{\link{f_solvePortfolio}}
#'   is performed to obtain \code{w0}.
#' @param g Moment target vector or function (see \code{\link{f_solveMVSKPortfolio}}).
#' @param lb,ub Bounds on weights (default: long-only \eqn{[0,1]}).
#' @param lin_eq,lin_eqC Linear equality constraint matrix and RHS. If omitted,
#'   the fully-invested constraint \eqn{\mathbf{1}^\top w = 1} is enforced.
#' @param nlin_eq Optional nonlinear equality constraints (function).
#' @param lin_ieq,lin_ieqC Linear inequality constraint matrix and RHS (left
#'   minus right \eqn{\le 0}).
#' @param nlin_ieq Optional nonlinear inequality constraints (function).
#' @param href Optional objective (function or string for
#'   \code{mvskPortfolios:::get_href()}) used to define a relative constraint.
#' @param kappa Optional numeric vector; if provided with \code{href}, a solve
#'   is run for each \code{kappa}, producing a path of portfolios.
#' @param relative Logical flag for relative vs absolute objective thresholding.
#' @param param List of extra arguments for the objective factory.
#' @param options \pkg{nloptr} options.
#' @param mompref Optional preference signs for moment directions.
#'
#' @return If \code{href} is \code{NULL}, a single list as returned by
#'   \code{\link{f_solveMVSKPortfolio}}. Otherwise, a list with components:
#'   \code{w} (matrix of weights over \code{kappa}), \code{delta} (vector),
#'   \code{moms} (matrix), and \code{constr} (constraint values).
#'
#' @examples
#' \dontrun{
#' p <- 3
#' mu <- c(0.06, 0.08, 0.10)
#' set.seed(2); A <- matrix(rnorm(p*p), p); Sigma <- crossprod(A)/p
#' res <- f_mvskPortfolio(m1 = mu, M2 = Sigma, w0 = rep(1/p,p))
#' res$w
#' }
#'
#' @seealso \code{\link{f_solvePortfolio}}, \code{\link{f_solveMVSKPortfolio}}
#' @importFrom nloptr nloptr
#' @export
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
