# R Source Files

This directory contains the reusable R functions used by the experiment scripts.

Load the project functions from the repository root:

```r
source("R/load_project.R")
load_project()
```

## File Map

| File | Role |
| --- | --- |
| `load_project.R` | Loads all core R source files in a fixed order |
| `packages.R` | Checks required package availability |
| `graph_utils.R` | DAG utilities, graph conversion and random DAG generation |
| `simulation.R` | Linear Gaussian Bayesian network simulation |
| `bidag_runner.R` | BiDAG wrappers for Order, Partition and iterative MCMC |
| `manual_mcmc.R` | Manual Structure/Order/Partition-state MCMC implementation |
| `metrics.R` | SHD, TPR, FPR, precision, recall and F1 calculations |
| `plotting.R` | Shared ggplot2 theme and simple plotting helpers |
| `experiments.R` | Experiment scheduling, checkpointing and metric writing |

The code submission does not include report-specific helpers. Report generation is handled outside this repository.
