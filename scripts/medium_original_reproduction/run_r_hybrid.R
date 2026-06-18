suppressMessages({
  source("R/load_project.R")
  load_project()
})

DATA_DIR <- "data/simulated"
OUT_CSV  <- "results/medium_original_reproduction/tables/hybrid_results.csv"
MCMC_STEPS <- 800
BURNIN     <- 150

data_files <- list.files(DATA_DIR, pattern = "_data\\.csv$", full.names = TRUE)
data_files <- data_files[grep("p(40|80)_", basename(data_files))]
cat("Found", length(data_files), "hybrid data files\n")

rows <- list()
for (data_f in data_files) {
  base <- sub("_data\\.csv$", "", basename(data_f))
  parts <- strsplit(base, "_")[[1]]
  p <- as.integer(sub("^p", "", parts[1]))
  n <- as.integer(sub("^n", "", parts[2]))
  seed <- as.integer(sub("^seed", "", parts[3]))
  prefix <- file.path(DATA_DIR, base)

  cat(sprintf("\n--- Hybrid p=%d n=%d seed=%d ---\n", p, n, seed))
  data <- as.data.frame(read.csv(data_f))
  adj_f <- paste0(prefix, "_adj.csv")
  true_adj <- as.matrix(read.csv(adj_f, header = FALSE))
  storage.mode(true_adj) <- "integer"

  ds <- paste0("simulated_p", p)
  paper <- "Kuipers, Suter and Moffa (2022)"
  exp_group <- "hybrid_iterative"

  run_one <- function(method, impl) {
    cat(sprintf("  %-22s ...", paste0(impl, ":", method)))
    start <- proc.time()[["elapsed"]]
    result <- tryCatch(
      safe_run_method(method, data, seed, MCMC_STEPS, BURNIN),
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
        comparable_level=if(result$status=="success") "approximate" else "failed",
        original_paper_trend="", comment="", stringsAsFactors=FALSE)))
      return()
    }

    m <- compute_metrics_directed(true_adj, result$map_adj)
    ent <- NA_real_; pgap <- NA_real_
    if (!is.null(result$edge_post)) {
      ep <- as.matrix(result$edge_post)
      diag(ep) <- NA; probs <- as.vector(ep); probs <- probs[!is.na(probs)]
      probs <- pmax(pmin(probs, 1-1e-15), 1e-15)
      ent <- mean(-probs*log(probs) - (1-probs)*log(1-probs))
      true_edges <- which((true_adj != 0) & (row(true_adj) != col(true_adj)))
      false_edges <- which((true_adj == 0) & (row(true_adj) != col(true_adj)))
      ep_vec <- as.vector(ep)
      if (length(true_edges)>0 && length(false_edges)>0)
        pgap <- mean(ep_vec[true_edges]) - mean(ep_vec[false_edges])
    }
    cat(sprintf(" success SHD=%d F1=%.3f %.1fs\n", m$SHD, m$F1, result$runtime))
    rows <<- append(rows, list(data.frame(
      paper=paper, experiment_group=exp_group, data_source=ds,
      p=p, n=n, seed=seed, method=method, implementation=impl,
      runtime=result$runtime, SHD=m$SHD, TPR=m$TPR, FPR=m$FPR,
      Precision=m$precision, F1=m$F1,
      acceptance_rate=NA_real_, mean_edge_entropy=ifelse(is.na(ent), NA_real_, ent),
      posterior_gap=ifelse(is.na(pgap), NA_real_, pgap),
      status="success", error="", comparable_level="approximate",
      original_paper_trend="", comment="", stringsAsFactors=FALSE)))
  }

  run_one("iterative", "BiDAG")
}

out <- do.call(rbind, rows)
rownames(out) <- NULL
dir.create(dirname(OUT_CSV), recursive=TRUE, showWarnings=FALSE)
write.csv(out, OUT_CSV, row.names=FALSE)
cat(sprintf("\nDone. %d rows -> %s\n", nrow(out), OUT_CSV))
