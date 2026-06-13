skeleton_adj <- function(adj) {
  ((adj + t(adj)) > 0) * 1L
}

compute_confusion_directed <- function(true_adj, est_adj) {
  true_vec <- as.vector(true_adj != 0)
  est_vec <- as.vector(est_adj != 0)
  diag_idx <- as.vector(row(true_adj) == col(true_adj))
  true_vec <- true_vec[!diag_idx]
  est_vec <- est_vec[!diag_idx]
  list(
    tp = sum(true_vec & est_vec),
    fp = sum(!true_vec & est_vec),
    tn = sum(!true_vec & !est_vec),
    fn = sum(true_vec & !est_vec)
  )
}

compute_metrics_directed <- function(true_adj, est_adj) {
  cm <- compute_confusion_directed(true_adj, est_adj)
  tpr <- if ((cm$tp + cm$fn) == 0) NA_real_ else cm$tp / (cm$tp + cm$fn)
  fpr <- if ((cm$fp + cm$tn) == 0) NA_real_ else cm$fp / (cm$fp + cm$tn)
  precision <- if ((cm$tp + cm$fp) == 0) NA_real_ else cm$tp / (cm$tp + cm$fp)
  recall <- tpr
  f1 <- if (is.na(precision) || is.na(recall) || (precision + recall) == 0) {
    NA_real_
  } else {
    2 * precision * recall / (precision + recall)
  }
  data.frame(
    SHD = compute_shd(true_adj, est_adj),
    TPR = tpr,
    FPR = fpr,
    precision = precision,
    recall = recall,
    F1 = f1
  )
}

compute_shd <- function(true_adj, est_adj) {
  stopifnot(all(dim(true_adj) == dim(est_adj)))
  p <- nrow(true_adj)
  shd <- 0L
  for (i in seq_len(p - 1)) {
    for (j in seq.int(i + 1, p)) {
      true_pair <- c(true_adj[i, j], true_adj[j, i])
      est_pair <- c(est_adj[i, j], est_adj[j, i])
      if (!identical(as.integer(true_pair), as.integer(est_pair))) shd <- shd + 1L
    }
  }
  shd
}

threshold_edge_posterior <- function(edge_post, threshold = 0.5) {
  if (is.null(edge_post)) return(NULL)
  adj <- (as.matrix(edge_post) >= threshold) * 1L
  diag(adj) <- 0L
  adj
}

evaluate_method_result <- function(true_adj, result, threshold = 0.5) {
  base <- data.frame(
    method = result$method,
    runtime = result$runtime,
    status = result$status,
    error = ifelse(is.na(result$error), NA_character_, result$error),
    stringsAsFactors = FALSE
  )
  if (!identical(result$status, "success")) {
    return(cbind(base, data.frame(
      SHD = NA_real_, TPR = NA_real_, FPR = NA_real_,
      precision = NA_real_, recall = NA_real_, F1 = NA_real_
    )))
  }
  est_adj <- result$map_adj
  if (is.null(est_adj) && !is.null(result$edge_post)) {
    est_adj <- threshold_edge_posterior(result$edge_post, threshold)
  }
  if (is.null(est_adj)) {
    base$status <- "failed"
    base$error <- "Could not extract MAP graph or edge posterior."
    return(cbind(base, data.frame(
      SHD = NA_real_, TPR = NA_real_, FPR = NA_real_,
      precision = NA_real_, recall = NA_real_, F1 = NA_real_
    )))
  }
  metrics <- compute_metrics_directed(true_adj, est_adj)
  cbind(base, metrics)
}

