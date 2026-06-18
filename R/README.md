# R 代码目录

这里放项目核心函数。Notebook 和实验脚本调用这里的函数，避免在入口脚本中重复实现核心逻辑。

推荐加载方式：

```r
source("R/load_project.R")
load_project()
```

文件说明：

- `load_project.R`：统一加载入口。
- `packages.R`：检查项目依赖包，不自动安装。
- `graph_utils.R`：DAG 邻接矩阵、igraph 转换、随机 DAG 生成。
- `simulation.R`：线性高斯贝叶斯网络数据模拟。
- `bidag_runner.R`：BiDAG 的 Order、Partition、iterative MCMC 统一包装。
- `manual_mcmc.R`：手工实现的 Structure / Order / Partition-state MCMC。
- `metrics.R`：SHD、TPR、FPR、precision、recall、F1 等指标。
- `plotting.R`：统一 ggplot2 作图主题和绘图函数。
- `experiments.R`：实验调度、checkpoint、结果写出。

主要阅读顺序：

1. `load_project.R`
2. `simulation.R`
3. `manual_mcmc.R`
4. `bidag_runner.R`
5. `metrics.R`
6. `experiments.R`
