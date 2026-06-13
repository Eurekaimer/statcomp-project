if (!dir.exists("R")) stop("Run this script from the Project directory.", call. = FALSE)
source("R/load_project.R")
load_project()
ensure_project_dirs()

log_path <- file.path("results", "logs", "small_compare.log")
cat("Small comparison started at", format(Sys.time()), "\n", file = log_path)

metrics_csv <- file.path("results", "tables", "small_compare_metrics.csv")
summary_csv <- file.path("results", "tables", "small_compare_summary.csv")

grid <- expand.grid(
  p = c(10, 20),
  n = c(200, 500),
  seed = 1:3,
  KEEP.OUT.ATTRS = FALSE
)
grid$expected_degree <- 2
grid$methods <- "order,partition"
grid$mcmc_steps <- 3000
grid$burnin <- 500

if (checkpoint_complete(metrics_csv, min_rows = nrow(grid) * 2)) {
  cat("Small comparison table already exists; using checkpoint table.\n", file = log_path, append = TRUE)
  metrics <- utils::read.csv(metrics_csv, stringsAsFactors = FALSE)
} else {
  metrics <- run_repeated_cases(grid, experiment = "small_compare", log_path = log_path)
}
summary <- summarize_metrics(metrics)

write_metrics(metrics, metrics_csv)
write_metrics(summary, summary_csv)
plot_shd_by_p(metrics, file.path("results", "figures", "small_compare_shd.png"))
plot_runtime_by_p(metrics, file.path("results", "figures", "small_compare_runtime.png"))
plot_metric_by_n(metrics, "F1", file.path("results", "figures", "small_compare_f1.png"))

cat("Small comparison finished at", format(Sys.time()), "\n", file = log_path, append = TRUE)
print(summary)
