# Result Index

这里列出当前已经生成并被报告使用的结果。

## 主线结果表

| 文件 | 实验 | 报告用途 |
| --- | --- | --- |
| `tables/smoke_test_metrics.csv` | smoke test | 验证 Order / Partition 最小链路 |
| `tables/manual_validation_metrics.csv` | 手工 MCMC 验证 | Structure / Order / Partition-style 教学版比较 |
| `tables/manual_validation_summary.csv` | 手工 MCMC 验证汇总 | 报告手工实现结果表 |
| `tables/small_compare_metrics.csv` | 小规模比较 | Order vs Partition 明细 |
| `tables/small_compare_summary.csv` | 小规模比较汇总 | 报告小规模结果表 |
| `tables/medium_compare_metrics.csv` | 中等规模比较 | p=30 对比结果 |
| `tables/medium_compare_summary.csv` | 中等规模比较汇总 | 报告中等规模结果表 |
| `tables/highdim_hybrid_metrics.csv` | iterative 补充实验 | p=40 补充实验结果 |
| `tables/highdim_hybrid_summary.csv` | iterative 补充实验汇总 | 报告补充结果表 |
| `tables/sample_size_metrics.csv` | 样本量影响 | p=20, n 变化明细 |
| `tables/sample_size_summary.csv` | 样本量影响汇总 | 报告样本量结果表 |
| `tables/posterior_uncertainty_metrics.csv` | 边后验不确定性分析 | 扩展实验：结构不确定性 |
| `tables/posterior_uncertainty_summary.csv` | 边后验不确定性汇总 | 报告扩展实验表 |
| `tables/manual_sensitivity_metrics.csv` | 手工父节点约束敏感性 | 扩展实验：父集搜索空间 |
| `tables/manual_sensitivity_summary.csv` | 手工父节点约束敏感性汇总 | 报告扩展实验表 |

## 主线图片

| 文件 | 内容 |
| --- | --- |
| `figures/smoke_test_shd.png` | smoke test 的 SHD |
| `figures/smoke_test_runtime.png` | smoke test 的运行时间 |
| `figures/manual_validation_shd.png` | 手工方法 SHD |
| `figures/manual_validation_f1.png` | 手工方法 F1 |
| `figures/manual_validation_runtime.png` | 手工方法运行时间 |
| `figures/small_compare_shd.png` | 小规模 SHD |
| `figures/small_compare_f1.png` | 小规模 F1 |
| `figures/small_compare_runtime.png` | 小规模运行时间 |
| `figures/medium_compare_shd.png` | 中等规模 SHD |
| `figures/medium_compare_runtime.png` | 中等规模运行时间 |
| `figures/highdim_hybrid_shd.png` | iterative 补充实验 SHD |
| `figures/highdim_hybrid_runtime.png` | iterative 补充实验运行时间 |
| `figures/sample_size_shd.png` | 样本量变化下的 SHD |
| `figures/sample_size_f1.png` | 样本量变化下的 F1 |
| `figures/posterior_uncertainty_entropy_by_p.png` | 不同维度下的平均边后验熵 |
| `figures/posterior_uncertainty_true_false_gap.png` | 真边与假边边后验分离度 |
| `figures/manual_sensitivity_f1.png` | 最大父节点数对手工 F1 的影响 |
| `figures/manual_sensitivity_runtime.png` | 最大父节点数对手工运行时间的影响 |

## 生成报告资产

运行：

```r
source("scripts/build_report_assets.R")
```

会把上述结果整理到：

```text
report/tables/
report/figures/
```

报告只引用整理后的 `report/tables/*.tex` 和 `report/figures/*.png`。
