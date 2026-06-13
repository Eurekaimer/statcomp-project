adj_to_igraph <- function(adj) {
  stopifnot(is.matrix(adj), nrow(adj) == ncol(adj))
  igraph::graph_from_adjacency_matrix(adj, mode = "directed", diag = FALSE)
}

is_dag_adj <- function(adj) {
  stopifnot(is.matrix(adj), nrow(adj) == ncol(adj))
  graph <- adj_to_igraph(adj)
  igraph::is_dag(graph)
}

random_dag_adj <- function(p, expected_degree = 2, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  stopifnot(p > 0, expected_degree >= 0)
  order <- sample.int(p)
  prob <- min(1, expected_degree / max(1, p - 1))
  adj <- matrix(0L, nrow = p, ncol = p)
  for (a in seq_len(p - 1)) {
    for (b in seq.int(a + 1, p)) {
      if (runif(1) < prob) adj[order[a], order[b]] <- 1L
    }
  }
  colnames(adj) <- rownames(adj) <- paste0("X", seq_len(p))
  adj
}

edge_list_from_adj <- function(adj) {
  idx <- which(adj != 0, arr.ind = TRUE)
  if (nrow(idx) == 0) {
    return(data.frame(from = character(), to = character()))
  }
  node_names <- colnames(adj)
  if (is.null(node_names)) node_names <- paste0("X", seq_len(ncol(adj)))
  data.frame(from = node_names[idx[, 1]], to = node_names[idx[, 2]], row.names = NULL)
}

save_adj_csv <- function(adj, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(adj, path, row.names = TRUE)
  invisible(path)
}

