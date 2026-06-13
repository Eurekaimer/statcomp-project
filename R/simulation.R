topological_order_from_adj <- function(adj) {
  graph <- adj_to_igraph(adj)
  if (!igraph::is_dag(graph)) stop("adj must be a DAG.", call. = FALSE)
  as.integer(igraph::topo_sort(graph, mode = "out"))
}

simulate_gaussian_bn <- function(adj, n, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  stopifnot(is.matrix(adj), nrow(adj) == ncol(adj), n > 0)
  if (!is_dag_adj(adj)) stop("adj must be acyclic.", call. = FALSE)

  p <- ncol(adj)
  order <- topological_order_from_adj(adj)
  beta <- matrix(0, p, p)
  edge_idx <- which(adj != 0, arr.ind = TRUE)
  if (nrow(edge_idx) > 0) {
    signs <- sample(c(-1, 1), nrow(edge_idx), replace = TRUE)
    beta[edge_idx] <- stats::runif(nrow(edge_idx), 0.5, 1.5) * signs
  }

  x <- matrix(0, nrow = n, ncol = p)
  for (j in order) {
    parents <- which(adj[, j] != 0)
    signal <- if (length(parents) == 0) 0 else x[, parents, drop = FALSE] %*% beta[parents, j]
    x[, j] <- as.numeric(signal) + stats::rnorm(n)
  }
  colnames(x) <- paste0("X", seq_len(p))
  list(data = as.data.frame(x), beta = beta)
}

generate_simulation_case <- function(p, n, expected_degree, seed) {
  adj <- random_dag_adj(p, expected_degree = expected_degree, seed = seed)
  sim <- simulate_gaussian_bn(adj, n = n, seed = seed + 10000L)
  list(
    p = p,
    n = n,
    expected_degree = expected_degree,
    seed = seed,
    adj = adj,
    beta = sim$beta,
    data = sim$data
  )
}

save_simulation_case <- function(case, prefix) {
  dir.create(dirname(prefix), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(case$data, paste0(prefix, "_data.csv"), row.names = FALSE)
  save_adj_csv(case$adj, paste0(prefix, "_adj.csv"))
  utils::write.csv(case$beta, paste0(prefix, "_beta.csv"), row.names = TRUE)
  invisible(prefix)
}

