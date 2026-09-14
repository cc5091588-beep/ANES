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
  "renv/library/windows/R-4.5/x86_64-w64-mingw32"
)
.libPaths(c(project_library, .libPaths()))

suppressPackageStartupMessages({
  library(bootnet)
  library(qgraph)
  library(digest)
})

run_started <- Sys.time()
years <- c(2004L, 2012L, 2016L, 2020L, 2024L)
mode_years <- c(2012L, 2016L, 2020L, 2024L)
expected_n <- c(`2004` = 789L, `2012` = 4353L, `2016` = 2709L,
                `2020` = 5390L, `2024` = 3525L)
expected_mode_n <- c(`2012` = 3062L, `2016` = 1914L,
                     `2020` = 5094L, `2024` = 2823L)
network_vars <- c(
  "VCF0806", "VCF0809", "VCF0838", "VCF0839", "VCF0879a",
  "VCF0888", "VCF0890", "VCF0894", "VCF9223"
)
eight_vars <- setdiff(network_vars, "VCF0839")
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
expected_mode_codes <- 0:9
matrix_tolerance <- sqrt(.Machine$double.eps)

model_dir <- file.path(project_root, "outputs/models/sensitivity")
table_dir <- file.path(project_root, "outputs/tables/sensitivity")
figure_dir <- file.path(project_root, "outputs/figures/sensitivity")
log_dir <- file.path(project_root, "outputs/logs")
for (path in c(model_dir, table_dir, figure_dir, log_dir)) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
}

log_file <- file.path(log_dir, "09_sensitivity_execution.log")
log_lines <- character()
log_note <- function(...) {
  line <- paste0(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " | ", paste0(...))
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
    error = error_text
  )
}

collapse_conditions <- function(x) {
  if (!length(x)) "" else paste(unique(trimws(x)), collapse = " | ")
}

ordered_node_data <- function(data, nodes = network_vars) {
  out <- as.data.frame(data[, nodes, drop = FALSE])
  for (node in nodes) {
    out[[node]] <- ordered(
      as.numeric(out[[node]]),
      levels = expected_categories[[node]]
    )
  }
  out
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

matrix_diagnostics <- function(mat, nodes, diagonal_target) {
  available <- !is.null(mat) && is.matrix(mat) &&
    identical(dim(mat), c(length(nodes), length(nodes)))
  if (!available) {
    return(data.frame(
      Rows = if (is.null(mat)) NA_integer_ else nrow(mat),
      Columns = if (is.null(mat)) NA_integer_ else ncol(mat),
      Correct_node_order = FALSE,
      All_finite = FALSE,
      Maximum_asymmetry = NA_real_,
      Maximum_diagonal_deviation = NA_real_,
      Maximum_absolute_off_diagonal = NA_real_,
      Within_correlation_bounds = FALSE,
      Minimum_eigenvalue = NA_real_,
      Positive_definite = FALSE,
      stringsAsFactors = FALSE
    ))
  }
  mat <- as.matrix(mat)
  off_diagonal <- mat[upper.tri(mat)]
  eig <- if (all(is.finite(mat))) {
    eigen((mat + t(mat)) / 2, symmetric = TRUE, only.values = TRUE)$values
  } else {
    NA_real_
  }
  data.frame(
    Rows = nrow(mat),
    Columns = ncol(mat),
    Correct_node_order = identical(rownames(mat), nodes) &&
      identical(colnames(mat), nodes),
    All_finite = all(is.finite(mat)),
    Maximum_asymmetry = max(abs(mat - t(mat))),
    Maximum_diagonal_deviation = max(abs(diag(mat) - diagonal_target)),
    Maximum_absolute_off_diagonal = if (length(off_diagonal)) {
      max(abs(off_diagonal))
    } else NA_real_,
    Within_correlation_bounds = if (diagonal_target == 1 &&
      all(is.finite(off_diagonal))) {
      all(abs(off_diagonal) <= 1 + matrix_tolerance)
    } else if (diagonal_target == 0 && all(is.finite(off_diagonal))) {
      all(abs(off_diagonal) <= 1 + matrix_tolerance)
    } else FALSE,
    Minimum_eigenvalue = if (all(is.finite(eig))) min(eig) else NA_real_,
    Positive_definite = if (diagonal_target == 1 && all(is.finite(eig))) {
      min(eig) > 0 && !inherits(try(chol(mat), silent = TRUE), "try-error")
    } else {
      NA
    },
    stringsAsFactors = FALSE
  )
}

edge_table <- function(mat) {
  stopifnot(is.matrix(mat), identical(rownames(mat), colnames(mat)))
  idx <- which(upper.tri(mat), arr.ind = TRUE)
  out <- data.frame(
    Node_1 = rownames(mat)[idx[, 1]],
    Node_2 = colnames(mat)[idx[, 2]],
    Edge_weight = as.numeric(mat[idx]),
    Retained = as.numeric(mat[idx]) != 0,
    Sign = ifelse(mat[idx] > 0, "POSITIVE", ifelse(mat[idx] < 0, "NEGATIVE", "ZERO")),
    stringsAsFactors = FALSE
  )
  out$Edge_ID <- paste(out$Node_1, out$Node_2, sep = "--")
  out[, c("Edge_ID", "Node_1", "Node_2", "Edge_weight", "Retained", "Sign")]
}

compare_networks <- function(primary, sensitivity, module_id, variant, wave,
                             estimation_status = "ESTIMABLE",
                             allow_global_strength = TRUE) {
  p <- edge_table(primary)
  s <- edge_table(sensitivity)
  stopifnot(
    !anyDuplicated(p$Edge_ID),
    !anyDuplicated(s$Edge_ID),
    setequal(p$Edge_ID, s$Edge_ID)
  )
  detailed <- merge(
    p, s,
    by = c("Edge_ID", "Node_1", "Node_2"),
    suffixes = c("_primary", "_sensitivity"),
    sort = FALSE
  )
  detailed <- detailed[match(p$Edge_ID, detailed$Edge_ID), , drop = FALSE]
  stopifnot(
    nrow(detailed) == nrow(p),
    !anyNA(match(p$Edge_ID, detailed$Edge_ID))
  )
  detailed$Module_ID <- module_id
  detailed$Variant <- variant
  detailed$Wave <- as.integer(wave)
  detailed$Signed_difference <-
    detailed$Edge_weight_sensitivity - detailed$Edge_weight_primary
  detailed$Absolute_difference <- abs(detailed$Signed_difference)
  detailed$Retained_status_changed <-
    detailed$Retained_primary != detailed$Retained_sensitivity
  detailed$Sign_reversed <-
    detailed$Retained_primary & detailed$Retained_sensitivity &
    detailed$Sign_primary != detailed$Sign_sensitivity
  detailed$Robustness_status <- ifelse(
    detailed$Sign_reversed,
    "REVERSED",
    ifelse(detailed$Retained_status_changed, "CHANGED", "UNCHANGED")
  )
  detailed$Estimation_status <- estimation_status
  detailed <- detailed[, c(
    "Module_ID", "Variant", "Wave", "Edge_ID", "Node_1", "Node_2",
    "Edge_weight_primary", "Edge_weight_sensitivity",
    "Retained_primary", "Retained_sensitivity",
    "Sign_primary", "Sign_sensitivity", "Signed_difference",
    "Absolute_difference", "Retained_status_changed", "Sign_reversed",
    "Robustness_status", "Estimation_status"
  )]

  p_ret <- detailed$Retained_primary
  s_ret <- detailed$Retained_sensitivity
  union_n <- sum(p_ret | s_ret)
  common_n <- sum(p_ret & s_ret)
  common_idx <- p_ret & s_ret
  metrics <- data.frame(
    Module_ID = module_id,
    Variant = variant,
    Wave = as.integer(wave),
    Compared_edges = nrow(detailed),
    Edge_weight_correlation = if (stats::sd(detailed$Edge_weight_primary) > 0 &&
      stats::sd(detailed$Edge_weight_sensitivity) > 0) {
      stats::cor(detailed$Edge_weight_primary, detailed$Edge_weight_sensitivity)
    } else NA_real_,
    Median_absolute_edge_difference = median(detailed$Absolute_difference),
    Mean_absolute_edge_difference = mean(detailed$Absolute_difference),
    Maximum_absolute_edge_difference = max(detailed$Absolute_difference),
    Primary_retained_edges = sum(p_ret),
    Sensitivity_retained_edges = sum(s_ret),
    Common_retained_edges = common_n,
    Retained_edge_union = union_n,
    Retained_edge_Jaccard = if (union_n > 0) common_n / union_n else NA_real_,
    Sign_agreement_common_retained = if (common_n > 0) {
      mean(detailed$Sign_primary[common_idx] == detailed$Sign_sensitivity[common_idx])
    } else NA_real_,
    Sign_reversals_common_retained = sum(
      common_idx & detailed$Sign_primary != detailed$Sign_sensitivity
    ),
    Primary_global_strength = if (allow_global_strength) {
      sum(abs(detailed$Edge_weight_primary))
    } else NA_real_,
    Sensitivity_global_strength = if (allow_global_strength) {
      sum(abs(detailed$Edge_weight_sensitivity))
    } else NA_real_,
    Global_strength_difference = if (allow_global_strength) {
      sum(abs(detailed$Edge_weight_sensitivity)) -
        sum(abs(detailed$Edge_weight_primary))
    } else NA_real_,
    Estimation_status = estimation_status,
    stringsAsFactors = FALSE
  )
  list(detailed = detailed, metrics = metrics)
}

not_evaluable_edges <- function(primary, module_id, variant, wave, status) {
  p <- edge_table(primary)
  data.frame(
    Module_ID = module_id,
    Variant = variant,
    Wave = as.integer(wave),
    Edge_ID = p$Edge_ID,
    Node_1 = p$Node_1,
    Node_2 = p$Node_2,
    Edge_weight_primary = p$Edge_weight,
    Edge_weight_sensitivity = NA_real_,
    Retained_primary = p$Retained,
    Retained_sensitivity = NA,
    Sign_primary = p$Sign,
    Sign_sensitivity = NA_character_,
    Signed_difference = NA_real_,
    Absolute_difference = NA_real_,
    Retained_status_changed = NA,
    Sign_reversed = NA,
    Robustness_status = "NOT_EVALUABLE",
    Estimation_status = status,
    stringsAsFactors = FALSE
  )
}

not_evaluable_metrics <- function(primary, module_id, variant, wave, status,
                                  allow_global_strength = TRUE) {
  p <- edge_table(primary)
  data.frame(
    Module_ID = module_id,
    Variant = variant,
    Wave = as.integer(wave),
    Compared_edges = nrow(p),
    Edge_weight_correlation = NA_real_,
    Median_absolute_edge_difference = NA_real_,
    Mean_absolute_edge_difference = NA_real_,
    Maximum_absolute_edge_difference = NA_real_,
    Primary_retained_edges = sum(p$Retained),
    Sensitivity_retained_edges = NA_integer_,
    Common_retained_edges = NA_integer_,
    Retained_edge_union = NA_integer_,
    Retained_edge_Jaccard = NA_real_,
    Sign_agreement_common_retained = NA_real_,
    Sign_reversals_common_retained = NA_integer_,
    Primary_global_strength = if (allow_global_strength) {
      sum(abs(p$Edge_weight))
    } else NA_real_,
    Sensitivity_global_strength = NA_real_,
    Global_strength_difference = NA_real_,
    Estimation_status = status,
    stringsAsFactors = FALSE
  )
}

log_note("Step 09 engine started")

# -----------------------------------------------------------------------------
# Stage 1-5: governance, inputs, hashes, packages and pre-result claim registry
# -----------------------------------------------------------------------------

paths <- list(
  scope = file.path(erp_root, "project_docs/decisions/step09_sensitivity_scope.csv"),
  authorisation = file.path(erp_root, "project_docs/decisions/step09_execution_authorisation.csv"),
  registry = file.path(erp_root, "project_docs/governance_audit/REVISED_PROPOSED_DECISION_REGISTRY_v5.csv"),
  claims = file.path(erp_root, "project_docs/decisions/step09_primary_claim_registry.csv"),
  cleaned = file.path(project_root, "data/cleaned/anes_cdf_20260205_cleaned_2004_2012_2016_2020_2024.rds"),
  analysis_ready = file.path(project_root, "data/analysis_ready/anes_cdf_20260205_analysis_ready_nine_node_complete_case_2004_2012_2016_2020_2024.rds"),
  primary_poly = file.path(project_root, "data/audit/anes_cdf_20260205_nine_node_complete_case_polychoric_diagnostics_2004_2012_2016_2020_2024.rds"),
  primary_networks = file.path(project_root, "outputs/models/formal/07_formal_five_wave_networks_gamma050.rds"),
  primary_edges = file.path(project_root, "outputs/tables/formal/07_formal_five_wave_edge_weights.csv"),
  d15_bundle = file.path(project_root, "outputs/models/pilot/d15_stage3b_five_wave_point_networks.rds"),
  d15_validation = file.path(project_root, "outputs/tables/pilot/d15_stage3b_five_wave_validation.csv"),
  d15_conditions = file.path(project_root, "outputs/tables/pilot/d15_stage3b_five_wave_conditions.csv"),
  d15_comparison = file.path(project_root, "outputs/tables/pilot/d15_stage3b_five_wave_point_network_comparison.csv"),
  d15_diagnostics = file.path(project_root, "outputs/tables/pilot/d15_stage3b_five_wave_point_network_diagnostics.csv"),
  d11_audit_dir = file.path(project_root, "data/audit/D11_PAIRWISE_20260828"),
  d11_hash_manifest = file.path(project_root, "data/audit/D11_PAIRWISE_20260828/D11_OUTPUT_HASH_MANIFEST.csv"),
  d11_n_summary = file.path(project_root, "data/audit/D11_PAIRWISE_20260828/D11_PAIRWISE_N_SUMMARY.csv"),
  d11_condition_log = file.path(project_root, "data/audit/D11_PAIRWISE_20260828/D11_CONDITION_LOG.csv"),
  d11_condition_summary = file.path(project_root, "data/audit/D11_PAIRWISE_20260828/D11_CONDITION_SUMMARY.csv")
)

expected_hashes <- c(
  scope = "C9EF8FE37A11A7A576387549E2277CF2136024E44B1B8824ACFF261058F3EB60",
  authorisation = "DEFCC7994E31548C45BE9D4C6BCF77E325DCE98D0B40C9EAD79E69D3099E6CD9",
  registry = "6F6E9A0567111FFACC5DA81642B4CB4E439DA2C6313D7E1EBB3BD73FD846036D",
  cleaned = "960B6C3B1E0718BC2C9FE3C070C7AFFF787D3FE06ADD31F348D8CC1396883F41",
  analysis_ready = "6726A0D548F8293E890AD380C4915097FDD4ABC1A51665D55E904A33F81432FA",
  primary_poly = "0AE377EC4E71F2AEE5F92FA3BF2CA4637BC95BD7869B670B676B28EC56FD7425",
  primary_networks = "B57D922A7E2AE925EECFDE2ADA6F3B6292F7188D1D389A086182E5481698B028",
  primary_edges = "7478595C145C842235E6B6F2D595C0692B927A2DD577CA1EEE0B7FF9F748AD65",
  d15_bundle = "20131F38D3F2B11AE5473794BFDD77CD8E4AA0355F080B56B5EE56481A49D604",
  d15_validation = "CD06818388441DA7945D7F2DB904B7A4AD03810BF38D8558AA55283694A8A598",
  d15_conditions = "38A3C5E9DF4FC3BB33814092DE04B48455F089FFEC4F81AE2D7538DC9CEA910A",
  d15_comparison = "213D952A94E2122D36106CC8CECF78FDFF8F64A3EF9D8EFAB1568577E1C92FFB",
  d15_diagnostics = "604808AAB258CB47EAC4686B51298BDEF3113CB5152AFE9C354876B0BA84B358",
  d11_hash_manifest = "DE8FFD4C25BA4B8FA6058270614F64028BF8F97F2253250CB0AC5B552269D57E",
  d11_n_summary = "456A5648C2B7C2EAC6DE1D8AEFBBB63B5A2B3882F41EF33E093D16E7640520D1",
  d11_condition_log = "620A7CBFE73B61D99676CA827951F01A13C167F7918EE4EEB49E5562C365CAAB",
  d11_condition_summary = "066AB8BB2F22D5A5DF5131B1EA428B020713BCA17322F0137BEE6AC9B448C889",
  claims = "2DA9C17F700731BAA899D4A11AB40F2D79A0A2C45C1482B8A119177351068F43"
)

scope <- read.csv(paths$scope, check.names = FALSE)
authorisation <- read.csv(paths$authorisation, check.names = FALSE)
registry <- read.csv(paths$registry, check.names = FALSE)
claims <- read.csv(paths$claims, check.names = FALSE)

included_rows <- scope[scope$included == "YES", , drop = FALSE]
excluded_rows <- scope[scope$included == "NO", , drop = FALSE]
required_modules <- c(
  "S09_D11", "S09_D20A_GAMMA", "S09_D20A_NO_VCF0839",
  "S09_D15_WEIGHT", "S09_D19_MODE"
)
decision_gate <- data.frame(
  Check = c(
    "Exactly five approved modules are included",
    "Included module IDs match the frozen scope",
    "Every included module is execution-authorised",
    "Every excluded module remains unauthorised",
    "Explicit execution authorisation is approved",
    "Primary claim registry contains 180 unique pre-result claims",
    "Current registry records D11/D15/D19/D20A/D27 as authorised"
  ),
  Passed = c(
    nrow(included_rows) == 5L,
    setequal(included_rows$module_id, required_modules),
    all(included_rows$execution_authorised == "YES"),
    all(excluded_rows$execution_authorised == "NO"),
    nrow(authorisation) == 1L &&
      authorisation$researcher_approval_status == "APPROVED" &&
      authorisation$implementation_status == "AUTHORISED",
    nrow(claims) == 180L && !anyDuplicated(claims$Claim_ID) &&
      all(claims$Frozen_before_sensitivity_results),
    {
      current_rows <- registry[
        registry$decision_id %in% c("D11", "D15", "D19", "D20A", "D27"),
        , drop = FALSE
      ]
      nrow(current_rows) == 5L &&
        setequal(current_rows$decision_id, c("D11", "D15", "D19", "D20A", "D27")) &&
        all(current_rows$implementation_status %in% c(
          "DIAGNOSTICS_COMPLETE_NETWORK_AUTHORISED",
          "PILOT_COMPLETE_REUSE_AUTHORISED",
          "AUTHORISED_NOT_EXECUTED"
        ))
    }
  ),
  stringsAsFactors = FALSE
)
write_csv(decision_gate, "09_decision_gate.csv")
if (!all(decision_gate$Passed)) stop("Step 09 decision gate failed")

input_keys <- names(expected_hashes)
input_paths <- unlist(paths[input_keys], use.names = TRUE)
input_inventory <- data.frame(
  Input_key = input_keys,
  Path = as.character(input_paths),
  Exists = file.exists(input_paths),
  Expected_SHA256 = unname(expected_hashes[input_keys]),
  Observed_SHA256 = vapply(input_paths, function(path) {
    if (file.exists(path)) file_sha256(path) else NA_character_
  }, character(1)),
  stringsAsFactors = FALSE
)
input_inventory$Hash_matches <-
  input_inventory$Expected_SHA256 == input_inventory$Observed_SHA256
write_csv(input_inventory, "09_input_inventory.csv")
write_csv(input_inventory[, c("Input_key", "Path", "Hash_matches")],
          "09_input_hash_validation.csv")
if (!all(input_inventory$Exists & input_inventory$Hash_matches)) {
  stop("Step 09 input file/hash gate failed")
}

d11_hash_manifest <- read.csv(paths$d11_hash_manifest, check.names = FALSE)
d11_archive_required <- unique(c(
  paste0("D11_PAIRWISE_N_MATRIX_", years, ".csv"),
  paste0("D11_CORRELATION_MATRIX_", years, ".csv"),
  "D11_PAIRWISE_N_SUMMARY.csv",
  "D11_CORRELATION_TYPES.csv",
  "D11_CONDITION_LOG.csv",
  "D11_CONDITION_SUMMARY.csv",
  "D11_MATRIX_CHECKS.csv"
))
d11_archive_gate <- data.frame(
  File = d11_archive_required,
  Path = file.path(paths$d11_audit_dir, d11_archive_required),
  Exists = file.exists(file.path(paths$d11_audit_dir, d11_archive_required)),
  Expected_SHA256 = d11_hash_manifest$sha256[
    match(d11_archive_required, d11_hash_manifest$file)
  ],
  stringsAsFactors = FALSE
)
d11_archive_gate$Observed_SHA256 <- vapply(
  d11_archive_gate$Path,
  function(path) if (file.exists(path)) file_sha256(path) else NA_character_,
  character(1)
)
d11_archive_gate$Hash_matches <-
  !is.na(d11_archive_gate$Expected_SHA256) &
  d11_archive_gate$Expected_SHA256 == d11_archive_gate$Observed_SHA256
write_csv(d11_archive_gate, "09_d11_archive_hash_gate.csv")
if (!all(d11_archive_gate$Exists & d11_archive_gate$Hash_matches)) {
  stop("D11 derived evidence archive gate failed")
}

required_packages <- c("bootnet", "qgraph", "digest", "lavaan")
package_gate <- data.frame(
  Package = required_packages,
  Installed = vapply(required_packages, requireNamespace, logical(1), quietly = TRUE),
  Version = vapply(required_packages, function(x) {
    if (requireNamespace(x, quietly = TRUE)) as.character(packageVersion(x)) else NA_character_
  }, character(1)),
  stringsAsFactors = FALSE
)
package_gate$Version_expected <- c("1.9.1", "1.10.1", "0.6.39", "0.7.2")
package_gate$Passed <- package_gate$Installed &
  package_gate$Version == package_gate$Version_expected
write_csv(package_gate, "09_package_gate.csv")
if (!all(package_gate$Passed)) stop("Step 09 package gate failed")

run_controls <- data.frame(
  Module = c("D11", "D20A_GAMMA025", "D20A_NO_VCF0839", "D15_REUSE", "D19_MODE"),
  Action = c("ESTIMATE", "ESTIMATE", "ESTIMATE", "REUSE_ONLY", "DIAGNOSE_THEN_ESTIMATE"),
  Bootstrap = FALSE,
  Centrality = FALSE,
  NCT = FALSE,
  Significance_testing = FALSE,
  Matrix_repair = FALSE,
  Category_merging = FALSE,
  stringsAsFactors = FALSE
)
write_csv(run_controls, "09_run_controls.csv")

engine_file <- file.path(project_root, "R", "09_sensitivity_analysis_engine.R")
engine_text <- if (file.exists(engine_file)) {
  paste(readLines(engine_file, warn = FALSE), collapse = "\n")
} else ""
prohibited_call_gate <- data.frame(
  Prohibited_call = c(
    "bootnet bootstrap",
    "Network Comparison Test",
    "centrality function",
    "nearest-positive-definite repair",
    "correlation smoothing enabled",
    "Spearman association"
  ),
  Pattern = c(
    paste0("bootnet::", "bootnet\\s*\\("),
    paste0("NetworkComparisonTest::", "NCT\\s*\\("),
    paste0("qgraph::", "centrality|centralityPlot\\s*\\(|centrality_auto\\s*\\("),
    paste0("Matrix::", "nearPD\\s*\\("),
    paste0("cor_smooth", "\\s*=\\s*TRUE"),
    paste0("corMethod", "\\s*=\\s*['\"]spearman['\"]")
  ),
  stringsAsFactors = FALSE
)
prohibited_call_gate$Detected <- vapply(
  prohibited_call_gate$Pattern,
  function(pattern) grepl(pattern, engine_text, perl = TRUE),
  logical(1)
)
write_csv(prohibited_call_gate, "09_prohibited_call_gate.csv")
if (any(prohibited_call_gate$Detected)) {
  stop("A prohibited Step 09 function call was detected in the engine")
}

cleaned <- readRDS(paths$cleaned)
analysis_ready <- readRDS(paths$analysis_ready)
primary_poly <- readRDS(paths$primary_poly)
primary_network_bundle <- readRDS(paths$primary_networks)
primary_graphs <- lapply(primary_network_bundle, function(x) x$object$graph)
primary_edges <- read.csv(paths$primary_edges, check.names = FALSE)

primary_input_validation <- data.frame(
  Check = c(
    "Cleaned data contains the five frozen waves and nine nodes",
    "Analysis-ready data has the frozen wave counts",
    "Primary polychoric bundle has the frozen node order",
    "Primary network bundle has five valid graphs",
    "Primary edge table contains 180 edges"
  ),
  Passed = c(
    all(c("VCF0004", "VCF0017", network_vars) %in% names(cleaned)) &&
      setequal(unique(cleaned$VCF0004), years),
    identical(
      as.integer(table(analysis_ready$VCF0004)[as.character(years)]),
      as.integer(expected_n)
    ),
    identical(as.character(primary_poly$Network_vars), network_vars) &&
      all(vapply(primary_poly$Matrices, function(m) {
        identical(rownames(m), network_vars) && identical(colnames(m), network_vars)
      }, logical(1))),
    length(primary_graphs) == 5L && all(vapply(primary_graphs, function(m) {
      is.matrix(m) && identical(dim(m), c(9L, 9L)) &&
        identical(rownames(m), network_vars) && all(is.finite(m))
    }, logical(1))),
    nrow(primary_edges) == 180L
  ),
  stringsAsFactors = FALSE
)
write_csv(primary_input_validation, "09_primary_input_validation.csv")
if (!all(primary_input_validation$Passed)) stop("Primary input validation failed")

primary_edge_key <- paste(
  primary_edges$Wave, primary_edges$Node_1, primary_edges$Node_2,
  sep = "|"
)
claim_edge_key <- paste(claims$Wave, claims$Node_1, claims$Node_2, sep = "|")
primary_match <- match(claim_edge_key, primary_edge_key)
matched_primary <- primary_edges[primary_match, , drop = FALSE]
matched_sign <- ifelse(
  matched_primary$Edge_weight > 0, "POSITIVE",
  ifelse(matched_primary$Edge_weight < 0, "NEGATIVE", "ZERO")
)
claim_registry_validation <- data.frame(
  Check = c(
    "Claim edge keys are unique",
    "Primary edge keys are unique",
    "Claim keys exactly equal the 07 primary edge keys",
    "Claim edge weights reproduce the 07 primary edge table",
    "Claim retained states reproduce the 07 primary edge table",
    "Claim signs reproduce the 07 primary edge table",
    "No-VCF0839 applicability is true only for 140 shared-edge claims",
    "D19 applicability is true only for 144 claims in 2012-2024"
  ),
  Passed = c(
    !anyDuplicated(claim_edge_key),
    !anyDuplicated(primary_edge_key),
    !anyNA(primary_match) && setequal(claim_edge_key, primary_edge_key),
    !anyNA(primary_match) && max(abs(
      claims$Primary_edge_weight - matched_primary$Edge_weight
    )) <= matrix_tolerance,
    !anyNA(primary_match) && identical(
      as.logical(claims$Primary_retained),
      as.logical(matched_primary$Retained_under_EBICglasso)
    ),
    !anyNA(primary_match) && identical(as.character(claims$Primary_sign), matched_sign),
    sum(as.logical(claims$D20A_no_VCF0839_applicable)) == 140L &&
      all(!as.logical(claims$D20A_no_VCF0839_applicable) ==
        (claims$Node_1 == "VCF0839" | claims$Node_2 == "VCF0839")),
    sum(as.logical(claims$D19_all_internet_applicable)) == 144L &&
      all(as.logical(claims$D19_all_internet_applicable) == claims$Wave %in% mode_years)
  ),
  stringsAsFactors = FALSE
)
write_csv(claim_registry_validation, "09_primary_claim_registry_validation.csv")
if (!all(claim_registry_validation$Passed)) {
  stop("Primary-claim registry validation failed")
}

log_note("Governance, claims, input hashes and packages passed")

# -----------------------------------------------------------------------------
# Stage 6: D11 pairwise-available polychoric point networks
# -----------------------------------------------------------------------------

d11_networks <- list()
d11_matrices <- list()
d11_conditions <- list()
d11_validation <- list()
d11_comparisons <- list()
d11_detailed <- list()
d11_n_summary_source <- read.csv(paths$d11_n_summary, check.names = FALSE)
d11_historical_conditions <- read.csv(paths$d11_condition_log, check.names = FALSE)

read_named_matrix_csv <- function(path, order) {
  x <- read.csv(path, check.names = FALSE)
  rownames(x) <- x[[1]]
  x[[1]] <- NULL
  m <- as.matrix(x)
  storage.mode(m) <- "double"
  m[order, order, drop = FALSE]
}

for (yr in years) {
  log_note("D11 start: ", yr)
  wave <- cleaned[cleaned$VCF0004 == yr, , drop = FALSE]
  ordered_wave <- ordered_node_data(wave, network_vars)
  pair_n <- outer(seq_along(network_vars), seq_along(network_vars),
                  Vectorize(function(i, j) {
                    sum(!is.na(ordered_wave[[i]]) & !is.na(ordered_wave[[j]]))
                  }))
  dimnames(pair_n) <- list(network_vars, network_vars)

  archived_n <- read_named_matrix_csv(
    file.path(paths$d11_audit_dir, paste0("D11_PAIRWISE_N_MATRIX_", yr, ".csv")),
    network_vars
  )
  archived_cor <- read_named_matrix_csv(
    file.path(paths$d11_audit_dir, paste0("D11_CORRELATION_MATRIX_", yr, ".csv")),
    network_vars
  )
  pair_n_match <-
    identical(dimnames(pair_n), dimnames(archived_n)) &&
    identical(dim(pair_n), dim(archived_n)) &&
    all(is.finite(archived_n)) &&
    all(pair_n == archived_n)
  cor_run <- capture_run(function() {
    qgraph::cor_auto(
      ordered_wave,
      detectOrdinal = TRUE,
      ordinalLevelMax = 7,
      npn.SKEPTIC = FALSE,
      forcePD = FALSE,
      missing = "pairwise",
      verbose = TRUE
    )
  })
  current_cor <- if (!is.null(cor_run$value)) {
    as.matrix(cor_run$value)[network_vars, network_vars, drop = FALSE]
  } else NULL
  archived_correlation_maximum_difference <- if (!is.null(current_cor)) {
    max(abs(current_cor - archived_cor))
  } else NA_real_
  archived_correlation_match <- !is.null(current_cor) &&
    isTRUE(all.equal(
      current_cor, archived_cor,
      tolerance = matrix_tolerance, check.attributes = FALSE
    ))
  cor_diag <- matrix_diagnostics(current_cor, network_vars, 1)
  pair_values <- pair_n[upper.tri(pair_n)]
  pair_average <- mean(pair_values)
  archived_summary_row <- d11_n_summary_source[
    d11_n_summary_source$year == yr, , drop = FALSE
  ]
  archived_average_match <- nrow(archived_summary_row) == 1L &&
    abs(
      pair_average -
        archived_summary_row$pairwise_average_sample_size_for_later_model
    ) <= matrix_tolerance
  pre_pass <- pair_n_match && archived_average_match &&
    archived_correlation_match &&
    isTRUE(cor_diag$All_finite) && isTRUE(cor_diag$Correct_node_order) &&
    cor_diag$Maximum_asymmetry <= matrix_tolerance &&
    cor_diag$Maximum_diagonal_deviation <= matrix_tolerance &&
    isTRUE(cor_diag$Positive_definite) &&
    all(vapply(ordered_wave, is.ordered, logical(1)))

  model_run <- if (pre_pass) capture_run(function() {
    bootnet::estimateNetwork(
      data = ordered_wave,
      default = "EBICglasso",
      corMethod = "cor_auto",
      missing = "pairwise",
      sampleSize = "pairwise_average",
      tuning = 0.50,
      corArgs = list(
        detectOrdinal = TRUE,
        ordinalLevelMax = 7,
        forcePD = FALSE
      ),
      nonPositiveDefinite = "stop",
      refit = FALSE,
      threshold = FALSE,
      nlambda = 100,
      lambda.min.ratio = 0.01,
      verbose = TRUE
    )
  }) else list(value = NULL, warnings = character(), messages = character(),
               error = "Pre-estimation identity or mathematical gate failed")

  graph <- if (!is.null(model_run$value)) model_run$value$graph else NULL
  reference_run <- if (pre_pass) capture_run(function() {
    qgraph::EBICglasso(
      S = current_cor,
      n = pair_average,
      gamma = 0.50,
      nlambda = 100L,
      lambda.min.ratio = 0.01,
      refit = FALSE,
      threshold = FALSE
    )
  }) else list(value = NULL, warnings = character(), messages = character(),
               error = "Pre-estimation identity or mathematical gate failed")
  reference_difference <- if (!is.null(graph) && !is.null(reference_run$value)) {
    max(abs(graph - reference_run$value))
  } else NA_real_
  graph_diag <- matrix_diagnostics(graph, network_vars, 0)
  graph_pass <- !is.null(graph) && isTRUE(graph_diag$All_finite) &&
    isTRUE(graph_diag$Correct_node_order) &&
    graph_diag$Maximum_asymmetry <= matrix_tolerance &&
    graph_diag$Maximum_diagonal_deviation <= matrix_tolerance &&
    !nzchar(model_run$error) && !nzchar(reference_run$error) &&
    is.finite(reference_difference) && reference_difference < 1e-8
  status <- if (!pre_pass || !graph_pass) {
    "NOT_ESTIMABLE"
  } else if (length(c(
    cor_run$warnings, model_run$warnings, reference_run$warnings
  )) || any(d11_historical_conditions$year == yr)) {
    "ESTIMABLE_WITH_WARNINGS"
  } else "ESTIMABLE"

  d11_matrices[as.character(yr)] <- list(current_cor)
  d11_networks[as.character(yr)] <- list(model_run$value)
  historical_rows <- d11_historical_conditions[
    d11_historical_conditions$year == yr, , drop = FALSE
  ]
  d11_conditions[[as.character(yr)]] <- data.frame(
    Module_ID = "S09_D11", Wave = yr,
    Correlation_warning_n = length(cor_run$warnings),
    Correlation_warnings = collapse_conditions(cor_run$warnings),
    Correlation_message_n = length(cor_run$messages),
    Correlation_messages = collapse_conditions(cor_run$messages),
    Correlation_error = cor_run$error,
    Network_warning_n = length(model_run$warnings),
    Network_warnings = collapse_conditions(model_run$warnings),
    Network_message_n = length(model_run$messages),
    Network_messages = collapse_conditions(model_run$messages),
    Network_error = model_run$error,
    Direct_reference_warning_n = length(reference_run$warnings),
    Direct_reference_warnings = collapse_conditions(reference_run$warnings),
    Direct_reference_message_n = length(reference_run$messages),
    Direct_reference_messages = collapse_conditions(reference_run$messages),
    Direct_reference_error = reference_run$error,
    Historical_unsuppressed_condition_n = nrow(historical_rows),
    Historical_unsuppressed_conditions = collapse_conditions(historical_rows$message),
    stringsAsFactors = FALSE
  )
  d11_validation[[as.character(yr)]] <- data.frame(
    Module_ID = "S09_D11", Wave = yr,
    Eligible_wave_N = nrow(wave),
    Complete_case_N = sum(complete.cases(ordered_wave)),
    Pairwise_N_minimum = min(pair_values),
    Pairwise_N_average = pair_average,
    Pairwise_N_maximum = max(pair_values),
    Archived_pairwise_N_match = pair_n_match,
    Archived_pairwise_average_match = archived_average_match,
    Archived_matrix_reordered_by_names = TRUE,
    Archived_correlation_maximum_difference =
      archived_correlation_maximum_difference,
    Archived_correlation_match = archived_correlation_match,
    Numerical_identity_tolerance = matrix_tolerance,
    All_nodes_ordered = all(vapply(ordered_wave, is.ordered, logical(1))),
    Minimum_eigenvalue = cor_diag$Minimum_eigenvalue,
    Positive_definite = cor_diag$Positive_definite,
    Direct_reference_maximum_difference = reference_difference,
    Pairwise_average_executed_as_frozen = is.finite(reference_difference) &&
      reference_difference < 1e-8,
    Network_returned = !is.null(graph),
    Status = status,
    stringsAsFactors = FALSE
  )
  if (graph_pass) {
    comp <- compare_networks(
      primary_graphs[[as.character(yr)]], graph,
      "S09_D11", "PAIRWISE_AVAILABLE", yr, status, TRUE
    )
    d11_detailed[[as.character(yr)]] <- comp$detailed
    d11_comparisons[[as.character(yr)]] <- comp$metrics
  } else {
    d11_detailed[[as.character(yr)]] <- not_evaluable_edges(
      primary_graphs[[as.character(yr)]], "S09_D11", "PAIRWISE_AVAILABLE", yr, status
    )
    d11_comparisons[[as.character(yr)]] <- not_evaluable_metrics(
      primary_graphs[[as.character(yr)]],
      "S09_D11", "PAIRWISE_AVAILABLE", yr, status, TRUE
    )
  }
}

d11_validation_df <- do.call(rbind, d11_validation)
d11_conditions_df <- do.call(rbind, d11_conditions)
d11_comparison_df <- if (length(d11_comparisons)) do.call(rbind, d11_comparisons) else data.frame()
d11_detailed_df <- do.call(rbind, d11_detailed)
saveRDS(list(
  Settings = data.frame(Gamma = 0.50, Missing = "pairwise",
                        Sample_size = "pairwise_average", Force_PD = FALSE),
  Matrices = d11_matrices,
  Point_networks = d11_networks,
  Conditions = d11_conditions_df,
  Validation = d11_validation_df,
  Comparisons = d11_comparison_df
), file.path(model_dir, "09_d11_pairwise_networks_gamma050.rds"))
write_csv(d11_validation_df, "09_d11_validation.csv")
write_csv(d11_conditions_df, "09_d11_conditions.csv")
write_csv(d11_comparison_df, "09_d11_primary_comparison.csv")
write_csv(d11_detailed_df, "09_d11_edge_comparison_long.csv")
log_note("D11 complete")

# -----------------------------------------------------------------------------
# Stage 7: D20A gamma 0.25
# -----------------------------------------------------------------------------

gamma_networks <- list()
gamma_conditions <- list()
gamma_validation <- list()
gamma_comparisons <- list()
gamma_detailed <- list()

for (yr in years) {
  key <- as.character(yr)
  input_matrix <- primary_poly$Matrices[[key]]
  primary_reference_run <- capture_run(function() {
    qgraph::EBICglasso(
      S = input_matrix,
      n = unname(expected_n[key]),
      gamma = 0.50,
      nlambda = 100L,
      lambda.min.ratio = 0.01,
      refit = FALSE,
      threshold = FALSE
    )
  })
  primary_reference_graph <- primary_reference_run$value
  if (!is.null(primary_reference_graph)) {
    dimnames(primary_reference_graph) <- list(network_vars, network_vars)
  }
  primary_reference_difference <- if (!is.null(primary_reference_graph)) {
    max(abs(primary_reference_graph - primary_graphs[[key]]))
  } else NA_real_
  primary_reference_pass <-
    !nzchar(primary_reference_run$error) &&
    is.finite(primary_reference_difference) &&
    primary_reference_difference < 1e-8

  run <- if (primary_reference_pass) capture_run(function() {
    qgraph::EBICglasso(
      S = input_matrix,
      n = unname(expected_n[key]),
      gamma = 0.25,
      nlambda = 100L,
      lambda.min.ratio = 0.01,
      refit = FALSE,
      threshold = FALSE
    )
  }) else list(value = NULL, warnings = character(), messages = character(),
               error = "Gamma 0.50 primary reproduction gate failed")
  graph <- run$value
  if (!is.null(graph)) dimnames(graph) <- list(network_vars, network_vars)
  diag <- matrix_diagnostics(graph, network_vars, 0)
  passed <- !is.null(graph) && isTRUE(diag$All_finite) &&
    isTRUE(diag$Correct_node_order) &&
    diag$Maximum_asymmetry <= matrix_tolerance &&
    diag$Maximum_diagonal_deviation <= matrix_tolerance &&
    !nzchar(run$error)
  status <- if (!passed) "NOT_ESTIMABLE" else if (length(run$warnings)) {
    "ESTIMABLE_WITH_WARNINGS"
  } else "ESTIMABLE"
  gamma_networks[key] <- list(graph)
  gamma_conditions[[key]] <- data.frame(
    Module_ID = "S09_D20A_GAMMA", Wave = yr,
    Warning_n = length(run$warnings), Warnings = collapse_conditions(run$warnings),
    Message_n = length(run$messages), Messages = collapse_conditions(run$messages),
    Error = run$error,
    Primary_reference_warning_n = length(primary_reference_run$warnings),
    Primary_reference_warnings = collapse_conditions(primary_reference_run$warnings),
    Primary_reference_error = primary_reference_run$error,
    stringsAsFactors = FALSE
  )
  gamma_validation[[key]] <- data.frame(
    Module_ID = "S09_D20A_GAMMA", Wave = yr,
    Input_matrix_source_is_frozen_bundle = TRUE,
    Primary_gamma050_maximum_reproduction_difference = primary_reference_difference,
    Primary_gamma050_reproduced = primary_reference_pass,
    Sample_N = unname(expected_n[key]),
    Gamma_primary = 0.50, Gamma_sensitivity = 0.25,
    Other_parameters_unchanged = primary_reference_pass,
    Network_returned = !is.null(graph), Status = status,
    stringsAsFactors = FALSE
  )
  if (passed) {
    comp <- compare_networks(primary_graphs[[key]], graph,
                             "S09_D20A_GAMMA", "GAMMA_025", yr, status, TRUE)
    gamma_detailed[[key]] <- comp$detailed
    gamma_comparisons[[key]] <- comp$metrics
  } else {
    gamma_detailed[[key]] <- not_evaluable_edges(
      primary_graphs[[key]], "S09_D20A_GAMMA", "GAMMA_025", yr, status
    )
    gamma_comparisons[[key]] <- not_evaluable_metrics(
      primary_graphs[[key]], "S09_D20A_GAMMA", "GAMMA_025", yr, status, TRUE
    )
  }
}

gamma_validation_df <- do.call(rbind, gamma_validation)
gamma_conditions_df <- do.call(rbind, gamma_conditions)
gamma_comparison_df <- if (length(gamma_comparisons)) do.call(rbind, gamma_comparisons) else data.frame()
gamma_detailed_df <- do.call(rbind, gamma_detailed)
saveRDS(list(
  Settings = data.frame(Gamma = 0.25, Sole_gamma_sensitivity = TRUE),
  Point_networks = gamma_networks,
  Conditions = gamma_conditions_df,
  Validation = gamma_validation_df,
  Comparisons = gamma_comparison_df
), file.path(model_dir, "09_d20a_gamma025_networks.rds"))
write_csv(gamma_validation_df, "09_d20a_gamma025_validation.csv")
write_csv(gamma_conditions_df, "09_d20a_gamma025_conditions.csv")
write_csv(gamma_comparison_df, "09_d20a_gamma025_primary_comparison.csv")
write_csv(gamma_detailed_df, "09_d20a_gamma025_edge_comparison_long.csv")
log_note("D20A gamma 0.25 complete")

# -----------------------------------------------------------------------------
# Stage 8: D20A remove VCF0839 while retaining the nine-node sample
# -----------------------------------------------------------------------------

node_networks <- list()
node_conditions <- list()
node_validation <- list()
node_comparisons <- list()
node_detailed <- list()

for (yr in years) {
  key <- as.character(yr)
  wave_ready <- analysis_ready[analysis_ready$VCF0004 == yr, , drop = FALSE]
  membership_key <- paste(
    as.character(wave_ready$VCF0004),
    as.character(wave_ready$VCF0006),
    as.character(wave_ready$VCF0006a),
    sep = "|"
  )
  membership_sha256 <- toupper(digest::digest(
    paste(membership_key, collapse = "\n"),
    algo = "sha256", serialize = FALSE
  ))
  submatrix <- primary_poly$Matrices[[key]][eight_vars, eight_vars, drop = FALSE]
  submatrix_sha256 <- toupper(digest::digest(submatrix, algo = "sha256"))
  sample_identity_pass <- nrow(wave_ready) == unname(expected_n[key]) &&
    all(stats::complete.cases(wave_ready[, network_vars, drop = FALSE])) &&
    all(stats::complete.cases(wave_ready[, eight_vars, drop = FALSE])) &&
    identical(rownames(submatrix), eight_vars) &&
    identical(colnames(submatrix), eight_vars)
  run <- if (sample_identity_pass) capture_run(function() {
    qgraph::EBICglasso(
      S = submatrix,
      n = unname(expected_n[key]),
      gamma = 0.50,
      nlambda = 100L,
      lambda.min.ratio = 0.01,
      refit = FALSE,
      threshold = FALSE
    )
  }) else list(value = NULL, warnings = character(), messages = character(),
               error = "Frozen nine-node sample or submatrix identity gate failed")
  graph <- run$value
  if (!is.null(graph)) dimnames(graph) <- list(eight_vars, eight_vars)
  diag <- matrix_diagnostics(graph, eight_vars, 0)
  passed <- !is.null(graph) && isTRUE(diag$All_finite) &&
    isTRUE(diag$Correct_node_order) &&
    diag$Maximum_asymmetry <= matrix_tolerance &&
    diag$Maximum_diagonal_deviation <= matrix_tolerance &&
    !nzchar(run$error)
  status <- if (!passed) "NOT_ESTIMABLE" else if (length(run$warnings)) {
    "ESTIMABLE_WITH_WARNINGS"
  } else "ESTIMABLE"
  node_networks[key] <- list(graph)
  node_conditions[[key]] <- data.frame(
    Module_ID = "S09_D20A_NO_VCF0839", Wave = yr,
    Warning_n = length(run$warnings), Warnings = collapse_conditions(run$warnings),
    Message_n = length(run$messages), Messages = collapse_conditions(run$messages),
    Error = run$error, stringsAsFactors = FALSE
  )
  node_validation[[key]] <- data.frame(
    Module_ID = "S09_D20A_NO_VCF0839", Wave = yr,
    Sample_N = nrow(wave_ready),
    Expected_sample_N = unname(expected_n[key]),
    Frozen_membership_SHA256 = membership_sha256,
    Frozen_submatrix_SHA256 = submatrix_sha256,
    Nine_nodes_complete_in_frozen_sample = all(stats::complete.cases(
      wave_ready[, network_vars, drop = FALSE]
    )),
    Eight_nodes_complete_in_same_frozen_sample = all(stats::complete.cases(
      wave_ready[, eight_vars, drop = FALSE]
    )),
    No_respondent_reselection = sample_identity_pass,
    Eight_node_order_correct = identical(rownames(submatrix), eight_vars),
    Submatrix_derived_by_name_from_frozen_matrix = TRUE,
    Gamma = 0.50,
    Network_returned = !is.null(graph), Status = status,
    stringsAsFactors = FALSE
  )
  if (passed) {
    primary_subgraph <- primary_graphs[[key]][eight_vars, eight_vars, drop = FALSE]
    comp <- compare_networks(
      primary_subgraph, graph, "S09_D20A_NO_VCF0839",
      "NO_VCF0839", yr, status, FALSE
    )
    node_detailed[[key]] <- comp$detailed
    node_comparisons[[key]] <- comp$metrics
  } else {
    node_detailed[[key]] <- not_evaluable_edges(
      primary_graphs[[key]][eight_vars, eight_vars, drop = FALSE],
      "S09_D20A_NO_VCF0839", "NO_VCF0839", yr, status
    )
    node_comparisons[[key]] <- not_evaluable_metrics(
      primary_graphs[[key]][eight_vars, eight_vars, drop = FALSE],
      "S09_D20A_NO_VCF0839", "NO_VCF0839", yr, status, FALSE
    )
  }
}

node_validation_df <- do.call(rbind, node_validation)
node_conditions_df <- do.call(rbind, node_conditions)
node_comparison_df <- if (length(node_comparisons)) do.call(rbind, node_comparisons) else data.frame()
node_detailed_df <- do.call(rbind, node_detailed)
saveRDS(list(
  Settings = data.frame(Removed_node = "VCF0839", Gamma = 0.50,
                        Original_nine_node_sample = TRUE),
  Point_networks = node_networks,
  Conditions = node_conditions_df,
  Validation = node_validation_df,
  Comparisons = node_comparison_df
), file.path(model_dir, "09_d20a_no_vcf0839_networks.rds"))
write_csv(node_validation_df, "09_d20a_no_vcf0839_identity_validation.csv")
write_csv(node_conditions_df, "09_d20a_no_vcf0839_conditions.csv")
write_csv(node_comparison_df, "09_d20a_no_vcf0839_primary_comparison.csv")
write_csv(node_detailed_df, "09_d20a_no_vcf0839_edge_comparison_long.csv")
log_note("D20A no-VCF0839 complete")

# -----------------------------------------------------------------------------
# Stage 9: D15 reuse only
# -----------------------------------------------------------------------------

d15 <- readRDS(paths$d15_bundle)
d15_validation_source <- read.csv(paths$d15_validation, check.names = FALSE)
required_d15_fields <- c(
  "Settings", "Input_checks", "Input_matrices", "Point_networks",
  "Conditions", "Diagnostics", "Comparisons", "Stage3A_reproduction",
  "Warning_classification"
)
d15_source_pass <- nrow(d15_validation_source) > 0 &&
  all(d15_validation_source$Passed) &&
  all(required_d15_fields %in% names(d15))
expected_d15_keys <- as.vector(outer(
  years,
  c("U_RAWN", "W_CDF_RAWN", "W_POST_COMPAT_RAWN"),
  paste, sep = "__"
))
d15_graph_gate <- lapply(expected_d15_keys, function(graph_key) {
  graph <- d15$Point_networks[[graph_key]]
  diag <- matrix_diagnostics(graph, network_vars, 0)
  data.frame(
    Graph_key = graph_key,
    Present = !is.null(graph),
    Correct_node_order = isTRUE(diag$Correct_node_order),
    All_finite = isTRUE(diag$All_finite),
    Symmetric = isTRUE(diag$Maximum_asymmetry <= matrix_tolerance),
    Zero_diagonal = isTRUE(diag$Maximum_diagonal_deviation <= matrix_tolerance),
    Passed = !is.null(graph) && isTRUE(diag$Correct_node_order) &&
      isTRUE(diag$All_finite) &&
      isTRUE(diag$Maximum_asymmetry <= matrix_tolerance) &&
      isTRUE(diag$Maximum_diagonal_deviation <= matrix_tolerance),
    stringsAsFactors = FALSE
  )
})
d15_graph_gate <- do.call(rbind, d15_graph_gate)
write_csv(d15_graph_gate, "09_d15_source_graph_gate.csv")
if (!d15_source_pass || !all(d15_graph_gate$Passed)) {
  stop("D15 reuse-only source object or graph validation failed")
}

d15_reuse_validation <- list()
d15_detailed <- list()
d15_metrics <- list()
for (yr in years) {
  key <- as.character(yr)
  unweighted_key <- paste0(yr, "__U_RAWN")
  primary_matches <- isTRUE(all.equal(
    d15$Point_networks[[unweighted_key]], primary_graphs[[key]],
    tolerance = matrix_tolerance, check.attributes = FALSE
  ))
  d15_reuse_validation[[key]] <- data.frame(
    Module_ID = "S09_D15_WEIGHT", Wave = yr,
    Source_validation_all_passed = d15_source_pass,
    Unweighted_reference_matches_primary = primary_matches,
    W_CDF_present = !is.null(d15$Point_networks[[paste0(yr, "__W_CDF_RAWN")]]),
    W_POST_COMPAT_present = !is.null(d15$Point_networks[[paste0(yr, "__W_POST_COMPAT_RAWN")]]),
    Reestimated_in_step09 = FALSE,
    stringsAsFactors = FALSE
  )
  for (candidate in c("W_CDF_RAWN", "W_POST_COMPAT_RAWN")) {
    variant <- if (candidate == "W_CDF_RAWN") "W_CDF" else "W_POST_COMPAT"
    graph <- d15$Point_networks[[paste0(yr, "__", candidate)]]
    status <- if (d15_source_pass && primary_matches && !is.null(graph)) {
      "REUSED_VALIDATED_POINT_NETWORK"
    } else "NOT_EVALUABLE"
    if (status == "REUSED_VALIDATED_POINT_NETWORK") {
      comp <- compare_networks(
        primary_graphs[[key]], graph, "S09_D15_WEIGHT", variant, yr,
        status, TRUE
      )
      d15_detailed[[paste0(yr, "_", variant)]] <- comp$detailed
      d15_metrics[[paste0(yr, "_", variant)]] <- comp$metrics
    } else {
      d15_detailed[[paste0(yr, "_", variant)]] <- not_evaluable_edges(
        primary_graphs[[key]], "S09_D15_WEIGHT", variant, yr, status
      )
    }
  }
}
d15_reuse_validation_df <- do.call(rbind, d15_reuse_validation)
d15_detailed_df <- do.call(rbind, d15_detailed)
d15_metrics_df <- if (length(d15_metrics)) do.call(rbind, d15_metrics) else data.frame()
write_csv(d15_reuse_validation_df, "09_d15_reuse_validation.csv")
write_csv(d15_metrics_df, "09_d15_weighted_network_summary.csv")
write_csv(d15_detailed_df, "09_d15_edge_comparison_long.csv")
log_note("D15 reuse-only summary complete")

# -----------------------------------------------------------------------------
# Stage 10: D19 all-internet diagnostics and point networks
# -----------------------------------------------------------------------------

d19_category <- list()
d19_cells <- list()
d19_types <- list()
d19_conditions <- list()
d19_matrix_diag <- list()
d19_validation <- list()
d19_matrices <- list()
d19_lavaan_matrices <- list()
d19_networks <- list()
d19_detailed <- list()
d19_comparisons <- list()

for (yr in mode_years) {
  log_note("D19 diagnostics start: ", yr)
  wave <- cleaned[cleaned$VCF0004 == yr, , drop = FALSE]
  mode_code <- numeric_value_codes(wave$VCF0017)
  mode_codes_valid <- all(mode_code[!is.na(mode_code)] %in% expected_mode_codes)
  mode_subset <- wave[!is.na(mode_code) & mode_code == 4L, , drop = FALSE]
  mode_complete <- mode_subset[complete.cases(mode_subset[, network_vars, drop = FALSE]), , drop = FALSE]
  ordered_mode <- ordered_node_data(mode_complete, network_vars)

  for (node in network_vars) {
    counts <- table(ordered_mode[[node]], useNA = "no")
    d19_category[[paste(yr, node)]] <- data.frame(
      Wave = yr,
      Node = node,
      Category = expected_categories[[node]],
      N = as.integer(counts[as.character(expected_categories[[node]])]),
      Sample_N = nrow(ordered_mode),
      stringsAsFactors = FALSE
    )
  }

  pair_counter <- 1L
  for (i in seq_len(length(network_vars) - 1L)) {
    for (j in (i + 1L):length(network_vars)) {
      a <- network_vars[i]
      b <- network_vars[j]
      tab <- table(ordered_mode[[a]], ordered_mode[[b]], useNA = "no")
      cell <- as.data.frame(tab, stringsAsFactors = FALSE)
      names(cell) <- c("Level_1", "Level_2", "Cell_N")
      cell$Wave <- yr
      cell$Pair_index <- pair_counter
      cell$Node_1 <- a
      cell$Node_2 <- b
      cell$Pairwise_N <- sum(cell$Cell_N)
      cell$Zero_cell <- cell$Cell_N == 0L
      cell$Cell_1_to_4 <- cell$Cell_N >= 1L & cell$Cell_N <= 4L
      d19_cells[[paste(yr, pair_counter)]] <- cell[, c(
        "Wave", "Pair_index", "Node_1", "Node_2", "Level_1", "Level_2",
        "Cell_N", "Pairwise_N", "Zero_cell", "Cell_1_to_4"
      )]
      d19_types[[paste(yr, pair_counter)]] <- data.frame(
        Wave = yr, Pair_index = pair_counter, Node_1 = a, Node_2 = b,
        Node_1_ordered = is.ordered(ordered_mode[[a]]),
        Node_2_ordered = is.ordered(ordered_mode[[b]]),
        Correlation_type = if (is.ordered(ordered_mode[[a]]) &&
          is.ordered(ordered_mode[[b]])) "polychoric" else "TYPE_ASSERTION_FAILED",
        stringsAsFactors = FALSE
      )
      pair_counter <- pair_counter + 1L
    }
  }

  cor_run <- capture_run(function() {
    qgraph::cor_auto(
      ordered_mode,
      detectOrdinal = TRUE,
      ordinalLevelMax = 7,
      npn.SKEPTIC = FALSE,
      forcePD = FALSE,
      missing = "listwise",
      verbose = TRUE
    )
  })
  cor_matrix <- if (!is.null(cor_run$value)) {
    as.matrix(cor_run$value)[network_vars, network_vars, drop = FALSE]
  } else NULL
  lavaan_run <- capture_run(function() {
    lavaan::lavCor(
      object = ordered_mode,
      ordered = network_vars,
      missing = "listwise",
      estimator = "two.step",
      meanstructure = FALSE,
      cor_smooth = FALSE,
      output = "cor"
    )
  })
  lavaan_matrix <- if (!is.null(lavaan_run$value)) {
    as.matrix(lavaan_run$value)[network_vars, network_vars, drop = FALSE]
  } else NULL
  lavaan_match <- !is.null(cor_matrix) && !is.null(lavaan_matrix) &&
    isTRUE(all.equal(
      cor_matrix, lavaan_matrix,
      tolerance = matrix_tolerance, check.attributes = FALSE
    ))
  cor_diag <- matrix_diagnostics(cor_matrix, network_vars, 1)
  type_rows <- do.call(rbind, d19_types[grepl(paste0("^", yr, " "), names(d19_types))])
  diag_pass <- mode_codes_valid &&
    nrow(mode_complete) == unname(expected_mode_n[as.character(yr)]) &&
    all(vapply(ordered_mode, is.ordered, logical(1))) &&
    all(vapply(ordered_mode, function(x) length(unique(x)) >= 2L, logical(1))) &&
    all(type_rows$Correlation_type == "polychoric") &&
    !is.null(cor_matrix) && isTRUE(cor_diag$All_finite) &&
    isTRUE(cor_diag$Correct_node_order) &&
    cor_diag$Maximum_asymmetry <= matrix_tolerance &&
    cor_diag$Maximum_diagonal_deviation <= matrix_tolerance &&
    isTRUE(cor_diag$Within_correlation_bounds) &&
    isTRUE(cor_diag$Positive_definite) && !nzchar(cor_run$error) &&
    !nzchar(lavaan_run$error) && lavaan_match

  network_run <- if (diag_pass) capture_run(function() {
    qgraph::EBICglasso(
      S = cor_matrix,
      n = nrow(ordered_mode),
      gamma = 0.50,
      nlambda = 100L,
      lambda.min.ratio = 0.01,
      refit = FALSE,
      threshold = FALSE
    )
  }) else list(value = NULL, warnings = character(), messages = character(),
               error = "D19 diagnostic gate failed")
  graph <- network_run$value
  if (!is.null(graph)) dimnames(graph) <- list(network_vars, network_vars)
  graph_diag <- matrix_diagnostics(graph, network_vars, 0)
  graph_pass <- !is.null(graph) && isTRUE(graph_diag$All_finite) &&
    isTRUE(graph_diag$Correct_node_order) &&
    graph_diag$Maximum_asymmetry <= matrix_tolerance &&
    graph_diag$Maximum_diagonal_deviation <= matrix_tolerance &&
    !nzchar(network_run$error)
  status <- if (!diag_pass || !graph_pass) "NOT_ESTIMABLE" else if (
    length(c(cor_run$warnings, network_run$warnings, lavaan_run$warnings))
  ) "ESTIMABLE_WITH_WARNINGS" else "ESTIMABLE"

  wave_cells <- do.call(rbind, d19_cells[grepl(paste0("^", yr, " "), names(d19_cells))])
  d19_matrices[as.character(yr)] <- list(cor_matrix)
  d19_lavaan_matrices[as.character(yr)] <- list(lavaan_matrix)
  d19_networks[as.character(yr)] <- list(graph)
  d19_conditions[[as.character(yr)]] <- data.frame(
    Module_ID = "S09_D19_MODE", Wave = yr,
    Correlation_warning_n = length(cor_run$warnings),
    Correlation_warnings = collapse_conditions(cor_run$warnings),
    Correlation_message_n = length(cor_run$messages),
    Correlation_messages = collapse_conditions(cor_run$messages),
    Correlation_error = cor_run$error,
    Lavaan_warning_n = length(lavaan_run$warnings),
    Lavaan_warnings = collapse_conditions(lavaan_run$warnings),
    Lavaan_message_n = length(lavaan_run$messages),
    Lavaan_messages = collapse_conditions(lavaan_run$messages),
    Lavaan_error = lavaan_run$error,
    Network_warning_n = length(network_run$warnings),
    Network_warnings = collapse_conditions(network_run$warnings),
    Network_message_n = length(network_run$messages),
    Network_messages = collapse_conditions(network_run$messages),
    Network_error = network_run$error,
    stringsAsFactors = FALSE
  )
  d19_matrix_diag[[as.character(yr)]] <- cbind(
    data.frame(Module_ID = "S09_D19_MODE", Wave = yr), cor_diag
  )
  d19_validation[[as.character(yr)]] <- data.frame(
    Module_ID = "S09_D19_MODE", Wave = yr,
    Mode_code = 4L,
    Observed_mode_codes_valid = mode_codes_valid,
    Mode_subset_N = nrow(mode_subset),
    Complete_case_N = nrow(mode_complete),
    Expected_complete_case_N = unname(expected_mode_n[as.character(yr)]),
    Complete_case_N_matches = nrow(mode_complete) == unname(expected_mode_n[as.character(yr)]),
    All_nodes_ordered = all(vapply(ordered_mode, is.ordered, logical(1))),
    Minimum_observed_categories = min(vapply(
      ordered_mode, function(x) length(unique(x)), integer(1)
    )),
    Pair_tables = 36L,
    Zero_cells_total = sum(wave_cells$Zero_cell),
    Cells_1_to_4_total = sum(wave_cells$Cell_1_to_4),
    All_associations_polychoric = all(type_rows$Correlation_type == "polychoric"),
    Cor_auto_matches_unsuppressed_lavaan = lavaan_match,
    Maximum_absolute_correlation = cor_diag$Maximum_absolute_off_diagonal,
    Within_correlation_bounds = cor_diag$Within_correlation_bounds,
    Minimum_eigenvalue = cor_diag$Minimum_eigenvalue,
    Positive_definite = cor_diag$Positive_definite,
    Network_returned = !is.null(graph),
    Status = status,
    stringsAsFactors = FALSE
  )
  if (graph_pass) {
    comp <- compare_networks(
      primary_graphs[[as.character(yr)]], graph,
      "S09_D19_MODE", "ALL_INTERNET", yr, status, TRUE
    )
    d19_detailed[[as.character(yr)]] <- comp$detailed
    d19_comparisons[[as.character(yr)]] <- comp$metrics
  } else {
    d19_detailed[[as.character(yr)]] <- not_evaluable_edges(
      primary_graphs[[as.character(yr)]], "S09_D19_MODE", "ALL_INTERNET", yr, status
    )
    d19_comparisons[[as.character(yr)]] <- not_evaluable_metrics(
      primary_graphs[[as.character(yr)]],
      "S09_D19_MODE", "ALL_INTERNET", yr, status, TRUE
    )
  }
}

d19_category_df <- do.call(rbind, d19_category)
d19_cells_df <- do.call(rbind, d19_cells)
d19_types_df <- do.call(rbind, d19_types)
d19_conditions_df <- do.call(rbind, d19_conditions)
d19_matrix_diag_df <- do.call(rbind, d19_matrix_diag)
d19_validation_df <- do.call(rbind, d19_validation)
d19_detailed_df <- do.call(rbind, d19_detailed)
d19_comparison_df <- if (length(d19_comparisons)) do.call(rbind, d19_comparisons) else data.frame()
saveRDS(list(
  Settings = data.frame(Mode_variable = "VCF0017", Mode_code = 4L,
                        Gamma = 0.50, Point_network_only = TRUE),
  Matrices = d19_matrices,
  Lavaan_matrices = d19_lavaan_matrices,
  Point_networks = d19_networks,
  Conditions = d19_conditions_df,
  Matrix_diagnostics = d19_matrix_diag_df,
  Validation = d19_validation_df,
  Comparisons = d19_comparison_df
), file.path(model_dir, "09_d19_all_internet_networks.rds"))
write_csv(d19_category_df, "09_d19_category_frequencies.csv")
write_csv(d19_cells_df, "09_d19_pairwise_cell_diagnostics.csv")
write_csv(d19_types_df, "09_d19_correlation_types.csv")
write_csv(d19_conditions_df, "09_d19_polychoric_conditions.csv")
write_csv(d19_matrix_diag_df, "09_d19_matrix_diagnostics.csv")
write_csv(d19_validation_df, "09_d19_validation.csv")
write_csv(d19_comparison_df, "09_d19_primary_comparison.csv")
write_csv(d19_detailed_df, "09_d19_edge_comparison_long.csv")
log_note("D19 diagnostics and point networks complete")

# -----------------------------------------------------------------------------
# Stage 11: consolidated robustness audit and completion records
# -----------------------------------------------------------------------------

comparison_long <- do.call(rbind, list(
  d11_detailed_df,
  gamma_detailed_df,
  node_detailed_df,
  d15_detailed_df,
  d19_detailed_df
))
comparison_metrics <- do.call(rbind, Filter(function(x) nrow(x) > 0, list(
  d11_comparison_df,
  gamma_comparison_df,
  node_comparison_df,
  d15_metrics_df,
  d19_comparison_df
)))
write_csv(comparison_long, "09_sensitivity_comparison_long.csv")
write_csv(comparison_metrics, "09_sensitivity_summary_by_wave.csv")

module_variants <- data.frame(
  Module_ID = c(
    "S09_D11", "S09_D20A_GAMMA", "S09_D20A_NO_VCF0839",
    "S09_D15_WEIGHT", "S09_D15_WEIGHT", "S09_D19_MODE"
  ),
  Variant = c(
    "PAIRWISE_AVAILABLE", "GAMMA_025", "NO_VCF0839",
    "W_CDF", "W_POST_COMPAT", "ALL_INTERNET"
  ),
  Applicability_column = c(
    "D11_applicable", "D20A_gamma025_applicable",
    "D20A_no_VCF0839_applicable", "D15_W_CDF_applicable",
    "D15_W_POST_COMPAT_applicable", "D19_all_internet_applicable"
  ),
  stringsAsFactors = FALSE
)

claim_module_rows <- list()
counter <- 1L
for (i in seq_len(nrow(claims))) {
  claim <- claims[i, , drop = FALSE]
  for (j in seq_len(nrow(module_variants))) {
    spec <- module_variants[j, , drop = FALSE]
    applicable <- isTRUE(as.logical(claim[[spec$Applicability_column]]))
    match_row <- comparison_long[
      comparison_long$Module_ID == spec$Module_ID &
        comparison_long$Variant == spec$Variant &
        comparison_long$Wave == claim$Wave &
        comparison_long$Node_1 == claim$Node_1 &
        comparison_long$Node_2 == claim$Node_2,
      , drop = FALSE
    ]
    if (!applicable) {
      status <- "NOT_APPLICABLE"
      sensitivity_edge <- NA_real_
      abs_diff <- NA_real_
      evidence_status <- "OUTSIDE_MODULE_SCOPE"
    } else if (nrow(match_row) != 1L) {
      status <- "NOT_EVALUABLE"
      sensitivity_edge <- NA_real_
      abs_diff <- NA_real_
      evidence_status <- "NO_UNIQUE_COMPARISON_ROW"
    } else {
      status <- match_row$Robustness_status
      sensitivity_edge <- match_row$Edge_weight_sensitivity
      abs_diff <- match_row$Absolute_difference
      evidence_status <- match_row$Estimation_status
    }
    claim_module_rows[[counter]] <- data.frame(
      Claim_ID = claim$Claim_ID,
      Wave = claim$Wave,
      Node_1 = claim$Node_1,
      Node_2 = claim$Node_2,
      Primary_edge_weight = claim$Primary_edge_weight,
      Primary_retained = claim$Primary_retained,
      Module_ID = spec$Module_ID,
      Variant = spec$Variant,
      Applicable = applicable,
      Sensitivity_edge_weight = sensitivity_edge,
      Absolute_difference = abs_diff,
      Robustness_status = status,
      Evidence_status = evidence_status,
      stringsAsFactors = FALSE
    )
    counter <- counter + 1L
  }
}
claim_audit <- do.call(rbind, claim_module_rows)
write_csv(claim_audit, "09_claim_robustness_audit.csv")

claim_summary_list <- lapply(split(claim_audit, claim_audit$Claim_ID), function(x) {
  observed <- x$Robustness_status[x$Robustness_status %in%
    c("UNCHANGED", "CHANGED", "REVERSED")]
  observed_status <- if (any(observed == "REVERSED")) {
    "REVERSED"
  } else if (any(observed == "CHANGED")) {
    "CHANGED"
  } else if (length(observed)) "UNCHANGED" else "NO_EVALUABLE_MODULE"
  evaluation_completeness <- if (any(x$Robustness_status == "NOT_EVALUABLE")) {
    "PARTIALLY_NOT_EVALUABLE"
  } else "COMPLETE"
  final <- if (observed_status == "NO_EVALUABLE_MODULE") {
    "NOT_EVALUABLE"
  } else observed_status
  data.frame(
    Claim_ID = x$Claim_ID[1],
    Wave = x$Wave[1],
    Node_1 = x$Node_1[1],
    Node_2 = x$Node_2[1],
    Primary_edge_weight = x$Primary_edge_weight[1],
    Primary_retained = x$Primary_retained[1],
    Applicable_module_variants = sum(x$Robustness_status != "NOT_APPLICABLE"),
    Evaluable_module_variants = sum(x$Robustness_status %in%
      c("UNCHANGED", "CHANGED", "REVERSED")),
    Any_not_evaluable = any(x$Robustness_status == "NOT_EVALUABLE"),
    Observed_change_status = observed_status,
    Evaluation_completeness = evaluation_completeness,
    Final_robustness_status = final,
    Maximum_observed_absolute_difference = if (all(is.na(x$Absolute_difference))) {
      NA_real_
    } else max(x$Absolute_difference, na.rm = TRUE),
    stringsAsFactors = FALSE
  )
})
claim_summary <- do.call(rbind, claim_summary_list)
write_csv(claim_summary, "09_primary_claim_robustness_summary.csv")

completion_status <- data.frame(
  Module = c("D11", "D20A_GAMMA025", "D20A_NO_VCF0839", "D15_REUSE", "D19_MODE", "CLAIM_AUDIT"),
  Expected_units = c(5L, 5L, 5L, 10L, 4L, 180L),
  Completed_units = c(
    nrow(d11_validation_df),
    nrow(gamma_validation_df),
    nrow(node_validation_df),
    nrow(d15_metrics_df),
    nrow(d19_validation_df),
    nrow(claim_summary)
  ),
  Not_estimable_units = c(
    sum(d11_validation_df$Status == "NOT_ESTIMABLE"),
    sum(gamma_validation_df$Status == "NOT_ESTIMABLE"),
    sum(node_validation_df$Status == "NOT_ESTIMABLE"),
    0L,
    sum(d19_validation_df$Status == "NOT_ESTIMABLE"),
    sum(claim_summary$Evaluation_completeness != "COMPLETE")
  ),
  Prohibited_analysis_run = FALSE,
  stringsAsFactors = FALSE
)
completion_status$Complete <- completion_status$Completed_units == completion_status$Expected_units
write_csv(completion_status, "09_completion_status.csv")

writeLines(capture.output(sessionInfo()), file.path(log_dir, "09_sessionInfo.txt"))
log_note("Step 09 consolidated audit complete")
flush_log()

output_files <- c(
  list.files(model_dir, pattern = "^09_", full.names = TRUE),
  list.files(table_dir, pattern = "^09_", full.names = TRUE),
  log_file,
  file.path(log_dir, "09_sessionInfo.txt")
)
output_files <- output_files[file.exists(output_files)]
inventory_path <- file.path(table_dir, "09_output_hash_inventory.csv")
output_files <- setdiff(output_files, inventory_path)
output_inventory <- data.frame(
  File = basename(output_files),
  Path = normalizePath(output_files, winslash = "/"),
  Bytes = file.info(output_files)$size,
  SHA256 = vapply(output_files, file_sha256, character(1)),
  stringsAsFactors = FALSE
)
output_inventory <- output_inventory[order(output_inventory$File), ]
write_csv(output_inventory, "09_output_hash_inventory.csv")

if (!all(completion_status$Complete)) {
  stop("Step 09 completion-count validation failed; inspect saved outputs")
}

cat("STEP09_ENGINE_COMPLETE\n")
