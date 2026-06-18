# 打包项目文件和 R 环境。

if (!file.exists("README.md") || !dir.exists("R") || !dir.exists("scripts")) {
  stop("Please run this script from the Project directory.", call. = FALSE)
}

if (!requireNamespace("renv", quietly = TRUE)) {
  stop("renv is required. Run source('sync_environment.R') first.", call. = FALSE)
}

if (!file.exists("renv.lock")) {
  stop("renv.lock does not exist. Run source('sync_environment.R') first.", call. = FALSE)
}

source(file.path("renv", "activate.R"))

if ("isolate" %in% getNamespaceExports("renv")) {
  message("Copying cached packages into the project library with renv::isolate().")
  renv::isolate()
} else {
  message("renv::isolate() is not available in this renv version; continuing with current project library.")
}

dir.create("dist", showWarnings = FALSE)
zipfile <- file.path("dist", paste0("SC_project_r_bundle_", format(Sys.Date(), "%Y%m%d"), ".zip"))

all_files <- list.files(".", all.files = TRUE, no.. = TRUE, recursive = TRUE)
exclude <- grepl("^dist/", all_files) |
  grepl("^\\.Rproj\\.user/", all_files) |
  grepl("^results/raw/", all_files) |
  grepl("^results/logs/.*\\.log$", all_files)
files <- all_files[!exclude]

old_wd <- getwd()
on.exit(setwd(old_wd), add = TRUE)

message("Creating bundle: ", zipfile)
utils::zip(zipfile = zipfile, files = files)
message("Bundle created: ", normalizePath(zipfile, winslash = "/", mustWork = FALSE))
