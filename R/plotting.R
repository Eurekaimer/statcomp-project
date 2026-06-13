sc_palette <- c(
  order = "#6C63FF",
  partition = "#00A6A6",
  iterative = "#FF7A59",
  hybrid = "#FFB000"
)

sc_theme <- function(base_size = 12) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = "#FBFAF7", color = NA),
      panel.background = ggplot2::element_rect(fill = "#FBFAF7", color = NA),
      panel.grid.major = ggplot2::element_line(color = "#E7E1D8", linewidth = 0.35),
      panel.grid.minor = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(face = "bold", color = "#22223B", size = base_size + 4),
      plot.subtitle = ggplot2::element_text(color = "#5F5C6B", size = base_size),
      axis.title = ggplot2::element_text(color = "#3F3D4A", face = "bold"),
      axis.text = ggplot2::element_text(color = "#4A4656"),
      legend.position = "top",
      legend.title = ggplot2::element_blank(),
      legend.text = ggplot2::element_text(color = "#3F3D4A"),
      plot.margin = ggplot2::margin(12, 16, 12, 16)
    )
}

method_colors <- function(values) {
  known <- sc_palette[names(sc_palette) %in% values]
  missing <- setdiff(values, names(known))
  if (length(missing) > 0) {
    extra <- grDevices::hcl.colors(length(missing), palette = "Dark 3")
    names(extra) <- missing
    known <- c(known, extra)
  }
  known
}

plot_metric_bar <- function(metrics_df, metric, output_path) {
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  colors <- method_colors(unique(metrics_df$method))
  p <- ggplot2::ggplot(metrics_df, ggplot2::aes(x = method, y = .data[[metric]], fill = method)) +
    ggplot2::geom_col(width = 0.62, alpha = 0.92, na.rm = TRUE) +
    ggplot2::geom_text(
      ggplot2::aes(label = ifelse(is.na(.data[[metric]]), "", round(.data[[metric]], 3))),
      vjust = -0.35,
      size = 3.4,
      color = "#2F2B3A",
      na.rm = TRUE
    ) +
    ggplot2::scale_fill_manual(values = colors) +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, 0.16))) +
    sc_theme(base_size = 12) +
    ggplot2::labs(
      x = NULL,
      y = metric,
      title = paste(metric, "comparison"),
      subtitle = "Lower is better for SHD and runtime; higher is better for F1, precision and recall."
    ) +
    ggplot2::theme(legend.position = "none")
  ggplot2::ggsave(output_path, p, width = 7.5, height = 4.6, dpi = 180)
  invisible(p)
}

plot_runtime <- function(metrics_df, output_path) {
  plot_metric_bar(metrics_df, "runtime", output_path)
}

plot_edge_posterior_heatmap <- function(edge_post, output_path, title) {
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  mat <- as.matrix(edge_post)
  df <- as.data.frame(as.table(mat))
  names(df) <- c("from", "to", "prob")
  p <- ggplot2::ggplot(df, ggplot2::aes(x = to, y = from, fill = prob)) +
    ggplot2::geom_tile(color = "#FBFAF7", linewidth = 0.25) +
    ggplot2::scale_fill_gradientn(
      colours = c("#F7F3EA", "#A8DADC", "#457B9D", "#6C63FF", "#2A1E5C"),
      limits = c(0, 1)
    ) +
    ggplot2::coord_equal() +
    sc_theme(base_size = 11) +
    ggplot2::labs(x = "Child", y = "Parent", fill = "Posterior", title = title)
  ggplot2::ggsave(output_path, p, width = 6.5, height = 5.5, dpi = 180)
  invisible(p)
}

plot_shd_by_p <- function(all_metrics, output_path) {
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  colors <- method_colors(unique(all_metrics$method))
  p <- ggplot2::ggplot(all_metrics, ggplot2::aes(x = factor(p), y = SHD, color = method, group = method)) +
    ggplot2::stat_summary(fun = mean, geom = "line", linewidth = 1.15, alpha = 0.9, na.rm = TRUE) +
    ggplot2::stat_summary(fun = mean, geom = "point", size = 3.2, na.rm = TRUE) +
    ggplot2::scale_color_manual(values = colors) +
    sc_theme(base_size = 12) +
    ggplot2::labs(x = "Number of nodes (p)", y = "Mean SHD", title = "Structure error by dimension")
  ggplot2::ggsave(output_path, p, width = 7.5, height = 4.6, dpi = 180)
  invisible(p)
}

plot_runtime_by_p <- function(all_metrics, output_path) {
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  colors <- method_colors(unique(all_metrics$method))
  p <- ggplot2::ggplot(all_metrics, ggplot2::aes(x = factor(p), y = runtime, color = method, group = method)) +
    ggplot2::stat_summary(fun = mean, geom = "line", linewidth = 1.15, alpha = 0.9, na.rm = TRUE) +
    ggplot2::stat_summary(fun = mean, geom = "point", size = 3.2, na.rm = TRUE) +
    ggplot2::scale_color_manual(values = colors) +
    sc_theme(base_size = 12) +
    ggplot2::labs(x = "Number of nodes (p)", y = "Mean runtime seconds", title = "Runtime scaling by dimension")
  ggplot2::ggsave(output_path, p, width = 7.5, height = 4.6, dpi = 180)
  invisible(p)
}

plot_metric_by_n <- function(all_metrics, metric, output_path) {
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  colors <- method_colors(unique(all_metrics$method))
  p <- ggplot2::ggplot(all_metrics, ggplot2::aes(x = factor(n), y = .data[[metric]], color = method, group = method)) +
    ggplot2::stat_summary(fun = mean, geom = "line", linewidth = 1.15, alpha = 0.9, na.rm = TRUE) +
    ggplot2::stat_summary(fun = mean, geom = "point", size = 3.2, na.rm = TRUE) +
    ggplot2::scale_color_manual(values = colors) +
    sc_theme(base_size = 12) +
    ggplot2::labs(x = "Sample size (n)", y = paste("Mean", metric), title = paste(metric, "by sample size"))
  ggplot2::ggsave(output_path, p, width = 7.5, height = 4.6, dpi = 180)
  invisible(p)
}
