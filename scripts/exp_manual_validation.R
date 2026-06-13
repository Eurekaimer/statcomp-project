if (!dir.exists("R")) stop("Run this script from the repository root.", call. = FALSE)

source("R/load_project.R")
load_project()

ensure_project_dirs()
experiment <- "manual_validation"
log_path <- file.path("results", "logs", "manual_validation.log")
metrics_path <- file.path("results", "tables", "manual_validation_metrics.csv")
summary_path <- file.path("results", "tables", "manual_validation_summary.csv")

if (checkpoint_complete(metrics_path, min_rows = 6) && checkpoint_complete(summary_path, min_rows = 3)) {
  append_log(log_path, "table checkpoint hit manual validation")
  metrics <- utils::read.csv(metrics_path)
  summary <- utils::read.csv(summary_path)
  print(summary)
} else {
  append_log(log_path, "start manual validation")

  rows <- list()
  idx <- 1L
  for (seed in 1:2) {
    case <- generate_simulation_case(p = 8, n = 120, expected_degree = 2, seed = seed)
    save_simulation_case(
      case,
      file.path("data", "simulated", sprintf("manual_validation_p8_n120_seed%s", seed))
    )

    for (method in c("manual_structure", "manual_order", "manual_partition")) {
      result <- safe_run_manual_method(
        method = method,
        data = case$data,
        seed = seed,
        mcmc_steps = 1500,
        burnin = 300,
        max_parents = 2
      )
      row <- evaluate_method_result(case$adj, result)
      row$p <- 8
      row$n <- 120
      row$expected_degree <- 2
      row$seed <- seed
      row$mcmc_steps <- 1500
      row$burnin <- 300
      row$max_parents <- 2
      rows[[idx]] <- row
      idx <- idx + 1L

      raw_path <- file.path(
        "results", "raw",
        sprintf("manual_validation_%s_seed%s.rds", method, seed)
      )
      saveRDS(list(case = case, result = result, metrics = row), raw_path)
    }
  }

  metrics <- do.call(rbind, rows)
  write_metrics(metrics, metrics_path)
  summary <- summarize_metrics(metrics)
  write_metrics(summary, summary_path)

  plot_metric_bar(metrics, "SHD", file.path("results", "figures", "manual_validation_shd.png"))
  plot_runtime(metrics, file.path("results", "figures", "manual_validation_runtime.png"))
  plot_metric_bar(metrics, "F1", file.path("results", "figures", "manual_validation_f1.png"))

  append_log(log_path, "finish manual validation")
  print(summary)
}
