#' FRED-MD Macro Factors and Dow Jones Returns (Monthly, 2015–2019)
#'
#' A list containing a matrix of 128 FRED-MD macroeconomic predictors and a
#' vector of monthly Dow Jones Industrial Average log-returns, aligned over the
#' period 2015-01 to 2019-12. Used to illustrate high-dimensional regularised
#' regression (Lasso, Ridge) in a return-prediction context.
#'
#' @format A named list with two components:
#' \describe{
#'   \item{X}{A \eqn{60 \times 128}{60 x 128} numeric matrix of standardised
#'     FRED-MD macro variables (monthly, January 2015 to December 2019).
#'     Row names are \code{"YYYY-MM-01"} strings; column names are FRED-MD
#'     series codes (e.g., \code{"INDPRO"}, \code{"CPIAUCSL"}, \code{"GS10"}).
#'     The series have been transformed (differenced or log-differenced) to
#'     achieve stationarity following the FRED-MD transformation codes.}
#'   \item{y}{A \eqn{60 \times 1}{60 x 1} numeric matrix of one-month-ahead
#'     Dow Jones Industrial Average log-returns (column name
#'     \code{"DJI.Adjusted"}), shifted so that row \eqn{t} of \code{X}
#'     predicts row \eqn{t} of \code{y}.}
#' }
#'
#' @details
#' The predictors in \code{X} were downloaded from the McCracken–Ng FRED-MD
#' database and transformed according to the recommended stationarity codes.
#' The target \code{y} was obtained from Yahoo Finance via
#' \code{quantmod::getSymbols("^DJI")} and converted to monthly log-returns.
#' Both series are restricted to the 60-month window 2015-01 to 2019-12 and
#' temporally aligned so that \code{X[t, ]} can be used to predict
#' \code{y[t]}.
#'
#' @source
#' \itemize{
#'   \item McCracken, M. W., & Ng, S. FRED-MD database,
#'     \url{https://www.stlouisfed.org/research/economists/mccracken/fred-databases}.
#'   \item Dow Jones daily prices via \code{quantmod::getSymbols("^DJI")},
#'     Yahoo Finance.
#' }
#'
#' @references
#' McCracken, M. W., & Ng, S. (2016). FRED-MD: A Monthly Database for
#' Macroeconomic Research. \emph{Journal of Business & Economic Statistics},
#' 34(4), 574–589.
#'
#' @examples
#' data("Fred")
#' X <- Fred$X   # 60 x 128 macro predictors
#' y <- Fred$y   # 60 x 1  DJ log-returns
#' dim(X)
#' head(rownames(X))
#'
#' # Lasso with cross-validation (requires glmnet)
#' if (requireNamespace("glmnet", quietly = TRUE)) {
#'   set.seed(1234)
#'   fit <- glmnet::cv.glmnet(X, y, alpha = 1)
#'   coef(fit, s = "lambda.min")[coef(fit, s = "lambda.min")[,1] != 0, , drop = FALSE]
#' }
#'
#' @seealso The book chapter on \emph{Dimension Reduction} (Chapter 4 of
#'   \emph{Statistical Methods in Quantitative Finance}) introduces Lasso and
#'   Ridge regression on the lower-dimensional \code{\link{GoyalWelch}} dataset;
#'   \code{Fred} provides a complementary high-dimensional (\eqn{p \gg n}) test
#'   bed for the same regularised-regression workflow.
#'
#' @usage data("Fred")
#' @docType data
#' @keywords datasets macro-economics finance regularisation
"Fred"
