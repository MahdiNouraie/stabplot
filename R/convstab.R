utils::globalVariables(c("Iteration", "Stability", "Lower", "Upper"))
#' Convstab
#'
#' Creates a diagnostic plot of stability estimates and their confidence
#' intervals across sequential subsamples in stability selection. The plot
#' is constructed using `lambda.stable` when the maximum stability exceeds
#' 0.75; otherwise, `lambda.stable.1sd` is used.
#'
#' @param x A numeric matrix of predictors.
#' @param y A numeric vector of response values.
#' @param B An integer specifying the number of subsamples.
#' @param alpha A numeric value specifying the significance level for the
#'   confidence intervals.
#' @param thr A numeric value specifying the minimum selection frequency
#'   for reporting selected variables.
#'
#' @return A list containing the stability plot (`plot`) and a data frame of
#' variables with selection frequencies exceeding `thr` (`selected`), returned
#' invisibly. The plot is also displayed as a side effect.
#' @examples
#' \donttest{
#' set.seed(123)
#' x <- matrix(rnorm(1000), ncol = 10)
#' # create beta based on the first 3 columns of x and some error
#' beta <- c(0.5, 0.4, 0.3, rep(0, 7))
#' y <- x %*% beta + rnorm(100)
#' B <- 200
#' res <- Convstab(x, y, B)  # Example usage of the Convstab function
#' res$selected
#' # output
#' # Variable Selection_Frequency
#' # 1       x1               0.970
#' # 2       x2               0.895
#'
#'}
#' @references
#' Nouraie, M., & Muller, S. (2026). Stability-guided hyper-parameter tuning for stability selection. Communications in Statistics - Theory and Methods, 1–19.
#'
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
  SM <- selection_matrix(x, y, B)
  sel_mats <- SM$S_list
  stability_results <- lapply(sel_mats, getStability)
  stab_values <- unlist(lapply(stability_results, function(x) x$stability))
  candidate_set <- SM$candidate_set

  if (max(stab_values, na.rm = TRUE) >= 0.75){
    stable_values <- which(stab_values >= 0.75) # Index of stable lambda values
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
    # Filter columns with selection frequencies > thr and return their names and means
    selected_cols <- col_means[col_means > thr]
    selected_df<- data.frame(Variable = names(selected_cols), Selection_Frequency = selected_cols, row.names = NULL)
    p <- ggplot2::ggplot(stability, ggplot2::aes(x = Iteration, y = Stability)) +
      ggplot2::geom_line() +
      ggplot2::geom_ribbon(ggplot2::aes(ymin = Lower, ymax = Upper), fill = 'blue', alpha = 0.7) + # Add ribbon for confidence interval
      ggplot2::labs(title = latex2exp::TeX('Stability of Stability Selection ($\\lambda = \\lambda_{stable}$)'),
           x = 'Iteration (sub-sample)', y = latex2exp::TeX('Stability ($\\hat{\\Phi}$)'))+
      ggplot2::theme_bw() +
      ggplot2::theme(
        plot.title = ggplot2::element_text(size = 20),       # Title text size
        axis.title.x = ggplot2::element_text(size = 18),     # X-axis label size
        axis.title.y = ggplot2::element_text(size = 18),     # Y-axis label size
        axis.text.x = ggplot2::element_text(size = 16),      # X-axis tick text size
        axis.text.y = ggplot2::element_text(size = 16)       # Y-axis tick text size
      )
    print(p)
    return(invisible(list(plot = p, selected = selected_df)))
  }
  else{
    max_stability <- max(stab_values, na.rm = TRUE) # Find the maximum stability value
    stability_1sd_threshold <- max_stability - stats::sd(stab_values, na.rm = TRUE) # Define the stability threshold as max stability - 1SD
    index_of_stable_1sd <- max(which(stab_values >= stability_1sd_threshold), na.rm = TRUE) # since candidate_set is in decreasing order,
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
    # Filter columns with selection frequencies > thr and return their names and means
    selected_cols <- col_means[col_means > thr]
    selected_df <- data.frame(Variable = names(selected_cols), Selection_Frequency = selected_cols, row.names = NULL)
    p <- ggplot2::ggplot(stability, ggplot2::aes(x = Iteration, y = Stability)) +
      ggplot2::geom_line() +
      ggplot2::geom_ribbon(ggplot2::aes(ymin = Lower, ymax = Upper), fill = 'blue', alpha = 0.7) + # Add ribbon for confidence interval
      ggplot2::labs(title = latex2exp::TeX('Stability of Stability Selection ($\\lambda = \\lambda_{stable.1sd}$)'),
           x = 'Iteration (sub-sample)', y = latex2exp::TeX('Stability ($\\hat{\\Phi}$)'))+
      ggplot2::theme_bw() +
      ggplot2::theme(
        plot.title = ggplot2::element_text(size = 20),       # Title text size
        axis.title.x = ggplot2::element_text(size = 18),     # X-axis label size
        axis.title.y = ggplot2::element_text(size = 18),     # Y-axis label size
        axis.text.x = ggplot2::element_text(size = 16),      # X-axis tick text size
        axis.text.y = ggplot2::element_text(size = 16)       # Y-axis tick text size
      )
    print(p)
    return(invisible(list(plot = p, selected = selected_df)))
  }
}



