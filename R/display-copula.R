#' Display a Bivariate Copula Surface
#'
#' Evaluates and displays a bivariate copula function (typically a PDF or CDF)
#' on a 2D grid, producing either a static 3D surface via base R's
#' [\code{persp()}] or an interactive 3D plot using the \pkg{rgl} package.
#'
#' @param my_copula A function that takes a numeric vector \code{c(u1, u2)} as input
#'   and returns a scalar value (e.g., a copula PDF or CDF).
#' @param grid_1,grid_2 Numeric vectors defining the evaluation grid for
#'   \eqn{u_1} and \eqn{u_2} in the interval \eqn{[0,1]}.
#'
#' @return Invisibly returns the matrix of evaluated copula values
#'   \code{f_U}, with rows corresponding to \code{grid_1} and columns to \code{grid_2}.
#'
#' @details
#' This function provides a simple way to visualize the surface of a bivariate
#' copula (e.g., Clayton, Gumbel, Gaussian). The copula function should accept a
#' vector of two uniform values \eqn{(u_1,u_2)} and return its density or CDF
#' value.
#'
#' @examples
#' # Example: Display the Clayton copula PDF surface
#' grid <- seq(0.05, 0.95, length.out = 25)
#' f_display_copula(
#'   my_copula = function(u) f_clayton_copula_2d_pdf(u, theta = 2),
#'   grid_1 = grid,
#'   grid_2 = grid
#' )
#'
#' @importFrom graphics persp
#' @export
f_display_copula <- function(my_copula, grid_1, grid_2) {

  n_mesh <- length(grid_1)

  f_U <- matrix(NA, n_mesh, n_mesh)
  for (j in 1:n_mesh) {
    for (k in 1:n_mesh) {
      u <- c(grid_1[j], grid_2[k])
      f_U[j, k] <- my_copula(u)
    }
  }

    graphics::persp(
      x = grid_1,
      y = grid_2,
      z = f_U,
      xlab = "U_1",
      ylab = "U_2",
      zlab = "Pdf",
      theta = 30,
      r = 20,
      col = "yellow",
      ticktype = "detailed",
      nticks = 4,
      expand = 0.5
    )

  invisible(f_U)
}



