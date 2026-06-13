if (!dir.exists("R")) stop("Run this script from the Project directory.", call. = FALSE)
source("R/load_project.R")
load_project()
ensure_project_dirs()

log_path <- file.path("results", "logs", "benchmark_optional.log")
cat("Optional benchmark started at", format(Sys.time()), "\n", file = log_path)

asia <- tryCatch(bnlearn::model2network("[A][S][T|A][L|S][B|S][E|T:L][X|E][D|E:B]"), error = identity)
if (inherits(asia, "error")) {
  cat("Could not load Asia network from bnlearn. Put benchmark data under data/benchmark/.\n",
      file = log_path, append = TRUE)
  quit(save = "no", status = 0)
}

set.seed(1)
data <- bnlearn::rbn(asia, n = 500)
cat("Asia network loaded; benchmark wrapper is available but not part of default run_all.R.\n",
    file = log_path, append = TRUE)

