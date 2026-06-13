# Bayesian Network MCMC Experiments

[中文说明](./README.zh-CN.md)

[![R](https://img.shields.io/badge/R-4.5.1-276DC3?logo=r&logoColor=white)](https://www.r-project.org/)
[![renv](https://img.shields.io/badge/renv-locked%20environment-75AADB)](https://rstudio.github.io/renv/)
[![BiDAG](https://img.shields.io/badge/BiDAG-reference%20implementation-4B5563)](https://github.com/cran/BiDAG)
[![Python](https://img.shields.io/badge/Python-plotting-3776AB?logo=python&logoColor=white)](./scripts/plot_results.py)
[![Reproducible](https://img.shields.io/badge/environment-reproducible-brightgreen)](./renv.lock)
[![Results](https://img.shields.io/badge/results-included-lightgrey)](./results/README.md)

This repository contains reproducible code for Bayesian network structure learning experiments based on Markov chain Monte Carlo methods. It includes readable manual implementations of Structure MCMC, Order MCMC and a simplified partition-state sampler, together with reference experiments built on the BiDAG R package.

The repository includes the source code, notebooks, simulated data and generated result files needed to inspect and reproduce the reported experiments. The LaTeX report and compiled PDF are kept outside this repository.

## Repository Structure

```text
.
├── R/                    Core functions for simulation, MCMC, BiDAG wrappers and metrics
├── scripts/              Experiment scripts and plotting entry points
├── notebooks/            Interactive environment, reproduction and result-inspection notebooks
├── data/                 Simulated data and optional benchmark-data location
├── results/              Generated tables, figures, raw objects and logs
├── renv/                 renv activation files
├── renv.lock             Locked R package versions
├── restore_environment.R Dependency restoration helper
├── run_all.R             Main experiment runner
└── README.md             Reproduction guide
```

The repository contains generated data and results so that the reported outputs can be inspected without rerunning every experiment. The scripts can still regenerate these files.

## Environment

The experiments were developed with R 4.5.1. Package versions are recorded in `renv.lock`.

Restore the R environment from the repository root:

```r
install.packages("renv")
source("restore_environment.R")
```

The Python plotting script requires `matplotlib`, `seaborn`, `pandas` and `numpy`. If `uv` is available, use `uv run scripts/plot_results.py`; otherwise install these packages in the active Python environment and run the script with `python`.

## Quick Check

Run a minimal end-to-end check before launching the full experiment suite:

```r
source("restore_environment.R")
source("R/load_project.R")
load_project()
source("scripts/smoke_test.R")
```

Equivalent PowerShell command:

```powershell
Rscript -e "source('restore_environment.R'); source('R/load_project.R'); load_project(); source('scripts/smoke_test.R')"
```

The smoke test verifies data simulation, BiDAG execution, metric computation and output writing. Generated files are placed under `results/tables/`, `results/figures/`, `results/raw/` and `results/logs/`.

## Running Experiments

Run the main experimental pipeline from the repository root:

```r
source("run_all.R")
```

`run_all.R` executes the following scripts:

| Script | Purpose |
| --- | --- |
| `scripts/smoke_test.R` | Minimal executable workflow |
| `scripts/exp_manual_validation.R` | Validation of manual MCMC implementations |
| `scripts/exp_manual_bidag_compare.R` | Matched manual-vs-BiDAG comparison |
| `scripts/exp_small_compare.R` | Small-scale Order/Partition comparison |
| `scripts/exp_medium_compare.R` | Medium-scale comparison with fallback handling |
| `scripts/exp_highdim_hybrid.R` | High-dimensional iterative/hybrid demonstration |
| `scripts/exp_sample_size.R` | Sample-size sensitivity experiment |
| `scripts/exp_manual_sensitivity.R` | Sensitivity to the maximum parent-set size `K` |
| `scripts/exp_posterior_uncertainty.R` | Edge posterior uncertainty summaries |

Individual experiments can be run directly:

```r
source("scripts/exp_manual_bidag_compare.R")
```

Optional scripts are kept outside the main runner because they may require additional data or longer runtime:

| Script | Purpose |
| --- | --- |
| `scripts/exp_convergence_diagnostics.R` | Prototype convergence diagnostics |
| `scripts/exp_benchmark_optional.R` | Optional benchmark-network experiments |

## Medium-Scale Original Paper Reproduction

A three-way comparison experiment benchmarking Python implementation, R manual implementation, and BiDAG official package against original paper trends (Friedman & Koller 2003, Kuipers & Moffa 2017).

### Three-Step Workflow

**Step 1 — Python MCMC + shared data generation:**

```powershell
python scripts/medium_original_reproduction/run_c_and_save_data.py
```

Generates simulated data (`data/simulated/p{n}_n{n}_seed{n}_*.csv`) and runs Python-native Order and Structure MCMC (BIC score, numpy). Results written to `results/medium_original_reproduction/tables/c_results.csv`.

**Step 2 — BiDAG + R manual (run from RStudio with renv activated):**

```r
setwd("C:/Users/HuangZg/OneDrive/Desktop/SC-project-r/Project")
source("renv/activate.R")
source("scripts/medium_original_reproduction/run_r_biag_manual.R")
```

Runs BiDAG order/partition + manual order/structure/partition on the same data. Results written to `results/medium_original_reproduction/tables/r_results.csv`.

**Step 3 — Merge and build report assets:**

```powershell
python scripts/medium_original_reproduction/merge_all.py
python scripts/medium_original_reproduction/build_report_assets.py
```

Produces:
- `results/medium_original_reproduction/tables/medium_original_metrics.csv` (132 MCMC runs)
- `results/medium_original_reproduction/tables/medium_original_summary.csv`
- `report/tables/medium_original_reproduction/*.tex`
- `report/figures/medium_original_reproduction/*.png`

### Experiment Grid

| Experiment | Data Source | p | n | Methods |
|---|---|---|---|---|
| Order MCMC (F&K 2003) | simulated\_flare\_like | 9 | 500, 1000 | Python order/structure, BiDAG order/partition, R manual order/structure/partition |
| Order MCMC (F&K 2003) | simulated\_alarm\_like | 37 | 500, 1000 | Python order/structure, BiDAG order, R manual order/structure |
| Partition MCMC (K&M 2017) | simulated\_toy\_like | 5 | 200, 500 | all three implementations |
| Partition MCMC (K&M 2017) | simulated\_boston\_like | 14 | 200, 500 | all three implementations |
| Partition MCMC (K&M 2017) | simulated\_large\_like | 20 | 200, 500 | all three implementations |
| Hybrid/Iterative (KSM 2022) | simulated\_p40 | 40 | 200 | BiDAG iterative only |

### Key Results

- BiDAG achieves best SHD/F1 at all scales; at p=5 BiDAG partition achieves SHD=0 (perfect recovery).
- Order MCMC consistently outperforms Structure MCMC; the gap widens from +3 SHD at p=5 to +52 SHD at p=37, reproducing Friedman & Koller (2003).
- BiDAG partition MCMC at p=20 (SHD=5.0) significantly outperforms BiDAG order (SHD=10.2), supporting Kuipers & Moffa (2017).
- BiDAG iterative MCMC at p=40 (SHD=15.0, F1=0.782) confirms feasibility of search-space reduction, matching Kuipers, Suter & Moffa (2022).
- Python implementation is ~50× faster than R manual at p=37 while maintaining identical accuracy (both BIC).
- All 134 MCMC runs completed successfully with zero failures.

### Why Three Implementations?

The three-way comparison (Python + R manual + BiDAG) is intentional, not redundant:

| Implementation | Scoring | Speed | Purpose |
|---|---|---|---|
| R manual | BIC | slow | Fully auditable mechanism reference |
| Python (numpy) | BIC | fast (~50× vs R) | Same algorithm, vectorized; validates correctness |
| BiDAG (R + C++) | BGe | fast | Production-grade reference; BGe > BIC in precision |

Python and R manual use the same BIC scoring and produce nearly identical SHD/F1 — two independent codebases converging on the same numbers eliminates implementation bugs. BiDAG's superior precision is attributable to BGe marginal likelihood scoring and search-space pruning, not just faster code.

## Plotting

After CSV result files have been generated, produce combined figures with:

```powershell
uv run scripts/plot_results.py
```

or:

```powershell
python scripts/plot_results.py
```

The plotting script reads `results/tables/*.csv` and writes figures to `results/figures/`.

## Implementation Notes

Manual samplers are implemented in `R/manual_mcmc.R`. They use Gaussian BIC scoring, explicit proposal generation, Metropolis-Hastings acceptance and edge posterior accumulation. The implementation prioritizes transparency: parent sets are enumerated, order and partition scores are recomputed through R-level logic, and sampled adjacency matrices are reconstructed for posterior summaries.

BiDAG-based experiments are wrapped in `R/bidag_runner.R`. They use BiDAG's BGe scoring and sampling interfaces for Order MCMC, Partition MCMC and iterative MCMC. The BiDAG source is available from the CRAN GitHub mirror: <https://github.com/cran/BiDAG>. Its package metadata describes data-driven search-space pruning based on a PC-algorithm skeleton followed by search-and-score refinement. The source also links against `Rcpp` and contains compiled C++ helper routines under `src/`.

For this reason, the manual samplers are expected to be slower than BiDAG. Their role is methodological inspection and controlled comparison, not optimized production inference.

Common evaluation metrics are implemented in `R/metrics.R`, including SHD, TPR, FPR, precision, recall, F1 and runtime.

## Version-Control Scope

Files intended for version control include source code, notebooks, simulated data, generated result tables and figures, raw RDS objects used by downstream summaries, dependency metadata and lightweight documentation.

The following local or report-specific artifacts are excluded by `.gitignore`:

- `report/`
- `renv/library/`
- `renv/staging/`
- `renv/python/`
- `renv/sandbox/`
- `dist/`

The local package library is intentionally not committed. It is platform- and R-version-specific, and can be restored from `renv.lock` with `source("restore_environment.R")`.
