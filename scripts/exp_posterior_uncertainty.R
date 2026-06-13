if (!dir.exists("R")) stop("Run this script from the Project directory.", call. = FALSE)

source("R/load_project.R")
load_project()
ensure_project_dirs()

log_path <- file.path("results", "logs", "posterior_uncertainty.log")
cat("Posterior uncertainty analysis started at", format(Sys.time()), "\n", file = log_path)

metrics_csv <- file.path("results", "tables", "posterior_uncertainty_metrics.csv")
summary_csv <- file.path("results", "tables", "posterior_uncertainty_summary.csv")

edge_entropy <- function(prob) {
  prob <- pmin(pmax(prob, 1e-12), 1 - 1e-12)
  -prob * log(prob) - (1 - prob) * log(1 - prob)
}

raw_files <- list.files("results/raw", pattern = "[.]rds$", full.names = TRUE)
rows <- list()
idx <- 1L

for (path in raw_files) {
  obj <- tryCatch(readRDS(path), error = identity)
  if (inherits(obj, "error") || is.null(obj$results) || is.null(obj$case$adj)) next
  true_adj <- as.matrix(obj$case$adj)
  diag_mask <- row(true_adj) != col(true_adj)
  true_vec <- as.vector(true_adj[diag_mask] != 0)

  for (result in obj$results) {
    if (!identical(result$status, "success") || is.null(result$edge_post)) next
    edge_post <- as.matrix(result$edge_post)
    if (!all(dim(edge_post) == dim(true_adj))) next
    prob <- as.vector(edge_post[diag_mask])
    entropy <- edge_entropy(prob)
    rows[[idx]] <- data.frame(
      source_file = basename(path),
      method = result$method,
      p = obj$case$p,
      n = obj$case$n,
      seed = obj$case$seed,
      mean_edge_posterior = mean(prob, na.rm = TRUE),
      mean_entropy = mean(entropy, na.rm = TRUE),
      high_uncertainty_fraction = mean(prob >= 0.25 & prob <= 0.75, na.rm = TRUE),
      confident_fraction = mean(prob <= 0.10 | prob >= 0.90, na.rm = TRUE),
      true_edge_mean_posterior = if (any(true_vec)) mean(prob[true_vec], na.rm = TRUE) else NA_real_,
      false_edge_mean_posterior = if (any(!true_vec)) mean(prob[!true_vec], na.rm = TRUE) else NA_real_,
      stringsAsFactors = FALSE
    )
    idx <- idx + 1L
  }
}

if (length(rows) == 0) {
  cat("No edge posterior matrices found in results/raw.\n", file = log_path, append = TRUE)
  quit(save = "no", status = 0)
}

metrics <- do.call(rbind, rows)
write_metrics(metrics, metrics_csv)

summary <- stats::aggregate(
  metrics[c(
    "mean_edge_posterior", "mean_entropy", "high_uncertainty_fraction",
    "confident_fraction", "true_edge_mean_posterior", "false_edge_mean_posterior"
  )],
  by = metrics[c("method", "p", "n")],
  FUN = function(x) mean(x, na.rm = TRUE)
)
write_metrics(summary, summary_csv)

colors <- method_colors(unique(metrics$method))

p_entropy <- ggplot2::ggplot(
  metrics,
  ggplot2::aes(x = factor(p), y = mean_entropy, color = method, group = method)
) +
  ggplot2::stat_summary(fun = mean, geom = "line", linewidth = 1.1, na.rm = TRUE) +
  ggplot2::stat_summary(fun = mean, geom = "point", size = 3, na.rm = TRUE) +
  ggplot2::scale_color_manual(values = colors) +
  sc_theme(base_size = 12) +
  ggplot2::labs(x = "Number of nodes (p)", y = "Mean edge posterior entropy",
                title = "Posterior uncertainty by dimension")
ggplot2::ggsave(file.path("results", "figures", "posterior_uncertainty_entropy_by_p.png"),
                p_entropy, width = 7.5, height = 4.6, dpi = 180)

p_gap <- ggplot2::ggplot(
  summary,
  ggplot2::aes(x = factor(n), y = true_edge_mean_posterior - false_edge_mean_posterior,
               color = method, group = method)
) +
  ggplot2::geom_line(linewidth = 1.1, na.rm = TRUE) +
  ggplot2::geom_point(size = 3, na.rm = TRUE) +
  ggplot2::scale_color_manual(values = colors) +
  sc_theme(base_size = 12) +
  ggplot2::labs(x = "Sample size (n)", y = "Mean posterior gap",
                title = "True-edge versus false-edge posterior separation")
ggplot2::ggsave(file.path("results", "figures", "posterior_uncertainty_true_false_gap.png"),
                p_gap, width = 7.5, height = 4.6, dpi = 180)

cat("Posterior uncertainty analysis finished at", format(Sys.time()), "\n",
    file = log_path, append = TRUE)
print(summary)
