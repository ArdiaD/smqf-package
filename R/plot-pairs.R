#' Pairwise Scatter and Histogram Matrix for Asset Returns
#'
#' Produces a grid of pairwise scatterplots and univariate histograms
#' for a multivariate return series. The off-diagonal panels show scatterplots
#' of each pair of return series; the diagonal panels show histograms of
#' individual series.
#'
#' @param rets Numeric matrix or data frame of dimension \eqn{T \times N}
#'   containing returns of \eqn{N} assets over \eqn{T} time periods.
#'   Each column represents one asset or variable. Column names are used in plot titles.
#'
#' @details
#' The function arranges an \eqn{N \times N} grid of panels:
#' \itemize{
#'   \item Off-diagonal panels: scatterplots of \code{rets[, i]} (x-axis)
#'         versus \code{rets[, j]} (y-axis).
#'   \item Diagonal panels: histograms of individual return series.
#' }
#' The number of histogram bins is chosen as \eqn{\mathrm{round}(10 \log T)}.
#'
#' The graphical layout is set with \code{par(mfrow = c(N, N))} and margin
#' adjustment; all plots use blue points or bars. The previous \code{par()}
#' settings are saved on entry and automatically restored on exit via
#' \code{on.exit()}.
#'
#' @return Invisibly returns \code{NULL}. Used for its side-effect of producing a multi-panel plot.
#'
#' @examples
#' set.seed(1)
#' X <- matrix(rnorm(200 * 3, sd = 0.01), ncol = 3)
#' colnames(X) <- c("Asset1", "Asset2", "Asset3")
#' f_plot_pairs(X)
#'
#' @seealso [graphics::pairs()]
#' @importFrom graphics par plot.default hist title box
#' @export
f_plot_pairs <- function(rets) {
  # Create pairs plots for multiple time series
  # INPUTS
  #  rets : [matrix/data.frame] (T x N) returns

  Dim <- dim(rets)
  T   <- Dim[1]
  N   <- Dim[2]

  nbins   <- round(10 * log(T))
  old_par <- par(mar = c(3, 2, 1.5, 1), mfrow = c(N, N))
  on.exit(par(old_par), add = TRUE)

  for (i in 1:N) {
    for (j in 1:N) {
      if (i != j) {
        plot.default(
          rets[, i], rets[, j],
          type = "p",
          col = "blue",
          xlab = paste0(i),
          ylab = paste0(j),
          pch = 19,
          tck = 0
        )
        title(main = paste0(names(rets)[i], " vs. ", names(rets)[j]))
      } else {
        hist(
          rets[, j],
          breaks = nbins,
          main = "",
          col = "blue",
          tck = 0
        )
        title(main = names(rets)[i])
        box()
      }
    }
  }

  invisible(NULL)
}
