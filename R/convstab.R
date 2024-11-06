source("R/regustab.R")
library(ggplot2)

#' convstab
#'
#' This function produces a plot of stability values and corresponding confidence intercval through sequential sub-sampling of stability selection to facilitate monitoring the convergence status.
#'
#' @param x A numeric matrix of predictors.
#' @param y A numeric vector of response values.
#' @param B An integer specifying the number of sub-samples.
#' @param alpha A numeric value specifying the level of significance.
#'
#' @return A plot displaying the stability values and corresponding confidence interval through sequential sub-sampling.
#' @examples
#' \dontrun{
#' set.seed(123)
#' library(hdi)
#' data(riboflavin) # Load the riboflavin data
#' data <- as.data.frame(cbind(Y=riboflavin$y - 1, X=riboflavin$x)) # Convert the data to a data frame
#' rm(riboflavin) # Remove the original data to save memory
#' x <- as.matrix(data[, -1]) # Extract the predictors
#' y <- data[,1] # Extract the response
#' B = 100
#' convstab(x, y, B, alpha = 0.05)
#'}
#' @references
#' Meinshausen, N., & Bühlmann, P. (2010). Stability selection. Journal of the Royal Statistical Society Series B: Statistical Methodology, 72(4), 417-473.
#'
#' https://github.com/nogueirs/JMLR2018
#'
#' @export
convstab <- function(x, y, B, alpha = 0.05){
  sel_mats <- selection_matrix(x, y, B)$S_list
  stability_results <- lapply(sel_mats, getStability)
  stab_values <- unlist(lapply(stability_results, function(x) x$stability))
  candidate_set <- selection_matrix(x, y, B)$candidate_set
  cv_lasso <- selection_matrix(x, y, B)$cv_lasso

  if (max(stab_values) >= 0.75){
    stable_values <- which(stab_values > 0.75) # Index of stable lambda values
    lambda_stable <- min(candidate_set[stable_values]) # Minimum stable lambda value
    index_of_lambda_stable <- which(candidate_set == lambda_stable) # Index of lambda_stable
    stability <- data.frame() # Initialize a data frame to store stability values
    Stable_S <- sel_mats[[index_of_lambda_stable]] # Stable selection matrix for lambda_stable
    for (k in 2:nrow(Stable_S)){ # loop through subsamples results
      output <- getStability(Stable_S[1:k,]) # Compute stability values
      stability <- rbind(stability, data.frame(k, output$stability, output$variance, output$lower, output$upper)) # Append stability values to the data frame
    }
    colnames(stability) <- c('Iteration', 'Stability', 'Variance', 'Lower', 'Upper') # Set column names of the data frame

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

    S_stable_1sd <- sel_mats[[index_of_stable_1sd]] # Extract the selection matrix for the stable.1sd lambda value
    stability <- data.frame() # Initialize an empty data frame to store stability values
    for (k in 2:nrow(S_stable_1sd)){ # Loop through sub-samples results for lambda stable.1sd
      output <- getStability(S_stable_1sd[1:k,]) # Compute stability values
      stability <- rbind(stability, data.frame(k, output$stability, output$variance, output$lower, output$upper)) # Append stability values to the data frame
    }
    colnames(stability) <- c('Iteration', 'Stability', 'Variance', 'Lower', 'Upper') # Set column names of the data frame
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



