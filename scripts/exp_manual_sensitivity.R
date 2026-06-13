if (!dir.exists("R")) stop("Run this script from the repository root.", call. = FALSE)

source("R/load_project.R")
load_project()
ensure_project_dirs()

experiment <- "manual_sensitivity"
log_path <- file.path("results", "logs", "manual_sensitivity.log")
metrics_csv <- file.path("results", "tables", "manual_sensitivity_metrics.csv")
summary_csv <- file.path("results", "tables", "manual_sensitivity_summary.csv")

cat("Manual sensitivity experiment started at", format(Sys.time()), "\n", file = log_path)

rows <- list()
idx <- 1L

for (seed in 1:2) {
  case <- generate_simulation_case(p = 8, n = 120, expected_degree = 2, seed = seed)
  for (max_parents in c(1, 2, 3)) {
    for (method in c("manual_structure", "manual_order", "manual_partition")) {
      result <- safe_run_manual_method(
        method = method,
        data = case$data,
        seed = seed + max_parents * 100,
        mcmc_steps = 1200,
        burnin = 300,
        max_parents = max_parents
      )
      row <- evaluate_method_result(case$adj, result)
      row$p <- 8
      row$n <- 120
      row$seed <- seed
      row$max_parents <- max_parents
      row$mcmc_steps <- 1200
      row$burnin <- 300
      rows[[idx]] <- row
      idx <- idx + 1L
    }
  }
}

metrics <- do.call(rbind, rows)
write_metrics(metrics, metrics_csv)

summary <- stats::aggregate(
  metrics[c("runtime", "SHD", "TPR", "FPR", "precision", "recall", "F1")],
  by = metrics[c("method", "max_parents")],
  FUN = function(x) mean(x, na.rm = TRUE)
)
write_metrics(summary, summary_csv)

colors <- method_colors(unique(metrics$method))

p_f1 <- ggplot2::ggplot(
  metrics,
  ggplot2::aes(x = factor(max_parents), y = F1, color = method, group = method)
) +
  ggplot2::stat_summary(fun = mean, geom = "line", linewidth = 1.1, na.rm = TRUE) +
  ggplot2::stat_summary(fun = mean, geom = "point", size = 3, na.rm = TRUE) +
  ggplot2::scale_color_manual(values = colors) +
  sc_theme(base_size = 12) +
  ggplot2::labs(x = "Maximum number of parents", y = "Mean F1",
                title = "Manual MCMC sensitivity to parent-set constraint")
ggplot2::ggsave(file.path("results", "figures", "manual_sensitivity_f1.png"),
                p_f1, width = 7.5, height = 4.6, dpi = 180)

p_runtime <- ggplot2::ggplot(
  metrics,
  ggplot2::aes(x = factor(max_parents), y = runtime, color = method, group = method)
) +
  ggplot2::stat_summary(fun = mean, geom = "line", linewidth = 1.1, na.rm = TRUE) +
  ggplot2::stat_summary(fun = mean, geom = "point", size = 3, na.rm = TRUE) +
  ggplot2::scale_color_manual(values = colors) +
  sc_theme(base_size = 12) +
  ggplot2::labs(x = "Maximum number of parents", y = "Mean runtime seconds",
                title = "Runtime cost of enlarging parent-set search")
ggplot2::ggsave(file.path("results", "figures", "manual_sensitivity_runtime.png"),
                p_runtime, width = 7.5, height = 4.6, dpi = 180)

cat("Manual sensitivity experiment finished at", format(Sys.time()), "\n",
    file = log_path, append = TRUE)
print(summary)
