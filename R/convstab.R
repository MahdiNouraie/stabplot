source("R/regustab.R")

#' Convstab
#'
#' `Convstab` creates a plot displaying stability values along with confidence intervals, against the sequential sub-sampling index within stability selection. This plot aids in monitoring the convergence status of stability values.
#' The function uses `lambda.stable` to generate the plot; if `lambda.stable` is unavailable, it defaults to `lambda.stable.1sd`.
#'
#' @import ggplot2
#' @param x A numeric matrix of predictors.
#' @param y A numeric vector of response values.
#' @param B An integer specifying the number of sub-samples.
#' @param alpha A numeric value specifying the level of significance.
#' @param thr A numeric value specifying the threshold for selection frequency.
#'
#' @return A plot displaying the stability values and corresponding confidence interval through sequential sub-sampling. `Convstab` also prints the variables selected with a selection frequency greater than the threshold value.
#' @examples
#' \dontrun{
#' set.seed(123)
#' x <- matrix(rnorm(1000), ncol = 10)
#' # create beta based on the first 3 columns of x and some error
#' beta <- c(0.5, 0.4, 0.3, rep(0, 7))
#' y <- x %*% beta + rnorm(100)
#' B <- 200
#' Convstab(x, y, B)  # Example usage of the Convstab function
#' #output
#' #Variable Selection_Frequency
#' #1       x1               0.970
#' #2       x2               0.895
#'
#'}
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
#'
#' @export
Convstab <- function(x, y, B, alpha = 0.05, thr = 0.5){
  options(warn = -1) # Suppress warnings
  library(ggplot2)
  SM <- selection_matrix(x, y, B)
  sel_mats <- SM$S_list
  stability_results <- lapply(sel_mats, getStability)
  stab_values <- unlist(lapply(stability_results, function(x) x$stability))
  candidate_set <- SM$candidate_set
  cv_lasso <- SM$cv_lasso

  if (max(stab_values) >= 0.75){
    stable_values <- which(stab_values > 0.75) # Index of stable lambda values
    lambda_stable <- min(candidate_set[stable_values]) # Minimum stable lambda value
    index_of_lambda_stable <- which(candidate_set == lambda_stable) # Index of lambda_stable
    stability <- data.frame() # Initialize a data frame to store stability values
    Stable_S <- sel_mats[[index_of_lambda_stable]] # Stable selection matrix for lambda_stable
    for (k in 2:nrow(Stable_S)){ # loop through subsamples results
      output <- getStability(Stable_S[1:k,], alpha) # Compute stability values
      stability <- rbind(stability, data.frame(k, output$stability, output$variance, output$lower, output$upper)) # Append stability values to the data frame
    }
    colnames(stability) <- c('Iteration', 'Stability', 'Variance', 'Lower', 'Upper') # Set column names of the data frame
    colnames(Stable_S) <- paste0('x', 1:ncol(x))
    # Calculate selection frequencies
    col_means <- colMeans(Stable_S)
    # Filter columns with selection frequencies > 0.5 and print their names and means
    selected_cols <- col_means[col_means > thr]
    print(data.frame(Variable = names(selected_cols), Selection_Frequency = selected_cols, row.names = NULL))
    ggplot(stability, aes(x = Iteration, y = Stability)) +
      geom_line() +
      geom_ribbon(aes(ymin = Lower, ymax = Upper), fill = 'blue', alpha = 0.7) + # Add ribbon for confidence interval
      labs(title = TeX('Stability of Stability Selection ($\\lambda = \\lambda_{stable}$)'),
           x = 'Iteration (sub-sample)', y = TeX('Stability ($\\hat{\\Phi}$)'))+
      theme_bw() +
      theme(
        plot.title = element_text(size = 20),       # Title text size
        axis.title.x = element_text(size = 18),     # X-axis label size
        axis.title.y = element_text(size = 18),     # Y-axis label size
        axis.text.x = element_text(size = 16),      # X-axis tick text size
        axis.text.y = element_text(size = 16)       # Y-axis tick text size
      )
  }
  else{
    max_stability <- max(stab_values) # Find the maximum stability value
    stability_1sd_threshold <- max_stability - sd(stab_values) # Define the stability threshold as max stability - 1SD
    index_of_stable_1sd <- max(which(stab_values >= stability_1sd_threshold)) # since candidate_set is in decreasing order,
    #we find the index of the stable.1sd lambda value by maximum index
    stability <- data.frame() # Initialize an empty data frame to store stability values
    S_stable_1sd <- sel_mats[[index_of_stable_1sd]] # Extract the selection matrix for the stable.1sd lambda value
    for (k in 2:nrow(S_stable_1sd)){ # Loop through sub-samples results for lambda stable.1sd
      output <- getStability(S_stable_1sd[1:k,]) # Compute stability values
      stability <- rbind(stability, data.frame(k, output$stability, output$variance, output$lower, output$upper)) # Append stability values to the data frame
    }
    colnames(stability) <- c('Iteration', 'Stability', 'Variance', 'Lower', 'Upper') # Set column names of the data frame
    colnames(S_stable_1sd) <- paste0('x', 1:ncol(x))
    # Calculate selection frequencies
    col_means <- colMeans(S_stable_1sd)
    # Filter columns with selection frequencies > 0.5 and print their names and means
    selected_cols <- col_means[col_means > thr]
    print(data.frame(Variable = names(selected_cols), Selection_Frequency = selected_cols, row.names = NULL))
    ggplot(stability, aes(x = Iteration, y = Stability)) +
      geom_line() +
      geom_ribbon(aes(ymin = Lower, ymax = Upper), fill = 'blue', alpha = 0.7) + # Add ribbon for confidence interval
      labs(title = TeX('Stability of Stability Selection ($\\lambda = \\lambda_{stable.1sd}$)'),
           x = 'Iteration (sub-sample)', y = TeX('Stability ($\\hat{\\Phi}$)'))+
      theme_bw() +
      theme(
        plot.title = element_text(size = 20),       # Title text size
        axis.title.x = element_text(size = 18),     # X-axis label size
        axis.title.y = element_text(size = 18),     # Y-axis label size
        axis.text.x = element_text(size = 16),      # X-axis tick text size
        axis.text.y = element_text(size = 16)       # Y-axis tick text size
      )
  }
}



