# Convergence diagnostics experiment
# Compares multiple independent chains for convergence assessment
if (!dir.exists("R")) stop("Run this script from the repository root.", call. = FALSE)

source("R/load_project.R")
load_project()
ensure_project_dirs()

experiment <- "convergence_diagnostics"
log_path <- file.path("results", "logs", paste0(experiment, ".log"))
metrics_csv <- file.path("results", "tables", paste0(experiment, "_metrics.csv"))
summary_csv <- file.path("results", "tables", paste0(experiment, "_summary.csv"))

cat("Convergence diagnostics experiment started at", format(Sys.time()), "\n", file = log_path)

# Edge-level between-chain variance
edge_between_chain_variance <- function(edge_post_list) {
  # edge_post_list: list of p x p matrices from different chains
  arr <- array(unlist(edge_post_list), dim = c(dim(edge_post_list[[1]]), length(edge_post_list)))
  mean_mat <- apply(arr, c(1, 2), mean)
  L <- length(edge_post_list)
  var_mat <- matrix(0, nrow(mean_mat), ncol(mean_mat))
  for (l in seq_len(L)) {
    diff_mat <- edge_post_list[[l]] - mean_mat
    var_mat <- var_mat + diff_mat^2
  }
  var_mat / (L - 1)
}

# Run multiple chains with different starting seeds
rows <- list()
idx <- 1L

for (seed in 1:2) {
  case <- generate_simulation_case(p = 10, n = 200, expected_degree = 2, seed = seed)
  save_simulation_case(
    case,
    file.path("data", "simulated", sprintf("conv_diag_p10_n200_seed%s", seed))
  )

  # Run 3 independent chains for manual_order
  chain_results <- list()
  for (chain_id in 1:3) {
    chain_seed <- seed * 100 + chain_id
    result <- safe_run_manual_method(
      method = "manual_order",
      data = case$data,
      seed = chain_seed,
      mcmc_steps = 2000,
      burnin = 400,
      max_parents = 2
    )
    chain_results[[chain_id]] <- result$edge_post
  }

  # Compute between-chain variance
  bc_var <- edge_between_chain_variance(chain_results)
  diag_mask <- row(bc_var) != col(bc_var)
  var_vec <- as.vector(bc_var[diag_mask])

  # Compute mean edge posterior across chains
  mean_post <- Reduce(`+`, chain_results) / length(chain_results)
  mean_post_vec <- as.vector(mean_post[diag_mask])
  true_vec <- as.vector(case$adj[diag_mask] != 0)

  # Convergence metrics
  rows[[idx]] <- data.frame(
    seed = seed,
    p = 10,
    n = 200,
    method = "manual_order",
    num_chains = 3L,
    mean_bc_variance = mean(var_vec, na.rm = TRUE),
    max_bc_variance = max(var_vec, na.rm = TRUE),
    edges_with_high_variance = sum(var_vec > 0.01, na.rm = TRUE),
    total_edges = length(var_vec),
    mean_posterior_sd = mean(sqrt(var_vec), na.rm = TRUE),
    max_posterior_sd = max(sqrt(var_vec), na.rm = TRUE),
    # Posterior calibration: how well does mean post separate true from false edges?
    true_edge_mean_post = if (any(true_vec)) mean(mean_post_vec[true_vec], na.rm = TRUE) else NA_real_,
    false_edge_mean_post = if (any(!true_vec)) mean(mean_post_vec[!true_vec], na.rm = TRUE) else NA_real_,
    stringsAsFactors = FALSE
  )
  idx <- idx + 1L

  # Also run manual_partition for comparison
  chain_results_part <- list()
  for (chain_id in 1:3) {
    chain_seed <- seed * 100 + chain_id
    result <- safe_run_manual_method(
      method = "manual_partition",
      data = case$data,
      seed = chain_seed,
      mcmc_steps = 2000,
      burnin = 400,
      max_parents = 2
    )
    chain_results_part[[chain_id]] <- result$edge_post
  }

  bc_var_part <- edge_between_chain_variance(chain_results_part)
  var_vec_part <- as.vector(bc_var_part[diag_mask])
  mean_post_part <- Reduce(`+`, chain_results_part) / length(chain_results_part)
  mean_post_vec_part <- as.vector(mean_post_part[diag_mask])

  rows[[idx]] <- data.frame(
    seed = seed,
    p = 10,
    n = 200,
    method = "manual_partition",
    num_chains = 3L,
    mean_bc_variance = mean(var_vec_part, na.rm = TRUE),
    max_bc_variance = max(var_vec_part, na.rm = TRUE),
    edges_with_high_variance = sum(var_vec_part > 0.01, na.rm = TRUE),
    total_edges = length(var_vec_part),
    mean_posterior_sd = mean(sqrt(var_vec_part), na.rm = TRUE),
    max_posterior_sd = max(sqrt(var_vec_part), na.rm = TRUE),
    true_edge_mean_post = if (any(true_vec)) mean(mean_post_vec_part[true_vec], na.rm = TRUE) else NA_real_,
    false_edge_mean_post = if (any(!true_vec)) mean(mean_post_vec_part[!true_vec], na.rm = TRUE) else NA_real_,
    stringsAsFactors = FALSE
  )
  idx <- idx + 1L
}

metrics <- do.call(rbind, rows)
write_metrics(metrics, metrics_csv)

summary <- stats::aggregate(
  metrics[c("mean_bc_variance", "max_bc_variance", "edges_with_high_variance",
             "mean_posterior_sd", "true_edge_mean_post", "false_edge_mean_post")],
  by = metrics[c("method")],
  FUN = function(x) mean(x, na.rm = TRUE)
)
write_metrics(summary, summary_csv)

# Plot: between-chain variance comparison
colors <- method_colors(unique(metrics$method))

p_bc <- ggplot2::ggplot(
  metrics,
  ggplot2::aes(x = method, y = mean_bc_variance, fill = method)
) +
  ggplot2::geom_col(width = 0.5, alpha = 0.85) +
  ggplot2::scale_fill_manual(values = colors) +
  sc_theme(base_size = 12) +
  ggplot2::labs(x = NULL, y = "Mean between-chain variance",
                title = "Multi-chain convergence: between-chain edge posterior variance",
                subtitle = "Lower variance indicates better chain mixing and convergence") +
  ggplot2::theme(legend.position = "none")
ggplot2::ggsave(file.path("results", "figures", "convergence_bc_variance.png"),
                p_bc, width = 7.5, height = 4.6, dpi = 180)

p_sd <- ggplot2::ggplot(
  metrics,
  ggplot2::aes(x = method, y = mean_posterior_sd, fill = method)
) +
  ggplot2::geom_col(width = 0.5, alpha = 0.85) +
  ggplot2::scale_fill_manual(values = colors) +
  sc_theme(base_size = 12) +
  ggplot2::labs(x = NULL, y = "Mean posterior SD",
                title = "Multi-chain convergence: edge posterior standard deviation",
                subtitle = "Lower SD indicates more consistent edge probability estimates across chains") +
  ggplot2::theme(legend.position = "none")
ggplot2::ggsave(file.path("results", "figures", "convergence_posterior_sd.png"),
                p_sd, width = 7.5, height = 4.6, dpi = 180)

cat("Convergence diagnostics experiment finished at", format(Sys.time()), "\n",
    file = log_path, append = TRUE)
print(summary)
