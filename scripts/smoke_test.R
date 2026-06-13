if (!dir.exists("R")) stop("Run this script from the Project directory.", call. = FALSE)

output_csv <- file.path("results", "tables", "smoke_test_metrics.csv")
quick_table_ok <- function(path, min_rows = 1) {
  if (!file.exists(path)) return(FALSE)
  out <- tryCatch(utils::read.csv(path), error = identity)
  !inherits(out, "error") && nrow(out) >= min_rows
}
if (quick_table_ok(output_csv, min_rows = 2)) {
  cat("Smoke test checkpoint table exists; skipping expensive BiDAG load.\n")
  print(utils::read.csv(output_csv, stringsAsFactors = FALSE))
  quit(save = "no", status = 0)
}

source("R/load_project.R")
load_project()
ensure_project_dirs()

log_path <- file.path("results", "logs", "smoke_test.log")
cat("Smoke test started at", format(Sys.time()), "\n", file = log_path)

if (checkpoint_complete(output_csv, min_rows = 2)) {
  cat("Smoke test output already exists; using checkpoint table.\n", file = log_path, append = TRUE)
  metrics <- utils::read.csv(output_csv, stringsAsFactors = FALSE)
} else {
metrics <- run_one_case(
  p = 8,
  n = 100,
  expected_degree = 2,
  seed = 1,
  methods = c("order", "partition"),
  mcmc_steps = 500,
  burnin = 100,
  experiment = "smoke_test",
  log_path = log_path
)

write_metrics(metrics, output_csv)
}
plot_runtime(metrics, file.path("results", "figures", "smoke_test_runtime.png"))
plot_metric_bar(metrics, "SHD", file.path("results", "figures", "smoke_test_shd.png"))

cat("Smoke test finished at", format(Sys.time()), "\n", file = log_path, append = TRUE)
print(metrics)
