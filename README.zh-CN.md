# 贝叶斯网络结构学习中的 MCMC 实验

[English README](./README.md)

[![R](https://img.shields.io/badge/R-4.5.1-276DC3?logo=r&logoColor=white)](https://www.r-project.org/)
[![renv](https://img.shields.io/badge/renv-locked%20environment-75AADB)](https://rstudio.github.io/renv/)
[![BiDAG](https://img.shields.io/badge/BiDAG-reference%20implementation-4B5563)](https://github.com/cran/BiDAG)
[![Python](https://img.shields.io/badge/Python-plotting-3776AB?logo=python&logoColor=white)](./scripts/plot_results.py)
[![Reproducible](https://img.shields.io/badge/environment-reproducible-brightgreen)](./renv.lock)
[![Results](https://img.shields.io/badge/results-included-lightgrey)](./results/README.md)

本仓库是 2026 Spring NKU 统计计算课程大作业的源代码仓库。项目围绕贝叶斯网络结构学习中的 MCMC 方法展开，主要内容包括 Structure MCMC、Order MCMC、Partition-state MCMC 的手工实现，以及基于 `BiDAG` 包的 Order MCMC、Partition MCMC 和 iterative/hybrid MCMC 对照实验。

仓库包含复现实验所需的 R 源代码、实验脚本、notebook、模拟数据、结果表、图像和原始 RDS 结果对象。LaTeX 报告和编译后的 PDF 不放在本仓库中；本仓库重点保存可复现的代码、数据与结果。

## 仓库结构

```text
.
├── R/                    核心 R 函数：模拟、MCMC、BiDAG 封装和指标计算
├── scripts/              实验脚本和作图入口
├── notebooks/            环境检查、主流程复现和结果查看 notebook
├── data/                 模拟数据和可选 benchmark 数据位置
├── results/              已生成的表格、图像、原始对象和日志
├── renv/                 renv 激活文件
├── renv.lock             R 包版本锁定文件
├── restore_environment.R 依赖恢复脚本
├── run_all.R             主实验流程入口
└── README.md             英文说明
```

`data/` 和 `results/` 中保留了已生成的数据和结果，因此不重新运行全部实验也可以直接检查主要输出。所有结果仍可由脚本重新生成。

## 环境

实验环境为 R 4.5.1，R 包版本记录在 `renv.lock` 中。首次运行时，在仓库根目录执行：

```r
install.packages("renv")
source("restore_environment.R")
```

Python 用于生成组合图，以及中等规模原论文对照实验中的 numpy 版本实现。相关脚本按需依赖 `matplotlib`、`seaborn`、`pandas` 和 `numpy`。如果安装了 `uv`，可以直接运行：

```powershell
uv run scripts/plot_results.py
```

否则在当前 Python 环境中安装上述依赖后运行：

```powershell
python scripts/plot_results.py
```

## 快速检查

仓库根目录下可运行最小流程：

```r
source("restore_environment.R")
source("R/load_project.R")
load_project()
source("scripts/smoke_test.R")
```

等价的 PowerShell 命令为：

```powershell
Rscript -e "source('restore_environment.R'); source('R/load_project.R'); load_project(); source('scripts/smoke_test.R')"
```

`smoke_test.R` 覆盖数据模拟、BiDAG 调用、指标计算和结果写出。运行结果会写入 `results/tables/`、`results/figures/`、`results/raw/` 和 `results/logs/`。

## 实验运行

主实验流程由 `run_all.R` 统一调度：

```r
source("run_all.R")
```

`run_all.R` 按顺序执行下列脚本：

| 脚本 | 作用 |
| --- | --- |
| `scripts/smoke_test.R` | 最小可运行流程 |
| `scripts/exp_manual_validation.R` | 手工 MCMC 实现验证 |
| `scripts/exp_manual_bidag_compare.R` | 手工实现与 BiDAG 的同参数对比 |
| `scripts/exp_small_compare.R` | 小规模 Order/Partition 比较 |
| `scripts/exp_medium_compare.R` | 中等规模 Order/Partition 比较 |
| `scripts/exp_highdim_hybrid.R` | iterative/hybrid 补充实验 |
| `scripts/exp_sample_size.R` | 样本量敏感性实验 |
| `scripts/exp_manual_sensitivity.R` | 最大父节点数 `K` 的敏感性实验 |
| `scripts/exp_posterior_uncertainty.R` | 边后验不确定性分析 |

也可以单独运行某个实验，例如：

```r
source("scripts/exp_manual_bidag_compare.R")
```

另有两个可选脚本不包含在默认主流程中：

| 脚本 | 作用 |
| --- | --- |
| `scripts/exp_convergence_diagnostics.R` | 收敛诊断原型 |
| `scripts/exp_benchmark_optional.R` | 可选 benchmark 网络实验 |

## 作图

结果表生成后，可以由 Python 脚本重新生成组合图：

```powershell
python scripts/plot_results.py
```

该脚本读取 `results/tables/*.csv`，并将图像写入 `results/figures/`。

## 实现说明

手工实现位于 `R/manual_mcmc.R`。代码实现了 Gaussian BIC 评分、proposal 生成、Metropolis-Hastings 接受步骤和边后验概率累积。该部分保留了父集枚举、order/partition 评分和邻接矩阵重建等关键计算过程，便于直接检查算法细节。

BiDAG 对照实验位于 `R/bidag_runner.R`。该文件封装了 `BiDAG` 的 BGe 评分和 `sampleBN` 等接口，用于运行 Order MCMC、Partition MCMC 和 iterative MCMC。BiDAG 的 CRAN GitHub 镜像见：<https://github.com/cran/BiDAG>。

手工实现通常慢于 BiDAG。主要原因是手工实现保留了较多 R 层循环和显式查表操作，而 BiDAG 使用搜索空间剪枝、评分表复用以及部分 Rcpp/C++ 辅助计算。手工实现的作用是提供可检查、可对照的算法实现；正式性能比较以共同指标输出为准。

评价指标位于 `R/metrics.R`，包括 SHD、TPR、FPR、precision、recall、F1 和运行时间。

## 版本控制范围

本仓库保留：

- R 源代码和实验脚本；
- notebook；
- 模拟数据；
- 结果表、图像、日志和原始 RDS 对象；
- `renv.lock` 和 `renv/activate.R`；
- 轻量说明文档。

本仓库不提交：

- LaTeX 报告和 PDF；
- 本地 `renv/library/` 包库；
- `renv/staging/`、`renv/python/`、`renv/sandbox/`；
- 本地打包目录 `dist/`。

本地包库没有提交是有意设计。`renv/library/` 与操作系统、R 版本和本机路径相关，不适合作为 GitHub 源码的一部分；依赖环境由 `renv.lock` 记录，并通过 `source("restore_environment.R")` 恢复。
