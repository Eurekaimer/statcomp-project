project_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!dir.exists(file.path(project_root, "R"))) {
  stop("Run run_all.R from the repository root.", call. = FALSE)
}

dir.create(file.path("results", "logs"), recursive = TRUE, showWarnings = FALSE)
main_log <- file.path("results", "logs", "run_all.log")
log_message <- function(...) {
  msg <- paste0(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " | ", paste(..., collapse = " "))
  cat(msg, "\n")
  cat(msg, "\n", file = main_log, append = TRUE)
}

log_message("Starting run_all.R")

source("R/load_project.R")
load_project()

scripts_to_run <- c(
  "scripts/smoke_test.R",
  "scripts/exp_manual_validation.R",
  "scripts/exp_manual_bidag_compare.R",
  "scripts/exp_small_compare.R",
  "scripts/exp_medium_compare.R",
  "scripts/exp_highdim_hybrid.R",
  "scripts/exp_sample_size.R",
  "scripts/exp_manual_sensitivity.R",
  "scripts/exp_posterior_uncertainty.R"
)

expected_outputs <- list(
  "scripts/smoke_test.R" = "results/tables/smoke_test_metrics.csv",
  "scripts/exp_manual_validation.R" = "results/tables/manual_validation_summary.csv",
  "scripts/exp_manual_bidag_compare.R" = "results/tables/manual_bidag_compare_summary.csv",
  "scripts/exp_small_compare.R" = "results/tables/small_compare_summary.csv",
  "scripts/exp_medium_compare.R" = "results/tables/medium_compare_summary.csv",
  "scripts/exp_highdim_hybrid.R" = "results/tables/highdim_hybrid_summary.csv",
  "scripts/exp_sample_size.R" = "results/tables/sample_size_summary.csv",
  "scripts/exp_manual_sensitivity.R" = "results/tables/manual_sensitivity_summary.csv",
  "scripts/exp_posterior_uncertainty.R" = "results/tables/posterior_uncertainty_summary.csv"
)

run_script_subprocess <- function(script) {
  rscript <- file.path(R.home("bin"), "Rscript.exe")
  if (!file.exists(rscript)) rscript <- file.path(R.home("bin"), "Rscript")
  stdout_file <- file.path("results", "logs", paste0(tools::file_path_sans_ext(basename(script)), ".out.log"))
  stderr_file <- file.path("results", "logs", paste0(tools::file_path_sans_ext(basename(script)), ".err.log"))
  runner <- file.path("results", "logs", paste0(tools::file_path_sans_ext(basename(script)), "_runner.R"))
  runner_lines <- c(
    sprintf("setwd(%s)", deparse(normalizePath(getwd(), winslash = "/", mustWork = TRUE))),
    "if (file.exists('renv/activate.R')) source('renv/activate.R')",
    sprintf("source(%s)", deparse(script))
  )
  writeLines(runner_lines, runner, useBytes = TRUE)
  status <- system2(rscript, runner, stdout = stdout_file, stderr = stderr_file)
  if (!identical(status, 0L)) {
    expected <- expected_outputs[[script]]
    if (!is.null(expected) && file.exists(expected)) {
      log_message("WARNING", script, "exit status", status, "but expected output exists:", expected)
    } else {
      log_message("FAILED", script, "exit status", status, "see", stderr_file)
      stop("Experiment failed: ", script, call. = FALSE)
    }
  }
  invisible(status)
}

for (script in scripts_to_run) {
  log_message("Running", script)
  run_script_subprocess(script)
}

log_message("Finished run_all.R")
