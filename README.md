# 贝叶斯网络结构学习中的 MCMC 方法

[English version](readme-en.md) | [中文版](README.md)

这是统计计算课程大作业的项目目录。最终报告在：

- `report/Report.pdf`
- `report/Report.tex`

代码主要比较 Structure MCMC、Order MCMC、Partition MCMC 和 hybrid/iterative MCMC。R 代码是主线，Python 主要用于部分对照实验和画图。

## 目录

```text
R/          核心函数
scripts/    实验脚本和画图脚本
data/       模拟数据
results/    实验结果、表格和图片
report/     报告、参考文献、报告用表格和图片
notebooks/  可选 notebook
```

## 环境

所有命令默认在项目根目录运行。

```bash
cd /path/to/Project
```

需要：

- R 4.5 左右
- TeX Live 或 MiKTeX
- Python 3.10+
- `uv`

R 包用 `renv.lock` 固定。第一次运行前先恢复环境：

```r
install.packages("renv")
source("restore_environment.R")
```

如果是自己重新整理环境，可以用：

```r
install.packages("renv")
source("sync_environment.R")
```

LaTeX 需要 `xelatex` 和 `bibtex`。如果是精简 TeX Live，需要有 `ctex`、`natbib`、`algorithm`、`algpseudocode`。NixOS 下对应包是 `algorithms` 和 `algorithmicx`。

## 快速测试

先跑一个小测试，确认环境没问题：

```r
source("R/load_project.R")
load_project()
source("scripts/smoke_test.R")
```

## 复现实验

主线实验直接运行：

```r
source("run_all.R")
```

它会按顺序运行：

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

也可以单独运行某个脚本，例如：

```r
source("scripts/exp_manual_bidag_compare.R")
source("scripts/exp_manual_sensitivity.R")
```

结果主要在：

```text
results/tables/
results/figures/
results/raw/
```

## 中等规模对照实验

这部分在：

```text
scripts/medium_original_reproduction/
```

先运行 Python 部分：

```bash
cd scripts/medium_original_reproduction
uv sync
uv run python run_python_and_save_data.py
cd ../..
```

再运行 R 部分：

```r
source("scripts/medium_original_reproduction/run_r_biag_manual.R")
source("scripts/medium_original_reproduction/run_r_hybrid.R")
```

最后合并结果：

```bash
cd scripts/medium_original_reproduction
uv run python merge_all.py
uv run python build_report_assets.py
cd ../..
```

输出位置：

```text
results/medium_original_reproduction/
report/tables/medium_original_reproduction/
report/figures/medium_original_reproduction/
```

## 重新生成报告

先整理报告用表格和图片：

```r
source("scripts/build_report_assets.R")
```

生成 Python 组合图：

```bash
uv run --script scripts/plot_results.py
uv run --script scripts/plot_concepts.py
```

编译报告：

```r
source("scripts/compile_latex_report.R")
```

生成的 PDF 在：

```text
report/Report.pdf
```

也可以手动编译：

```bash
cd report
xelatex Report.tex
bibtex Report
xelatex Report.tex
xelatex Report.tex
```

## 已有结果

如果只是看结果，不需要重新跑实验，直接看：

```text
report/Report.pdf
results/tables/
results/figures/
results/RESULT_INDEX.md
```

完整实验会花比较久，尤其是中等规模和 high-dimensional/hybrid 部分。
