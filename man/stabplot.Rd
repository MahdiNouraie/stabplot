% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Regustab.R
\docType{package}
\name{stabplot}
\alias{-package}
\alias{stabplot}
\alias{selection_matrix}
\title{stabplot: Stability Plots for Evaluating Stability Selection}
\usage{
Regustab(x, y, B)

Convstab(x, y, B)
}
\description{
This package contains two functions: `Regustab` and `Convstab`.
The `Regustab` function generates a plot showing the relationship between stability values and regularization parameters for LASSO, aiding in the process of regularization tuning via stability selection.
The `Convstab` function creates a plot of stability values against index of the iterative sub-sampling, helping to monitor the convergence of stability values over time.
`Regustab` also prints the values of highlighted regularization parameters on the plot (`lambda.min`, `lambda.1se`, `lambda.stable` if applicable, otherwise, `lambda.stable.1sd`).
`Convstab` also prints the variables with selection frequencies above a specified threshold (default threshold = 0.5).
}
\references{
Meinshausen, N., & Bühlmann, P. (2010). Stability selection. Journal of the Royal Statistical Society Series B: Statistical Methodology, 72(4), 417-473.

Nogueira, S., Sechidis, K., & Brown, G. (2018). On the stability of feature selection algorithms. Journal of Machine Learning Research, 18(174), 1-54.

https://github.com/nogueirs/JMLR2018

Tibshirani, R. (1996). Regression shrinkage and selection via the lasso. Journal of the Royal Statistical Society Series B: Statistical Methodology, 58(1), 267-288.
}
\seealso{
\link[=Regustab]{Regustab}, \link[=Convstab]{Convstab}
}
\author{
Mahdi Nouraie (mahdinouraie20@gmail.com)
}
