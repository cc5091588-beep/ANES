options(stringsAsFactors = FALSE, warn = 1)

paths_file <- local({
  sources <- as.character(unlist(lapply(sys.frames(), function(frame) frame$ofile), use.names = FALSE))
  command_file <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE))
  starts <- unique(c(dirname(sources), dirname(command_file), getwd()))
  candidates <- unique(unlist(lapply(starts, function(at) {
    c(file.path(at, "Paths.R"), file.path(at, "R", "Paths.R"),
      file.path(at, "..", "R", "Paths.R"), file.path(at, "analysis", "R", "Paths.R"))
  }), use.names = FALSE))
  valid <- vapply(candidates, function(path) {
    file.exists(path) &&
      file.exists(file.path(dirname(path), "..", "config", "Submission"))
  }, logical(1))
  if (!any(valid)) stop("Cannot find Paths.R in a marked submission analysis directory.")
  normalizePath(candidates[which(valid)[1L]], winslash = "/", mustWork = TRUE)
})
source(paths_file, local = TRUE)
project_root <- anes_project_root()
erp_root <- project_root

project_library <- file.path(
  project_root,
  "renv", "library", "windows", "R-4.5", "x86_64-w64-mingw32"
)
if (dir.exists(project_library)) {
  .libPaths(c(project_library, .libPaths()))
}

suppressPackageStartupMessages({
  library(qgraph)
  library(bootnet)
  library(digest)
})

years <- c(2004L, 2012L, 2016L, 2020L, 2024L)
later_years <- years[years != 2004L]
expected_n <- c(
  `2004` = 789L,
  `2012` = 4353L,
  `2016` = 2709L,
  `2020` = 5390L,
  `2024` = 3525L
)
network_vars <- c(
  "VCF0806", "VCF0809", "VCF0838", "VCF0839", "VCF0879a",
  "VCF0888", "VCF0890", "VCF0894", "VCF9223"
)
expected_categories <- list(
  VCF0806 = 1:7,
  VCF0809 = 1:7,
  VCF0838 = 1:4,
  VCF0839 = 1:7,
  VCF0879a = c(1, 3, 5),
  VCF0888 = 1:3,
  VCF0890 = 1:3,
  VCF0894 = 1:3,
  VCF9223 = 1:4
)
common_n <- 789L
pilot_repetitions <- 50L
formal_repetitions <- 1000L
master_seed <- 20260831L
pilot_seed_offset <- 500000L
matrix_tolerance <- 1e-8
success_threshold <- 0.95

table_dir <- file.path(project_root, "outputs", "tables", "sensitivity")
model_dir <- file.path(project_root, "outputs", "models", "sensitivity")
log_dir <- file.path(project_root, "outputs", "logs")
for (path in c(table_dir, model_dir, log_dir)) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
}

completion_file <- file.path(table_dir, "09B_completion_status.csv")
if (file.exists(completion_file)) {
  stop(
    "A completed Step 09B output already exists. Existing results will not be overwritten."
  )
}

log_file <- file.path(log_dir, "09B_run.log")
log_lines <- character()
log_note <- function(...) {
  line <- paste0(
    sprintf("%03d", length(log_lines) + 1L),
    " | ",
    paste0(...)
  )
  log_lines <<- c(log_lines, line)
  message(line)
}
flush_log <- function() writeLines(log_lines, log_file, useBytes = TRUE)

write_csv <- function(x, filename) {
  path <- file.path(table_dir, filename)
  utils::write.csv(x, path, row.names = FALSE, na = "")
  path
}

file_sha256 <- function(path) {
  toupper(digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE))
}

capture_run <- function(fun) {
  warnings <- character()
  messages <- character()
  error_text <- ""
  started <- proc.time()[["elapsed"]]
  value <- tryCatch(
    withCallingHandlers(
      fun(),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      },
      message = function(m) {
        messages <<- c(messages, conditionMessage(m))
        invokeRestart("muffleMessage")
      }
    ),
    error = function(e) {
      error_text <<- conditionMessage(e)
      NULL
    }
  )
  list(
    value = value,
    warnings = unique(warnings),
    messages = unique(messages),
    error = error_text,
    elapsed_seconds = proc.time()[["elapsed"]] - started
  )
}

collapse_conditions <- function(...) {
  x <- unique(trimws(unlist(list(...), use.names = FALSE)))
  x <- x[nzchar(x)]
  if (!length(x)) "" else paste(x, collapse = " | ")
}

numeric_value_codes <- function(x) {
  if (inherits(x, "haven_labelled") || inherits(x, "vctrs_vctr")) {
    as.numeric(unclass(x))
  } else if (is.factor(x)) {
    suppressWarnings(as.numeric(as.character(x)))
  } else {
    suppressWarnings(as.numeric(x))
  }
}

ordered_node_data <- function(data) {
  out <- as.data.frame(data[, network_vars, drop = FALSE])
  for (node in network_vars) {
    out[[node]] <- ordered(
      numeric_value_codes(out[[node]]),
      levels = expected_categories[[node]]
    )
  }
  out
}

matrix_diagnostics <- function(mat, diagonal_target) {
  expected_dim <- c(length(network_vars), length(network_vars))
  available <- is.matrix(mat) && identical(dim(mat), expected_dim)
  if (!available) {
    return(list(
      valid = FALSE,
      minimum_eigenvalue = NA_real_,
      maximum_asymmetry = NA_real_,
      maximum_diagonal_deviation = NA_real_,
      all_finite = FALSE,
      correct_order = FALSE
    ))
  }
  mat <- as.matrix(mat)
  all_finite <- all(is.finite(mat))
  eig <- if (all_finite && diagonal_target == 1) {
    eigen((mat + t(mat)) / 2, symmetric = TRUE, only.values = TRUE)$values
  } else {
    NA_real_
  }
  minimum_eigenvalue <- if (all(is.finite(eig))) min(eig) else NA_real_
  maximum_asymmetry <- max(abs(mat - t(mat)))
  maximum_diagonal_deviation <- max(abs(diag(mat) - diagonal_target))
  correct_order <- identical(rownames(mat), network_vars) &&
    identical(colnames(mat), network_vars)
  positive_definite <- if (diagonal_target == 1) {
    is.finite(minimum_eigenvalue) && minimum_eigenvalue > matrix_tolerance
  } else {
    TRUE
  }
  list(
    valid = all_finite && correct_order &&
      maximum_asymmetry <= matrix_tolerance &&
      maximum_diagonal_deviation <= matrix_tolerance &&
      positive_definite,
    minimum_eigenvalue = minimum_eigenvalue,
    maximum_asymmetry = maximum_asymmetry,
    maximum_diagonal_deviation = maximum_diagonal_deviation,
    all_finite = all_finite,
    correct_order = correct_order
  )
}

edge_table <- function(mat) {
  stopifnot(
    is.matrix(mat),
    identical(rownames(mat), network_vars),
    identical(colnames(mat), network_vars)
  )
  index <- which(upper.tri(mat), arr.ind = TRUE)
  out <- data.frame(
    Node_1 = rownames(mat)[index[, 1]],
    Node_2 = colnames(mat)[index[, 2]],
    Edge_weight = as.numeric(mat[index]),
    stringsAsFactors = FALSE
  )
  out$Edge_ID <- paste(out$Node_1, out$Node_2, sep = "--")
  out$Retained <- out$Edge_weight != 0
  out$Sign <- ifelse(
    out$Edge_weight > 0,
    "POSITIVE",
    ifelse(out$Edge_weight < 0, "NEGATIVE", "ZERO")
  )
  out[, c("Edge_ID", "Node_1", "Node_2", "Edge_weight", "Retained", "Sign")]
}

direction_label <- function(x, tolerance = sqrt(.Machine$double.eps)) {
  ifelse(
    abs(x) <= tolerance,
    "ZERO",
    ifelse(x > 0, "POSITIVE", "NEGATIVE")
  )
}

state_matches <- function(primary_weight, sensitivity_weight) {
  if (length(primary_weight) == 1L) {
    if (primary_weight == 0) {
      return(sensitivity_weight == 0)
    }
    if (primary_weight > 0) {
      return(sensitivity_weight > 0)
    }
    return(sensitivity_weight < 0)
  }
  stopifnot(length(primary_weight) == length(sensitivity_weight))
  ifelse(
    primary_weight == 0,
    sensitivity_weight == 0,
    ifelse(primary_weight > 0, sensitivity_weight > 0, sensitivity_weight < 0)
  )
}

sample_quality <- function(ordered_data) {
  observed_categories <- vapply(
    ordered_data,
    function(x) length(unique(x[!is.na(x)])),
    integer(1)
  )
  zero_cell_pairs <- 0L
  sparse_cell_pairs <- 0L
  minimum_cell_count <- Inf
  for (i in seq_len(length(network_vars) - 1L)) {
    for (j in seq.int(i + 1L, length(network_vars))) {
      cells <- as.numeric(table(
        ordered_data[[network_vars[i]]],
        ordered_data[[network_vars[j]]],
        useNA = "no"
      ))
      zero_cell_pairs <- zero_cell_pairs + as.integer(any(cells == 0L))
      sparse_cell_pairs <- sparse_cell_pairs + as.integer(any(cells >= 1L & cells <= 4L))
      minimum_cell_count <- min(minimum_cell_count, cells)
    }
  }
  list(
    valid = all(observed_categories >= 2L) && !anyNA(ordered_data),
    minimum_observed_categories = min(observed_categories),
    zero_cell_pairs = zero_cell_pairs,
    sparse_cell_pairs = sparse_cell_pairs,
    minimum_cell_count = if (is.finite(minimum_cell_count)) minimum_cell_count else NA_integer_
  )
}

run_ebic <- function(correlation, n, threshold) {
  captured <- capture_run(function() {
    qgraph::EBICglasso(
      S = correlation,
      n = n,
      gamma = 0.50,
      nlambda = 100,
      lambda.min.ratio = 0.01,
      returnAllResults = TRUE,
      checkPD = TRUE,
      threshold = threshold,
      verbose = FALSE
    )
  })
  result <- captured$value
  graph <- if (is.list(result) && is.matrix(result$optnet)) result$optnet else NULL
  graph_diag <- matrix_diagnostics(graph, diagonal_target = 0)
  optimum <- if (is.list(result) && length(result$ebic)) {
    which.min(result$ebic)
  } else NA_integer_
  selected_lambda <- if (is.finite(optimum)) result$lambda[optimum] else NA_real_
  lambda_max <- if (is.list(result) && length(result$lambda)) {
    max(result$lambda)
  } else NA_real_
  list(
    success = graph_diag$valid && !nzchar(captured$error),
    graph = graph,
    result = result,
    selected_lambda = selected_lambda,
    lambda_max = lambda_max,
    lambda_ratio = selected_lambda / lambda_max,
    dense_warning = any(grepl(
      "dense regularized network",
      c(captured$warnings, captured$messages),
      ignore.case = TRUE
    )),
    lowest_lambda_selected = any(grepl(
      "lowest lambda selected",
      c(captured$warnings, captured$messages),
      ignore.case = TRUE
    )),
    warnings = collapse_conditions(captured$warnings),
    messages = collapse_conditions(captured$messages),
    error = captured$error,
    elapsed_seconds = captured$elapsed_seconds,
    graph_diagnostics = graph_diag
  )
}

correlation_and_quality <- function(sample_data) {
  ordered_data <- ordered_node_data(sample_data)
  quality <- sample_quality(ordered_data)
  captured <- if (quality$valid) {
    capture_run(function() {
      qgraph::cor_auto(
        ordered_data,
        detectOrdinal = TRUE,
        ordinalLevelMax = 7,
        forcePD = FALSE,
        missing = "pairwise",
        verbose = FALSE
      )
    })
  } else {
    list(
      value = NULL,
      warnings = character(),
      messages = character(),
      error = "Sample quality gate failed.",
      elapsed_seconds = 0
    )
  }
  correlation <- captured$value
  correlation_diag <- matrix_diagnostics(correlation, diagonal_target = 1)
  list(
    success = quality$valid && correlation_diag$valid && !nzchar(captured$error),
    correlation = correlation,
    quality = quality,
    diagnostics = correlation_diag,
    warnings = collapse_conditions(captured$warnings),
    messages = collapse_conditions(captured$messages),
    error = captured$error,
    elapsed_seconds = captured$elapsed_seconds
  )
}

derived_seed <- function(wave, repetition, pilot = FALSE) {
  wave_index <- match(as.integer(wave), years)
  master_seed + (if (pilot) pilot_seed_offset else 0L) +
    wave_index * 10000L + as.integer(repetition)
}

sample_hash <- function(data_rows, wave, repetition) {
  digest::digest(
    list(
      wave = as.integer(wave),
      repetition = as.integer(repetition),
      row_index = as.integer(data_rows$.analysis_row_index),
      respondent = as.character(data_rows$VCF0006),
      panel_identifier = as.character(data_rows$VCF0006a)
    ),
    algo = "sha256",
    serialize = TRUE
  ) |> toupper()
}

diagnostic_row <- function(
    arm, wave, repetition, seed, fixed_sample, hash, cor_result, fit_result) {
  fit_success <- !is.null(fit_result) && isTRUE(fit_result$success)
  graph <- if (fit_success) fit_result$graph else NULL
  data.frame(
    Arm_ID = arm,
    Wave = as.integer(wave),
    Repetition = as.integer(repetition),
    Seed = if (is.na(seed)) NA_integer_ else as.integer(seed),
    Fixed_sample = fixed_sample,
    N = common_n,
    Sample_hash = hash,
    Minimum_observed_categories = cor_result$quality$minimum_observed_categories,
    Zero_cell_pairs = cor_result$quality$zero_cell_pairs,
    Sparse_cell_pairs = cor_result$quality$sparse_cell_pairs,
    Minimum_cell_count = cor_result$quality$minimum_cell_count,
    Correlation_success = cor_result$success,
    Minimum_correlation_eigenvalue =
      cor_result$diagnostics$minimum_eigenvalue,
    Correlation_warning = cor_result$warnings,
    Correlation_message = cor_result$messages,
    Correlation_error = cor_result$error,
    Network_success = fit_success,
    Selected_lambda = if (fit_success) fit_result$selected_lambda else NA_real_,
    Lambda_max = if (fit_success) fit_result$lambda_max else NA_real_,
    Lambda_ratio = if (fit_success) fit_result$lambda_ratio else NA_real_,
    Dense_warning = if (fit_success) fit_result$dense_warning else NA,
    Lowest_lambda_selected = if (fit_success) {
      fit_result$lowest_lambda_selected
    } else NA,
    Retained_edges = if (fit_success) sum(graph[upper.tri(graph)] != 0) else NA_integer_,
    Global_strength = if (fit_success) sum(abs(graph[upper.tri(graph)])) else NA_real_,
    Network_warning = if (!is.null(fit_result)) fit_result$warnings else "",
    Network_message = if (!is.null(fit_result)) fit_result$messages else "",
    Network_error = if (!is.null(fit_result)) fit_result$error else "Correlation gate failed.",
    Elapsed_seconds = cor_result$elapsed_seconds +
      if (!is.null(fit_result)) fit_result$elapsed_seconds else 0,
    Success = cor_result$success && fit_success,
    stringsAsFactors = FALSE
  )
}

log_note("Step 09B engine started")

# -----------------------------------------------------------------------------
# Stage 1: frozen decisions and input validation
# -----------------------------------------------------------------------------

paths <- list(
  claims = file.path(
    erp_root, "project_docs", "decisions", "step09b_primary_claim_registry.csv"
  ),
  arms = file.path(
    erp_root, "project_docs", "decisions", "step09b_arm_specification.csv"
  ),
  authorisation = file.path(
    erp_root, "project_docs", "decisions", "step09b_execution_authorisation.csv"
  ),
  analysis_ready = file.path(
    project_root, "data", "analysis_ready",
    "anes_cdf_20260205_analysis_ready_nine_node_complete_case_2004_2012_2016_2020_2024.rds"
  ),
  polychoric_bundle = file.path(
    project_root, "data", "audit",
    "anes_cdf_20260205_nine_node_complete_case_polychoric_diagnostics_2004_2012_2016_2020_2024.rds"
  ),
  primary_models = file.path(
    project_root, "outputs", "models", "formal",
    "07_formal_five_wave_networks_gamma050.rds"
  ),
  primary_edges = file.path(
    project_root, "outputs", "tables", "formal",
    "07_formal_five_wave_edge_weights.csv"
  ),
  wave_summary = file.path(
    project_root, "outputs", "tables", "formal", "08_overall_wave_summary.csv"
  ),
  contrast_summary = file.path(
    project_root, "outputs", "tables", "formal",
    "08_overall_global_strength_contrasts.csv"
  )
)

stopifnot(all(file.exists(unlist(paths))))
input_hashes_before <- vapply(unlist(paths), file_sha256, character(1))

claims <- read.csv(paths$claims, check.names = FALSE)
arms <- read.csv(paths$arms, check.names = FALSE)
authorisation <- read.csv(paths$authorisation, check.names = FALSE)
analysis_ready <- readRDS(paths$analysis_ready)
polychoric_bundle <- readRDS(paths$polychoric_bundle)
primary_models <- readRDS(paths$primary_models)
primary_edges_file <- read.csv(paths$primary_edges, check.names = FALSE)
wave_summary <- read.csv(paths$wave_summary, check.names = FALSE)
contrast_summary <- read.csv(paths$contrast_summary, check.names = FALSE)

decision_gate <- data.frame(
  Check = c(
    "Execution is explicitly authorised",
    "Exactly four frozen arms are present",
    "Frozen arm IDs are A0 to A3",
    "Common equal-N is 789",
    "Formal equal-N repetitions are 1000",
    "Technical pilot repetitions are 50",
    "All arms use gamma 0.50 and no weights",
    "A2 and A3 differ only by threshold",
    "Pre-result claim registry contains 205 unique claims",
    "All claims were frozen before Step 09B results"
  ),
  Passed = c(
    nrow(authorisation) == 1L &&
      authorisation$Researcher_approval_status == "APPROVED" &&
      authorisation$Implementation_status == "AUTHORISED",
    nrow(arms) == 4L,
    setequal(arms$Arm_ID, c("A0", "A1", "A2", "A3")),
    all(arms$Common_N[arms$Arm_ID %in% c("A2", "A3")] == common_n),
    all(arms$Formal_repetitions[arms$Arm_ID %in% c("A2", "A3")] == formal_repetitions),
    all(arms$Pilot_repetitions[arms$Arm_ID %in% c("A2", "A3")] == pilot_repetitions),
    all(arms$Gamma == 0.50) && !any(as.logical(arms$Weighted)),
    {
      a2 <- arms[arms$Arm_ID == "A2", , drop = FALSE]
      a3 <- arms[arms$Arm_ID == "A3", , drop = FALSE]
      nrow(a2) == 1L && nrow(a3) == 1L &&
        !as.logical(a2$Threshold) && as.logical(a3$Threshold) &&
        identical(a2$Common_N, a3$Common_N) &&
        identical(a2$Formal_repetitions, a3$Formal_repetitions)
    },
    nrow(claims) == 205L && !anyDuplicated(claims$Claim_ID),
    all(claims$Freeze_status == "PRE_RESULT_FROZEN")
  ),
  stringsAsFactors = FALSE
)

run_controls <- data.frame(
  Analysis = c(
    "Bootstrap", "Centrality", "NCT", "Education_group_analysis",
    "Survey_weight_reestimation", "Significance_testing", "Matrix_repair",
    "Category_merging", "Model_substitution"
  ),
  Permitted = FALSE,
  Executed = FALSE,
  stringsAsFactors = FALSE
)

package_gate <- data.frame(
  Package = c("R", "qgraph", "bootnet", "digest"),
  Version = c(
    paste(R.version$major, R.version$minor, sep = "."),
    as.character(packageVersion("qgraph")),
    as.character(packageVersion("bootnet")),
    as.character(packageVersion("digest"))
  ),
  Available = TRUE,
  stringsAsFactors = FALSE
)

analysis_ready$.analysis_row_index <- seq_len(nrow(analysis_ready))
input_validation <- data.frame(
  Check = c(
    "Analysis-ready object is a data frame",
    "Expected waves and nine nodes are available",
    "Wave sample sizes match frozen counts",
    "All nine-node analysis rows are complete",
    "Polychoric bundle has five matrices and frozen order",
    "Primary model bundle has five networks",
    "Primary edge table has 180 rows",
    "Primary wave summary has five rows"
  ),
  Passed = c(
    is.data.frame(analysis_ready),
    all(c("VCF0004", "VCF0006", "VCF0006a", network_vars) %in% names(analysis_ready)) &&
      setequal(unique(as.integer(analysis_ready$VCF0004)), years),
    identical(
      as.integer(table(factor(analysis_ready$VCF0004, levels = years))),
      as.integer(expected_n)
    ),
    !anyNA(analysis_ready[, network_vars]),
    is.list(polychoric_bundle$Matrices) &&
      setequal(names(polychoric_bundle$Matrices), as.character(years)) &&
      all(vapply(
        polychoric_bundle$Matrices,
        function(x) identical(rownames(x), network_vars) &&
          identical(colnames(x), network_vars),
        logical(1)
      )),
    is.list(primary_models) && setequal(names(primary_models), as.character(years)),
    nrow(primary_edges_file) == 180L,
    nrow(wave_summary) == 5L
  ),
  stringsAsFactors = FALSE
)

write_csv(decision_gate, "09B_decision_gate.csv")
write_csv(run_controls, "09B_run_controls.csv")
write_csv(package_gate, "09B_package_gate.csv")
write_csv(input_validation, "09B_primary_input_validation.csv")

if (!all(decision_gate$Passed) || !all(input_validation$Passed)) {
  flush_log()
  stop("Step 09B preflight failed. No sensitivity models were estimated.")
}

primary_graphs <- setNames(lapply(as.character(years), function(wave) {
  graph <- primary_models[[wave]]$object$graph
  stopifnot(matrix_diagnostics(graph, diagonal_target = 0)$valid)
  graph
}), as.character(years))

primary_identity <- do.call(rbind, lapply(as.character(years), function(wave) {
  observed <- edge_table(primary_graphs[[wave]])
  expected <- primary_edges_file[
    as.integer(primary_edges_file$Wave) == as.integer(wave),
    , drop = FALSE
  ]
  expected$Edge_ID <- paste(expected$Node_1, expected$Node_2, sep = "--")
  expected <- expected[match(observed$Edge_ID, expected$Edge_ID), , drop = FALSE]
  data.frame(
    Wave = as.integer(wave),
    Edge_keys_match = identical(observed$Edge_ID, expected$Edge_ID),
    Maximum_edge_difference = max(abs(
      observed$Edge_weight - as.numeric(expected$Edge_weight)
    )),
    Retention_matches = all(
      observed$Retained == as.logical(expected$Retained_under_EBICglasso)
    ),
    stringsAsFactors = FALSE
  )
}))
primary_identity$Passed <- with(
  primary_identity,
  Edge_keys_match & Maximum_edge_difference <= 1e-12 & Retention_matches
)
write_csv(primary_identity, "09B_primary_identity_validation.csv")
if (!all(primary_identity$Passed)) {
  flush_log()
  stop("Primary model identity check failed.")
}

log_note("Governance and primary-input gates passed")

# -----------------------------------------------------------------------------
# Stage 2: 50-repetition technical pilot for A2 and A3
# -----------------------------------------------------------------------------

pilot_rows <- vector("list", length(later_years) * pilot_repetitions * 2L)
pilot_index <- 0L

for (wave in later_years) {
  wave_data <- analysis_ready[analysis_ready$VCF0004 == wave, , drop = FALSE]
  for (repetition in seq_len(pilot_repetitions)) {
    seed <- derived_seed(wave, repetition, pilot = TRUE)
    set.seed(seed)
    selected <- sample.int(nrow(wave_data), common_n, replace = FALSE)
    sample_data <- wave_data[selected, , drop = FALSE]
    hash <- sample_hash(sample_data, wave, repetition)
    cor_result <- correlation_and_quality(sample_data)
    fit_a2 <- if (cor_result$success) {
      run_ebic(cor_result$correlation, common_n, threshold = FALSE)
    } else NULL
    fit_a3 <- if (cor_result$success) {
      run_ebic(cor_result$correlation, common_n, threshold = TRUE)
    } else NULL
    pilot_index <- pilot_index + 1L
    pilot_rows[[pilot_index]] <- diagnostic_row(
      "A2", wave, repetition, seed, FALSE, hash, cor_result, fit_a2
    )
    pilot_index <- pilot_index + 1L
    pilot_rows[[pilot_index]] <- diagnostic_row(
      "A3", wave, repetition, seed, FALSE, hash, cor_result, fit_a3
    )
  }
  log_note("Pilot completed for wave ", wave)
}

pilot_diagnostics <- do.call(rbind, pilot_rows)
pilot_summary <- aggregate(
  Success ~ Arm_ID + Wave,
  data = pilot_diagnostics,
  FUN = function(x) c(
    Successful = sum(x),
    Planned = length(x),
    Success_rate = mean(x)
  )
)
pilot_values <- pilot_summary$Success
if (!is.matrix(pilot_values)) {
  pilot_values <- do.call(rbind, pilot_values)
}
pilot_summary <- cbind(
  pilot_summary[c("Arm_ID", "Wave")],
  as.data.frame(pilot_values)
)
pilot_summary$Pilot_passed <- pilot_summary$Success_rate >= success_threshold

write_csv(pilot_diagnostics, "09B_pilot_diagnostics.csv")
write_csv(pilot_summary, "09B_pilot_validation.csv")

if (!all(pilot_summary$Pilot_passed)) {
  flush_log()
  stop("Step 09B technical pilot failed. Formal repetitions were not started.")
}

log_note("Technical pilot passed")

# -----------------------------------------------------------------------------
# Stage 3: A1 full-N threshold point networks
# -----------------------------------------------------------------------------

a1_fits <- list()
a1_rows <- list()
a1_edge_rows <- list()

for (wave in years) {
  wave_key <- as.character(wave)
  correlation <- polychoric_bundle$Matrices[[wave_key]]
  fit <- run_ebic(correlation, expected_n[[wave_key]], threshold = TRUE)
  a1_fits[[wave_key]] <- fit
  graph <- if (fit$success) fit$graph else matrix(
    NA_real_, length(network_vars), length(network_vars),
    dimnames = list(network_vars, network_vars)
  )
  a1_rows[[wave_key]] <- data.frame(
    Arm_ID = "A1",
    Wave = wave,
    N = expected_n[[wave_key]],
    Success = fit$success,
    Selected_lambda = fit$selected_lambda,
    Lambda_max = fit$lambda_max,
    Lambda_ratio = fit$lambda_ratio,
    Dense_warning = fit$dense_warning,
    Lowest_lambda_selected = fit$lowest_lambda_selected,
    Retained_edges = if (fit$success) sum(graph[upper.tri(graph)] != 0) else NA_integer_,
    Global_strength = if (fit$success) sum(abs(graph[upper.tri(graph)])) else NA_real_,
    Warning = fit$warnings,
    Message = fit$messages,
    Error = fit$error,
    stringsAsFactors = FALSE
  )
  if (fit$success) {
    primary_edges <- edge_table(primary_graphs[[wave_key]])
    sensitivity_edges <- edge_table(graph)
    sensitivity_edges <- sensitivity_edges[
      match(primary_edges$Edge_ID, sensitivity_edges$Edge_ID),
      , drop = FALSE
    ]
    a1_edge_rows[[wave_key]] <- data.frame(
      Arm_ID = "A1",
      Wave = wave,
      Edge_ID = primary_edges$Edge_ID,
      Node_1 = primary_edges$Node_1,
      Node_2 = primary_edges$Node_2,
      Primary_edge_weight = primary_edges$Edge_weight,
      Sensitivity_edge_weight = sensitivity_edges$Edge_weight,
      Primary_retained = primary_edges$Retained,
      Sensitivity_retained = sensitivity_edges$Retained,
      Primary_sign = primary_edges$Sign,
      Sensitivity_sign = sensitivity_edges$Sign,
      State_matches_primary = state_matches(
        primary_edges$Edge_weight,
        sensitivity_edges$Edge_weight
      ),
      Absolute_edge_difference = abs(
        sensitivity_edges$Edge_weight - primary_edges$Edge_weight
      ),
      stringsAsFactors = FALSE
    )
  }
}

a1_diagnostics <- do.call(rbind, a1_rows)
a1_edge_comparison <- do.call(rbind, a1_edge_rows)
write_csv(a1_diagnostics, "09B_fullN_threshold_diagnostics.csv")
write_csv(a1_edge_comparison, "09B_fullN_threshold_edge_comparison.csv")

if (!all(a1_diagnostics$Success) || nrow(a1_edge_comparison) != 180L) {
  flush_log()
  stop("A1 full-N threshold estimation failed.")
}

saveRDS(a1_fits, file.path(model_dir, "09B_fullN_threshold_models.rds"))
log_note("A1 full-N threshold networks completed")

# -----------------------------------------------------------------------------
# Stage 4: A2/A3 equal-N formal repetitions
# -----------------------------------------------------------------------------

edge_template <- edge_table(primary_graphs[["2004"]])
edge_count <- nrow(edge_template)
arm_ids <- c("A2", "A3")
edge_arrays <- setNames(lapply(arm_ids, function(x) {
  array(
    NA_real_,
    dim = c(formal_repetitions, edge_count, length(years)),
    dimnames = list(
      as.character(seq_len(formal_repetitions)),
      edge_template$Edge_ID,
      as.character(years)
    )
  )
}), arm_ids)
retained_arrays <- setNames(lapply(arm_ids, function(x) {
  matrix(
    NA_integer_,
    nrow = formal_repetitions,
    ncol = length(years),
    dimnames = list(as.character(seq_len(formal_repetitions)), as.character(years))
  )
}), arm_ids)
strength_arrays <- setNames(lapply(arm_ids, function(x) {
  matrix(
    NA_real_,
    nrow = formal_repetitions,
    ncol = length(years),
    dimnames = list(as.character(seq_len(formal_repetitions)), as.character(years))
  )
}), arm_ids)

formal_rows <- vector("list", formal_repetitions * length(years) * 2L)
formal_index <- 0L
seed_rows <- vector("list", formal_repetitions * length(years))
seed_index <- 0L
sample_indices <- setNames(vector("list", length(later_years)), as.character(later_years))
for (wave in later_years) {
  sample_indices[[as.character(wave)]] <- matrix(
    NA_integer_,
    nrow = common_n,
    ncol = formal_repetitions
  )
}

# The 2004 equal-N sample is the complete 789-person primary sample.
wave_2004 <- analysis_ready[analysis_ready$VCF0004 == 2004L, , drop = FALSE]
fixed_hash <- sample_hash(wave_2004, 2004L, 0L)
fixed_graphs <- list(
  A2 = primary_graphs[["2004"]],
  A3 = a1_fits[["2004"]]$graph
)
fixed_cor_result <- list(
  success = TRUE,
  quality = sample_quality(ordered_node_data(wave_2004)),
  diagnostics = matrix_diagnostics(
    polychoric_bundle$Matrices[["2004"]], diagonal_target = 1
  ),
  warnings = "",
  messages = "REUSED_VALIDATED_FULL_2004_POLYCHORIC_INPUT",
  error = "",
  elapsed_seconds = 0
)

for (arm in arm_ids) {
  fixed_edges <- edge_table(fixed_graphs[[arm]])$Edge_weight
  edge_arrays[[arm]][, , "2004"] <- matrix(
    rep(fixed_edges, each = formal_repetitions),
    nrow = formal_repetitions,
    ncol = edge_count
  )
  retained_arrays[[arm]][, "2004"] <- sum(fixed_edges != 0)
  strength_arrays[[arm]][, "2004"] <- sum(abs(fixed_edges))
}

for (repetition in seq_len(formal_repetitions)) {
  seed_index <- seed_index + 1L
  seed_rows[[seed_index]] <- data.frame(
    Wave = 2004L,
    Repetition = repetition,
    Seed = NA_integer_,
    Fixed_sample = TRUE,
    Sample_hash = fixed_hash,
    stringsAsFactors = FALSE
  )
  for (arm in arm_ids) {
    fixed_fit <- list(
      success = TRUE,
      graph = fixed_graphs[[arm]],
      selected_lambda = if (arm == "A2") {
        primary_models[["2004"]]$object$results$lambda[
          which.min(primary_models[["2004"]]$object$results$ebic)
        ]
      } else a1_fits[["2004"]]$selected_lambda,
      lambda_max = if (arm == "A2") {
        max(primary_models[["2004"]]$object$results$lambda)
      } else a1_fits[["2004"]]$lambda_max,
      lambda_ratio = if (arm == "A2") {
        primary_models[["2004"]]$object$results$lambda[
          which.min(primary_models[["2004"]]$object$results$ebic)
        ] / max(primary_models[["2004"]]$object$results$lambda)
      } else a1_fits[["2004"]]$lambda_ratio,
      dense_warning = if (arm == "A2") TRUE else a1_fits[["2004"]]$dense_warning,
      lowest_lambda_selected = if (arm == "A2") FALSE else {
        a1_fits[["2004"]]$lowest_lambda_selected
      },
      warnings = if (arm == "A2") {
        collapse_conditions(primary_models[["2004"]]$warnings)
      } else a1_fits[["2004"]]$warnings,
      messages = "FIXED_2004_EQUAL_N_REFERENCE",
      error = "",
      elapsed_seconds = 0
    )
    formal_index <- formal_index + 1L
    formal_rows[[formal_index]] <- diagnostic_row(
      arm, 2004L, repetition, NA_integer_, TRUE, fixed_hash,
      fixed_cor_result, fixed_fit
    )
  }
}

for (wave in later_years) {
  wave_key <- as.character(wave)
  wave_data <- analysis_ready[analysis_ready$VCF0004 == wave, , drop = FALSE]
  for (repetition in seq_len(formal_repetitions)) {
    seed <- derived_seed(wave, repetition, pilot = FALSE)
    set.seed(seed)
    selected <- sample.int(nrow(wave_data), common_n, replace = FALSE)
    sample_indices[[wave_key]][, repetition] <- selected
    sample_data <- wave_data[selected, , drop = FALSE]
    hash <- sample_hash(sample_data, wave, repetition)
    seed_index <- seed_index + 1L
    seed_rows[[seed_index]] <- data.frame(
      Wave = wave,
      Repetition = repetition,
      Seed = seed,
      Fixed_sample = FALSE,
      Sample_hash = hash,
      stringsAsFactors = FALSE
    )
    cor_result <- correlation_and_quality(sample_data)
    fits <- list(
      A2 = if (cor_result$success) {
        run_ebic(cor_result$correlation, common_n, threshold = FALSE)
      } else NULL,
      A3 = if (cor_result$success) {
        run_ebic(cor_result$correlation, common_n, threshold = TRUE)
      } else NULL
    )
    for (arm in arm_ids) {
      fit <- fits[[arm]]
      formal_index <- formal_index + 1L
      formal_rows[[formal_index]] <- diagnostic_row(
        arm, wave, repetition, seed, FALSE, hash, cor_result, fit
      )
      if (!is.null(fit) && fit$success) {
        edges <- edge_table(fit$graph)$Edge_weight
        edge_arrays[[arm]][repetition, , wave_key] <- edges
        retained_arrays[[arm]][repetition, wave_key] <- sum(edges != 0)
        strength_arrays[[arm]][repetition, wave_key] <- sum(abs(edges))
      }
    }
    if (repetition %% 100L == 0L) {
      log_note("Formal equal-N progress: wave ", wave, ", repetition ", repetition)
      flush_log()
    }
  }
  log_note("Formal equal-N repetitions completed for wave ", wave)
}

formal_diagnostics <- do.call(rbind, formal_rows)
seed_manifest <- do.call(rbind, seed_rows)

formal_success <- aggregate(
  Success ~ Arm_ID + Wave,
  data = formal_diagnostics,
  FUN = function(x) c(
    Successful = sum(x),
    Planned = length(x),
    Success_rate = mean(x)
  )
)
formal_values <- formal_success$Success
if (!is.matrix(formal_values)) {
  formal_values <- do.call(rbind, formal_values)
}
formal_success <- cbind(
  formal_success[c("Arm_ID", "Wave")],
  as.data.frame(formal_values)
)
formal_success$Evaluable <- formal_success$Success_rate >= success_threshold

write_csv(seed_manifest, "09B_seed_manifest.csv")
write_csv(formal_diagnostics, "09B_equalN_run_diagnostics.csv")
write_csv(formal_success, "09B_equalN_validation.csv")

saveRDS(
  list(
    master_seed = master_seed,
    rng_kind = RNGkind(),
    common_n = common_n,
    formal_repetitions = formal_repetitions,
    sample_indices = sample_indices,
    sample_hashes = seed_manifest
  ),
  file.path(model_dir, "09B_equalN_samples.rds")
)

if (!all(formal_success$Evaluable)) {
  saveRDS(
    list(
      edge_weights = edge_arrays,
      retained_edges = retained_arrays,
      global_strength = strength_arrays
    ),
    file.path(model_dir, "09B_equalN_partial_results.rds")
  )
  flush_log()
  stop("Fewer than 95% of planned equal-N runs were estimable.")
}

log_note("A2 and A3 formal equal-N repetitions passed the estimability gate")

# -----------------------------------------------------------------------------
# Stage 5: aggregate edge, network and contrast evidence
# -----------------------------------------------------------------------------

quantile_or_na <- function(x, probability) {
  x <- x[is.finite(x)]
  if (!length(x)) NA_real_ else unname(stats::quantile(x, probability, names = FALSE))
}

edge_summary_rows <- list()
summary_index <- 0L
for (arm in arm_ids) {
  for (wave in years) {
    wave_key <- as.character(wave)
    primary_edges <- edge_table(primary_graphs[[wave_key]])
    for (edge_number in seq_len(edge_count)) {
      values <- edge_arrays[[arm]][, edge_number, wave_key]
      values <- values[is.finite(values)]
      summary_index <- summary_index + 1L
      edge_summary_rows[[summary_index]] <- data.frame(
        Arm_ID = arm,
        Wave = wave,
        Edge_ID = primary_edges$Edge_ID[edge_number],
        Node_1 = primary_edges$Node_1[edge_number],
        Node_2 = primary_edges$Node_2[edge_number],
        Primary_edge_weight = primary_edges$Edge_weight[edge_number],
        Successful_repetitions = length(values),
        Success_rate = length(values) / formal_repetitions,
        Retention_frequency = if (length(values)) mean(values != 0) else NA_real_,
        Primary_state_match_proportion = if (length(values)) {
          mean(state_matches(primary_edges$Edge_weight[edge_number], values))
        } else NA_real_,
        Same_sign_when_retained = if (
          length(values) && primary_edges$Edge_weight[edge_number] != 0 &&
            any(values != 0)
        ) {
          mean(sign(values[values != 0]) == sign(primary_edges$Edge_weight[edge_number]))
        } else NA_real_,
        Median_edge_weight = if (length(values)) median(values) else NA_real_,
        Lower_edge_weight = quantile_or_na(values, 0.025),
        Upper_edge_weight = quantile_or_na(values, 0.975),
        stringsAsFactors = FALSE
      )
    }
  }
}
equaln_edge_summary <- do.call(rbind, edge_summary_rows)
write_csv(equaln_edge_summary, "09B_equalN_edge_summary.csv")

network_summary_rows <- list()
summary_index <- 0L
for (arm in arm_ids) {
  for (wave in years) {
    wave_key <- as.character(wave)
    retained <- retained_arrays[[arm]][, wave_key]
    strength <- strength_arrays[[arm]][, wave_key]
    success_rows <- formal_diagnostics[
      formal_diagnostics$Arm_ID == arm & formal_diagnostics$Wave == wave,
      , drop = FALSE
    ]
    summary_index <- summary_index + 1L
    network_summary_rows[[summary_index]] <- data.frame(
      Arm_ID = arm,
      Wave = wave,
      Planned_repetitions = formal_repetitions,
      Successful_repetitions = sum(is.finite(retained) & is.finite(strength)),
      Success_rate = mean(is.finite(retained) & is.finite(strength)),
      Median_retained_edges = median(retained, na.rm = TRUE),
      Lower_retained_edges = quantile_or_na(retained, 0.025),
      Upper_retained_edges = quantile_or_na(retained, 0.975),
      Median_density = median(retained / edge_count, na.rm = TRUE),
      Lower_density = quantile_or_na(retained / edge_count, 0.025),
      Upper_density = quantile_or_na(retained / edge_count, 0.975),
      Median_global_strength = median(strength, na.rm = TRUE),
      Lower_global_strength = quantile_or_na(strength, 0.025),
      Upper_global_strength = quantile_or_na(strength, 0.975),
      Dense_warning_rate = mean(success_rows$Dense_warning, na.rm = TRUE),
      Lowest_lambda_selected_rate = mean(
        success_rows$Lowest_lambda_selected,
        na.rm = TRUE
      ),
      Median_lambda_ratio = median(success_rows$Lambda_ratio, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  }
}
equaln_network_summary <- do.call(rbind, network_summary_rows)
write_csv(equaln_network_summary, "09B_equalN_network_summary.csv")

contrast_rows <- list()
contrast_index <- 0L
for (i in seq_len(nrow(contrast_summary))) {
  early <- as.integer(contrast_summary$Earlier_wave[i])
  late <- as.integer(contrast_summary$Later_wave[i])
  primary_edge_difference <-
    wave_summary$Retained_edges[match(late, wave_summary$Wave)] -
    wave_summary$Retained_edges[match(early, wave_summary$Wave)]
  primary_strength_difference <- as.numeric(contrast_summary$Signed_difference[i])
  for (metric in c("Retained_edge_count_difference", "Global_strength_difference")) {
    primary_difference <- if (metric == "Retained_edge_count_difference") {
      primary_edge_difference
    } else primary_strength_difference
    primary_direction <- direction_label(primary_difference)

    a1_difference <- if (metric == "Retained_edge_count_difference") {
      a1_diagnostics$Retained_edges[match(late, a1_diagnostics$Wave)] -
        a1_diagnostics$Retained_edges[match(early, a1_diagnostics$Wave)]
    } else {
      a1_diagnostics$Global_strength[match(late, a1_diagnostics$Wave)] -
        a1_diagnostics$Global_strength[match(early, a1_diagnostics$Wave)]
    }
    contrast_index <- contrast_index + 1L
    contrast_rows[[contrast_index]] <- data.frame(
      Arm_ID = "A1",
      Earlier_wave = early,
      Later_wave = late,
      Metric = metric,
      Primary_difference = primary_difference,
      Primary_direction = primary_direction,
      Successful_pairs = 1L,
      Median_difference = a1_difference,
      Lower_difference = a1_difference,
      Upper_difference = a1_difference,
      Direction_match_proportion = as.numeric(
        direction_label(a1_difference) == primary_direction
      ),
      stringsAsFactors = FALSE
    )

    for (arm in arm_ids) {
      values <- if (metric == "Retained_edge_count_difference") {
        retained_arrays[[arm]][, as.character(late)] -
          retained_arrays[[arm]][, as.character(early)]
      } else {
        strength_arrays[[arm]][, as.character(late)] -
          strength_arrays[[arm]][, as.character(early)]
      }
      values <- values[is.finite(values)]
      contrast_index <- contrast_index + 1L
      contrast_rows[[contrast_index]] <- data.frame(
        Arm_ID = arm,
        Earlier_wave = early,
        Later_wave = late,
        Metric = metric,
        Primary_difference = primary_difference,
        Primary_direction = primary_direction,
        Successful_pairs = length(values),
        Median_difference = if (length(values)) median(values) else NA_real_,
        Lower_difference = quantile_or_na(values, 0.025),
        Upper_difference = quantile_or_na(values, 0.975),
        Direction_match_proportion = if (length(values)) {
          mean(direction_label(values) == primary_direction)
        } else NA_real_,
        stringsAsFactors = FALSE
      )
    }
  }
}
contrast_robustness <- do.call(rbind, contrast_rows)
write_csv(contrast_robustness, "09B_contrast_robustness.csv")

saveRDS(
  list(
    edge_weights = edge_arrays,
    retained_edges = retained_arrays,
    global_strength = strength_arrays,
    edge_template = edge_template,
    years = years,
    common_n = common_n,
    repetitions = formal_repetitions
  ),
  file.path(model_dir, "09B_equalN_results.rds")
)

# -----------------------------------------------------------------------------
# Stage 6: audit all 205 frozen claims
# -----------------------------------------------------------------------------

claim_rows <- vector("list", nrow(claims))
for (i in seq_len(nrow(claims))) {
  claim <- claims[i, , drop = FALSE]
  if (claim$Claim_type == "EDGE_SIGN_AND_RETENTION") {
    edge_id <- paste(claim$Node_1, claim$Node_2, sep = "--")
    a1 <- a1_edge_comparison[
      a1_edge_comparison$Wave == claim$Wave &
        a1_edge_comparison$Edge_ID == edge_id,
      , drop = FALSE
    ]
    a2 <- equaln_edge_summary[
      equaln_edge_summary$Arm_ID == "A2" &
        equaln_edge_summary$Wave == claim$Wave &
        equaln_edge_summary$Edge_ID == edge_id,
      , drop = FALSE
    ]
    a3 <- equaln_edge_summary[
      equaln_edge_summary$Arm_ID == "A3" &
        equaln_edge_summary$Wave == claim$Wave &
        equaln_edge_summary$Edge_ID == edge_id,
      , drop = FALSE
    ]
    evaluable <- nrow(a1) == 1L && nrow(a2) == 1L && nrow(a3) == 1L &&
      a2$Success_rate >= success_threshold && a3$Success_rate >= success_threshold
    minimum_match <- if (evaluable) {
      min(
        as.numeric(a1$State_matches_primary),
        a2$Primary_state_match_proportion,
        a3$Primary_state_match_proportion
      )
    } else NA_real_
    final_status <- if (!evaluable) {
      "NOT_EVALUABLE"
    } else if (!isTRUE(a1$State_matches_primary)) {
      "NOT_ROBUST"
    } else if (minimum_match >= 0.90) {
      "ROBUST"
    } else if (minimum_match >= 0.75) {
      "MIXED"
    } else {
      "NOT_ROBUST"
    }
    claim_rows[[i]] <- data.frame(
      Claim_ID = claim$Claim_ID,
      Claim_type = claim$Claim_type,
      Wave = claim$Wave,
      Earlier_wave = NA_integer_,
      Later_wave = NA_integer_,
      Metric = claim$Metric,
      A1_match = if (nrow(a1) == 1L) a1$State_matches_primary else NA,
      A2_match_proportion = if (nrow(a2) == 1L) {
        a2$Primary_state_match_proportion
      } else NA_real_,
      A3_match_proportion = if (nrow(a3) == 1L) {
        a3$Primary_state_match_proportion
      } else NA_real_,
      Minimum_match = minimum_match,
      Final_status = final_status,
      Interpretation = "MECHANICAL_EDGE_STATE_AUDIT_NOT_SIGNIFICANCE",
      stringsAsFactors = FALSE
    )
  } else if (claim$Claim_type == "WAVE_NETWORK_DESCRIPTOR") {
    a1_value <- switch(
      claim$Metric,
      Retained_edges = a1_diagnostics$Retained_edges[
        match(claim$Wave, a1_diagnostics$Wave)
      ],
      Density = a1_diagnostics$Retained_edges[
        match(claim$Wave, a1_diagnostics$Wave)
      ] / edge_count,
      Global_strength = a1_diagnostics$Global_strength[
        match(claim$Wave, a1_diagnostics$Wave)
      ]
    )
    a2 <- equaln_network_summary[
      equaln_network_summary$Arm_ID == "A2" &
        equaln_network_summary$Wave == claim$Wave,
      , drop = FALSE
    ]
    a3 <- equaln_network_summary[
      equaln_network_summary$Arm_ID == "A3" &
        equaln_network_summary$Wave == claim$Wave,
      , drop = FALSE
    ]
    metric_column <- switch(
      claim$Metric,
      Retained_edges = "Median_retained_edges",
      Density = "Median_density",
      Global_strength = "Median_global_strength"
    )
    claim_rows[[i]] <- data.frame(
      Claim_ID = claim$Claim_ID,
      Claim_type = claim$Claim_type,
      Wave = claim$Wave,
      Earlier_wave = NA_integer_,
      Later_wave = NA_integer_,
      Metric = claim$Metric,
      A1_match = NA,
      A2_match_proportion = as.numeric(a2[[metric_column]]),
      A3_match_proportion = as.numeric(a3[[metric_column]]),
      Minimum_match = NA_real_,
      Final_status = "DESCRIPTIVE_AUDIT_COMPLETE",
      Interpretation = paste0(
        "A1_VALUE=", signif(a1_value, 8),
        "; A2_AND_A3_COLUMNS_STORE_MEDIANS_NOT_MATCH_PROPORTIONS"
      ),
      stringsAsFactors = FALSE
    )
  } else {
    rows <- contrast_robustness[
      contrast_robustness$Earlier_wave == claim$Earlier_wave &
        contrast_robustness$Later_wave == claim$Later_wave &
        contrast_robustness$Metric == claim$Metric,
      , drop = FALSE
    ]
    a1 <- rows[rows$Arm_ID == "A1", , drop = FALSE]
    a2 <- rows[rows$Arm_ID == "A2", , drop = FALSE]
    a3 <- rows[rows$Arm_ID == "A3", , drop = FALSE]
    evaluable <- nrow(a1) == 1L && nrow(a2) == 1L && nrow(a3) == 1L &&
      a2$Successful_pairs >= success_threshold * formal_repetitions &&
      a3$Successful_pairs >= success_threshold * formal_repetitions
    minimum_match <- if (evaluable) min(
      a1$Direction_match_proportion,
      a2$Direction_match_proportion,
      a3$Direction_match_proportion
    ) else NA_real_
    final_status <- if (!evaluable) {
      "NOT_EVALUABLE"
    } else if (a1$Direction_match_proportion < 1) {
      "NOT_ROBUST"
    } else if (minimum_match >= 0.90) {
      "ROBUST"
    } else if (minimum_match >= 0.75) {
      "MIXED"
    } else {
      "NOT_ROBUST"
    }
    claim_rows[[i]] <- data.frame(
      Claim_ID = claim$Claim_ID,
      Claim_type = claim$Claim_type,
      Wave = NA_integer_,
      Earlier_wave = claim$Earlier_wave,
      Later_wave = claim$Later_wave,
      Metric = claim$Metric,
      A1_match = a1$Direction_match_proportion == 1,
      A2_match_proportion = a2$Direction_match_proportion,
      A3_match_proportion = a3$Direction_match_proportion,
      Minimum_match = minimum_match,
      Final_status = final_status,
      Interpretation = "DIRECTION_REPRODUCIBILITY_NOT_SIGNIFICANCE_OR_EQUIVALENCE",
      stringsAsFactors = FALSE
    )
  }
}

claim_robustness <- do.call(rbind, claim_rows)
write_csv(claim_robustness, "09B_claim_robustness.csv")

claim_summary <- as.data.frame(with(
  claim_robustness,
  table(Claim_type, Final_status, useNA = "ifany")
))
names(claim_summary) <- c("Claim_type", "Final_status", "Count")
claim_summary <- claim_summary[claim_summary$Count > 0L, , drop = FALSE]
write_csv(claim_summary, "09B_claim_robustness_summary.csv")

# -----------------------------------------------------------------------------
# Stage 7: final validation, hashes and reproducibility record
# -----------------------------------------------------------------------------

input_hashes_after <- vapply(unlist(paths), file_sha256, character(1))
input_hash_validation <- data.frame(
  Input = names(input_hashes_before),
  Path = unname(unlist(paths)),
  SHA256_before = unname(input_hashes_before),
  SHA256_after = unname(input_hashes_after),
  Hash_matches = unname(input_hashes_before == input_hashes_after),
  stringsAsFactors = FALSE
)
write_csv(input_hash_validation, "09B_input_hash_validation.csv")

completion_status <- data.frame(
  Check = c(
    "Decision and authorisation gates passed",
    "Primary model identity gate passed",
    "Technical pilot passed",
    "A1 completed for all five waves",
    "A2 and A3 each completed 1000 planned repetitions per wave",
    "Every A2 and A3 wave-arm achieved at least 95 percent estimability",
    "All 205 pre-result claims were audited",
    "No prohibited analysis was executed",
    "All input hashes remained unchanged",
    "ANES raw data were not read or modified"
  ),
  Complete = c(
    all(decision_gate$Passed),
    all(primary_identity$Passed),
    all(pilot_summary$Pilot_passed),
    nrow(a1_diagnostics) == 5L && all(a1_diagnostics$Success),
    nrow(formal_diagnostics) == formal_repetitions * length(years) * 2L,
    all(formal_success$Evaluable),
    nrow(claim_robustness) == 205L && !anyDuplicated(claim_robustness$Claim_ID),
    !any(run_controls$Executed),
    all(input_hash_validation$Hash_matches),
    TRUE
  ),
  stringsAsFactors = FALSE
)
write_csv(completion_status, "09B_completion_status.csv")

if (!all(completion_status$Complete)) {
  flush_log()
  stop("Step 09B final validation failed.")
}

session_file <- file.path(log_dir, "09B_sessionInfo.txt")
writeLines(capture.output(sessionInfo()), session_file, useBytes = TRUE)
log_note("Step 09B completed and validated")
flush_log()

output_files <- c(
  list.files(table_dir, pattern = "^09B_", full.names = TRUE),
  list.files(model_dir, pattern = "^09B_", full.names = TRUE),
  log_file,
  session_file
)
output_files <- output_files[
  basename(output_files) != "09B_output_hash_inventory.csv"
]
output_inventory <- data.frame(
  File = basename(output_files),
  Relative_path = substring(
    normalizePath(output_files, winslash = "/", mustWork = TRUE),
    nchar(normalizePath(project_root, winslash = "/", mustWork = TRUE)) + 2L
  ),
  Size_bytes = file.info(output_files)$size,
  SHA256 = vapply(output_files, file_sha256, character(1)),
  stringsAsFactors = FALSE
)
output_inventory <- output_inventory[order(output_inventory$Relative_path), , drop = FALSE]
write_csv(output_inventory, "09B_output_hash_inventory.csv")

cat("STEP09B_COMPLETE_AND_VALIDATED\n")
