# notebooks 目录

Notebook 提供交互式检查、实验展示和结果浏览入口。它们不重复实现核心算法；核心函数位于 `R/`，正式实验入口位于 `scripts/` 和 `run_all.R`。

文件说明：

- `environment.ipynb`：检查 `renv` 环境、加载项目函数并输出 `sessionInfo()`。
- `main_reproduction.ipynb`：以 notebook 形式运行 smoke test、主实验入口和报告资源整理脚本。
- `result_analysis.ipynb`：读取 `results/tables/` 中的 CSV 表格，辅助查看手工实现与 BiDAG 等实验结果。

Notebook 的第一个 cell 使用统一加载方式。若 notebook 从 `notebooks/` 目录启动，代码会自动切换到项目根目录：

```r
if (!dir.exists("R") && dir.exists("../R")) setwd("..")
stopifnot(dir.exists("R"), dir.exists("scripts"))
if (file.exists("renv/activate.R")) source("renv/activate.R")
source("R/load_project.R")
load_project()
```
