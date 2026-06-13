# notebooks

These notebooks provide interactive entry points for environment checks, experiment execution and result inspection. They do not reimplement the core algorithms; reusable functions are stored in `R/`, and batch entry points are stored in `scripts/` and `run_all.R`.

## Files

- `environment.ipynb`: loads the project environment and records `sessionInfo()`.
- `main_reproduction.ipynb`: runs the smoke test and the main experiment pipeline.
- `result_analysis.ipynb`: reads generated CSV tables from `results/tables/` and inspects selected summaries.

The first code cell uses relative project-root detection:

```r
if (!dir.exists("R") && dir.exists("../R")) setwd("..")
stopifnot(dir.exists("R"), dir.exists("scripts"))
if (file.exists("renv/activate.R")) source("renv/activate.R")
source("R/load_project.R")
load_project()
```
