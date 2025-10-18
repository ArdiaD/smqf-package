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
#' @param type Integer indicating the plotting method:
#'   \describe{
#'     \item{1}{(default) Static 3D surface plot via \code{persp()}.}
#'     \item{2}{Interactive 3D plot via \code{rgl::persp3d()}.}
#'   }
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
#'   grid_2 = grid,
#'   type = 1
#' )
#'
#' @importFrom rgl persp3d
#' @export
f_display_copula <- function(my_copula, grid_1, grid_2, type = 1) {

  n_mesh <- length(grid_1)

  f_U <- matrix(NA, n_mesh, n_mesh)
  for (j in 1:n_mesh) {
    for (k in 1:n_mesh) {
      u <- c(grid_1[j], grid_2[k])
      f_U[j, k] <- my_copula(u)
    }
  }

  if (type == 1) {
    persp(
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
  }

  if (type == 2) {
    persp3d(x = grid_1, y = grid_2, z = f_U, add = FALSE)
  }

  invisible(f_U)
}

# f_display_copula <- function(
#     my_copula,
#     grid_1,
#     grid_2,
#     type = 1,
#     zlab = "Value",
#     col = NULL,
#     transform = NULL,   # e.g., function(z) log1p(z)
#     ...
# ) {
#   # ---- validate -------------------------------------------------------------
#   if (!is.function(my_copula)) stop("`my_copula` must be a function.", call. = FALSE)
#   if (!is.numeric(grid_1) || !is.numeric(grid_2)) stop("`grid_1` and `grid_2` must be numeric vectors.", call. = FALSE)
#   if (any(!is.finite(grid_1)) || any(!is.finite(grid_2))) stop("Grids must be finite.", call. = FALSE)
#   if (any(grid_1 <= 0 | grid_1 > 1) || any(grid_2 <= 0 | grid_2 > 1))
#     warning("Grid values should lie in (0,1] for copula evaluation.", call. = FALSE)
#   if (!identical(grid_1, sort(grid_1)) || !identical(grid_2, sort(grid_2)))
#     warning("Grids are not sorted increasingly; reordering may flip axes.", call. = FALSE)
#
#   # ---- evaluate (vectorized) -----------------------------------------------
#   # Wrap the copula so outer() can apply it to two vectors
#   f2 <- function(u1, u2) my_copula(c(u1, u2), ...)
#   f2v <- Vectorize(f2)
#   f_U <- outer(grid_1, grid_2, f2v)  # matrix [length(grid_1) x length(grid_2)]
#
#   # Optional visualization transform (for spiky densities)
#   z <- f_U
#   if (is.null(transform)) {
#     # default: identity
#   } else {
#     if (!is.function(transform)) stop("`transform` must be a function or NULL.", call. = FALSE)
#     z <- transform(z)
#     if (!is.numeric(z) || any(!is.finite(z))) stop("`transform` produced non-finite values.", call. = FALSE)
#   }
#
#   # ---- plotting -------------------------------------------------------------
#   if (type == 1) {
#     # base persp
#     if (is.null(col)) col <- "lightgray"
#     persp(
#       x = grid_1, y = grid_2, z = z,
#       xlab = "U_1", ylab = "U_2", zlab = zlab,
#       theta = 30, r = 20, col = col,
#       ticktype = "detailed", nticks = 5, expand = 0.6
#     )
#   } else if (type == 2) {
#     # rgl persp3d
#     if (!requireNamespace("rgl", quietly = TRUE))
#       stop("type=2 requires the 'rgl' package. Install it or choose another type.", call. = FALSE)
#     rgl::persp3d(x = grid_1, y = grid_2, z = z, col = if (is.null(col)) "gray80" else col, add = FALSE)
#   } else if (type == 3) {
#     # contour (2D)
#     contour(x = grid_1, y = grid_2, z = z, xlab = "U_1", ylab = "U_2", main = zlab)
#   } else if (type == 4) {
#     # heatmap (2D image)
#     image(x = grid_1, y = grid_2, z = z, xlab = "U_1", ylab = "U_2")
#     title(main = zlab)
#   } else {
#     stop("`type` must be one of {1=persp, 2=persp3d, 3=contour, 4=image}.", call. = FALSE)
#   }
#
#   invisible(f_U)  # return raw (untransformed) surface for downstream use
# }

