ensure_project_dirs <- function() {
  dirs <- c(
    "data/simulated", "data/benchmark",
    "results/raw", "results/tables", "results/figures", "results/logs",
    "results/checkpoints",
    "report"
  )
  for (d in dirs) dir.create(d, recursive = TRUE, showWarnings = FALSE)
}

source_project_r <- function() {
  source(file.path("R", "load_project.R"))
  load_project()
}

checkpoint_path <- function(experiment, p, n, seed, methods) {
  method_key <- paste(methods, collapse = "-")
  file.path(
    "results", "checkpoints",
    sprintf("%s_p%s_n%s_seed%s_%s.rds", experiment, p, n, seed, method_key)
  )
}

append_log <- function(path, ...) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  cat(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "|", paste(..., collapse = " "), "\n",
      file = path, append = TRUE)
}

run_one_case <- function(p, n, expected_degree, seed, methods, mcmc_steps, burnin,
                         experiment = "case", use_checkpoint = TRUE,
                         log_path = file.path("results", "logs", paste0(experiment, ".log"))) {
  ensure_project_dirs()
  ckpt <- checkpoint_path(experiment, p, n, seed, methods)
  if (use_checkpoint && file.exists(ckpt)) {
    saved <- readRDS(ckpt)
    append_log(log_path, "checkpoint hit", basename(ckpt))
    return(saved$metrics)
  }

  append_log(log_path, "start case", paste0("p=", p), paste0("n=", n),
             paste0("seed=", seed), paste0("methods=", paste(methods, collapse = ",")))
  case <- generate_simulation_case(p, n, expected_degree, seed)
  prefix <- file.path("data", "simulated", sprintf("p%s_n%s_seed%s", p, n, seed))
  save_simulation_case(case, prefix)

  results <- lapply(methods, function(method) {
    safe_run_method(method, case$data, seed = seed, mcmc_steps = mcmc_steps, burnin = burnin)
  })

  metrics <- do.call(rbind, lapply(results, function(result) evaluate_method_result(case$adj, result)))
  metrics$p <- p
  metrics$n <- n
  metrics$expected_degree <- expected_degree
  metrics$seed <- seed
  metrics$mcmc_steps <- mcmc_steps
  metrics$burnin <- burnin

  raw_path <- file.path("results", "raw", sprintf("case_p%s_n%s_seed%s.rds", p, n, seed))
  payload <- list(case = case, results = results, metrics = metrics)
  saveRDS(payload, raw_path)
  saveRDS(payload, ckpt)
  append_log(log_path, "finish case", basename(ckpt))
  metrics
}

run_repeated_cases <- function(config_grid, experiment = "experiment", use_checkpoint = TRUE,
                               log_path = file.path("results", "logs", paste0(experiment, ".log"))) {
  rows <- vector("list", nrow(config_grid))
  for (i in seq_len(nrow(config_grid))) {
    cfg <- config_grid[i, ]
    methods <- strsplit(cfg$methods, ",", fixed = TRUE)[[1]]
    rows[[i]] <- run_one_case(
      p = cfg$p,
      n = cfg$n,
      expected_degree = cfg$expected_degree,
      seed = cfg$seed,
      methods = methods,
      mcmc_steps = cfg$mcmc_steps,
      burnin = cfg$burnin,
      experiment = experiment,
      use_checkpoint = use_checkpoint,
      log_path = log_path
    )
  }
  do.call(rbind, rows)
}

summarize_metrics <- function(metrics_df) {
  numeric_cols <- c("runtime", "SHD", "TPR", "FPR", "precision", "recall", "F1")
  stats::aggregate(
    metrics_df[numeric_cols],
    by = metrics_df[c("method", "p", "n")],
    FUN = function(x) mean(x, na.rm = TRUE)
  )
}

write_metrics <- function(metrics, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(metrics, path, row.names = FALSE)
  invisible(path)
}

checkpoint_complete <- function(path, min_rows = 1) {
  if (!file.exists(path)) return(FALSE)
  out <- tryCatch(utils::read.csv(path), error = identity)
  !inherits(out, "error") && nrow(out) >= min_rows
}
