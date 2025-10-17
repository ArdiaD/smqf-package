f_plot_pairs <- function(rets) {
  # Create pairs plots for multiple time series
  # INPUTS
  #  rets : [vector] (T x N) returns
  
  Dim <- dim(rets)
  T   <- Dim[1]
  N   <- Dim[2]
  
  nbins <- round(10 * log(T))
  par(mar = c(3,2,1.5,1))
  par(mfrow = c(N,N))
  for (i in 1:N) {
    for (j in 1:N) {
      if (i != j) {
        plot.default(rets[ ,i], rets[, j], type = "p", col = "blue", xlab = paste0(i), ylab = paste0(j), pch = 19, tck = 0) 
        title(main = paste0(names(rets)[i]," vs. ", names(rets)[j]))
       
      } else {
        hist(rets[,j], breaks = nbins, main = "", col = "blue", tck = 0)
        title(main = names(rets)[i])
        box()
      }
    }
  }
}