# data 数据目录

本目录保存实验数据。主线实验使用脚本生成的线性高斯贝叶斯网络模拟数据；可选 benchmark 数据仅对应额外实验。

## 子目录

- `simulated/`：模拟数据目录。文件名通常包含节点数、样本量和随机种子，例如 `p20_n500_seed1_data.csv`、`p20_n500_seed1_adj.csv` 和 `p20_n500_seed1_beta.csv`。
- `benchmark/`：可选 benchmark 数据目录，可放置 Asia、Sachs、ALARM 等外部网络数据。主线实验不依赖该目录。

## 文件类型

- `*_data.csv`：模拟观测数据矩阵。
- `*_adj.csv`：真实 DAG 邻接矩阵。
- `*_beta.csv`：线性结构方程中的边权矩阵。

默认实验会自动生成或复用 `simulated/` 中的数据。
