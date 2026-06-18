# MCMC Methods for Bayesian Network Structure Learning

[English version](readme-en.md) | [中文版](README.md)

This is the code repository for the Statistical Computing course assignment. The code mainly compares Structure MCMC, Order MCMC, Partition MCMC, and hybrid/iterative MCMC. R is the primary language, with Python used for supplementary control experiments and plotting.

## Directory

```text
R/          Core functions
scripts/    Experiment and plotting scripts
data/       Simulated data
results/    Experiment results, tables, and figures
notebooks/  Optional notebooks
```

## Environment

All commands are run from the project root by default.

```bash
cd /path/to/Project
```

Requirements:

- R ~4.5
- TeX Live or MiKTeX
- Python 3.10+
- `uv`

R packages are pinned with `renv.lock`. Restore the environment before the first run:

```r
install.packages("renv")
source("restore_environment.R")
```

If you are rebuilding the environment from scratch, use:

```r
install.packages("renv")
source("sync_environment.R")
```

LaTeX requires `xelatex` and `bibtex`. A minimal TeX Live needs `ctex`, `natbib`, `algorithm`, `algpseudocode`. On NixOS the corresponding packages are `algorithms` and `algorithmicx`.

## Quick Test

Run a small test to verify the environment:

```r
source("R/load_project.R")
load_project()
source("scripts/smoke_test.R")
```

## Reproducing Experiments

To run the main experiments:

```r
source("run_all.R")
```

This runs the following in order:

```text
scripts/smoke_test.R
scripts/exp_manual_validation.R
scripts/exp_manual_bidag_compare.R
scripts/exp_small_compare.R
scripts/exp_medium_compare.R
scripts/exp_highdim_hybrid.R
scripts/exp_sample_size.R
scripts/exp_manual_sensitivity.R
scripts/exp_posterior_uncertainty.R
```

You can also run individual scripts, e.g.:

```r
source("scripts/exp_manual_bidag_compare.R")
source("scripts/exp_manual_sensitivity.R")
```

Results are mainly in:

```text
results/tables/
results/figures/
results/raw/
```

## Medium-Scale Comparative Experiments

These are located in:

```text
scripts/medium_original_reproduction/
```

Run the Python part first:

```bash
cd scripts/medium_original_reproduction
uv sync
uv run python run_python_and_save_data.py
cd ../..
```

Then run the R part:

```r
source("scripts/medium_original_reproduction/run_r_biag_manual.R")
source("scripts/medium_original_reproduction/run_r_hybrid.R")
```

Finally merge the results:

```bash
cd scripts/medium_original_reproduction
uv run python merge_all.py
uv run python build_report_assets.py
cd ../..
```

Output location:

```text
results/medium_original_reproduction/
```

## Existing Results

If you just want to view the results without rerunning experiments, see:

```text
results/tables/
results/figures/
results/RESULT_INDEX.md
```

Full experiments take considerable time, especially the medium-scale and high-dimensional/hybrid sections.
