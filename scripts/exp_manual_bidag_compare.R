if (!dir.exists("R")) stop("Run this script from the repository root.", call. = FALSE)

source("R/load_project.R")
load_project()
ensure_project_dirs()

experiment <- "manual_bidag_compare"
log_path <- file.path("results", "logs", paste0(experiment, ".log"))
metrics_path <- file.path("results", "tables", "manual_bidag_compare_metrics.csv")
summary_path <- file.path("results", "tables", "manual_bidag_compare_summary.csv")

append_log(log_path, "start manual versus BiDAG matched comparison")

rows <- list()
idx <- 1L

for (seed in 1:2) {
  case <- generate_simulation_case(p = 8, n = 120, expected_degree = 2, seed = seed)
  save_simulation_case(
    case,
    file.path("data", "simulated", sprintf("manual_bidag_compare_p8_n120_seed%s", seed))
  )

  for (max_parents in c(2, 3)) {
    for (method in c("manual_order", "manual_partition")) {
      result <- safe_run_manual_method(
        method = method,
        data = case$data,
        seed = seed + max_parents * 100,
        mcmc_steps = 1500,
        burnin = 300,
        max_parents = max_parents
      )
      row <- evaluate_method_result(case$adj, result)
      row$implementation <- "manual"
      row$score <- "Gaussian BIC"
      row$max_parents <- max_parents
      row$K <- as.character(max_parents)
      row$p <- 8
      row$n <- 120
      row$expected_degree <- 2
      row$seed <- seed
      row$mcmc_steps <- 1500
      row$burnin <- 300
      rows[[idx]] <- row
      idx <- idx + 1L
    }
  }

  result <- safe_run_manual_method(
    method = "manual_structure",
    data = case$data,
    seed = seed + 200,
    mcmc_steps = 1500,
    burnin = 300,
    max_parents = 2
  )
  row <- evaluate_method_result(case$adj, result)
  row$implementation <- "manual"
  row$score <- "Gaussian BIC"
  row$max_parents <- 2
  row$K <- "2"
  row$p <- 8
  row$n <- 120
  row$expected_degree <- 2
  row$seed <- seed
  row$mcmc_steps <- 1500
  row$burnin <- 300
  rows[[idx]] <- row
  idx <- idx + 1L

  for (method in c("order", "partition")) {
    result <- safe_run_method(
      method = method,
      data = case$data,
      seed = seed,
      mcmc_steps = 1500,
      burnin = 300,
      score_type = "bge"
    )
    row <- evaluate_method_result(case$adj, result)
    row$implementation <- "BiDAG"
    row$score <- "BGe"
    row$max_parents <- NA_integer_
    row$K <- "N/A"
    row$p <- 8
    row$n <- 120
    row$expected_degree <- 2
    row$seed <- seed
    row$mcmc_steps <- 1500
    row$burnin <- 300
    rows[[idx]] <- row
    idx <- idx + 1L
  }
}

metrics <- do.call(rbind, rows)
write_metrics(metrics, metrics_path)

summary <- stats::aggregate(
  metrics[c("runtime", "SHD", "TPR", "FPR", "precision", "recall", "F1")],
  by = metrics[c("implementation", "method", "score", "K", "p", "n", "mcmc_steps", "burnin")],
  FUN = function(x) mean(x, na.rm = TRUE)
)
summary <- summary[order(summary$implementation, summary$method, summary$K), ]
write_metrics(summary, summary_path)

append_log(log_path, "finish manual versus BiDAG matched comparison")
print(summary)
