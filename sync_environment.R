# 同步项目 R 环境。
# source("sync_environment.R")

options(repos = c(CRAN = "https://cloud.r-project.org"))

required_packages <- c(
  "BiDAG", "bnlearn", "igraph", "pcalg",
  "ggplot2", "dplyr", "tidyr", "purrr",
  "readr", "tibble", "Matrix",
  "IRkernel", "rmarkdown", "knitr"
)

bioconductor_packages <- c("graph", "RBGL", "Rgraphviz")

if (!file.exists("README.md") || !dir.exists("R") || !dir.exists("scripts")) {
  stop("Please run this script from the Project directory.", call. = FALSE)
}

message("==> Checking renv")
if (!requireNamespace("renv", quietly = TRUE)) {
  message("renv is not installed in the user library. Installing renv first...")
  install.packages("renv")
}

message("==> Initializing / activating renv")
if (!file.exists(file.path("renv", "activate.R"))) {
  renv::init(bare = TRUE)
}
source(file.path("renv", "activate.R"))

message("==> Installing Bioconductor manager")
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}

message("==> Installing Bioconductor dependencies required by graph-learning packages")
BiocManager::install(
  bioconductor_packages,
  ask = FALSE,
  update = FALSE
)

message("==> Installing required packages into this project's renv library")
renv::install(required_packages)

message("==> Registering Jupyter R kernel")
if (!requireNamespace("IRkernel", quietly = TRUE)) {
  renv::install("IRkernel")
}
IRkernel::installspec(
  name = "sc_project_r",
  displayname = "R - Statistical Computing Project",
  user = TRUE
)

message("==> Writing renv.lock")
renv::snapshot(prompt = FALSE)

message("==> Environment sync finished.")
message("Next steps:")
message("  source('R/load_project.R'); load_project()")
message("  source('scripts/smoke_test.R')")
