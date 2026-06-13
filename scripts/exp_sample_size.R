if (!dir.exists("R")) stop("Run this script from the repository root.", call. = FALSE)

metrics_csv <- file.path("results", "tables", "sample_size_metrics.csv")
summary_csv <- file.path("results", "tables", "sample_size_summary.csv")
quick_table_ok <- function(path, min_rows = 1) {
  if (!file.exists(path)) return(FALSE)
  out <- tryCatch(utils::read.csv(path), error = identity)
  !inherits(out, "error") && nrow(out) >= min_rows
}
if (quick_table_ok(metrics_csv, min_rows = 24) && quick_table_ok(summary_csv, min_rows = 8)) {
  cat("Sample size checkpoint table exists; skipping expensive BiDAG load.\n")
  print(utils::read.csv(summary_csv, stringsAsFactors = FALSE))
  quit(save = "no", status = 0)
}

source("R/load_project.R")
load_project()
ensure_project_dirs()

log_path <- file.path("results", "logs", "sample_size.log")
cat("Sample size experiment started at", format(Sys.time()), "\n", file = log_path)

grid <- expand.grid(
  p = 20,
  n = c(100, 200, 500, 1000),
  seed = 1:3,
  KEEP.OUT.ATTRS = FALSE
)
grid$expected_degree <- 2
grid$methods <- "order,partition"
grid$mcmc_steps <- 3000
grid$burnin <- 500

if (checkpoint_complete(metrics_csv, min_rows = nrow(grid) * 2)) {
  cat("Sample size table already exists; using checkpoint table.\n", file = log_path, append = TRUE)
  metrics <- utils::read.csv(metrics_csv, stringsAsFactors = FALSE)
} else {
  metrics <- run_repeated_cases(grid, experiment = "sample_size", log_path = log_path)
}
summary <- summarize_metrics(metrics)

write_metrics(metrics, metrics_csv)
write_metrics(summary, summary_csv)
plot_metric_by_n(metrics, "SHD", file.path("results", "figures", "sample_size_shd.png"))
plot_metric_by_n(metrics, "F1", file.path("results", "figures", "sample_size_f1.png"))

cat("Sample size experiment finished at", format(Sys.time()), "\n", file = log_path, append = TRUE)
print(summary)
