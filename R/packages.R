core_packages <- c(
  "BiDAG", "bnlearn", "igraph", "pcalg",
  "ggplot2", "dplyr", "tidyr", "purrr",
  "readr", "tibble", "Matrix",
  "IRkernel", "rmarkdown", "knitr"
)

missing_packages <- core_packages[!vapply(core_packages, requireNamespace, logical(1), quietly = TRUE)]

if ("BiDAG" %in% missing_packages) {
  stop(
    "BiDAG is required but not installed. In the Project directory, run setup.R ",
    "and install BiDAG through renv::install('BiDAG').",
    call. = FALSE
  )
}

if (length(missing_packages) > 0) {
  stop(
    "Missing required packages: ", paste(missing_packages, collapse = ", "),
    ". Install them with setup.R / renv::install().",
    call. = FALSE
  )
}

cat("Package check passed.\n")

