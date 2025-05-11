#' @docType package
#' @name stabplot
#' @title stabplot: Stability Plots for Evaluating Stability Selection
#' @description
#' This package contains two functions: `Regustab` and `Convstab`.
#' The `Regustab` function generates a plot showing the relationship between stability values and regularization parameters for LASSO, aiding in the process of regularization tuning via stability selection.
#' The `Convstab` function creates a plot of stability values against index of the iterative sub-sampling, helping to monitor the convergence of stability values over time.
#' `Regustab` also prints the values of highlighted regularization parameters on the plot (`lambda.min`, `lambda.1se`, `lambda.stable` if applicable, otherwise, `lambda.stable.1sd`).
#' `Convstab` also prints the variables with selection frequencies above a specified threshold (default threshold = 0.5).
#' @usage Regustab(x, y, B)
#' @usage Convstab(x, y, B)
#' @author Mahdi Nouraie (mahdinouraie20@gmail.com)
#' @references
#' Meinshausen, N., & Bühlmann, P. (2010). Stability selection. Journal of the Royal Statistical Society Series B: Statistical Methodology, 72(4), 417-473.
#'
#' Nogueira, S., Sechidis, K., & Brown, G. (2018). On the stability of feature selection algorithms. Journal of Machine Learning Research, 18(174), 1-54.
#'
#' https://github.com/nogueirs/JMLR2018
#'
#' Tibshirani, R. (1996). Regression shrinkage and selection via the lasso. Journal of the Royal Statistical Society Series B: Statistical Methodology, 58(1), 267-288.
#'
#' @seealso \link[=Regustab]{Regustab}, \link[=Convstab]{Convstab}


selection_matrix <- function(x, y, B){
  options(warn = -1) # Suppress warnings
  required_packages <- c("glmnet", "latex2exp", "ggplot2")
  for (pkg in required_packages) {
    if (!requireNamespace(pkg)) {
      install.packages(pkg)
    }
  }
  library(glmnet)
  library(latex2exp)
  p <- ncol(x) # Number of predictors
  cv_lasso <- cv.glmnet(x, y, nfolds = 10, alpha = 1) # Fit LASSO model with 10-fold CV
  candidate_set <- cv_lasso$lambda # Candidate set of lambda values
  S_list <- vector("list", length(candidate_set)) # Initialize a list to store selection matrix for each lambda
  names(S_list) <- paste0("lambda_", seq_along(candidate_set)) # Name the list entries
  data <- cbind(y, x) # Combine response and predictors into a single data frame

  for (lambda_idx in seq_along(candidate_set)) { # Stability Selection for each lambda in candidate_set

    lambda <- candidate_set[lambda_idx]  # Current lambda value
    S <- matrix(0, nrow = B, ncol = p)  # Initialize selection matrix for the current lambda
    colnames(S) <- colnames(x) # Set column names of S to predictor names

    for (i in 1:B) {
      # Sub-sample the data (half of the original data without replacement)
      model_data <- data[sample(1:nrow(data), nrow(data) / 2, replace = FALSE), ]

      # Prepare the response and predictors
      x_sub <- as.matrix(model_data[, -1]) # Exclude the response variable
      y_sub <- model_data[,1] # Response variable

      # Fit the LASSO model with the current lambda
      lasso_model <- glmnet(x_sub, y_sub, alpha = 1, lambda = lambda)

      # Extract significant predictors (ignoring the intercept, hence [-1])
      significant_predictors <- ifelse(coef(lasso_model) != 0, 1, 0)[-1]

      # Store the significant predictors in matrix S
      S[i, ] <- significant_predictors
    }

    # Store the matrix S for the current lambda in the corresponding list entry
    S_list[[lambda_idx]] <- S
  }
  return(list("S_list" = S_list, "candidate_set" = candidate_set, "cv_lasso" = cv_lasso))
}


# Stability measure (2018) from "https://github.com/nogueirs/JMLR2018/blob/master/R/getStability.R"
getStability <- function(X,alpha=0.05) {
  ## the input X is a binary matrix of size M*d where:
  ## M is the number of bootstrap replicates
  ## d is the total number of features
  ## alpha is the level of significance (e.g. if alpha=0.05, we will get 95% confidence intervals)
  ## it's an optional argument and is set to 5% by default
  ### first we compute the stability

  M<-nrow(X)
  d<-ncol(X)
  hatPF<-colMeans(X)
  kbar<-sum(hatPF)
  v_rand=(kbar/d)*(1-kbar/d)
  stability<-1-(M/(M-1))*mean(hatPF*(1-hatPF))/v_rand ## this is the stability estimate

  ## then we compute the variance of the estimate
  ki<-rowSums(X)
  phi_i<-rep(0,M)
  for(i in 1:M){
    phi_i[i]<-(1/v_rand)*((1/d)*sum(X[i,]*hatPF)-(ki[i]*kbar)/d^2-(stability/2)*((2*kbar*ki[i])/d^2-ki[i]/d-kbar/d+1))
  }
  phi_bar=mean(phi_i)
  var_stab=(4/M^2)*sum((phi_i-phi_bar)^2) ## this is the variance of the stability estimate

  ## then we calculate lower and upper limits of the confidence intervals
  z<-qnorm(1-alpha/2) # this is the standard normal cumulative inverse at a level 1-alpha/2
  upper<-stability+z*sqrt(var_stab) ## the upper bound of the (1-alpha) confidence interval
  lower<-stability-z*sqrt(var_stab) ## the lower bound of the (1-alpha) confidence interval

  return(list("stability"=stability,"variance"=var_stab,"lower"=lower,"upper"=upper))

}

#' Regustab
#'
#' This function creates a plot that displays stability values in relation to regularization values for LASSO through stability selection.
#' The plot highlights key lambda values, including `lambda.min`, `lambda.1se`, and `lambda.stable`. If `lambda.stable` is not available, the function will display `lambda.stable.1sd` instead. Regustab also prints the values of highlighted regularization values on the plot (`lambda.min`, `lambda.1se`, and `lambda.stable` or `lambda.stable.1sd`).
#'
#' @import glmnet
#' @import latex2exp
#' @param x A numeric matrix of predictors.
#' @param y A numeric vector of response values.
#' @param B An integer specifying the number of sub-samples.
#'
#' @return A plot displaying the relationship between lambda values and stability. `Regustab` also prints the values of `lambda.min`, `lambda.1se`, and `lambda.stable`. If `lambda.stable` is not available, the function will display `lambda.stable.1sd` instead.
#' @examples
#' \dontrun{
#' set.seed(123)
#' x <- matrix(rnorm(1000), ncol = 10)
#' # create beta based on the first 3 columns of x and some error
#' beta <- c(1, 2, 3, rep(0, 7))
#' y <- x %*% beta + rnorm(100)
#' B <- 10
#' Regustab(x, y, B)  # Example usage of the Regustab function
#' #output
#' $min
#' [1] 0.07609021
#' $`1se`
#' [1] 0.2550241
#' $stable
#' [1] 0.3371269
#'
#'}
#'
#' @references
#' Meinshausen, N., & Bühlmann, P. (2010). Stability selection. Journal of the Royal Statistical Society Series B: Statistical Methodology, 72(4), 417-473.
#'
#' Nogueira, S., Sechidis, K., & Brown, G. (2018). On the stability of feature selection algorithms. Journal of Machine Learning Research, 18(174), 1-54.
#'
#' https://github.com/nogueirs/JMLR2018
#'
#' Tibshirani, R. (1996). Regression shrinkage and selection via the lasso. Journal of the Royal Statistical Society Series B: Statistical Methodology, 58(1), 267-288.
#'
#' @seealso \link[=stabplot]{stabplot}
#' @export

Regustab <- function(x, y, B){
  options(warn = -1) # Suppress warnings
  SM <- selection_matrix(x, y, B)
  sel_mats <- SM$S_list
  stability_results <- lapply(sel_mats, getStability)
  stab_values <- unlist(lapply(stability_results, function(x) x$stability))
  candidate_set <- SM$candidate_set
  cv_lasso <- SM$cv_lasso

  par(mgp = c(2.2, 0.6, 0))  # Adjust the second value to control title spacing
  plot(candidate_set, stab_values, type = "l", col = "blue", lwd = 2,
       xlab = TeX("Regularisation Value ($\\lambda$)"),
       ylab = TeX("Stability ($\\hat{\\Phi}$)"),
       main = TeX("Stability vs. Regularisation Value"),
       cex.lab = 1.5, # Increase axis title size
       cex.main = 1.8, # Increase main title size
       ylim = c(0, 1)) # Plot stability values against lambda values
  abline(h = 0.75, col = "red", lty = 5)  # Add a horizontal line at stability = 0.75
  abline(h = 0.4, col = "red", lty = 5)  # Add a horizontal line at stability = 0.4

  index_of_min <- which(candidate_set == cv_lasso$lambda.min) # Index of lambda.min
  points(candidate_set[index_of_min], stab_values[index_of_min],
         col = "red", pch = 19, cex = 2) # Show by red dot index_of_min and stab_values[index_of_min] on the plot
  text(candidate_set[index_of_min], stab_values[index_of_min],
       "min", pos = 1, col = "red", cex = 1.5) # Add text for lambda.min

  index_of_1se <- which(candidate_set == cv_lasso$lambda.1se) # Index of lambda.1se
  points(candidate_set[index_of_1se], stab_values[index_of_1se],
         col = "red", pch = 19, cex = 2) # Show by red dot index_of_1se and stab_values[index_of_1se] on the plot
  text(candidate_set[index_of_1se], stab_values[index_of_1se], "1se",
       pos = 1, col = "red", cex = 1.5) # Add text for lambda.1se
  if (max(stab_values, na.rm = TRUE) >= 0.75){
  stable_values <- which(stab_values > 0.75) # Index of stable lambda values
  lambda_stable <- min(candidate_set[stable_values]) # Minimum stable lambda value
  index_of_lambda_stable <- which(candidate_set == lambda_stable) # Index of lambda_stable
  points(candidate_set[index_of_lambda_stable], stab_values[index_of_lambda_stable],
         col = "red", pch = 19, cex = 2) # Show by red dot index_of_lambda_stable and stab_values[index_of_lambda_stable] on the plot
  text(candidate_set[index_of_lambda_stable], stab_values[index_of_lambda_stable],
       "stable", pos = 1, col = "red", cex = 1.5) # Add text for lambda_stable
  print(list('min' = cv_lasso$lambda.min, '1se' = cv_lasso$lambda.1se, 'stable' = lambda_stable))
  }
  else{
    max_stability <- max(stab_values, na.rm = TRUE) # Find the maximum stability value
    stability_1sd_threshold <- max_stability - sd(stab_values, na.rm = TRUE) # Define the stability threshold as max stability - 1SD
    index_of_stable_1sd <- max(which(stab_values >= stability_1sd_threshold), na.rm = TRUE) # since candidate values are sorted decreasingly,
    #we take the last index to get the minimum value
    points(candidate_set[index_of_stable_1sd], stab_values[index_of_stable_1sd],
           col = "red", pch = 19, cex = 2) # Show by red dot index_of_stable_1sd and stab_values[index_of_stable_1sd] on the plot
    text(candidate_set[index_of_stable_1sd], stab_values[index_of_stable_1sd],
         "stable.1sd", pos = 1, col = "red", cex = 1.5) # Add text for stable.1sd
    print(list('min' = cv_lasso$lambda.min, '1se' = cv_lasso$lambda.1se, 'stable.1sd' = candidate_set[index_of_stable_1sd]))

  }
}
