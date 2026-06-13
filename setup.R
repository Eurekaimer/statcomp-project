required_packages <- c(
  "BiDAG", "bnlearn", "igraph", "pcalg",
  "ggplot2", "dplyr", "tidyr", "purrr",
  "readr", "tibble", "Matrix",
  "IRkernel", "rmarkdown", "knitr"
)

cat("Statistical Computing Project setup\n")

if (!requireNamespace("renv", quietly = TRUE)) {
  stop(
    "Package 'renv' is not installed. Please run install.packages('renv') first, ",
    "then re-run source('setup.R').",
    call. = FALSE
  )
}

if (!file.exists("renv/activate.R")) {
  cat("Initializing renv project...\n")
  renv::init(bare = TRUE)
} else {
  source("renv/activate.R")
}

missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing_packages) > 0) {
  cat("Missing packages:\n")
  cat(paste0("  - ", missing_packages, collapse = "\n"), "\n")
  cat("Install them with:\n")
  cat("renv::install(c(\n")
  cat(paste0('  "', missing_packages, '"', collapse = ",\n"))
  cat("\n))\n")
} else {
  cat("All required packages are available.\n")
}

if (requireNamespace("IRkernel", quietly = TRUE)) {
  cat("Registering Jupyter R kernel sc_project_r...\n")
  IRkernel::installspec(
    name = "sc_project_r",
    displayname = "R - Statistical Computing Project",
    user = TRUE
  )
} else {
  cat("IRkernel is missing. Install it before registering the Jupyter kernel.\n")
}

cat("After installing packages, run renv::snapshot() to generate renv.lock.\n")

