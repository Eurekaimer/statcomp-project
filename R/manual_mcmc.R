as_numeric_matrix <- function(data) {
  x <- as.matrix(data)
  storage.mode(x) <- "double"
  if (is.null(colnames(x))) colnames(x) <- paste0("X", seq_len(ncol(x)))
  x
}

parent_key <- function(parents) {
  if (length(parents) == 0) return("")
  paste(sort(as.integer(parents)), collapse = ",")
}

key_to_parents <- function(key) {
  if (is.na(key) || identical(key, "")) return(integer())
  as.integer(strsplit(key, ",", fixed = TRUE)[[1]])
}

enumerate_parent_sets <- function(candidates, max_parents = 2) {
  candidates <- sort(as.integer(candidates))
  max_size <- min(max_parents, length(candidates))
  out <- list(integer())
  if (max_size == 0) return(out)
  for (k in seq_len(max_size)) {
    cmb <- utils::combn(candidates, k, simplify = FALSE)
    out <- c(out, cmb)
  }
  out
}

gaussian_local_bic_score <- function(y, x_parents = NULL) {
  n <- length(y)
  if (is.null(x_parents) || NCOL(x_parents) == 0) {
    rss <- sum((y - mean(y))^2)
    k <- 2L
  } else {
    design <- cbind(1, as.matrix(x_parents))
    fit <- stats::lm.fit(design, y)
    rss <- sum(fit$residuals^2)
    k <- ncol(design) + 1L
  }
  rss <- max(rss, .Machine$double.eps)
  loglik <- -0.5 * n * (log(2 * pi) + 1 + log(rss / n))
  loglik - 0.5 * k * log(n)
}

precompute_local_scores <- function(data, max_parents = 2) {
  x <- as_numeric_matrix(data)
  p <- ncol(x)
  scores <- vector("list", p)
  names(scores) <- colnames(x)
  for (j in seq_len(p)) {
    candidates <- setdiff(seq_len(p), j)
    parent_sets <- enumerate_parent_sets(candidates, max_parents = max_parents)
    node_scores <- data.frame(
      key = vapply(parent_sets, parent_key, character(1)),
      score = NA_real_,
      stringsAsFactors = FALSE
    )
    for (i in seq_along(parent_sets)) {
      pa <- parent_sets[[i]]
      node_scores$score[i] <- gaussian_local_bic_score(
        y = x[, j],
        x_parents = if (length(pa) == 0) NULL else x[, pa, drop = FALSE]
      )
    }
    scores[[j]] <- node_scores
  }
  scores
}

allowed_parent_row <- function(node_scores, allowed) {
  allowed <- sort(as.integer(allowed))
  ok <- vapply(node_scores$key, function(key) {
    pa <- key_to_parents(key)
    all(pa %in% allowed)
  }, logical(1))
  candidates <- node_scores[ok, , drop = FALSE]
  candidates[which.max(candidates$score), , drop = FALSE]
}

sample_parent_row <- function(node_scores, allowed) {
  allowed <- sort(as.integer(allowed))
  ok <- vapply(node_scores$key, function(key) {
    pa <- key_to_parents(key)
    all(pa %in% allowed)
  }, logical(1))
  candidates <- node_scores[ok, , drop = FALSE]
  weights <- exp(candidates$score - max(candidates$score))
  candidates[sample.int(nrow(candidates), 1L, prob = weights), , drop = FALSE]
}

order_score <- function(order, local_scores) {
  total <- 0
  for (pos in seq_along(order)) {
    j <- order[pos]
    allowed <- if (pos == 1L) integer() else order[seq_len(pos - 1L)]
    total <- total + allowed_parent_row(local_scores[[j]], allowed)$score
  }
  total
}

order_to_adj <- function(order, local_scores, sample_parents = FALSE) {
  p <- length(order)
  adj <- matrix(0L, p, p)
  for (pos in seq_along(order)) {
    j <- order[pos]
    allowed <- if (pos == 1L) integer() else order[seq_len(pos - 1L)]
    row <- if (sample_parents) {
      sample_parent_row(local_scores[[j]], allowed)
    } else {
      allowed_parent_row(local_scores[[j]], allowed)
    }
    parents <- key_to_parents(row$key)
    if (length(parents) > 0) adj[parents, j] <- 1L
  }
  colnames(adj) <- rownames(adj) <- paste0("X", seq_len(p))
  adj
}

local_score_for_parents <- function(node_scores, parents) {
  key <- parent_key(parents)
  idx <- match(key, node_scores$key)
  if (is.na(idx)) return(-Inf)
  node_scores$score[idx]
}

dag_score <- function(adj, local_scores) {
  total <- 0
  for (j in seq_len(ncol(adj))) {
    total <- total + local_score_for_parents(local_scores[[j]], which(adj[, j] != 0))
  }
  total
}

propose_structure_move <- function(adj, max_parents = 2) {
  p <- ncol(adj)
  proposal <- adj
  move <- sample(c("add", "delete", "reverse"), 1L)
  candidates <- which(row(adj) != col(adj), arr.ind = TRUE)
  edge_idx <- which(adj != 0, arr.ind = TRUE)
  nonedge_idx <- candidates[adj[candidates] == 0, , drop = FALSE]

  if (identical(move, "add") && nrow(nonedge_idx) > 0) {
    pick <- nonedge_idx[sample.int(nrow(nonedge_idx), 1L), ]
    if (sum(proposal[, pick[2]] != 0) < max_parents) proposal[pick[1], pick[2]] <- 1L
  } else if (identical(move, "delete") && nrow(edge_idx) > 0) {
    pick <- edge_idx[sample.int(nrow(edge_idx), 1L), ]
    proposal[pick[1], pick[2]] <- 0L
  } else if (identical(move, "reverse") && nrow(edge_idx) > 0) {
    pick <- edge_idx[sample.int(nrow(edge_idx), 1L), ]
    proposal[pick[1], pick[2]] <- 0L
    if (sum(proposal[, pick[1]] != 0) < max_parents) proposal[pick[2], pick[1]] <- 1L
  }

  if (!is_dag_adj(proposal)) return(adj)
  proposal
}

run_manual_structure_mcmc <- function(data, seed, mcmc_steps, burnin, max_parents = 2) {
  if (!is.null(seed)) set.seed(seed)
  start <- proc.time()[["elapsed"]]
  x <- as_numeric_matrix(data)
  p <- ncol(x)
  local_scores <- precompute_local_scores(x, max_parents = max_parents)

  current <- matrix(0L, p, p)
  colnames(current) <- rownames(current) <- colnames(x)
  current_score <- dag_score(current, local_scores)
  best <- current
  best_score <- current_score
  edge_sum <- matrix(0, p, p)
  kept <- 0L
  accepted <- 0L

  for (iter in seq_len(mcmc_steps)) {
    proposal <- propose_structure_move(current, max_parents = max_parents)
    proposal_score <- dag_score(proposal, local_scores)
    if (log(runif(1)) < proposal_score - current_score) {
      current <- proposal
      current_score <- proposal_score
      accepted <- accepted + 1L
    }
    if (current_score > best_score) {
      best <- current
      best_score <- current_score
    }
    if (iter > burnin) {
      edge_sum <- edge_sum + current
      kept <- kept + 1L
    }
  }

  edge_post <- edge_sum / max(1L, kept)
  colnames(edge_post) <- rownames(edge_post) <- colnames(x)
  runtime <- proc.time()[["elapsed"]] - start
  manual_mcmc_result(
    method = "manual_structure",
    map_adj = best,
    edge_post = edge_post,
    runtime = runtime,
    trace = data.frame(iterations = mcmc_steps, burnin = burnin, kept = kept,
                       accept_rate = accepted / mcmc_steps, best_score = best_score)
  )
}

propose_order_swap <- function(order) {
  out <- order
  idx <- sample.int(length(order), 2L)
  out[idx] <- out[rev(idx)]
  out
}

normalize_partition <- function(blocks) {
  blocks <- lapply(blocks, function(x) sort(as.integer(x)))
  blocks[lengths(blocks) > 0]
}

random_partition_state <- function(p) {
  order <- sample.int(p)
  cuts <- cumsum(sample.int(3L, p, replace = TRUE))
  split(order, cuts)
}

partition_score <- function(blocks, local_scores) {
  blocks <- normalize_partition(blocks)
  previous <- integer()
  total <- 0
  for (block in blocks) {
    for (j in block) {
      total <- total + allowed_parent_row(local_scores[[j]], previous)$score
    }
    previous <- c(previous, block)
  }
  total
}

partition_to_adj <- function(blocks, local_scores, sample_parents = FALSE) {
  blocks <- normalize_partition(blocks)
  p <- length(local_scores)
  adj <- matrix(0L, p, p)
  previous <- integer()
  for (block in blocks) {
    for (j in block) {
      row <- if (sample_parents) {
        sample_parent_row(local_scores[[j]], previous)
      } else {
        allowed_parent_row(local_scores[[j]], previous)
      }
      parents <- key_to_parents(row$key)
      if (length(parents) > 0) adj[parents, j] <- 1L
    }
    previous <- c(previous, block)
  }
  colnames(adj) <- rownames(adj) <- paste0("X", seq_len(p))
  adj
}

propose_partition_state <- function(blocks) {
  blocks <- normalize_partition(blocks)
  move <- sample(c("split", "merge", "move"), 1L)

  if (identical(move, "split") && any(lengths(blocks) > 1L)) {
    candidates <- which(lengths(blocks) > 1L)
    b <- sample(candidates, 1L)
    node <- sample(blocks[[b]], 1L)
    left <- setdiff(blocks[[b]], node)
    blocks[[b]] <- left
    blocks <- append(blocks, list(node), after = b)
    return(normalize_partition(blocks))
  }

  if (identical(move, "merge") && length(blocks) > 1L) {
    b <- sample.int(length(blocks) - 1L, 1L)
    blocks[[b]] <- sort(c(blocks[[b]], blocks[[b + 1L]]))
    blocks[[b + 1L]] <- integer()
    return(normalize_partition(blocks))
  }

  node_block <- sample.int(length(blocks), 1L)
  node <- sample(blocks[[node_block]], 1L)
  blocks[[node_block]] <- setdiff(blocks[[node_block]], node)
  insert_after <- sample.int(length(blocks) + 1L, 1L) - 1L
  if (insert_after == 0L) {
    blocks <- c(list(node), blocks)
  } else {
    blocks <- append(blocks, list(node), after = insert_after)
  }
  normalize_partition(blocks)
}

manual_mcmc_result <- function(method, map_adj, edge_post, runtime, trace) {
  list(
    method = method,
    fit = list(trace = trace, implementation = "manual_educational"),
    map_adj = map_adj,
    edge_post = edge_post,
    runtime = runtime,
    status = "success",
    error = NA_character_
  )
}

run_manual_order_mcmc <- function(data, seed, mcmc_steps, burnin, max_parents = 2) {
  if (!is.null(seed)) set.seed(seed)
  start <- proc.time()[["elapsed"]]
  x <- as_numeric_matrix(data)
  p <- ncol(x)
  local_scores <- precompute_local_scores(x, max_parents = max_parents)

  current <- sample.int(p)
  current_score <- order_score(current, local_scores)
  best <- current
  best_score <- current_score
  edge_sum <- matrix(0, p, p)
  kept <- 0L
  accepted <- 0L

  for (iter in seq_len(mcmc_steps)) {
    proposal <- propose_order_swap(current)
    proposal_score <- order_score(proposal, local_scores)
    if (log(runif(1)) < proposal_score - current_score) {
      current <- proposal
      current_score <- proposal_score
      accepted <- accepted + 1L
    }
    if (current_score > best_score) {
      best <- current
      best_score <- current_score
    }
    if (iter > burnin) {
      edge_sum <- edge_sum + order_to_adj(current, local_scores, sample_parents = TRUE)
      kept <- kept + 1L
    }
  }

  edge_post <- edge_sum / max(1L, kept)
  colnames(edge_post) <- rownames(edge_post) <- colnames(x)
  map_adj <- order_to_adj(best, local_scores, sample_parents = FALSE)
  runtime <- proc.time()[["elapsed"]] - start
  manual_mcmc_result(
    method = "manual_order",
    map_adj = map_adj,
    edge_post = edge_post,
    runtime = runtime,
    trace = data.frame(iterations = mcmc_steps, burnin = burnin, kept = kept,
                       accept_rate = accepted / mcmc_steps, best_score = best_score)
  )
}

run_manual_partition_mcmc <- function(data, seed, mcmc_steps, burnin, max_parents = 2) {
  if (!is.null(seed)) set.seed(seed)
  start <- proc.time()[["elapsed"]]
  x <- as_numeric_matrix(data)
  p <- ncol(x)
  local_scores <- precompute_local_scores(x, max_parents = max_parents)

  current <- random_partition_state(p)
  current_score <- partition_score(current, local_scores)
  best <- current
  best_score <- current_score
  edge_sum <- matrix(0, p, p)
  kept <- 0L
  accepted <- 0L

  for (iter in seq_len(mcmc_steps)) {
    proposal <- propose_partition_state(current)
    proposal_score <- partition_score(proposal, local_scores)
    if (log(runif(1)) < proposal_score - current_score) {
      current <- proposal
      current_score <- proposal_score
      accepted <- accepted + 1L
    }
    if (current_score > best_score) {
      best <- current
      best_score <- current_score
    }
    if (iter > burnin) {
      edge_sum <- edge_sum + partition_to_adj(current, local_scores, sample_parents = TRUE)
      kept <- kept + 1L
    }
  }

  edge_post <- edge_sum / max(1L, kept)
  colnames(edge_post) <- rownames(edge_post) <- colnames(x)
  map_adj <- partition_to_adj(best, local_scores, sample_parents = FALSE)
  runtime <- proc.time()[["elapsed"]] - start
  manual_mcmc_result(
    method = "manual_partition",
    map_adj = map_adj,
    edge_post = edge_post,
    runtime = runtime,
    trace = data.frame(iterations = mcmc_steps, burnin = burnin, kept = kept,
                       accept_rate = accepted / mcmc_steps, best_score = best_score)
  )
}

safe_run_manual_method <- function(method, data, seed, mcmc_steps, burnin, max_parents = 2) {
  start <- proc.time()[["elapsed"]]
  tryCatch({
    switch(
      method,
      manual_structure = run_manual_structure_mcmc(data, seed, mcmc_steps, burnin, max_parents),
      manual_order = run_manual_order_mcmc(data, seed, mcmc_steps, burnin, max_parents),
      manual_partition = run_manual_partition_mcmc(data, seed, mcmc_steps, burnin, max_parents),
      stop("Unknown manual method: ", method, call. = FALSE)
    )
  }, error = function(e) {
    list(
      method = method,
      fit = NULL,
      map_adj = NULL,
      edge_post = NULL,
      runtime = proc.time()[["elapsed"]] - start,
      status = "failed",
      error = conditionMessage(e)
    )
  })
}
