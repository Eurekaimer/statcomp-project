# Experiment Scripts

Run scripts from the repository root. Each script writes generated outputs under `data/` and `results/`.

## Common Commands

```r
source("scripts/smoke_test.R")
source("scripts/exp_manual_validation.R")
source("scripts/exp_manual_bidag_compare.R")
source("run_all.R")
```

## Script Map

| Script | Purpose |
| --- | --- |
| `smoke_test.R` | Minimum executable check for simulation, BiDAG, metrics and output writing |
| `exp_manual_validation.R` | Validates the three manual MCMC implementations |
| `exp_manual_bidag_compare.R` | Runs a matched manual-vs-BiDAG comparison with explicit manual `K` values |
| `exp_manual_sensitivity.R` | Evaluates sensitivity to the maximum parent-set size `K` |
| `exp_small_compare.R` | Compares BiDAG Order and Partition MCMC on small networks |
| `exp_medium_compare.R` | Runs medium-scale BiDAG comparisons with fallback handling |
| `exp_highdim_hybrid.R` | Demonstrates iterative/hybrid MCMC in a higher-dimensional setting |
| `exp_sample_size.R` | Measures the effect of sample size on recovery accuracy |
| `exp_posterior_uncertainty.R` | Summarizes edge posterior uncertainty from successful raw runs |
| `exp_convergence_diagnostics.R` | Optional convergence-diagnostic prototype |
| `exp_benchmark_optional.R` | Optional benchmark-network experiments |
| `plot_results.py` | Generates combined figures from `results/tables/*.csv` |

`run_all.R` executes the main experimental pipeline. Optional benchmark and convergence-diagnostic scripts are kept separate because they may require additional data or longer runtime.
