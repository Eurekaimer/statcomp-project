suppressMessages({
  source("R/load_project.R")
  load_project()
})

DATA_DIR   <- "data/simulated"
OUT_CSV    <- "results/medium_original_reproduction/tables/r_results.csv"
MCMC_STEPS <- 800
BURNIN     <- 150
MAX_PARENTS <- 2

data_files <- list.files(DATA_DIR, pattern = "_data\\.csv$", full.names = TRUE)
cat("Found", length(data_files), "data files\n")

rows <- list()

for (data_f in data_files) {
  base <- sub("_data\\.csv$", "", basename(data_f))
  parts <- strsplit(base, "_")[[1]]
  p_str <- parts[1]; n_str <- parts[2]; seed_str <- parts[3]
  p <- as.integer(sub("^p", "", p_str))
  n <- as.integer(sub("^n", "", n_str))
  seed <- as.integer(sub("^seed", "", seed_str))
  prefix <- file.path(DATA_DIR, base)

  cat(sprintf("\n--- p=%d n=%d seed=%d ---\n", p, n, seed))

  data <- as.data.frame(read.csv(data_f))
  adj_f <- paste0(prefix, "_adj.csv")
  true_adj <- as.matrix(read.csv(adj_f, header = FALSE))
  storage.mode(true_adj) <- "integer"

  if (p %in% c(9, 37)) {
    exp_group <- "order_mcmc"
    paper <- "Friedman and Koller (2003)"
  } else {
    exp_group <- "partition_mcmc"
    paper <- "Kuipers and Moffa (2017)"
  }
  ds <- switch(as.character(p),
    "9"="simulated_flare_like", "37"="simulated_alarm_like",
    "5"="simulated_toy_like", "14"="simulated_boston_like",
    "20"="simulated_large_like", paste0("simulated_p", p))

  run_one <- function(method, impl) {
    cat(sprintf("  %-22s ...", paste0(impl, ":", method)))
    start <- proc.time()[["elapsed"]]
    result <- tryCatch(
      if (impl == "BiDAG") {
        safe_run_method(method, data, seed, MCMC_STEPS, BURNIN)
      } else {
        safe_run_manual_method(method, data, seed, MCMC_STEPS, BURNIN, MAX_PARENTS)
      },
      error = function(e) list(method=method, fit=NULL, map_adj=NULL, edge_post=NULL,
                               runtime=proc.time()[["elapsed"]]-start, status="failed",
                               error=conditionMessage(e))
    )
    if (is.null(result$runtime)) result$runtime <- proc.time()[["elapsed"]] - start

    if (!identical(result$status, "success") || is.null(result$map_adj)) {
      cat(sprintf(" %s\n", result$status))
      rows <<- append(rows, list(data.frame(
        paper=paper, experiment_group=exp_group, data_source=ds,
        p=p, n=n, seed=seed, method=method, implementation=impl,
        runtime=result$runtime, SHD=NA_integer_, TPR=NA_real_, FPR=NA_real_,
        Precision=NA_real_, F1=NA_real_, acceptance_rate=NA_real_,
        mean_edge_entropy=NA_real_, posterior_gap=NA_real_,
        status=result$status,
        error=ifelse(is.na(result$error), "", result$error),
        comparable_level="failed", original_paper_trend="", comment="",
        stringsAsFactors=FALSE)))
      return()
    }

    m <- compute_metrics_directed(true_adj, result$map_adj)
    ar <- NA_real_
    trace <- result$fit$trace
    if (!is.null(trace) && is.list(trace) && !is.null(trace$accept_rate)) ar <- trace$accept_rate[1]

    ent <- NA_real_; pgap <- NA_real_
    if (!is.null(result$edge_post)) {
      ep <- as.matrix(result$edge_post)
      diag(ep) <- NA
      probs <- as.vector(ep); probs <- probs[!is.na(probs)]
      probs <- pmax(pmin(probs, 1-1e-15), 1e-15)
      ent <- mean(-probs*log(probs) - (1-probs)*log(1-probs))
      true_edges <- which((true_adj != 0) & (row(true_adj) != col(true_adj)))
      false_edges <- which((true_adj == 0) & (row(true_adj) != col(true_adj)))
      ep_vec <- as.vector(ep)
      if (length(true_edges) > 0 && length(false_edges) > 0)
        pgap <- mean(ep_vec[true_edges]) - mean(ep_vec[false_edges])
    }

    cat(sprintf(" success SHD=%d F1=%.3f %.1fs\n", m$SHD, m$F1, result$runtime))
    rows <<- append(rows, list(data.frame(
      paper=paper, experiment_group=exp_group, data_source=ds,
      p=p, n=n, seed=seed, method=method, implementation=impl,
      runtime=result$runtime, SHD=m$SHD, TPR=m$TPR, FPR=m$FPR,
      Precision=m$precision, F1=m$F1,
      acceptance_rate=ifelse(is.na(ar), NA_real_, ar),
      mean_edge_entropy=ifelse(is.na(ent), NA_real_, ent),
      posterior_gap=ifelse(is.na(pgap), NA_real_, pgap),
      status="success", error="", comparable_level="approximate",
      original_paper_trend="", comment="", stringsAsFactors=FALSE)))
  }

  run_one("order", "BiDAG")
  if (p <= 20) run_one("partition", "BiDAG")

  if (p <= 20) {
    run_one("manual_order", "manual_R")
    run_one("manual_structure", "manual_R")
    run_one("manual_partition", "manual_R")
  } else if (p <= 37) {
    run_one("manual_order", "manual_R")
    setTimeLimit(cpu=300, elapsed=300, transient=TRUE)
    tryCatch({
      run_one("manual_structure", "manual_R")
    }, error=function(e) {
      cat(sprintf("  manual_structure: timeout (%s)\n", conditionMessage(e)))
      rows <<- append(rows, list(data.frame(
        paper=paper, experiment_group=exp_group, data_source=ds,
        p=p, n=n, seed=seed, method="manual_structure", implementation="manual_R",
        runtime=NA_real_, SHD=NA_integer_, TPR=NA_real_, FPR=NA_real_,
        Precision=NA_real_, F1=NA_real_, acceptance_rate=NA_real_,
        mean_edge_entropy=NA_real_, posterior_gap=NA_real_,
        status="timeout", error=conditionMessage(e),
        comparable_level="failed", original_paper_trend="", comment="",
        stringsAsFactors=FALSE)))
    })
    setTimeLimit(cpu=Inf, elapsed=Inf, transient=TRUE)
  }
}

out <- do.call(rbind, rows)
rownames(out) <- NULL
dir.create(dirname(OUT_CSV), recursive = TRUE, showWarnings = FALSE)
write.csv(out, OUT_CSV, row.names = FALSE)
cat(sprintf("\nDone. %d rows written to %s\n", nrow(out), OUT_CSV))
print(table(out$method, out$implementation, out$status))
