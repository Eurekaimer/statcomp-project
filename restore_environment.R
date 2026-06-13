# For teammates who already received renv.lock:
# source("restore_environment.R")

options(repos = c(CRAN = "https://cloud.r-project.org"))

if (!file.exists("README.md") || !dir.exists("R") || !dir.exists("scripts")) {
  stop("Please run this script from the repository root.", call. = FALSE)
}

if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv")
}

if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}

if (!file.exists("renv.lock")) {
  stop("renv.lock does not exist. Ask the maintainer to run source('sync_environment.R') first.", call. = FALSE)
}

if (!file.exists(file.path("renv", "activate.R"))) {
  renv::init(bare = TRUE)
}
source(file.path("renv", "activate.R"))

options(repos = BiocManager::repositories())

renv::restore(prompt = FALSE)

if (requireNamespace("IRkernel", quietly = TRUE)) {
  IRkernel::installspec(
    name = "sc_project_r",
    displayname = "R - Statistical Computing Project",
    user = TRUE
  )
}

message("Environment restored from renv.lock.")
