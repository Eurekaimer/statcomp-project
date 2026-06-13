# scripts 实验脚本目录

这里保存可以直接运行的实验入口。所有脚本默认从 `Project` 根目录运行。

常用命令：

```r
source("scripts/smoke_test.R")
source("scripts/exp_manual_validation.R")
source("scripts/exp_manual_bidag_compare.R")
source("run_all.R")
source("scripts/build_report_assets.R")
source("scripts/compile_latex_report.R")
```

脚本说明：

- `smoke_test.R`：最小可运行测试，覆盖数据生成、BiDAG 调用、指标计算和结果写出。
- `exp_manual_validation.R`：手工 MCMC 验证实验。
- `exp_manual_bidag_compare.R`：手工实现与 BiDAG 的同参数小规模对比，显式记录手工方法的父节点上限 `K`。
- `exp_small_compare.R`：小规模 Order / Partition 比较。
- `exp_medium_compare.R`：中等规模比较，带 checkpoint。
- `exp_highdim_hybrid.R`：iterative / hybrid 补充实验。
- `exp_sample_size.R`：样本量影响实验。
- `exp_posterior_uncertainty.R`：基于 `results/raw/` 的边后验不确定性分析。
- `exp_manual_sensitivity.R`：手工 MCMC 最大父节点数敏感性实验。
- `exp_benchmark_optional.R`：可选 benchmark，不进入默认 `run_all.R`。
- `build_report_assets.R`：把 `results/` 中的 CSV 和图片整理到 `report/tables/` 与 `report/figures/`。
- `compile_latex_report.R`：编译 LaTeX 报告。
- `medium_original_reproduction/`：中等规模原论文对照实验，包含 Python/numpy 实现、R 自主实现、BiDAG 调用和报告图表生成脚本。Python 入口为 `run_python_and_save_data.py`，输出文件为 `results/medium_original_reproduction/tables/python_results.csv`。

`run_all.R` 的执行顺序：

1. `scripts/smoke_test.R`
2. `scripts/exp_manual_validation.R`
3. `scripts/exp_manual_bidag_compare.R`
4. `scripts/exp_small_compare.R`
5. `scripts/exp_medium_compare.R`
6. `scripts/exp_highdim_hybrid.R`
7. `scripts/exp_sample_size.R`
8. `scripts/exp_manual_sensitivity.R`
9. `scripts/exp_posterior_uncertainty.R`

报告资源和 PDF 由 `build_report_assets.R` 与 `compile_latex_report.R` 单独生成。
