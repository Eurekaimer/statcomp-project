# Result Index

This file lists generated outputs included with the repository. The files are used for result inspection, plotting and comparison with rerun experiments.

## Main Tables

| File | Experiment | Role |
| --- | --- | --- |
| `tables/smoke_test_metrics.csv` | smoke test | Minimal Order/Partition workflow check |
| `tables/manual_validation_metrics.csv` | manual MCMC validation | Per-run manual Structure/Order/Partition-state metrics |
| `tables/manual_validation_summary.csv` | manual MCMC validation | Summary of manual implementation results |
| `tables/manual_bidag_compare_metrics.csv` | manual vs BiDAG comparison | Matched per-run comparison |
| `tables/manual_bidag_compare_summary.csv` | manual vs BiDAG comparison | Summary of matched comparison |
| `tables/small_compare_metrics.csv` | small-scale comparison | Order vs Partition details |
| `tables/small_compare_summary.csv` | small-scale comparison | Summary of small-scale results |
| `tables/medium_compare_metrics.csv` | medium-scale comparison | Stable fallback results |
| `tables/medium_compare_summary.csv` | medium-scale comparison | Summary of medium-scale results |
| `tables/highdim_hybrid_metrics.csv` | high-dimensional iterative demonstration | High-dimensional run details |
| `tables/highdim_hybrid_summary.csv` | high-dimensional iterative demonstration | Summary of high-dimensional results |
| `tables/sample_size_metrics.csv` | sample-size sensitivity | Per-run sample-size results |
| `tables/sample_size_summary.csv` | sample-size sensitivity | Summary by sample size |
| `tables/posterior_uncertainty_metrics.csv` | posterior uncertainty analysis | Edge-posterior uncertainty details |
| `tables/posterior_uncertainty_summary.csv` | posterior uncertainty analysis | Summary of uncertainty metrics |
| `tables/manual_sensitivity_metrics.csv` | manual parent-set sensitivity | Per-run sensitivity results |
| `tables/manual_sensitivity_summary.csv` | manual parent-set sensitivity | Summary by maximum parent-set size |

## Main Figures

| File | Content |
| --- | --- |
| `figures/smoke_test_shd.png` | Smoke-test SHD |
| `figures/smoke_test_runtime.png` | Smoke-test runtime |
| `figures/manual_validation_shd.png` | Manual-method SHD |
| `figures/manual_validation_f1.png` | Manual-method F1 |
| `figures/manual_validation_runtime.png` | Manual-method runtime |
| `figures/py_manual_bidag_comparison.png` | Manual-vs-BiDAG combined comparison |
| `figures/small_compare_shd.png` | Small-scale SHD |
| `figures/small_compare_f1.png` | Small-scale F1 |
| `figures/small_compare_runtime.png` | Small-scale runtime |
| `figures/medium_compare_shd.png` | Medium-scale SHD |
| `figures/medium_compare_runtime.png` | Medium-scale runtime |
| `figures/highdim_hybrid_shd.png` | High-dimensional iterative SHD |
| `figures/highdim_hybrid_runtime.png` | High-dimensional iterative runtime |
| `figures/sample_size_shd.png` | SHD by sample size |
| `figures/sample_size_f1.png` | F1 by sample size |
| `figures/posterior_uncertainty_entropy_by_p.png` | Mean edge-posterior entropy by dimension |
| `figures/posterior_uncertainty_true_false_gap.png` | True-edge and false-edge posterior separation |
| `figures/manual_sensitivity_f1.png` | Effect of maximum parent-set size on manual F1 |
| `figures/manual_sensitivity_runtime.png` | Effect of maximum parent-set size on manual runtime |

Combined figures can be regenerated from the CSV tables with:

```powershell
python scripts/plot_results.py
```
