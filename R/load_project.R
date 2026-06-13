project_r_files <- function(root = ".") {
  file.path(root, "R", c(
    "packages.R",
    "graph_utils.R",
    "simulation.R",
    "bidag_runner.R",
    "metrics.R",
    "plotting.R",
    "manual_mcmc.R",
    "experiments.R"
  ))
}

load_project <- function(root = ".") {
  files <- project_r_files(root)
  missing <- files[!file.exists(files)]
  if (length(missing) > 0) {
    stop("Missing project R file(s): ", paste(missing, collapse = ", "), call. = FALSE)
  }
  for (file in files) source(file)
  invisible(TRUE)
}
