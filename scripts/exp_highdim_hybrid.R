if (!dir.exists("R")) stop("Run this script from the repository root.", call. = FALSE)

metrics_csv <- file.path("results", "tables", "highdim_hybrid_metrics.csv")
summary_csv <- file.path("results", "tables", "highdim_hybrid_summary.csv")
quick_table_ok <- function(path, min_rows = 1) {
  if (!file.exists(path)) return(FALSE)
  out <- tryCatch(utils::read.csv(path), error = identity)
  !inherits(out, "error") && nrow(out) >= min_rows
}
if (quick_table_ok(metrics_csv, min_rows = 2) && quick_table_ok(summary_csv, min_rows = 1)) {
  cat("High-dimensional hybrid checkpoint table exists; skipping expensive BiDAG load.\n")
  print(utils::read.csv(summary_csv, stringsAsFactors = FALSE))
  quit(save = "no", status = 0)
}

source("R/load_project.R")
load_project()
ensure_project_dirs()

log_path <- file.path("results", "logs", "highdim_hybrid.log")
cat("High-dimensional hybrid experiment started at", format(Sys.time()), "\n", file = log_path)

cat("p = 100 iterative/order caused Windows access violation in this local BiDAG/R setup; p = 60 iterative also failed. Running p = 40 iterative as the stable high-dimensional demonstration.\n",
    file = log_path, append = TRUE)

grid <- expand.grid(
  p = 40,
  n = 500,
  seed = 1:2,
  KEEP.OUT.ATTRS = FALSE
)
grid$expected_degree <- 2
grid$methods <- "iterative"
grid$mcmc_steps <- 500
grid$burnin <- 100
cat("Default high-dimensional run uses iterative only to avoid ordinary order MCMC instability.\n",
    file = log_path, append = TRUE)

if (checkpoint_complete(metrics_csv, min_rows = nrow(grid))) {
  cat("High-dimensional hybrid table already exists; using checkpoint table.\n", file = log_path, append = TRUE)
  metrics <- utils::read.csv(metrics_csv, stringsAsFactors = FALSE)
} else {
metrics <- tryCatch(
  run_repeated_cases(grid, experiment = "highdim_hybrid", log_path = log_path),
  error = function(e) {
    cat("Order + iterative failed; retrying iterative only. Error:", conditionMessage(e), "\n",
        file = log_path, append = TRUE)
    grid$methods <- "iterative"
    grid$mcmc_steps <- 800
    grid$burnin <- 100
    run_repeated_cases(grid, experiment = "highdim_hybrid_retry", log_path = log_path)
  }
)
}

summary <- summarize_metrics(metrics)
write_metrics(metrics, metrics_csv)
write_metrics(summary, summary_csv)
plot_runtime_by_p(metrics, file.path("results", "figures", "highdim_hybrid_runtime.png"))
plot_shd_by_p(metrics, file.path("results", "figures", "highdim_hybrid_shd.png"))

cat("High-dimensional hybrid experiment finished at", format(Sys.time()), "\n", file = log_path, append = TRUE)
print(summary)
