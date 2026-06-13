if (!dir.exists("results/tables")) {
  stop("Run from Project directory after experiments have produced results/tables.", call. = FALSE)
}

dir.create("report/tables", recursive = TRUE, showWarnings = FALSE)
dir.create("report/figures", recursive = TRUE, showWarnings = FALSE)

latex_escape <- function(x) {
  x <- as.character(x)
  x <- gsub("\\\\", "\\\\textbackslash{}", x)
  x <- gsub("_", "\\_", x, fixed = TRUE)
  x <- gsub("%", "\\\\%", x, fixed = TRUE)
  x <- gsub("&", "\\\\&", x, fixed = TRUE)
  x
}

fmt <- function(x) {
  if (is.numeric(x)) {
    ifelse(is.na(x), "--", ifelse(abs(x) >= 100, sprintf("%.1f", x), sprintf("%.3f", x)))
  } else {
    latex_escape(x)
  }
}

write_latex_table <- function(df, path, caption, label, align = NULL) {
  if (is.null(align)) align <- paste0("l", paste(rep("r", ncol(df) - 1), collapse = ""))
  formatted <- as.data.frame(lapply(df, fmt), stringsAsFactors = FALSE)
  lines <- c(
    "\\begin{table}[H]",
    "\\centering",
    "\\small",
    "\\setlength{\\tabcolsep}{2pt}",
    paste0("\\caption{", caption, "}"),
    paste0("\\label{", label, "}"),
    paste0("\\begin{tabular}{", align, "}"),
    "\\toprule",
    paste(latex_escape(names(df)), collapse = " & "),
    "\\\\",
    "\\midrule"
  )
  body <- apply(formatted, 1, function(row) paste(row, collapse = " & "))
  lines <- c(lines, paste0(body, " \\\\"), "\\bottomrule", "\\end{tabular}", "\\end{table}")
  writeLines(lines, path, useBytes = TRUE)
}

read_result <- function(name) {
  path <- file.path("results/tables", name)
  if (!file.exists(path)) stop("Missing result table: ", path, call. = FALSE)
  read.csv(path, stringsAsFactors = FALSE)
}

smoke <- read_result("smoke_test_metrics.csv")[, c("method", "runtime", "SHD", "TPR", "FPR", "precision", "F1")]
manual <- read_result("manual_validation_summary.csv")[, c("method", "runtime", "SHD", "TPR", "FPR", "precision", "F1")]
small <- read_result("small_compare_summary.csv")[, c("method", "p", "n", "runtime", "SHD", "TPR", "FPR", "precision", "F1")]
medium <- read_result("medium_compare_summary.csv")[, c("method", "p", "n", "runtime", "SHD", "TPR", "FPR", "precision", "F1")]
high <- read_result("highdim_hybrid_summary.csv")[, c("method", "p", "n", "runtime", "SHD", "TPR", "FPR", "precision", "F1")]
sample_size <- read_result("sample_size_summary.csv")[, c("method", "p", "n", "runtime", "SHD", "TPR", "FPR", "precision", "F1")]
posterior_uncertainty <- read_result("posterior_uncertainty_summary.csv")[,
  c("method", "p", "n", "mean_entropy", "high_uncertainty_fraction",
    "confident_fraction", "true_edge_mean_posterior", "false_edge_mean_posterior")
]
manual_sensitivity <- read_result("manual_sensitivity_summary.csv")[,
  c("method", "max_parents", "runtime", "SHD", "precision", "recall", "F1")
]

names(smoke) <- c("方法", "运行时间", "SHD", "TPR", "FPR", "Precision", "F1")
names(manual) <- c("方法", "运行时间", "SHD", "TPR", "FPR", "Precision", "F1")
names(small) <- c("方法", "p", "n", "运行时间", "SHD", "TPR", "FPR", "Precision", "F1")
names(medium) <- c("方法", "p", "n", "运行时间", "SHD", "TPR", "FPR", "Precision", "F1")
names(high) <- c("方法", "p", "n", "运行时间", "SHD", "TPR", "FPR", "Precision", "F1")
names(sample_size) <- c("方法", "p", "n", "运行时间", "SHD", "TPR", "FPR", "Precision", "F1")
names(posterior_uncertainty) <- c("方法", "p", "n", "平均熵", "高不确定比例", "高置信比例", "真边后验均值", "假边后验均值")
names(manual_sensitivity) <- c("方法", "最大父节点数", "运行时间", "SHD", "Precision", "Recall", "F1")

write_latex_table(smoke, "report/tables/smoke_test.tex", "Smoke test 结果", "tab:smoke")
write_latex_table(manual, "report/tables/manual_validation.tex", "手工实现验证结果", "tab:manual")
write_latex_table(small, "report/tables/small_compare.tex", "小规模 Order MCMC 与 Partition MCMC 比较", "tab:small", align = "lrrrrrrrr")
write_latex_table(medium, "report/tables/medium_compare.tex", "中等规模实验结果", "tab:medium", align = "lrrrrrrrr")
write_latex_table(high, "report/tables/highdim_hybrid.tex", "Iterative MCMC 补充实验结果", "tab:highdim", align = "lrrrrrrrr")
write_latex_table(sample_size, "report/tables/sample_size.tex", "样本量影响实验结果", "tab:sample", align = "lrrrrrrrr")
write_latex_table(posterior_uncertainty, "report/tables/posterior_uncertainty.tex", "边后验不确定性分析结果", "tab:posterior_uncertainty", align = "lrrrrrrr")
write_latex_table(manual_sensitivity, "report/tables/manual_sensitivity.tex", "手工 MCMC 最大父节点数敏感性实验", "tab:manual_sensitivity", align = "lrrrrrr")

method_compare <- data.frame(
  方法 = c("Structure MCMC", "Order MCMC", "Partition MCMC", "Hybrid / iterative MCMC"),
  状态空间 = c("DAG 空间", "变量排序空间", "有序 partition 空间", "缩小后的候选搜索空间"),
  Proposal = c("add / delete / reverse", "swap / relocate / reverse", "split / merge / move", "迭代更新候选父集与 MCMC 搜索"),
  无环约束处理 = c("每步检查 DAG", "排序天然保证", "分层约束保证", "在约束空间内保证"),
  优点 = c("直观、目标明确", "计算较快、避免逐步环检查", "缓解 order-space 偏差", "适合较大规模网络"),
  局限 = c("节点数增加后混合慢", "多个排序可对应同一 DAG", "严格实现复杂", "依赖预筛选质量"),
  本文角色 = c("理论背景与手工基准说明", "手工实现与 BiDAG 复现", "教学版与 BiDAG 复现", "BiDAG 规模扩展补充")
)
write_latex_table(method_compare, "report/tables/method_compare.tex", "MCMC 方法比较", "tab:method_compare", align = "p{1.9cm}p{2.0cm}p{2.5cm}p{2.1cm}p{2.2cm}p{2.0cm}p{2.3cm}")

experiment_design <- data.frame(
  实验 = c("Smoke test", "手工实现验证", "小规模比较", "中等规模比较", "iterative 补充", "样本量影响", "边后验不确定性", "父节点上限敏感性", "Benchmark 可选"),
  目的 = c("检查项目最小链路", "验证手工 MCMC 机制", "比较 Order 与 Partition", "观察 p 增大后的表现", "展示 iterative/hybrid 必要性", "分析 n 对恢复精度影响", "比较结构不确定性", "检验父集约束影响", "预留标准网络对照"),
  p = c("8", "8", "10, 20", "30", "40", "20", "已有 raw 结果", "8", "Asia / Sachs / ALARM 可选"),
  n = c("100", "120", "200, 500", "500", "500", "100, 200, 500, 1000", "已有 raw 结果", "120", "视数据而定"),
  方法 = c("order, partition", "manual_structure, manual_order, manual_partition", "order, partition", "order, partition", "iterative", "order, partition", "所有成功方法", "三种手工方法", "可选"),
  输出指标 = c("SHD, F1, runtime", "SHD, F1, runtime, accept rate", "SHD, F1, runtime", "SHD, F1, runtime", "SHD, F1, runtime", "SHD, F1, runtime", "entropy, posterior gap", "SHD, F1, runtime", "若存在则报告")
)
write_latex_table(experiment_design, "report/tables/experiment_design.tex", "实验设计总表", "tab:experiment_design", align = "p{1.8cm}p{2.8cm}p{2.0cm}p{2.2cm}p{2.7cm}p{2.5cm}")

raw_files <- list.files("results/raw", pattern = "^manual_validation_.*[.]rds$", full.names = TRUE)
if (length(raw_files) > 0) {
  diag_rows <- lapply(raw_files, function(f) {
    x <- readRDS(f)
    tr <- x$result$fit$trace
    ep <- x$result$edge_post
    probs <- as.vector(ep[row(ep) != col(ep)])
    probs <- pmin(pmax(probs, 1e-12), 1 - 1e-12)
    entropy <- -mean(probs * log(probs) + (1 - probs) * log(1 - probs))
    data.frame(
      method = x$result$method,
      seed = x$metrics$seed,
      accept_rate = tr$accept_rate,
      best_score = tr$best_score,
      mean_edge_posterior = mean(as.vector(ep[row(ep) != col(ep)])),
      posterior_entropy = entropy
    )
  })
  manual_diag <- do.call(rbind, diag_rows)
  write.csv(manual_diag, "report/tables/manual_diagnostics.csv", row.names = FALSE)
  manual_diag_summary <- aggregate(
    manual_diag[c("accept_rate", "best_score", "mean_edge_posterior", "posterior_entropy")],
    by = manual_diag["method"],
    FUN = mean
  )
  names(manual_diag_summary) <- c("方法", "接受率", "最佳得分", "平均边后验", "后验熵")
  write_latex_table(manual_diag_summary, "report/tables/manual_diagnostics.tex", "手工 MCMC 采样诊断摘要", "tab:manual_diag", align = "lrrrr")
}

figs <- list.files("results/figures", pattern = "[.]png$", full.names = TRUE)
if (length(figs) > 0) {
  file.copy(figs, file.path("report/figures", basename(figs)), overwrite = TRUE)
}

cat("Report tables and figures prepared.\n")
