make_score_parameters <- function(data, score_type = "bge") {
  data <- normalize_bidag_data(data)
  BiDAG::scoreparameters(scoretype = score_type, data = data)
}

normalize_bidag_data <- function(data) {
  if (is.data.frame(data)) {
    data <- as.matrix(data)
  }
  if (!is.matrix(data)) {
    stop("BiDAG input data must be a numeric matrix or data.frame.", call. = FALSE)
  }
  storage.mode(data) <- "double"
  data
}

bidag_algorithm_name <- function(method) {
  switch(
    method,
    order = "order",
    partition = "partition",
    iterative = "orderIter",
    stop("Unknown method: ", method, call. = FALSE)
  )
}

effective_mcmc_steps <- function(algorithm, p, mcmc_steps) {
  if (identical(algorithm, "partition")) {
    return(max(mcmc_steps, 1000L))
  }
  mcmc_steps
}

call_sample_bn <- function(scorepar, algorithm, mcmc_steps) {
  p <- NCOL(scorepar$data)
  iterations <- effective_mcmc_steps(algorithm, p, mcmc_steps)
  stepsave <- max(1L, floor(iterations / 1000L))
  BiDAG::sampleBN(
    scorepar = scorepar,
    algorithm = algorithm,
    iterations = iterations,
    stepsave = stepsave,
    chainout = TRUE,
    scoreout = FALSE,
    verbose = FALSE
  )
}

extract_edge_posterior <- function(fit, burnin_fraction = 0) {
  attempts <- list(
    function() BiDAG::edgep(fit, pdag = FALSE, burnin = burnin_fraction),
    function() BiDAG::edgep(fit, burnin = burnin_fraction),
    function() BiDAG::edgep(fit, pdag = FALSE),
    function() BiDAG::edgep(fit)
  )
  for (fn in attempts) {
    out <- tryCatch(fn(), error = identity)
    if (!inherits(out, "error")) return(as.matrix(out))
  }
  NULL
}

extract_map_adj <- function(fit) {
  attempts <- list(
    function() BiDAG::getDAG(fit, amat = TRUE),
    function() BiDAG::getDAG(fit),
    function() fit$DAG,
    function() fit$map
  )
  for (fn in attempts) {
    out <- tryCatch(fn(), error = identity)
    if (!inherits(out, "error") && !is.null(out)) {
      if (is.list(out) && !is.null(out$DAG)) out <- out$DAG
      return((as.matrix(out) != 0) * 1L)
    }
  }
  NULL
}

run_bidag_method <- function(method, data, seed, mcmc_steps, burnin, score_type = "bge") {
  set.seed(seed)
  data <- normalize_bidag_data(data)
  scorepar <- make_score_parameters(data, score_type = score_type)
  algorithm <- bidag_algorithm_name(method)
  fit <- call_sample_bn(scorepar, algorithm = algorithm, mcmc_steps = mcmc_steps)
  burnin_fraction <- min(0.95, max(0, burnin / mcmc_steps))
  map_adj <- extract_map_adj(fit)
  edge_post <- extract_edge_posterior(fit, burnin_fraction = burnin_fraction)
  list(fit = fit, map_adj = map_adj, edge_post = edge_post)
}

run_order_mcmc <- function(data, seed, mcmc_steps, burnin, score_type = "bge") {
  run_bidag_method("order", data, seed, mcmc_steps, burnin, score_type)
}

run_partition_mcmc <- function(data, seed, mcmc_steps, burnin, score_type = "bge") {
  run_bidag_method("partition", data, seed, mcmc_steps, burnin, score_type)
}

run_iterative_mcmc <- function(data, seed, mcmc_steps, burnin, score_type = "bge") {
  run_bidag_method("iterative", data, seed, mcmc_steps, burnin, score_type)
}

safe_run_method <- function(method, data, seed, mcmc_steps, burnin, score_type = "bge") {
  start <- proc.time()[["elapsed"]]
  out <- tryCatch(
    run_bidag_method(method, data, seed, mcmc_steps, burnin, score_type),
    error = identity
  )
  runtime <- proc.time()[["elapsed"]] - start
  if (inherits(out, "error")) {
    return(list(
      method = method,
      fit = NULL,
      map_adj = NULL,
      edge_post = NULL,
      runtime = runtime,
      status = "failed",
      error = conditionMessage(out)
    ))
  }
  list(
    method = method,
    fit = out$fit,
    map_adj = out$map_adj,
    edge_post = out$edge_post,
    runtime = runtime,
    status = "success",
    error = NA_character_
  )
}
