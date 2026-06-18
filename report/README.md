# 报告目录

本目录保存课程报告的最终版本、参考文献、报告图表和 LaTeX 表格。

主要内容：

- `Report.tex`：最终 LaTeX 报告源文件。
- `Report.pdf`：编译后的最终报告。
- `references.bib`：BibTeX 参考文献。
- `tables/`：由实验结果转换得到的 LaTeX 表格。
- `figures/`：报告引用的图像副本。
- `tables/medium_original_reproduction/` 与 `figures/medium_original_reproduction/`：中等规模原论文对照实验的表格和图像，包含 Python/numpy、R 自主实现和 BiDAG 三类实现路径的比较。

从项目根目录重新编译报告：

```r
source("scripts/build_report_assets.R")
source("scripts/compile_latex_report.R")
```
