core_packages <- c(
  "BiDAG",
  "bnlearn",
  "igraph",
  "pcalg",
  "ggplot2"
)

missing_packages <- core_packages[!vapply(core_packages, requireNamespace, logical(1), quietly = TRUE)]

if ("BiDAG" %in% missing_packages) {
  stop(
    "BiDAG is required but not installed. In the repository root, run ",
    "source('restore_environment.R') to restore packages from renv.lock.",
    call. = FALSE
  )
}

if (length(missing_packages) > 0) {
  stop(
    "Missing required packages: ", paste(missing_packages, collapse = ", "),
    ". Restore them with source('restore_environment.R').",
    call. = FALSE
  )
}

cat("Package check passed.\n")
