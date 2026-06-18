if (!dir.exists("report")) {
  stop("Run this script from the Project directory.", call. = FALSE)
}

tex_file <- file.path("report", "Report.tex")
if (!file.exists(tex_file)) {
  stop("Missing report/Report.tex", call. = FALSE)
}

old_wd <- getwd()
on.exit(setwd(old_wd), add = TRUE)
setwd("report")

cmd <- Sys.which("xelatex")
if (cmd == "") {
  stop("xelatex was not found. Install TeX Live or compile Report.tex manually.", call. = FALSE)
}

run_xelatex <- function() {
  status <- system2(cmd, c("-interaction=nonstopmode", "-halt-on-error", "Report.tex"))
  if (!identical(status, 0L)) {
    stop("xelatex failed. See report/Report.log.", call. = FALSE)
  }
}

run_xelatex()

if (file.exists("references.bib")) {
  bibtex <- Sys.which("bibtex")
  if (bibtex != "") {
    status <- system2(bibtex, "Report")
    if (!identical(status, 0L)) {
      if (!file.exists("Report.bbl")) {
        stop("bibtex failed and Report.bbl is missing.", call. = FALSE)
      }
      warning("bibtex failed; using existing Report.bbl.", call. = FALSE)
    }
  }
}

run_xelatex()
run_xelatex()

message("LaTeX report compiled: report/Report.pdf")
