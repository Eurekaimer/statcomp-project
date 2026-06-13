if (!dir.exists("R")) stop("Run this script from the Project directory.", call. = FALSE)

metrics_csv <- file.path("results", "tables", "medium_compare_metrics.csv")
summary_csv <- file.path("results", "tables", "medium_compare_summary.csv")
quick_table_ok <- function(path, min_rows = 1) {
  if (!file.exists(path)) return(FALSE)
  out <- tryCatch(utils::read.csv(path), error = identity)
  !inherits(out, "error") && nrow(out) >= min_rows
}
if (quick_table_ok(metrics_csv, min_rows = 4) && quick_table_ok(summary_csv, min_rows = 2)) {
  cat("Medium comparison checkpoint table exists; skipping expensive BiDAG load.\n")
  print(utils::read.csv(summary_csv, stringsAsFactors = FALSE))
  quit(save = "no", status = 0)
}

source("R/load_project.R")
load_project()
ensure_project_dirs()

log_path <- file.path("results", "logs", "medium_compare.log")
cat("Medium comparison started at", format(Sys.time()), "\n", file = log_path)

mcmc_steps <- 1000
burnin <- 200
cat("Requested mcmc_steps =", mcmc_steps, "burnin =", burnin, "\n", file = log_path, append = TRUE)

cat("Using p = 30, n = 500 as the medium-scale comparison setting.\n",
    file = log_path, append = TRUE)

grid <- expand.grid(
  p = 30,
  n = 500,
  seed = 1:2,
  KEEP.OUT.ATTRS = FALSE
)
grid$expected_degree <- 2
grid$methods <- "order,partition"
grid$mcmc_steps <- mcmc_steps
grid$burnin <- burnin

if (checkpoint_complete(metrics_csv, min_rows = nrow(grid) * 2)) {
  cat("Medium comparison table already exists; using checkpoint table.\n", file = log_path, append = TRUE)
  metrics <- utils::read.csv(metrics_csv, stringsAsFactors = FALSE)
} else {
metrics <- tryCatch(
  run_repeated_cases(grid, experiment = "medium_compare", log_path = log_path),
  error = function(e) {
    cat("Full medium run failed; retrying with mcmc_steps = 1000. Error:", conditionMessage(e), "\n",
        file = log_path, append = TRUE)
    grid$mcmc_steps <- 1000
    grid$burnin <- 200
    run_repeated_cases(grid, experiment = "medium_compare_retry", log_path = log_path)
  }
)
}

summary <- summarize_metrics(metrics)
write_metrics(metrics, metrics_csv)
write_metrics(summary, summary_csv)
plot_shd_by_p(metrics, file.path("results", "figures", "medium_compare_shd.png"))
plot_runtime_by_p(metrics, file.path("results", "figures", "medium_compare_runtime.png"))

cat("Medium comparison finished at", format(Sys.time()), "\n", file = log_path, append = TRUE)
print(summary)
