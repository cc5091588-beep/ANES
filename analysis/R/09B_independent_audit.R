options(stringsAsFactors = FALSE)

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
project_library <- file.path(
  project_root,
  "renv", "library", "windows", "R-4.5", "x86_64-w64-mingw32"
)
if (dir.exists(project_library)) {
  .libPaths(c(project_library, .libPaths()))
}
suppressPackageStartupMessages({
  library(qgraph)
  library(digest)
})

table_dir <- file.path(project_root, "outputs", "tables", "sensitivity")
model_dir <- file.path(project_root, "outputs", "models", "sensitivity")
log_dir <- file.path(project_root, "outputs", "logs")
engine_file <- file.path(
  project_root, "R", "09B_specificity_sample_size_sensitivity_engine.R"
)

read_table <- function(name) {
  read.csv(file.path(table_dir, name), check.names = FALSE)
}
file_sha256 <- function(path) {
  toupper(digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE))
}
quantile_or_na <- function(x, probability) {
  x <- x[is.finite(x)]
  if (!length(x)) NA_real_ else unname(quantile(x, probability, names = FALSE))
}
maximum_numeric_difference <- function(x, y) {
  valid <- is.finite(x) & is.finite(y)
  if (!any(valid)) 0 else max(abs(x[valid] - y[valid]))
}

completion <- read_table("09B_completion_status.csv")
decision <- read_table("09B_decision_gate.csv")
input_gate <- read_table("09B_primary_input_validation.csv")
identity <- read_table("09B_primary_identity_validation.csv")
pilot <- read_table("09B_pilot_validation.csv")
formal <- read_table("09B_equalN_run_diagnostics.csv")
formal_validation <- read_table("09B_equalN_validation.csv")
seed_manifest <- read_table("09B_seed_manifest.csv")
edge_summary <- read_table("09B_equalN_edge_summary.csv")
network_summary <- read_table("09B_equalN_network_summary.csv")
contrast_summary <- read_table("09B_contrast_robustness.csv")
claims <- read_table("09B_claim_robustness.csv")
claim_summary <- read_table("09B_claim_robustness_summary.csv")
input_hashes <- read_table("09B_input_hash_validation.csv")
output_hashes <- read_table("09B_output_hash_inventory.csv")
a1_diagnostics <- read_table("09B_fullN_threshold_diagnostics.csv")
diagnostic_label_validation <- read_table(
  "09B_diagnostic_label_correction_validation.csv"
)

results <- readRDS(file.path(model_dir, "09B_equalN_results.rds"))
samples <- readRDS(file.path(model_dir, "09B_equalN_samples.rds"))
a1_models <- readRDS(file.path(model_dir, "09B_fullN_threshold_models.rds"))

years <- as.integer(results$years)
arms <- c("A2", "A3")
edge_ids <- results$edge_template$Edge_ID

diagnostic_pairs <- merge(
  formal[formal$Arm_ID == "A2", c(
    "Wave", "Repetition", "Seed", "Sample_hash", "N",
    "Minimum_observed_categories", "Zero_cell_pairs", "Sparse_cell_pairs"
  )],
  formal[formal$Arm_ID == "A3", c(
    "Wave", "Repetition", "Seed", "Sample_hash", "N",
    "Minimum_observed_categories", "Zero_cell_pairs", "Sparse_cell_pairs"
  )],
  by = c("Wave", "Repetition"),
  suffixes = c("_A2", "_A3"),
  sort = FALSE
)

same_seed <- with(
  diagnostic_pairs,
  (is.na(Seed_A2) & is.na(Seed_A3)) | Seed_A2 == Seed_A3
)
same_sample_inputs <- with(
  diagnostic_pairs,
  same_seed &
    Sample_hash_A2 == Sample_hash_A3 &
    N_A2 == N_A3 &
    Minimum_observed_categories_A2 == Minimum_observed_categories_A3 &
    Zero_cell_pairs_A2 == Zero_cell_pairs_A3 &
    Sparse_cell_pairs_A2 == Sparse_cell_pairs_A3
)

recomputed_edge_rows <- list()
row_index <- 0L
for (arm in arms) {
  for (wave in years) {
    wave_key <- as.character(wave)
    primary <- results$edge_template
    primary_graph <- if (wave == 2004L) {
      if (arm == "A2") {
        results$edge_weights[[arm]][1, , wave_key]
      } else {
        results$edge_weights[[arm]][1, , wave_key]
      }
    } else {
      NA_real_
    }
    for (edge_number in seq_along(edge_ids)) {
      values <- results$edge_weights[[arm]][, edge_number, wave_key]
      values <- values[is.finite(values)]
      source_row <- edge_summary[
        edge_summary$Arm_ID == arm &
          edge_summary$Wave == wave &
          edge_summary$Edge_ID == edge_ids[edge_number],
        , drop = FALSE
      ]
      primary_weight <- source_row$Primary_edge_weight
      state_match <- if (primary_weight == 0) {
        values == 0
      } else if (primary_weight > 0) {
        values > 0
      } else {
        values < 0
      }
      row_index <- row_index + 1L
      recomputed_edge_rows[[row_index]] <- data.frame(
        Arm_ID = arm,
        Wave = wave,
        Edge_ID = edge_ids[edge_number],
        Successful_repetitions = length(values),
        Retention_frequency = mean(values != 0),
        Primary_state_match_proportion = mean(state_match),
        Median_edge_weight = median(values),
        Lower_edge_weight = quantile_or_na(values, 0.025),
        Upper_edge_weight = quantile_or_na(values, 0.975),
        stringsAsFactors = FALSE
      )
    }
  }
}
recomputed_edges <- do.call(rbind, recomputed_edge_rows)
edge_comparison <- merge(
  edge_summary,
  recomputed_edges,
  by = c("Arm_ID", "Wave", "Edge_ID"),
  suffixes = c("_saved", "_recomputed"),
  sort = FALSE
)
edge_recalculation_difference <- max(c(
  maximum_numeric_difference(
    edge_comparison$Successful_repetitions_saved,
    edge_comparison$Successful_repetitions_recomputed
  ),
  maximum_numeric_difference(
    edge_comparison$Retention_frequency_saved,
    edge_comparison$Retention_frequency_recomputed
  ),
  maximum_numeric_difference(
    edge_comparison$Primary_state_match_proportion_saved,
    edge_comparison$Primary_state_match_proportion_recomputed
  ),
  maximum_numeric_difference(
    edge_comparison$Median_edge_weight_saved,
    edge_comparison$Median_edge_weight_recomputed
  ),
  maximum_numeric_difference(
    edge_comparison$Lower_edge_weight_saved,
    edge_comparison$Lower_edge_weight_recomputed
  ),
  maximum_numeric_difference(
    edge_comparison$Upper_edge_weight_saved,
    edge_comparison$Upper_edge_weight_recomputed
  )
))

edge_comparison$Difference_successful_repetitions <-
  edge_comparison$Successful_repetitions_saved -
  edge_comparison$Successful_repetitions_recomputed
edge_comparison$Difference_retention_frequency <-
  edge_comparison$Retention_frequency_saved -
  edge_comparison$Retention_frequency_recomputed
edge_comparison$Difference_primary_state_match <-
  edge_comparison$Primary_state_match_proportion_saved -
  edge_comparison$Primary_state_match_proportion_recomputed
edge_comparison$Difference_median_edge <-
  edge_comparison$Median_edge_weight_saved -
  edge_comparison$Median_edge_weight_recomputed
edge_comparison$Difference_lower_edge <-
  edge_comparison$Lower_edge_weight_saved -
  edge_comparison$Lower_edge_weight_recomputed
edge_comparison$Difference_upper_edge <-
  edge_comparison$Upper_edge_weight_saved -
  edge_comparison$Upper_edge_weight_recomputed
edge_comparison$Maximum_row_difference <- apply(
  abs(edge_comparison[, c(
    "Difference_successful_repetitions",
    "Difference_retention_frequency",
    "Difference_primary_state_match",
    "Difference_median_edge",
    "Difference_lower_edge",
    "Difference_upper_edge"
  )]),
  1,
  max,
  na.rm = TRUE
)

recomputed_network_rows <- list()
row_index <- 0L
for (arm in arms) {
  for (wave in years) {
    wave_key <- as.character(wave)
    retained <- results$retained_edges[[arm]][, wave_key]
    strength <- results$global_strength[[arm]][, wave_key]
    row_index <- row_index + 1L
    recomputed_network_rows[[row_index]] <- data.frame(
      Arm_ID = arm,
      Wave = wave,
      Median_retained_edges = median(retained),
      Lower_retained_edges = quantile_or_na(retained, 0.025),
      Upper_retained_edges = quantile_or_na(retained, 0.975),
      Median_density = median(retained / length(edge_ids)),
      Lower_density = quantile_or_na(retained / length(edge_ids), 0.025),
      Upper_density = quantile_or_na(retained / length(edge_ids), 0.975),
      Median_global_strength = median(strength),
      Lower_global_strength = quantile_or_na(strength, 0.025),
      Upper_global_strength = quantile_or_na(strength, 0.975),
      stringsAsFactors = FALSE
    )
  }
}
recomputed_networks <- do.call(rbind, recomputed_network_rows)
network_comparison <- merge(
  network_summary,
  recomputed_networks,
  by = c("Arm_ID", "Wave"),
  suffixes = c("_saved", "_recomputed"),
  sort = FALSE
)
network_columns <- c(
  "Median_retained_edges", "Lower_retained_edges", "Upper_retained_edges",
  "Median_density", "Lower_density", "Upper_density",
  "Median_global_strength", "Lower_global_strength", "Upper_global_strength"
)
network_recalculation_difference <- max(vapply(
  network_columns,
  function(column) maximum_numeric_difference(
    network_comparison[[paste0(column, "_saved")]],
    network_comparison[[paste0(column, "_recomputed")]]
  ),
  numeric(1)
))

hash_paths <- file.path(project_root, output_hashes$Relative_path)
output_hash_check <- file.exists(hash_paths) &
  vapply(hash_paths, file_sha256, character(1)) == output_hashes$SHA256

source_text <- paste(readLines(engine_file, warn = FALSE), collapse = "\n")
prohibited_patterns <- c(
  "bootnet::bootnet\\s*\\(",
  "NetworkComparisonTest::NCT\\s*\\(",
  "centralityPlot\\s*\\(",
  "corStability\\s*\\(",
  "Matrix::nearPD\\s*\\(",
  "estimateNetwork\\s*\\("
)
prohibited_detected <- vapply(
  prohibited_patterns,
  function(pattern) grepl(pattern, source_text, perl = TRUE),
  logical(1)
)

claim_counts_recomputed <- as.data.frame(with(
  claims,
  table(Claim_type, Final_status, useNA = "ifany")
))
names(claim_counts_recomputed) <- c("Claim_type", "Final_status", "Count")
claim_counts_recomputed <- claim_counts_recomputed[
  claim_counts_recomputed$Count > 0L,
  , drop = FALSE
]
claim_count_keys <- paste(
  claim_counts_recomputed$Claim_type,
  claim_counts_recomputed$Final_status
)
saved_count_keys <- paste(claim_summary$Claim_type, claim_summary$Final_status)
claim_counts_match <- setequal(claim_count_keys, saved_count_keys) && all(
  claim_counts_recomputed$Count[
    match(saved_count_keys, claim_count_keys)
  ] == claim_summary$Count
)

no_creation_time_columns <- !any(grepl(
  "(^|_)(created|creation|timestamp|run_date|run_time|completed_at)(_|$)",
  unlist(lapply(
    list(formal, edge_summary, network_summary, contrast_summary, claims),
    names
  )),
  ignore.case = TRUE
))

formal_condition_text <- paste(
  ifelse(is.na(formal$Network_warning), "", formal$Network_warning),
  ifelse(is.na(formal$Network_message), "", formal$Network_message)
)
a1_condition_text <- paste(
  ifelse(is.na(a1_diagnostics$Warning), "", a1_diagnostics$Warning),
  ifelse(is.na(a1_diagnostics$Message), "", a1_diagnostics$Message)
)
diagnostic_labels_match_sources <- all(
  formal$Dense_warning == grepl(
    "dense regularized network", formal_condition_text, ignore.case = TRUE
  )
) && all(
  formal$Lowest_lambda_selected == grepl(
    "lowest lambda selected", formal_condition_text, ignore.case = TRUE
  )
) && all(
  a1_diagnostics$Dense_warning == grepl(
    "dense regularized network", a1_condition_text, ignore.case = TRUE
  )
) && all(
  a1_diagnostics$Lowest_lambda_selected == grepl(
    "lowest lambda selected", a1_condition_text, ignore.case = TRUE
  )
)

validation <- data.frame(
  Check = c(
    "All engine completion checks are true",
    "All decision and input gates are true",
    "All five primary model identities match",
    "All eight pilot wave-arm cells completed 50 of 50",
    "Formal diagnostics contain 10000 rows",
    "Every formal run succeeded",
    "A2 and A3 have identical inputs for all 5000 wave-repetition pairs",
    "Seed manifest contains 5000 unique wave-repetition rows",
    "Saved equal-N result arrays have dimensions 1000 by 36 by 5",
    "Independent edge summaries match saved summaries",
    "Independent network summaries match saved summaries",
    "Saved claim counts match independent counts",
    "All 24 inventoried output hashes match",
    "All nine input hashes remained unchanged",
    "No prohibited function call is present in the engine",
    "No visible creation-date or creation-time column is present",
    "A1 contains five successful full-N threshold models",
    "Claim audit contains 205 unique preregistered claims",
    "Dense and lowest-lambda diagnostic labels match captured sources",
    "All diagnostic-label correction checks passed"
  ),
  Passed = c(
    all(completion$Complete),
    all(decision$Passed) && all(input_gate$Passed),
    nrow(identity) == 5L && all(identity$Passed),
    nrow(pilot) == 8L && all(pilot$Successful == 50L) && all(pilot$Pilot_passed),
    nrow(formal) == 10000L,
    all(formal$Success),
    nrow(diagnostic_pairs) == 5000L && all(same_sample_inputs),
    nrow(seed_manifest) == 5000L &&
      !anyDuplicated(paste(seed_manifest$Wave, seed_manifest$Repetition)),
    all(vapply(results$edge_weights, function(x) identical(dim(x), c(1000L, 36L, 5L)), logical(1))),
    edge_recalculation_difference <= 1e-12,
    network_recalculation_difference <= 1e-12,
    claim_counts_match,
    length(output_hash_check) == 24L && all(output_hash_check),
    nrow(input_hashes) == 9L && all(input_hashes$Hash_matches),
    !any(prohibited_detected),
    no_creation_time_columns,
    nrow(a1_diagnostics) == 5L && all(a1_diagnostics$Success),
    nrow(claims) == 205L && !anyDuplicated(claims$Claim_ID),
    diagnostic_labels_match_sources,
    all(diagnostic_label_validation$Passed)
  ),
  Evidence = c(
    "09B_completion_status.csv",
    "09B_decision_gate.csv; 09B_primary_input_validation.csv",
    "09B_primary_identity_validation.csv",
    "09B_pilot_validation.csv",
    "09B_equalN_run_diagnostics.csv",
    "09B_equalN_run_diagnostics.csv",
    "A2/A3 diagnostic key merge",
    "09B_seed_manifest.csv",
    "09B_equalN_results.rds",
    "Independent recomputation from RDS arrays",
    "Independent recomputation from RDS arrays",
    "Independent table of 09B_claim_robustness.csv",
    "09B_output_hash_inventory.csv",
    "09B_input_hash_validation.csv",
    "Static engine scan",
    "CSV header audit",
    "09B_fullN_threshold_diagnostics.csv",
    "09B_claim_robustness.csv",
    "Captured warning and message fields",
    "09B_diagnostic_label_correction_validation.csv"
  ),
  stringsAsFactors = FALSE
)

comparison <- data.frame(
  Quantity = c(
    "Maximum edge-summary absolute difference",
    "Maximum network-summary absolute difference",
    "A2/A3 identical sample-input pairs",
    "Formal successful runs",
    "Robust edge claims",
    "Not-robust edge claims",
    "Robust contrast claims",
    "Mixed contrast claims",
    "Not-robust contrast claims"
  ),
  Value = c(
    edge_recalculation_difference,
    network_recalculation_difference,
    sum(same_sample_inputs),
    sum(formal$Success),
    sum(claims$Claim_type == "EDGE_SIGN_AND_RETENTION" & claims$Final_status == "ROBUST"),
    sum(claims$Claim_type == "EDGE_SIGN_AND_RETENTION" & claims$Final_status == "NOT_ROBUST"),
    sum(claims$Claim_type == "WAVE_CONTRAST_DIRECTION" & claims$Final_status == "ROBUST"),
    sum(claims$Claim_type == "WAVE_CONTRAST_DIRECTION" & claims$Final_status == "MIXED"),
    sum(claims$Claim_type == "WAVE_CONTRAST_DIRECTION" & claims$Final_status == "NOT_ROBUST")
  ),
  stringsAsFactors = FALSE
)

write.csv(
  validation,
  file.path(table_dir, "09B_independent_audit_validation.csv"),
  row.names = FALSE,
  na = ""
)
write.csv(
  comparison,
  file.path(table_dir, "09B_independent_recalculation_comparison.csv"),
  row.names = FALSE,
  na = ""
)
write.csv(
  edge_comparison[order(-edge_comparison$Maximum_row_difference), ],
  file.path(table_dir, "09B_independent_edge_recalculation_detail.csv"),
  row.names = FALSE,
  na = ""
)
writeLines(
  c(
    "STEP_09B_INDEPENDENT_AUDIT",
    paste0("Checks_passed=", sum(validation$Passed), "/", nrow(validation)),
    paste0("Edge_summary_max_difference=", signif(edge_recalculation_difference, 12)),
    paste0("Network_summary_max_difference=", signif(network_recalculation_difference, 12)),
    paste0("A2_A3_identical_sample_pairs=", sum(same_sample_inputs)),
    paste0("Formal_successful_runs=", sum(formal$Success)),
    "No model was re-estimated during this independent audit."
  ),
  file.path(log_dir, "09B_independent_audit.log"),
  useBytes = TRUE
)

if (!all(validation$Passed)) {
  stop("Independent Step 09B audit found one or more failed checks.")
}

cat("STEP09B_INDEPENDENT_AUDIT_PASSED\n")
