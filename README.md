# stabplot

`stabplot` is an R package designed to facilitate regularization tuning and convergence monitoring in stability selection using LASSO. It provides two core functions, `Regustab` and `Convstab`, which help visualize stability in regularized models, supporting users in selecting appropriate regularization parameters and assessing convergence.

## Installation

You can install the latest version of `stabplot` from GitHub:

```r
# install.packages("devtools")  # Uncomment if you haven't installed devtools
devtools::install_github("MahdiNouraie/stabplot")

# library(stabplot) #loading the insttalled libarary
```
`Regustab` function creates a plot that displays stability values in relation to regularization values for LASSO through stability selection. The plot highlights key lambda values, including `lambda.min`, `lambda.1se`, and `lambda.stable`. If `lambda.stable` is not available, the function will display `lambda.stable.1sd` 
A toy example of usage:
```r
instead.set.seed(123)
x <- matrix(rnorm(1000), ncol = 10)
# create beta based on the first 3 columns of x and some error
beta <- c(1, 2, 3, rep(0, 7))
y <- x %*% beta + rnorm(100)
B <- 10
Regustab(x, y, B)
```

![Regustab Example](man/Regustab.png)














