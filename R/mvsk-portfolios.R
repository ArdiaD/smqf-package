# ---------------------------------------------------------------------------
# Higher-moment portfolio tilting.
#
# Ported into smqf from the mvskPortfolios package by Dries Cornilly and Kris
# Boudt (https://github.com/cdries/mvskPortfolios, commit 175bb38), which is
# distributed under GPL-2 | GPL-3. The port keeps the algorithm of Boudt,
# Cornilly, Van Holle & Willems (2020) unchanged; it exists so that the book's
# examples run from CRAN alone, without an install_github() step.
#
# Two deliberate departures from the original:
#
#   1. The original calls PerformanceAnalytics:::portm2/3/4 and :::derportm2/3/4,
#      i.e. non-exported symbols of another package, which CRAN policy forbids.
#      Those calls are replaced by smqf's own .portm* / .derportm* helpers
#      (see portfolio-moments.R), which compute the same quantities.
#
#   2. Consequently the co-moment matrices must be supplied in the "matrix"
#      form returned by PerformanceAnalytics::M3.MM(x) and M4.MM(x) with the
#      default as.mat = TRUE. The compact vector form (as.mat = FALSE) is not
#      accepted; convert it first with PerformanceAnalytics::M3.vec2mat().
#
# ---------------------------------------------------------------------------

# Portfolio moments selected by indmom, in the order (mean, variance,
# skewness, kurtosis).
.mvsk_getmom <- function(indmom, w, m1, M2, M3, M4) {
  moms <- NULL
  if (indmom[1]) moms <- c(moms, sum(w * m1))
  if (indmom[2]) moms <- c(moms, .portm2(w, M2))
  if (indmom[3]) moms <- c(moms, .portm3(w, M3))
  if (indmom[4]) moms <- c(moms, .portm4(w, M4))
  moms
}

# Jacobian of the selected portfolio moments with respect to w.
.mvsk_getmomgr <- function(indmom, w, m1, M2, M3, M4) {
  momsgr <- matrix(NA_real_, nrow = 4, ncol = length(w))
  if (indmom[1]) momsgr[1, ] <- m1
  if (indmom[2]) momsgr[2, ] <- .derportm2(w, M2)
  if (indmom[3]) momsgr[3, ] <- .derportm3(w, M3)
  if (indmom[4]) momsgr[4, ] <- .derportm4(w, M4)
  # drop = FALSE: with a single selected moment the original would silently
  # return a vector, breaking the rbind() that consumes this.
  momsgr[indmom, , drop = FALSE]
}

# Minus the diversification ratio of Choueifaty & Coignard (2008).
.mvsk_fDR <- function(w, M2) {
  s <- sqrt(diag(M2))
  wSigw <- sum(w * M2 %*% w)
  obj <- -sum(w * s) / sqrt(wSigw)
  gr <- -(s / sqrt(wSigw) - sum(w * s) / (wSigw)^1.5 * M2 %*% w)
  list(objective = obj, gradient = gr)
}

# Equal-risk-contribution objective.
.mvsk_fERC <- function(w, M2) {
  p <- length(w)
  Sigw <- M2 %*% w
  pctRC <- w * Sigw / sum(w * Sigw)
  obj <- sum((pctRC - 1 / p)^2)
  sp <- sqrt(sum(w * Sigw))
  dff <- pctRC - 1 / p
  gr <- 2 * (sp^2 * (M2 %*% (w * dff) + dff * Sigw) -
               2 * sum(w * dff * Sigw) * Sigw) / sp^4
  list(objective = obj, gradient = gr)
}

# Minus the fourth-order expansion of CRRA expected utility. Same objective as
# f_ptf_max_U(); kept here so the tilting code is self-contained.
.mvsk_fEU <- function(w, gamma, M2, M3, M4, m1 = NULL) {
  if (is.null(m1)) m1 <- rep(0, length(w))
  mom2 <- .portm2(w, M2)
  mom3 <- .portm3(w, M3)
  mom4 <- .portm4(w, M4)
  obj <- -sum(w * m1) + gamma * mom2 / 2 - gamma * (gamma + 1) * mom3 / 6 +
    gamma * (gamma + 1) * (gamma + 2) * mom4 / 24
  gr <- -m1 + gamma * .derportm2(w, M2) / 2 -
    gamma * (gamma + 1) * .derportm3(w, M3) / 6 +
    gamma * (gamma + 1) * (gamma + 2) * .derportm4(w, M4) / 24
  list(objective = obj, gradient = gr)
}

# Herfindahl index.
.mvsk_fHI <- function(w) {
  list(objective = sum(w^2), gradient = 2 * w)
}

# Tracking-error volatility against a reference portfolio.
.mvsk_fTEvol <- function(w, M2, wref) {
  wdiff <- w - wref
  M2wdiff <- M2 %*% wdiff
  TEvol <- sqrt(sum(wdiff * M2wdiff))
  gr <- if (TEvol < 1e-10) rep(0, length(w)) else M2wdiff / TEvol
  list(objective = TEvol, gradient = gr)
}

# Resolve a reference-function name to the function itself.
.mvsk_get_href <- function(href, m1, M2, M3, M4, param) {
  if (href == "DR") {
    function(w) .mvsk_fDR(w, M2)
  } else if (href == "ERC") {
    function(w) .mvsk_fERC(w, M2)
  } else if (href %in% c("HI", "EW")) {
    function(w) .mvsk_fHI(w)
  } else if (href == "EU") {
    function(w) .mvsk_fEU(w, param$gamma, M2, M3, M4, m1)
  } else if (href == "TEvol") {
    function(w) .mvsk_fTEvol(w, M2, param$wref)
  } else {
    stop("'", href, "' is not a valid reference function. Use one of ",
         "\"DR\", \"ERC\", \"HI\", \"EW\", \"EU\", \"TEvol\".", call. = FALSE)
  }
}

# NLopt exit codes: > 0 is a success, but 5 means the evaluation budget ran
# out before convergence and 6 means the time limit did.
.mvsk_check_status <- function(sol, what) {
  if (sol$status < 0) {
    warning("nloptr failed while solving the ", what, " (status ", sol$status,
            "): ", sol$message, call. = FALSE)
  } else if (sol$status %in% c(5L, 6L)) {
    warning("nloptr hit its evaluation or time budget while solving the ", what,
            " (status ", sol$status, "): ", sol$message,
            ". The reported solution may not be optimal.", call. = FALSE)
  }
  invisible(sol)
}

# Solve for a named starting portfolio (DR, ERC, HI/EW, EU, TEvol).
.mvsk_solvePortfolio <- function(p, w0, m1, M2, M3, M4, lb, ub, lin_eq, lin_eqC,
                                 nlin_eq, lin_ieq, lin_ieqC, nlin_ieq, options, param) {
  if (!("maxeval" %in% names(options)))           options$maxeval <- 10000
  if (!("check_derivatives" %in% names(options))) options$check_derivatives <- FALSE
  if (!("print_level" %in% names(options)))       options$print_level <- 0
  options$algorithm <- "NLOPT_LD_SLSQP"

  g_eq <- function(w) {
    cts <- jac <- NULL
    if (!is.null(lin_eq)) {
      cts <- lin_eq %*% w - lin_eqC
      jac <- lin_eq
    }
    if (!is.null(nlin_eq)) {
      res <- nlin_eq(w)
      cts <- c(cts, res$constraints)
      jac <- rbind(jac, res$jacobian)
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
      res <- nlin_ieq(w)
      cts <- c(cts, res$constraints)
      jac <- rbind(jac, res$jacobian)
    }
    list(constraints = cts, jacobian = jac)
  }

  fn  <- .mvsk_get_href(w0, m1, M2, M3, M4, param)
  sol <- nloptr::nloptr(x0 = rep(1 / p, p), eval_f = fn, lb = lb, ub = ub,
                        eval_g_eq = g_eq, eval_g_ineq = g_ineq, opts = options)
  .mvsk_check_status(sol, paste0("initial \"", w0, "\" portfolio"))
  sol$solution
}

# Solve one tilting problem at a given margin kappa.
.mvsk_solveMVSK <- function(p, w0, g, m1, M2, M3, M4, indmom, lb, ub, lin_eq, lin_eqC,
                            nlin_eq, lin_ieq, lin_ieqC, nlin_ieq, options,
                            href, kappa, relative, param, mompref) {
  if (!("maxeval" %in% names(options)))           options$maxeval <- 10000
  if (!("check_derivatives" %in% names(options))) options$check_derivatives <- FALSE
  if (!("print_level" %in% names(options)))       options$print_level <- 0
  options$algorithm <- "NLOPT_LD_SLSQP"

  g_eq <- function(x) {
    w <- x[-1]
    cts <- jac <- NULL
    if (!is.null(lin_eq)) {
      cts <- lin_eq %*% w - lin_eqC
      jac <- lin_eq
    }
    if (!is.null(nlin_eq)) {
      res <- nlin_eq(w)
      cts <- c(cts, res$constraints)
      jac <- rbind(jac, res$jacobian)
    }
    if (!is.null(cts)) jac <- cbind(0, jac)
    list(constraints = cts, jacobian = jac)
  }

  if (is.null(href)) {
    objw0 <- NULL
    fn <- function(w) NULL
  } else {
    if (is.function(href)) {
      fn <- href
    } else {
      if (href == "TEvol" && !("wref" %in% names(param))) param <- list(wref = w0)
      fn <- .mvsk_get_href(href, m1, M2, M3, M4, param)
    }
    fn0   <- fn(w0)$objective
    objw0 <- if (relative) (1 + sign(fn0) * kappa) * fn0 else fn0 + kappa
  }

  mw0 <- .mvsk_getmom(indmom, w0, m1, M2, M3, M4)
  sgm <- if (is.null(mompref)) c(-1, 1, -1, 1)[indmom] else -mompref

  g_ineq <- function(x) {
    delta <- x[1]
    w     <- x[-1]
    objRtemp <- fn(w)
    if (is.numeric(g)) {
      gf   <- delta * g
      gfgr <- g
    } else {
      gtmp <- g(delta)
      gf   <- gtmp$objective
      gfgr <- gtmp$gradient
    }
    mw  <- .mvsk_getmom(indmom, w, m1, M2, M3, M4)
    obj <- sgm * (mw - mw0) + gf
    obj <- c(obj, objRtemp$objective - objw0)
    momgr <- .mvsk_getmomgr(indmom, w, m1, M2, M3, M4)
    momgr <- rbind(cbind(gfgr, momgr * sgm), c(0, objRtemp$gradient))

    cts <- jac <- NULL
    if (!is.null(lin_ieq)) {
      cts <- lin_ieq %*% w - lin_ieqC
      jac <- lin_ieq
    }
    if (!is.null(nlin_ieq)) {
      res <- nlin_ieq(w)
      cts <- c(cts, res$constraints)
      jac <- rbind(jac, res$jacobian)
    }
    if (!is.null(jac)) jac <- cbind(0, jac)
    cts <- c(obj, cts)
    jac <- rbind(momgr, jac)[seq_along(cts), , drop = FALSE]
    list(constraints = cts, jacobian = jac)
  }

  fobj <- function(x) {
    gr <- rep(0, length(x))
    gr[1] <- -1
    list(objective = -x[1], gradient = gr)
  }

  sol <- nloptr::nloptr(x0 = c(0, w0), eval_f = fobj, lb = c(-1, lb), ub = c(1, ub),
                        eval_g_eq = g_eq, eval_g_ineq = g_ineq, opts = options)
  .mvsk_check_status(sol, paste0("tilting problem at kappa = ", signif(kappa, 4)))

  list(w      = sol$solution[-1],
       delta  = sol$solution[1],
       moms   = .mvsk_getmom(indmom, sol$solution[-1], m1, M2, M3, M4),
       constr = sol$eval_g_ineq(sol$solution)$constraints,
       status = sol$status)
}


#' Higher-Moment Efficient Portfolios
#'
#' Tilts a reference portfolio towards more preferable moments — lower
#' variance, higher skewness, lower kurtosis and optionally higher mean — while
#' allowing the reference criterion to deteriorate by at most a margin
#' \code{kappa}. This implements the algorithmic tilting of
#' Boudt, Cornilly, Van Holle & Willems (2020).
#'
#' @param m1 Numeric vector of expected returns, or \code{NULL} to leave the
#'   mean out of the tilting.
#' @param M2 Numeric \eqn{d \times d} covariance matrix.
#' @param M3 Numeric \eqn{d \times d^2} coskewness matrix, as returned by
#'   \code{PerformanceAnalytics::M3.MM()}, or \code{NULL}.
#' @param M4 Numeric \eqn{d \times d^3} cokurtosis matrix, as returned by
#'   \code{PerformanceAnalytics::M4.MM()}, or \code{NULL}.
#' @param w0 Reference portfolio: either a numeric weight vector, or the name of
#'   a criterion to solve for it — \code{"DR"} (most diversified),
#'   \code{"ERC"} (equal risk contribution), \code{"HI"} / \code{"EW"}
#'   (equally weighted), \code{"EU"} (expected utility, needs
#'   \code{param$gamma}) or \code{"TEvol"}. Defaults to equal weights.
#' @param g Direction of moment improvement: a numeric vector, a function of
#'   \code{delta}, or one of \code{"mvsk"} / \code{"vsk"} to derive it from the
#'   reference portfolio's own moments.
#' @param lb,ub Lower and upper bounds for the weights. Default \code{0} and
#'   \code{1}.
#' @param lin_eq,lin_eqC Linear equality constraints \eqn{A w = b}. Default is
#'   the full-investment constraint.
#' @param nlin_eq Function returning non-linear equality constraints and their
#'   Jacobian.
#' @param lin_ieq,lin_ieqC Linear inequality constraints \eqn{A w \le b}.
#' @param nlin_ieq Function returning non-linear inequality constraints and
#'   their Jacobian.
#' @param href Reference criterion held in check while tilting: a name (as for
#'   \code{w0}) or a function.
#' @param kappa Numeric vector of margins by which \code{href} may deteriorate.
#' @param relative Logical: is \code{kappa} relative rather than absolute?
#' @param param List of extra arguments for the \code{href} function, such as
#'   \code{gamma} for \code{"EU"} or \code{wref} for \code{"TEvol"}.
#' @param options List of \pkg{nloptr} options.
#' @param mompref Direction of preference per moment (\code{+1} higher,
#'   \code{-1} lower). Defaults to higher mean and skewness, lower variance and
#'   kurtosis.
#'
#' @return A list with the tilted \code{weights} (one row per \code{kappa}),
#'   the achieved improvement \code{delta}, the resulting portfolio
#'   \code{moms}, the constraint values \code{constr}, and the solver
#'   \code{status} for each margin.
#'
#' @details
#' The co-moment matrices must be in the \strong{matrix} form returned by
#' \code{PerformanceAnalytics::M3.MM(x)} and \code{M4.MM(x)} with the default
#' \code{as.mat = TRUE}. If you hold the compact vector form, convert it first
#' with \code{PerformanceAnalytics::M3.vec2mat()} and \code{M4.vec2mat()}.
#'
#' \code{delta} is the largest improvement attainable within the margin. It is
#' non-decreasing in \code{kappa} — a wider margin never shrinks the feasible
#' set — but it need not increase strictly, and at \code{kappa = 0} it is zero
#' only up to solver tolerance.
#'
#' @section Provenance:
#' This function is a port of \code{mvskPortfolio()} from the
#' \strong{mvskPortfolios} package by Dries Cornilly and Kris Boudt
#' (\url{https://github.com/cdries/mvskPortfolios}), redistributed here under
#' the same GPL (\eqn{\ge 2}) licence so that the book's examples install from
#' CRAN alone. The algorithm is unchanged; the internal calls to non-exported
#' \pkg{PerformanceAnalytics} symbols have been replaced by the equivalent
#' helpers of this package, and the solver status is now reported.
#'
#' @references
#' Boudt, K., Cornilly, D., Van Holle, F., & Willems, J. (2020). Algorithmic
#' portfolio tilting to harvest higher moment gains. \emph{Heliyon}, 6(3).
#'
#' Briec, W., Kerstens, K., & Jokung, O. (2007). Mean-variance-skewness
#' portfolio performance gauging: a general shortage function and dual
#' approach. \emph{Management Science}, 53(1), 135–149.
#'
#' Choueifaty, Y., & Coignard, Y. (2008). Toward maximum diversification.
#' \emph{Journal of Portfolio Management}, 35(1), 40–51.
#'
#' @author Dries Cornilly and Kris Boudt, ported by David Ardia.
#'
#' @seealso \code{\link{f_ptf_max_U}}, \code{\link{f_portfolio_moments}}
#'
#' @examples
#' if (requireNamespace("PerformanceAnalytics", quietly = TRUE)) {
#'   data(edhec, package = "PerformanceAnalytics")
#'   x  <- edhec[, 1:5]
#'   M2 <- stats::cov(x)
#'   M3 <- PerformanceAnalytics::M3.MM(x)
#'   M4 <- PerformanceAnalytics::M4.MM(x)
#'
#'   res <- f_mvsk_portfolio(M2 = M2, M3 = M3, M4 = M4, w0 = "DR",
#'                           g = "vsk", href = "DR",
#'                           kappa = c(0, 0.005, 0.01))
#'   round(100 * res$weights, 2)
#'   res$delta
#' }
#'
#' @importFrom nloptr nloptr
#' @export
f_mvsk_portfolio <- function(m1 = NULL, M2 = NULL, M3 = NULL, M4 = NULL,
                             w0 = NULL, g = NULL, lb = NULL, ub = NULL,
                             lin_eq = NULL, lin_eqC = NULL, nlin_eq = NULL,
                             lin_ieq = NULL, lin_ieqC = NULL, nlin_ieq = NULL,
                             href = NULL, kappa = NULL, relative = FALSE,
                             param = NULL, options = list(), mompref = NULL) {

  ## --- input validation ------------------------------------------------------
  if (is.null(M2) || !is.numeric(M2) || !is.matrix(M2) || nrow(M2) != ncol(M2))
    stop("'M2' must be a square numeric covariance matrix.", call. = FALSE)
  p <- nrow(M2)
  if (any(!is.finite(M2)))
    stop("'M2' must contain only finite values.", call. = FALSE)
  if (max(abs(M2 - t(M2))) > sqrt(.Machine$double.eps) * max(1, max(abs(diag(M2)))))
    stop("'M2' must be symmetric.", call. = FALSE)
  if (!is.null(m1) && (!is.numeric(m1) || length(m1) != p || any(!is.finite(m1))))
    stop("'m1' must be a finite numeric vector of length ", p, ".", call. = FALSE)
  if (!is.null(M3) && (!is.numeric(M3) || !is.matrix(M3) ||
                       nrow(M3) != p || ncol(M3) != p^2))
    stop("'M3' must be a numeric ", p, " x ", p^2, " coskewness matrix, as ",
         "returned by PerformanceAnalytics::M3.MM() with as.mat = TRUE.",
         call. = FALSE)
  if (!is.null(M4) && (!is.numeric(M4) || !is.matrix(M4) ||
                       nrow(M4) != p || ncol(M4) != p^3))
    stop("'M4' must be a numeric ", p, " x ", p^3, " cokurtosis matrix, as ",
         "returned by PerformanceAnalytics::M4.MM() with as.mat = TRUE.",
         call. = FALSE)

  ## --- defaults --------------------------------------------------------------
  if (is.null(lin_eq) || is.null(lin_eqC)) {
    lin_eq  <- matrix(1, nrow = 1, ncol = p)
    lin_eqC <- 1
  }
  if (is.null(lb)) lb <- rep(0, p)
  if (is.null(ub)) ub <- rep(1, p)
  if (sum(ub) < 1 - 1e-10)
    stop("the upper bounds cannot sum to less than one; the full-investment ",
         "constraint would be infeasible.", call. = FALSE)

  ## --- reference portfolio ---------------------------------------------------
  if (is.null(w0)) w0 <- rep(1 / p, p)
  if (!is.numeric(w0)) {
    w0 <- .mvsk_solvePortfolio(p, w0, m1, M2, M3, M4, lb, ub, lin_eq, lin_eqC,
                               nlin_eq, lin_ieq, lin_ieqC, nlin_ieq, options, param)
  }

  ## --- direction of improvement ----------------------------------------------
  indmom <- !c(is.null(m1), is.null(M2), is.null(M3), is.null(M4))
  if (is.null(g)) g <- abs(.mvsk_getmom(indmom, w0, m1, M2, M3, M4))
  if (is.character(g) && g[1] %in% c("mvsk", "vsk")) {
    g <- abs(.mvsk_getmom(indmom, w0, m1, M2, M3, M4))
    if (indmom[1]) g[1] <- 0
  }

  ## --- solve -----------------------------------------------------------------
  if (is.null(href)) {
    out <- .mvsk_solveMVSK(p, w0, g, m1, M2, M3, M4, indmom, lb, ub, lin_eq,
                           lin_eqC, nlin_eq, lin_ieq, lin_ieqC, nlin_ieq,
                           options, NULL, 0, FALSE, NULL, mompref)
    list(weights = out$w, delta = out$delta, moms = out$moms,
         constr = out$constr, status = out$status)
  } else {
    if (is.null(kappa)) kappa <- 0
    n_k    <- length(kappa)
    wopt   <- matrix(NA_real_, nrow = n_k, ncol = p)
    delta  <- rep(NA_real_, n_k)
    status <- rep(NA_integer_, n_k)
    moms   <- matrix(NA_real_, nrow = n_k, ncol = sum(indmom))
    constr <- NULL
    for (ii in seq_len(n_k)) {
      eff <- .mvsk_solveMVSK(p, w0, g, m1, M2, M3, M4, indmom, lb, ub, lin_eq,
                             lin_eqC, nlin_eq, lin_ieq, lin_ieqC, nlin_ieq,
                             options, href, kappa[ii], relative, param, mompref)
      wopt[ii, ]  <- eff$w
      delta[ii]   <- eff$delta
      moms[ii, ]  <- eff$moms
      status[ii]  <- eff$status
      constr      <- rbind(constr, eff$constr)
    }
    colnames(wopt) <- colnames(M2)
    list(weights = wopt, delta = delta, moms = moms,
         constr = constr, status = status)
  }
}
