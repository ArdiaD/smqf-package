#include<Rcpp.h>

// [[Rcpp::export]]

double f_add_c(double x, double y) {
  double value = x + y;
  return value;
}