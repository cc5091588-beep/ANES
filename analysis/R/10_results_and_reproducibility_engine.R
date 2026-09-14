options(stringsAsFactors = FALSE, warn = 1)

# STEP 10 BOUNDARY
# This script assembles and audits existing outputs from Steps 00--09B.
# It does not read raw ANES data, estimate a network, resample cases, or run a
# significance test. No visible creation date or time is written to outputs.

expected_waves <- c(2004L, 2012L, 2016L, 2020L, 2024L)
expected_education_waves <- c(2012L, 2016L, 2020L, 2024L)

locate_project_root <- function(start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = TRUE)
  candidates <- unique(c(current, dirname(current)))
  hit <- candidates[
    file.exists(file.path(candidates, "ANES.Rproj"))
  ]
  if (length(hit) != 1L) {
    stop("STEP 10 STOP: the ANES_dissertation project root was not identified uniquely.")
  }
  hit[[1L]]
}

project_root <- locate_project_root()
formal_table_dir <- file.path(project_root, "outputs", "tables", "formal")
sensitivity_table_dir <- file.path(project_root, "outputs", "tables", "sensitivity")
final_table_dir <- file.path(project_root, "outputs", "tables", "final")
formal_figure_dir <- file.path(project_root, "outputs", "figures", "formal")
final_figure_dir <- file.path(project_root, "outputs", "figures", "final")
final_audit_dir <- file.path(project_root, "outputs", "audits", "final")
log_dir <- file.path(project_root, "outputs", "logs")
working_dir <- file.path(project_root, "project_docs", "working")
decision_dir <- file.path(project_root, "project_docs", "decisions")
runtime_dir <- file.path(project_root, "runtime")

for (path in c(
  final_table_dir, final_figure_dir, final_audit_dir, log_dir,
  working_dir, decision_dir, runtime_dir
)) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
}

if (!requireNamespace("digest", quietly = TRUE)) {
  stop("STEP 10 STOP: package 'digest' is required for SHA-256 validation.")
}

sha256 <- function(path) {
  if (!file.exists(path)) return(NA_character_)
  unname(digest::digest(file = path, algo = "sha256", serialize = FALSE))
}

read_csv_required <- function(path) {
  if (!file.exists(path) || file.info(path)$size <= 0) {
    stop("STEP 10 STOP: required input is missing or empty: ", path)
  }
  read.csv(path, check.names = FALSE, na.strings = c("NA"))
}

write_csv <- function(x, path) {
  write.csv(x, path, row.names = FALSE, na = "")
  stopifnot(file.exists(path), file.info(path)$size > 0)
  invisible(path)
}

as_flag <- function(x) {
  if (is.logical(x)) return(x)
  toupper(trimws(as.character(x))) == "TRUE"
}

collapse_values <- function(x) {
  paste(unique(as.character(x)), collapse = "; ")
}

input_paths <- c(
  sample_flow = file.path(
    project_root, "data", "audit",
    "anes_cdf_20260205_sample_flow_nine_node_complete_case_2004_2012_2016_2020_2024.csv"
  ),
  polychoric_diagnostics = file.path(
    project_root, "data", "audit",
    "anes_cdf_20260205_nine_node_complete_case_polychoric_diagnostics_2004_2012_2016_2020_2024.csv"
  ),
  step07_completion = file.path(formal_table_dir, "07_formal_step07_completion_status.csv"),
  step07a_validation = file.path(formal_table_dir, "07A_edge_accuracy_validation.csv"),
  step07a_wave = file.path(formal_table_dir, "07A_edge_accuracy_by_wave.csv"),
  step07b_completion = file.path(formal_table_dir, "07B_completion_status.csv"),
  step07b_cs = file.path(formal_table_dir, "07B_CS_coefficients.csv"),
  step08_completion = file.path(formal_table_dir, "08_stage1_12_completion_status.csv"),
  overall_wave_summary = file.path(formal_table_dir, "08_overall_wave_summary.csv"),
  overall_expected_influence = file.path(formal_table_dir, "08_overall_expected_influence.csv"),
  overall_centrality_stability = file.path(formal_table_dir, "08_overall_centrality_stability.csv"),
  education_sample_flow = file.path(formal_table_dir, "08_education_sample_flow.csv"),
  step08b_completion = file.path(formal_table_dir, "08B_education_completion_status.csv"),
  education_point_diagnostics = file.path(formal_table_dir, "08B_education_point_network_diagnostics.csv"),
  education_readiness = file.path(formal_table_dir, "08C_education_result_readiness.csv"),
  education_figure_manifest = file.path(formal_table_dir, "08C_education_figure_manifest.csv"),
  step08c_validation = file.path(formal_table_dir, "08C_final_validation.csv"),
  step09_completion = file.path(sensitivity_table_dir, "09_completion_status.csv"),
  sensitivity_by_wave = file.path(sensitivity_table_dir, "09_sensitivity_summary_by_wave.csv"),
  step09_claims = file.path(sensitivity_table_dir, "09_primary_claim_robustness_summary.csv"),
  step09b_completion = file.path(sensitivity_table_dir, "09B_completion_status.csv"),
  step09b_claims = file.path(sensitivity_table_dir, "09B_claim_robustness.csv"),
  step09b_claim_summary = file.path(sensitivity_table_dir, "09B_claim_robustness_summary.csv"),
  step09b_independent_audit = file.path(sensitivity_table_dir, "09B_independent_audit_validation.csv"),
  renv_lock = file.path(project_root, "renv.lock"),
  decision_log_copy = file.path(decision_dir, "research_decisions_log.md")
)

input_inventory <- data.frame(
  Input_ID = names(input_paths),
  Path = unname(input_paths),
  Exists = file.exists(input_paths),
  Bytes = ifelse(file.exists(input_paths), file.info(input_paths)$size, NA_real_),
  SHA256 = vapply(input_paths, sha256, character(1L)),
  Purpose = c(
    "Primary complete-case sample flow",
    "Primary polychoric input diagnostics",
    "Step 07 completion gate",
    "Step 07A validation gate",
    "Edge-accuracy wave summary",
    "Step 07B completion gate",
    "Case-dropping CS coefficients",
    "Step 08 stages 1--12 completion gate",
    "Five-wave point-network summary",
    "Exploratory Expected Influence",
    "Exploratory centrality stability",
    "Education-group sample flow",
    "Step 08B completion gate",
    "Education-group point-network diagnostics",
    "Education-group result-readiness audit",
    "Education-group figure source manifest",
    "Step 08C final validation",
    "Step 09 completion gate",
    "Step 09 wave-level sensitivity summary",
    "Step 09 primary claim audit",
    "Step 09B completion gate",
    "Step 09B joint robustness claims",
    "Step 09B robustness counts",
    "Step 09B independent validation",
    "Locked package environment",
    "D-drive copy of latest research decision log"
  ),
  stringsAsFactors = FALSE
)
write_csv(input_inventory, file.path(final_table_dir, "10_input_inventory.csv"))

if (!all(input_inventory$Exists) || any(input_inventory$Bytes <= 0)) {
  stop("STEP 10 STOP: one or more required inputs are missing or empty.")
}

# -------------------------------------------------------------------------
# Stage-completion gate. Only contemporaneous rows are used; earlier
# stage-local NOT_AUTHORISED entries are not treated as the current state.
# -------------------------------------------------------------------------

step07 <- read_csv_required(input_paths[["step07_completion"]])
step07a <- read_csv_required(input_paths[["step07a_validation"]])
step07b <- read_csv_required(input_paths[["step07b_completion"]])
step08 <- read_csv_required(input_paths[["step08_completion"]])
step08b <- read_csv_required(input_paths[["step08b_completion"]])
step08c <- read_csv_required(input_paths[["step08c_validation"]])
step09 <- read_csv_required(input_paths[["step09_completion"]])
step09b <- read_csv_required(input_paths[["step09b_completion"]])
step09b_audit <- read_csv_required(input_paths[["step09b_independent_audit"]])

step07_required <- step07$Component %in% c(
  "Five ordered complete-case inputs",
  "Five primary point networks",
  "Five 1,000-repetition edge bootstraps"
)
step07b_required <- step07b$Component %in% c(
  "D23 authorisation",
  "Five-wave 1,000-repetition case-dropping"
)

stage_gate <- data.frame(
  Stage = c("00--06", "07", "07A", "07B", "08 stages 1--12", "08B", "08C", "09", "09B", "09B independent audit"),
  Criterion = c(
    "Five primary matrices finite, symmetric, positive definite and warning-free",
    "Inputs, five point networks and five 1,000-run edge bootstraps complete",
    "Every edge-accuracy validation check passed",
    "D23 authorised and five 1,000-run case-dropping outputs validated",
    "Every required stage 1--12 row passed",
    "Every required D08A row passed",
    "Every final result-readiness validation passed",
    "Every authorised sensitivity module complete and no prohibited analysis run",
    "Every Step 09B completion check true",
    "Every independent Step 09B audit check passed"
  ),
  Passed = c(
    {
      x <- read_csv_required(input_paths[["polychoric_diagnostics"]])
      nrow(x) == 5L && setequal(as.integer(x$Election_year), expected_waves) &&
        all(as_flag(x$All_values_finite)) && all(as_flag(x$Positive_definite)) &&
        all(x$Warning_n == 0)
    },
    sum(step07_required) == 3L &&
      all(step07$Status[step07_required] == "COMPLETE_AND_VALIDATED"),
    all(as_flag(step07a$Passed)),
    sum(step07b_required) == 2L &&
      step07b$Status[step07b$Component == "D23 authorisation"] == "AUTHORISED" &&
      step07b$Status[step07b$Component == "Five-wave 1,000-repetition case-dropping"] == "REUSED_VALIDATED_OUTPUTS",
    all(as_flag(step08$Passed[as_flag(step08$Required_for_stage1_12)])),
    all(as_flag(step08b$Passed[as_flag(step08b$Required_for_D08A)])),
    all(as_flag(step08c$Passed)),
    all(as_flag(step09$Complete)) && !any(as_flag(step09$Prohibited_analysis_run)),
    all(as_flag(step09b$Complete)),
    all(as_flag(step09b_audit$Passed))
  ),
  Notes = c(
    "Based on saved pre-analysis diagnostics; no model rerun in Step 10.",
    "Later 07A/07B files supersede stage-local future-scope rows in the Step 07 completion table.",
    "Percentile intervals are precision descriptors, not a second edge-selection rule.",
    "Expected Influence and Strength remain exploratory.",
    "NCT and political interpretation were outside scope.",
    "Eight descriptive education networks; no between-group inference.",
    "Within-network description only.",
    "Point-network sensitivities and reuse-only weighted summaries.",
    "Joint robustness is reproducibility evidence, not significance or equivalence.",
    "Independent recalculation had already passed before Step 10."
  ),
  stringsAsFactors = FALSE
)
write_csv(stage_gate, file.path(final_table_dir, "10_stage_completion_gate.csv"))
if (!all(stage_gate$Passed)) {
  stop("STEP 10 STOP: at least one upstream completion gate failed.")
}

# -------------------------------------------------------------------------
# Primary five-wave summary.
# -------------------------------------------------------------------------

sample_flow <- read_csv_required(input_paths[["sample_flow"]])
poly_diag <- read_csv_required(input_paths[["polychoric_diagnostics"]])
overall <- read_csv_required(input_paths[["overall_wave_summary"]])
accuracy <- read_csv_required(input_paths[["step07a_wave"]])
centrality <- read_csv_required(input_paths[["overall_centrality_stability"]])
ei <- read_csv_required(input_paths[["overall_expected_influence"]])

sample_flow$Wave <- as.integer(sample_flow$Election_year)
poly_diag$Wave <- as.integer(poly_diag$Election_year)
overall$Wave <- as.integer(overall$Wave)
accuracy$Wave <- as.integer(accuracy$Wave)
centrality$Wave <- as.integer(centrality$Wave)
ei$Wave <- as.integer(ei$Wave)

if (!setequal(overall$Wave, expected_waves) || anyDuplicated(overall$Wave)) {
  stop("STEP 10 STOP: five-wave primary summary has an unexpected wave set.")
}

highest_ei <- do.call(rbind, lapply(split(ei, ei$Wave), function(d) {
  row <- d[which.max(d$Expected_Influence), , drop = FALSE]
  data.frame(
    Wave = as.integer(row$Wave),
    Highest_Expected_Influence_node = as.character(row$Node),
    Highest_Expected_Influence = as.numeric(row$Expected_Influence),
    stringsAsFactors = FALSE
  )
}))

cs_ei <- centrality[centrality$Statistic == "expectedInfluence", c("Wave", "CS_coefficient"), drop = FALSE]
names(cs_ei)[2L] <- "Expected_Influence_CS"
cs_strength <- centrality[centrality$Statistic == "strength", c("Wave", "CS_coefficient"), drop = FALSE]
names(cs_strength)[2L] <- "Strength_CS"

primary <- merge(sample_flow, poly_diag[, c("Wave", "Warning_n", "Minimum_eigenvalue", "Condition_number", "Positive_definite")], by = "Wave")
primary <- merge(primary, overall, by = "Wave")
primary <- merge(primary, accuracy, by = "Wave")
primary <- merge(primary, highest_ei, by = "Wave")
primary <- merge(primary, cs_ei, by = "Wave")
primary <- merge(primary, cs_strength, by = "Wave")
primary <- primary[order(primary$Wave), ]

# `overall` and `accuracy` both carry Retained_edges. Preserve the formal
# overall value only after confirming the two independently produced tables
# agree exactly.
if (!all(primary$Retained_edges.x == primary$Retained_edges.y)) {
  stop("STEP 10 STOP: retained-edge counts disagree between Step 08 and Step 07A.")
}
primary$Retained_edges <- primary$Retained_edges.x

primary_summary <- data.frame(
  Wave = primary$Wave,
  Cleaned_n = primary$Cleaned_n,
  Excluded_missing_nine_node_n = primary$Excluded_missing_nine_node_n,
  Analysis_ready_n = primary$Analysis_ready_n,
  Point_network_n = primary$N,
  Education_missing_n = primary$Education_missing_n,
  Nodes = primary$Nodes,
  Possible_edges = primary$Possible_edges,
  Retained_edges = primary$Retained_edges,
  Density = primary$Density,
  Global_strength_descriptive = primary$Global_strength_descriptive,
  Dense_network_warning = primary$Captured_warning_n > 0,
  Polychoric_warning_n = primary$Warning_n,
  Positive_definite = primary$Positive_definite,
  Polychoric_minimum_eigenvalue = primary$Minimum_eigenvalue,
  Polychoric_condition_number = primary$Condition_number,
  Median_percentile_interval_width = primary$Median_percentile_interval_width,
  Maximum_percentile_interval_width = primary$Maximum_percentile_interval_width,
  Retained_edges_percentile_interval_excluding_zero_audit_only = primary$Retained_edges_percentile_interval_excluding_zero,
  Highest_Expected_Influence_node = primary$Highest_Expected_Influence_node,
  Highest_Expected_Influence = primary$Highest_Expected_Influence,
  Expected_Influence_CS = primary$Expected_Influence_CS,
  Strength_CS = primary$Strength_CS,
  Result_scope = "DESCRIPTIVE_ANES_ANALYSIS_SAMPLE_CONDITIONAL_ASSOCIATIONS",
  Interpretation_boundary = paste(
    "Repeated cross-sections; no individual change, causality, population-design inference,",
    "measurement-invariance claim, NCT, or equation of edge count/global strength with ideological constraint."
  ),
  stringsAsFactors = FALSE
)
write_csv(primary_summary, file.path(final_table_dir, "10_sample_primary_summary.csv"))

# -------------------------------------------------------------------------
# Education-group result readiness. No between-group significance statement.
# -------------------------------------------------------------------------

education <- read_csv_required(input_paths[["education_readiness"]])
education$Wave <- as.integer(education$Wave)
if (nrow(education) != 8L || !setequal(education$Wave, expected_education_waves)) {
  stop("STEP 10 STOP: education readiness does not contain the expected eight groups.")
}

education_summary <- data.frame(
  Group_key = education$Group_key,
  Wave = education$Wave,
  Education_group = education$Education_group,
  N = education$N,
  Nodes = education$Nodes,
  Retained_edges = education$Retained_edges,
  Not_retained_edges = education$Not_retained_edges,
  Bootstrap_repetitions = education$Bootstrap_repetitions,
  Retained_edges_percentile_CI_excludes_zero_audit_only = education$Retained_edges_percentile_CI_excludes_zero_audit_only,
  Median_percentile_CI_width = education$Median_percentile_CI_width,
  Maximum_percentile_CI_width = education$Maximum_percentile_CI_width,
  Sparse_cell_status = education$Sparse_cell_status,
  Point_warning_n = education$Point_warning_n,
  Bootstrap_warning_n = education$Bootstrap_warning_n,
  Result_readiness = education$Result_readiness,
  Permitted_scope = education$Permitted_scope,
  Between_group_inference = "NOT_RUN_AND_NOT_PERMITTED",
  stringsAsFactors = FALSE
)
write_csv(education_summary, file.path(final_table_dir, "10_education_summary.csv"))

# -------------------------------------------------------------------------
# Sensitivity evidence.
# -------------------------------------------------------------------------

sensitivity <- read_csv_required(input_paths[["sensitivity_by_wave"]])
module_groups <- split(sensitivity, interaction(sensitivity$Module_ID, sensitivity$Variant, drop = TRUE))
module_summary <- do.call(rbind, lapply(module_groups, function(d) {
  data.frame(
    Evidence_type = "STEP09_MODULE",
    Module_or_claim_type = paste(unique(d$Module_ID), unique(d$Variant), sep = "__"),
    Units = nrow(d),
    Minimum_edge_weight_correlation = min(d$Edge_weight_correlation, na.rm = TRUE),
    Maximum_edge_weight_correlation = max(d$Edge_weight_correlation, na.rm = TRUE),
    Maximum_absolute_global_strength_difference = if (all(is.na(d$Global_strength_difference))) {
      NA_real_
    } else {
      max(abs(d$Global_strength_difference), na.rm = TRUE)
    },
    Common_retained_sign_reversals = sum(d$Sign_reversals_common_retained, na.rm = TRUE),
    Status = collapse_values(d$Estimation_status),
    Interpretation = "DESCRIPTIVE_SPECIFICATION_SENSITIVITY_NOT_MODEL_SELECTION_OR_SIGNIFICANCE",
    stringsAsFactors = FALSE
  )
}))
rownames(module_summary) <- NULL

step09_claims <- read_csv_required(input_paths[["step09_claims"]])
step09_counts <- as.data.frame(table(step09_claims$Final_robustness_status), stringsAsFactors = FALSE)
names(step09_counts) <- c("Status", "Units")
step09_counts <- data.frame(
  Evidence_type = "STEP09_PRIMARY_CLAIM_AUDIT",
  Module_or_claim_type = "EDGE_RETENTION_AND_SIGN",
  Units = step09_counts$Units,
  Minimum_edge_weight_correlation = NA_real_,
  Maximum_edge_weight_correlation = NA_real_,
  Maximum_absolute_global_strength_difference = NA_real_,
  Common_retained_sign_reversals = NA_real_,
  Status = step09_counts$Status,
  Interpretation = "SENSITIVITY_CLASSIFICATION_NOT_SIGNIFICANCE_OR_EQUIVALENCE",
  stringsAsFactors = FALSE
)

step09b_counts <- read_csv_required(input_paths[["step09b_claim_summary"]])
step09b_summary <- data.frame(
  Evidence_type = "STEP09B_JOINT_ROBUSTNESS_AUDIT",
  Module_or_claim_type = step09b_counts$Claim_type,
  Units = step09b_counts$Count,
  Minimum_edge_weight_correlation = NA_real_,
  Maximum_edge_weight_correlation = NA_real_,
  Maximum_absolute_global_strength_difference = NA_real_,
  Common_retained_sign_reversals = NA_real_,
  Status = step09b_counts$Final_status,
  Interpretation = "REPRODUCIBILITY_CLASSIFICATION_NOT_P_VALUE_SIGNIFICANCE_OR_EQUIVALENCE",
  stringsAsFactors = FALSE
)

sensitivity_summary <- rbind(module_summary, step09_counts, step09b_summary)
write_csv(sensitivity_summary, file.path(final_table_dir, "10_sensitivity_summary.csv"))

# -------------------------------------------------------------------------
# Claim-to-output registry. This is a Results drafting control, not prose.
# -------------------------------------------------------------------------

claim_rows <- list()
claim_index <- 0L
add_claim <- function(...) {
  claim_index <<- claim_index + 1L
  claim_rows[[claim_index]] <<- data.frame(..., stringsAsFactors = FALSE)
}

for (i in seq_len(nrow(primary_summary))) {
  d <- primary_summary[i, ]
  add_claim(
    Claim_ID = paste0("RQ1_WAVE_", d$Wave, "_NETWORK_DESCRIPTOR"),
    Research_question = "RQ1",
    Analysis_scope = paste0("Overall ANES analysis sample, ", d$Wave),
    Claim_type = "DESCRIPTIVE_NETWORK_DESCRIPTOR",
    Value_or_status = paste0(
      "N=", d$Analysis_ready_n, "; retained_edges=", d$Retained_edges,
      "; global_strength=", format(round(d$Global_strength_descriptive, 4), nsmall = 4)
    ),
    Permitted_wording = "Describe the saved sample-level conditional-association network.",
    Required_qualification = "Dense-network warning; edge count and global strength are not ideological constraint; no significance test.",
    Evidence_file = "10_sample_primary_summary.csv",
    Evidence_columns = "Analysis_ready_n; Retained_edges; Global_strength_descriptive; Dense_network_warning",
    Validation_status = "READY_WITH_METHOD_LIMITATIONS",
    Method_reference_ids = "M01;M02;M03;D01",
    Supervisor_confirmation = if (d$Wave %in% c(2004L, 2024L)) "HISTORICAL_INTERPRETATION_SCOPE_ADVISED" else "NO"
  )
  add_claim(
    Claim_ID = paste0("RQ1_WAVE_", d$Wave, "_EDGE_ACCURACY"),
    Research_question = "RQ1",
    Analysis_scope = paste0("Within-wave edge accuracy, ", d$Wave),
    Claim_type = "EDGE_PRECISION",
    Value_or_status = paste0(
      "median_CI_width=", format(round(d$Median_percentile_interval_width, 4), nsmall = 4),
      "; maximum_CI_width=", format(round(d$Maximum_percentile_interval_width, 4), nsmall = 4)
    ),
    Permitted_wording = "Describe uncertainty width and bootstrap diagnostics.",
    Required_qualification = "Whether a bootstrap percentile interval contains zero is audit information, not a second edge-selection threshold.",
    Evidence_file = "10_sample_primary_summary.csv",
    Evidence_columns = "Median_percentile_interval_width; Maximum_percentile_interval_width",
    Validation_status = "READY",
    Method_reference_ids = "M02;M03",
    Supervisor_confirmation = "NO"
  )
  add_claim(
    Claim_ID = paste0("EXPLORATORY_WAVE_", d$Wave, "_CENTRALITY"),
    Research_question = "EXPLORATORY_NOT_FORMAL_RQ",
    Analysis_scope = paste0("Within-wave centrality, ", d$Wave),
    Claim_type = "EXPLORATORY_EXPECTED_INFLUENCE",
    Value_or_status = paste0(
      "highest_EI_node=", d$Highest_Expected_Influence_node,
      "; EI_CS_at_max_examined_drop=", format(round(d$Expected_Influence_CS, 4), nsmall = 4)
    ),
    Permitted_wording = "Cautiously describe signed connectivity within the selected node set.",
    Required_qualification = "No causal importance, public salience, cross-wave centrality test, or intervention claim.",
    Evidence_file = "10_sample_primary_summary.csv",
    Evidence_columns = "Highest_Expected_Influence_node; Highest_Expected_Influence; Expected_Influence_CS",
    Validation_status = "EXPLORATORY_READY",
    Method_reference_ids = "M02;M04;M05",
    Supervisor_confirmation = "NO"
  )
}

for (i in seq_len(nrow(education_summary))) {
  d <- education_summary[i, ]
  add_claim(
    Claim_ID = paste0("RQ2_", toupper(gsub("[^A-Za-z0-9]+", "_", d$Group_key))),
    Research_question = "RQ2",
    Analysis_scope = paste0(d$Wave, ", ", d$Education_group),
    Claim_type = "DESCRIPTIVE_EDUCATION_NETWORK",
    Value_or_status = paste0("N=", d$N, "; retained_edges=", d$Retained_edges),
    Permitted_wording = "Describe edges and relational configuration within this education-group network.",
    Required_qualification = "No formal between-group inference; education is not elite status or a direct measure of political sophistication.",
    Evidence_file = "10_education_summary.csv",
    Evidence_columns = "N; Retained_edges; Result_readiness; Permitted_scope",
    Validation_status = "READY_WITHIN_NETWORK_ONLY",
    Method_reference_ids = "M01;M02;M03;D01",
    Supervisor_confirmation = "RQ2_EXACT_WORDING_STILL_TO_BE_ENTERED_IN_DECISION_LOG"
  )
}

step09b_claims <- read_csv_required(input_paths[["step09b_claims"]])
contrast_claims <- step09b_claims[step09b_claims$Claim_type == "WAVE_CONTRAST_DIRECTION", ]
for (i in seq_len(nrow(contrast_claims))) {
  d <- contrast_claims[i, ]
  add_claim(
    Claim_ID = as.character(d$Claim_ID),
    Research_question = "RQ1",
    Analysis_scope = paste0(d$Earlier_wave, " to ", d$Later_wave),
    Claim_type = "DESCRIPTIVE_DIRECTION_ROBUSTNESS",
    Value_or_status = as.character(d$Final_status),
    Permitted_wording = if (d$Final_status == "ROBUST") {
      "The observed direction met the pre-specified Step 09B reproducibility rule."
    } else {
      "The observed direction did not consistently meet the pre-specified Step 09B reproducibility rule."
    },
    Required_qualification = "This classification is not a p-value, significance test, equivalence test, or population inference.",
    Evidence_file = "09B_claim_robustness.csv",
    Evidence_columns = "A1_match; A2_match_proportion; A3_match_proportion; Minimum_match; Final_status",
    Validation_status = "AUDITED",
    Method_reference_ids = "M01;M03",
    Supervisor_confirmation = if (d$Earlier_wave == 2004L && d$Later_wave == 2024L) "HISTORICAL_INTERPRETATION_SCOPE_ADVISED" else "NO"
  )
}

claim_registry <- do.call(rbind, claim_rows)
write_csv(claim_registry, file.path(final_table_dir, "10_result_claim_registry.csv"))

# -------------------------------------------------------------------------
# Method citation register and explicit Zotero-gap register.
# -------------------------------------------------------------------------

citation_register <- data.frame(
  Reference_ID = c("M01", "M02", "M03", "M04", "M05", "S01", "S02", "D01"),
  Authors = c(
    "Epskamp and Fried",
    "Epskamp, Borsboom and Fried",
    "Burger et al.",
    "Bringmann et al.",
    "Robinaugh, Millner and McNally",
    "Epskamp, Cramer, Waldorp, Schmittmann and Borsboom",
    "bootnet package documentation",
    "American National Election Studies"
  ),
  Year = c("2018", "2018", "2023", "2019", "2016", "2012", "VERIFICATION REQUIRED", "2026"),
  Title = c(
    "A Tutorial on Regularized Partial Correlation Networks",
    "Estimating Psychological Networks and Their Accuracy: A Tutorial Paper",
    "Reporting Standards for Psychological Network Analyses in Cross-Sectional Data",
    "What Do Centrality Measures Measure in Psychological Networks?",
    "Identifying Highly Influential Nodes in the Complicated Grief Network",
    "qgraph: Network Visualizations of Relationships in Psychometric Data",
    "bootnet package documentation and citation metadata",
    "ANES Time Series Cumulative Data File 1948--2024 documentation"
  ),
  Publication = c(
    "Psychological Methods, 23(4), 617--634",
    "Behavior Research Methods, 50(1), 195--212",
    "Psychological Methods, 28(4), 806--824",
    "Journal of Abnormal Psychology, 128(8), 892--903",
    "Journal of Abnormal Psychology, 125(6), 747--757",
    "Journal of Statistical Software, 48(4), 1--18",
    "R package documentation",
    "Official ANES documentation"
  ),
  DOI_or_official_identifier = c(
    "10.1037/met0000167",
    "10.3758/s13428-017-0862-1",
    "10.1037/met0000471",
    "10.1037/abn0000446",
    "10.1037/abn0000181",
    "10.18637/jss.v048.i04",
    "bootnet 1.9.1",
    "ANES CDF release 2026-02-05"
  ),
  Role_in_Step10 = c(
    "Conditional-edge, ordinal-polychoric, EBICglasso and regularisation interpretation",
    "Edge-accuracy bootstrap, case-dropping stability and CS interpretation",
    "Transparent reporting, comparable figures, software/defaults and limitation reporting",
    "Centrality interpretation boundary",
    "Original one-step Expected Influence definition; used only for definition",
    "qgraph software citation",
    "bootnet implementation record; theory is cited to Epskamp et al. 2018",
    "Data release, harmonisation and repeated-cross-section documentation"
  ),
  Full_text_or_official_source_status = c(
    "LOCAL_FULL_TEXT_INSPECTED",
    "LOCAL_FULL_TEXT_INSPECTED",
    "LOCAL_FULL_TEXT_INSPECTED",
    "LOCAL_FULL_TEXT_INSPECTED",
    "FULL_TEXT_AVAILABLE_VIA_PMC_AND_INSPECTED_THIS_PROJECT;_LOCAL_ZOTERO_PDF_ABSENT",
    "LOCAL_PACKAGE_CITATION_INSPECTED",
    "LOCAL_PACKAGE_CITATION_INSPECTED",
    "LOCAL_OFFICIAL_DOCUMENTATION_AVAILABLE"
  ),
  Local_or_official_path = c(
    "C:/Users/hua/Zotero/storage/2SPCXJB3/Epskamp和Fried - 2018 - A Tutorial on Regularized Partial Correlation Networks.pdf",
    "C:/Users/hua/Zotero/storage/SF6F8YS4/Epskamp 等 - 2018 - Estimating psychological networks and their accuracy A tutorial paper.pdf",
    "C:/Users/hua/Zotero/storage/ZLK7KBDN/Burger 等 - 2023 - Reporting standards for psychological network analyses in cross-sectional data..pdf",
    "C:/Users/hua/Zotero/storage/F77P44II/Bringmann 等 - 2019 - What Do Centrality Measures Measure in Psychological Networks.pdf",
    "https://pmc.ncbi.nlm.nih.gov/articles/PMC5060093/",
    "D:/ANES_code/ANES_dissertation/renv/library/windows/R-4.5/x86_64-w64-mingw32/qgraph/CITATION",
    "D:/ANES_code/ANES_dissertation/renv/library/windows/R-4.5/x86_64-w64-mingw32/bootnet/CITATION",
    "C:/Users/hua/Desktop/ERP/tmp/additional_material_staging/01_Data_Documentation/ANES_CDF_Codebook.pdf"
  ),
  Zotero_status = c(
    "IN_ZOTERO_DUPLICATE_RECORDS_PRESENT",
    "IN_ZOTERO",
    "IN_ZOTERO_DUPLICATE_RECORDS_PRESENT",
    "IN_ZOTERO",
    "NOT_IN_ZOTERO",
    "NOT_IN_ZOTERO",
    "NOT_IN_ZOTERO_AS_SOFTWARE_RESOURCE",
    "NOT_IN_ZOTERO"
  ),
  Verification_note = c(
    "Use the inspected local full text; deduplicate later without editing Zotero in Step 10.",
    "Supervisor-recommended full text inspected.",
    "Supervisor-recommended full text inspected; duplicate metadata records exist.",
    "Local full text inspected.",
    "Do not treat lack of a Zotero attachment as lack of accessible full text.",
    "Verified from the installed qgraph CITATION file.",
    "Record version and interface only; do not substitute package documentation for the method paper.",
    "Official operational data source, not a peer-reviewed method article."
  ),
  stringsAsFactors = FALSE
)
write_csv(citation_register, file.path(final_table_dir, "10_method_citation_register.csv"))
write_csv(
  citation_register[grepl("^NOT_IN_ZOTERO", citation_register$Zotero_status), ],
  file.path(final_table_dir, "10_references_not_in_zotero.csv")
)

# -------------------------------------------------------------------------
# Software/package manifest.
# -------------------------------------------------------------------------

renv_data <- tryCatch(
  {
    if (requireNamespace("renv", quietly = TRUE)) {
      renv::lockfile_read(input_paths[["renv_lock"]])
    } else if (requireNamespace("jsonlite", quietly = TRUE)) {
      jsonlite::fromJSON(input_paths[["renv_lock"]], simplifyVector = FALSE)
    } else {
      NULL
    }
  },
  error = function(e) {
    warning("Unable to parse renv.lock for the package manifest: ", conditionMessage(e))
    NULL
  }
)
locked_version <- function(package) {
  if (is.null(renv_data) || is.null(renv_data$Packages[[package]]$Version)) return(NA_character_)
  as.character(renv_data$Packages[[package]]$Version)
}

package_names <- c("qgraph", "bootnet", "psych", "lavaan", "digest", "knitr", "rmarkdown", "renv")
package_manifest <- data.frame(
  Software = c("R", package_names),
  Version_locked = c(as.character(getRversion()), vapply(package_names, locked_version, character(1L))),
  Version_loaded_for_Step10 = c(
    as.character(getRversion()),
    vapply(package_names, function(p) {
      if (requireNamespace(p, quietly = TRUE)) as.character(utils::packageVersion(p)) else NA_character_
    }, character(1L))
  ),
  Role = c(
    "Analysis environment",
    "Primary network estimation and visualisation in earlier validated steps",
    "Bootstrap accuracy and stability in earlier validated steps",
    "Polychoric correlations in earlier validated steps",
    "Correlation support in earlier validated steps",
    "SHA-256 hashing in Step 10",
    "Step 10 report rendering",
    "Step 10 report rendering",
    "Project dependency lock"
  ),
  Step10_model_execution = "NO",
  stringsAsFactors = FALSE
)
write_csv(package_manifest, file.path(final_table_dir, "10_package_manifest.csv"))

session_file <- file.path(log_dir, "10_sessionInfo.txt")
sink(session_file)
print(sessionInfo())
sink()

renv_status_file <- file.path(log_dir, "10_renv_status.txt")
renv_status_result <- "NOT_RUN_PACKAGE_UNAVAILABLE"
if (requireNamespace("renv", quietly = TRUE)) {
  status_object <- NULL
  status_error <- NULL
  status_capture <- capture.output({
    status_object <- tryCatch(
      renv::status(project = project_root, sources = FALSE),
      error = function(e) {
        status_error <<- conditionMessage(e)
        NULL
      }
    )
  })
  if (!is.null(status_error)) {
    status_capture <- c(status_capture, paste("renv status error:", status_error))
  } else {
    status_capture <- c(
      status_capture,
      paste0("renv synchronized: ", isTRUE(status_object$synchronized))
    )
  }
  writeLines(status_capture, renv_status_file, useBytes = TRUE)
  renv_status_result <- if (!is.null(status_error)) {
    "COMPLETED_WITH_ERROR_RECORDED"
  } else if (isTRUE(status_object$synchronized)) {
    "COMPLETED"
  } else {
    "COMPLETED_INCONSISTENCIES_RECORDED"
  }
} else {
  writeLines("renv package unavailable; renv.lock was still hashed and parsed where possible.", renv_status_file)
}

# -------------------------------------------------------------------------
# Final figure set: byte-for-byte copies of validated figures.
# -------------------------------------------------------------------------

selected_figures <- data.frame(
  Source_name = c(
    "08_overall_networks_five_wave_panel.png",
    paste0("07A_edge_accuracy_", expected_waves, ".png"),
    "08_expected_influence_over_time.png",
    "08_strength_over_time.png"
  ),
  Figure_role = c(
    "MAIN_CANDIDATE_OVERALL_NETWORK_PANEL",
    rep("SUPPLEMENTARY_EDGE_ACCURACY", length(expected_waves)),
    "EXPLORATORY_CENTRALITY_CANDIDATE",
    "EXPLORATORY_CENTRALITY_AUXILIARY"
  ),
  Required_caption_boundary = c(
    "Repeated cross-sectional ANES analysis samples; descriptive conditional associations; common layout and scale; no NCT.",
    rep("Within-wave percentile uncertainty; interval inclusion of zero is not a second edge-selection rule.", length(expected_waves)),
    "Exploratory Expected Influence only; no cross-wave significance or causal-importance claim.",
    "Auxiliary Strength only; no cross-wave significance or causal-importance claim."
  ),
  stringsAsFactors = FALSE
)

education_manifest <- read_csv_required(input_paths[["education_figure_manifest"]])
education_selected <- data.frame(
  Source_name = basename(education_manifest$Path),
  Figure_role = ifelse(
    education_manifest$Figure_type == "FIXED_LAYOUT_NETWORK",
    "SUPPLEMENTARY_EDUCATION_WITHIN_NETWORK",
    "SUPPLEMENTARY_EDUCATION_EDGE_ACCURACY"
  ),
  Required_caption_boundary = ifelse(
    education_manifest$Figure_type == "FIXED_LAYOUT_NETWORK",
    "Within-group descriptive network only; common layout and scale; no between-group inference.",
    "Within-group edge uncertainty only; no between-group inference and no second edge-selection rule."
  ),
  stringsAsFactors = FALSE
)
selected_figures <- rbind(selected_figures, education_selected)

selected_figures$Source_path <- file.path(formal_figure_dir, selected_figures$Source_name)
selected_figures$Final_name <- paste0("10_", selected_figures$Source_name)
selected_figures$Final_path <- file.path(final_figure_dir, selected_figures$Final_name)

if (!all(file.exists(selected_figures$Source_path))) {
  stop("STEP 10 STOP: one or more selected source figures are missing.")
}

copy_ok <- mapply(
  function(from, to) file.copy(from, to, overwrite = TRUE, copy.date = FALSE),
  selected_figures$Source_path,
  selected_figures$Final_path,
  USE.NAMES = FALSE
)
if (!all(copy_ok)) stop("STEP 10 STOP: one or more validated figures could not be copied.")

figure_manifest <- data.frame(
  Figure_ID = sprintf("FIG10_%02d", seq_len(nrow(selected_figures))),
  Source_path = selected_figures$Source_path,
  Final_path = selected_figures$Final_path,
  Figure_role = selected_figures$Figure_role,
  Required_caption_boundary = selected_figures$Required_caption_boundary,
  Bytes = file.info(selected_figures$Final_path)$size,
  Source_SHA256 = vapply(selected_figures$Source_path, sha256, character(1L)),
  Final_SHA256 = vapply(selected_figures$Final_path, sha256, character(1L)),
  Byte_identical = mapply(
    function(a, b) identical(readBin(a, "raw", n = file.info(a)$size), readBin(b, "raw", n = file.info(b)$size)),
    selected_figures$Source_path,
    selected_figures$Final_path,
    USE.NAMES = FALSE
  ),
  stringsAsFactors = FALSE
)
write_csv(figure_manifest, file.path(final_table_dir, "10_figure_manifest.csv"))

# -------------------------------------------------------------------------
# Table, reproducibility and result-readiness manifests.
# -------------------------------------------------------------------------

table_manifest <- data.frame(
  Table_ID = c("T10_01", "T10_02", "T10_03", "T10_04", "T10_05", "T10_06", "T10_07"),
  File = c(
    "10_sample_primary_summary.csv",
    "10_education_summary.csv",
    "10_sensitivity_summary.csv",
    "10_result_claim_registry.csv",
    "10_method_citation_register.csv",
    "10_references_not_in_zotero.csv",
    "10_package_manifest.csv"
  ),
  Purpose = c(
    "Verified five-wave sample and primary network descriptors",
    "Verified education-group within-network result readiness",
    "Sensitivity and joint-robustness summary",
    "Claim-to-output drafting control",
    "Method and data-source citation register",
    "Sources used by Step 10 but absent from Zotero",
    "Locked and active software versions"
  ),
  Candidate_location = c(
    "MAIN_TEXT_OR_APPENDIX",
    "MAIN_TEXT_SUMMARY_WITH_DETAILS_IN_APPENDIX",
    "MAIN_TEXT_SUMMARY_WITH_DETAILS_IN_APPENDIX",
    "AUDIT_ONLY",
    "AUDIT_ONLY",
    "AUDIT_ONLY_ACTION_LIST",
    "ADDITIONAL_MATERIAL"
  ),
  No_visible_timestamp = TRUE,
  stringsAsFactors = FALSE
)
write_csv(table_manifest, file.path(final_table_dir, "10_table_manifest.csv"))

reproducibility_manifest <- data.frame(
  Component = c(
    "Source data documentation",
    "Derived analysis-ready data",
    "Ordered preprocessing notebooks",
    "Primary point-network objects",
    "Edge bootstrap objects",
    "Centrality case-drop objects",
    "Education network and bootstrap objects",
    "Sensitivity objects",
    "Dependency lock",
    "Package manifest",
    "Session information",
    "renv status snapshot",
    "Random seeds",
    "Claim-to-output registry",
    "Input and output SHA-256 inventories"
  ),
  Status = c(
    "AVAILABLE_READ_ONLY",
    "AVAILABLE",
    "AVAILABLE",
    "AVAILABLE_VALIDATED",
    "AVAILABLE_VALIDATED_1000_PER_WAVE",
    "AVAILABLE_VALIDATED_1000_PER_WAVE",
    "AVAILABLE_VALIDATED_1000_PER_GROUP",
    "AVAILABLE_VALIDATED",
    "AVAILABLE_HASHED",
    "CREATED",
    "CREATED",
    renv_status_result,
    "AVAILABLE_IN_PRIOR_OUTPUTS_AND_SCRIPTS",
    "CREATED",
    "CREATED"
  ),
  Evidence = c(
    "Official ANES documentation and project source inventory",
    "data/processed and data/audit",
    "notebooks/00--06 and their rendered reports",
    "outputs/models/formal",
    "outputs/models/formal and 07A validation",
    "outputs/models/formal and 07B validation",
    "outputs/models/formal and 08B/08C validation",
    "outputs/models/sensitivity and 09/09B validation",
    "renv.lock",
    "10_package_manifest.csv",
    "outputs/logs/10_sessionInfo.txt",
    "outputs/logs/10_renv_status.txt",
    "Prior seed manifests and executable notebooks",
    "10_result_claim_registry.csv",
    "10_input_inventory.csv; 10_output_hash_inventory.csv"
  ),
  Limitation = c(
    "ANES access and source-version requirements still apply.",
    "Raw ANES data are not redistributed.",
    "Step 10 does not rerun Steps 00--09B.",
    "All primary networks carry a dense-network warning.",
    "Intervals are precision evidence, not edge-selection tests.",
    "Centrality remains exploratory.",
    "No education-group significance test.",
    "Robustness labels are not p-values or equivalence tests.",
    "A current renv status snapshot is reported separately.",
    "Package-version fields should be checked again at final submission.",
    "Operating-system and locale warnings may be environment-specific.",
    "Any recorded issue must be resolved before final archive freeze.",
    "No new random process was executed in Step 10.",
    "Registry is an audit aid, not dissertation prose.",
    "Hashes attest file identity, not substantive validity."
  ),
  stringsAsFactors = FALSE
)
write_csv(reproducibility_manifest, file.path(final_table_dir, "10_reproducibility_manifest.csv"))

results_readiness <- data.frame(
  Section = c(
    "RQ1 overall network descriptors",
    "RQ1 edge accuracy",
    "Exploratory centrality",
    "RQ2 education-group networks",
    "Step 09 specification sensitivities",
    "Step 09B joint robustness",
    "Final tables and figures",
    "Reproducibility materials",
    "Title and exact RQ wording"
  ),
  Status = c(
    "READY_WITH_METHOD_LIMITATIONS",
    "READY",
    "READY_EXPLORATORY_ONLY",
    "READY_WITHIN_NETWORK_ONLY",
    "READY_AS_SENSITIVITY_EVIDENCE",
    "READY_AS_REPRODUCIBILITY_EVIDENCE",
    "ASSEMBLED_AND_HASHED",
    if (renv_status_result == "COMPLETED") {
      "ASSEMBLED_AND_ENVIRONMENT_CONSISTENT"
    } else {
      "ASSEMBLED_RENV_INCONSISTENCY_RECORDED_ARCHIVE_NOT_READY"
    },
    "RESEARCHER_SELECTED_SUPERVISOR_CONFIRMATION_ADVISED"
  ),
  What_can_be_written = c(
    "Sample-level descriptive differences in selected nine-node conditional-association networks.",
    "Within-wave edge-weight uncertainty and diagnostic limits.",
    "Cautious within-wave Expected Influence and auxiliary Strength descriptions.",
    "Edges and relational configurations within each pre-specified education group and wave.",
    "Whether descriptive patterns persist under pre-specified alternative specifications.",
    "Whether direction/retention claims meet the pre-specified reproducibility rule.",
    "Use only manifested figures/tables with the required caption boundaries.",
    if (renv_status_result == "COMPLETED") {
      "A researcher with authorised ANES access can trace code, inputs, versions, seeds and outputs."
    } else {
      "Code, inputs, versions, seeds and outputs are traceable, but the dependency environment must be reconciled before final archive freeze."
    },
    "Current researcher-selected title and RQs may guide drafting but remain to be entered in the formal decision log."
  ),
  What_must_not_be_written = c(
    "Individual change, causality, population-design inference, measurement invariance, or constraint equivalence.",
    "Bootstrap interval crossing zero as a second edge-selection rule.",
    "Cross-wave significance, causal importance, salience or intervention priority.",
    "Statistically significant education-group differences or education as elite/sophistication.",
    "Sensitivity result as post-hoc selection of the most favourable specification.",
    "ROBUST/MIXED/NOT_ROBUST as a p-value, significance, or equivalence result.",
    "Unqualified figure captions or invisible scale/layout changes.",
    "A claim that raw ANES data are redistributed with the archive.",
    "A claim that supervisor confirmation has already been obtained."
  ),
  stringsAsFactors = FALSE
)
write_csv(results_readiness, file.path(final_table_dir, "10_results_readiness.csv"))

# -------------------------------------------------------------------------
# D-drive scope and storage snapshots. These do not modify C-drive sources.
# -------------------------------------------------------------------------

scope_text <- c(
  "# Step 10 Scope Snapshot",
  "",
  "## Current researcher-selected title",
  "",
  "Structural Differences in Selected Policy-Attitude Networks across U.S. Election Years: Evidence from ANES Samples, 2004–2024",
  "",
  "Status: researcher-selected working title; entry in the formal decision log and supervisor confirmation remain advised.",
  "",
  "## Research-question scope represented by completed outputs",
  "",
  "- RQ1: descriptive comparison of selected nine-node policy-attitude conditional-association networks in the 2004, 2012, 2016, 2020 and 2024 ANES analysis samples.",
  "- RQ2: descriptive edges and relational configurations within the two education groups in the pre-specified years 2012, 2016, 2020 and 2024.",
  "- Expected Influence and Strength are exploratory and are not separate confirmatory research questions.",
  "",
  "## Hard interpretation boundaries",
  "",
  "No NCT, no education-group significance test, no individual change, no causal inference, no design-consistent US population-network inference, no claim of strict measurement invariance, and no equation of network density or global strength with ideological constraint.",
  "",
  "## Step 10 execution boundary",
  "",
  "Step 10 assembles, hashes and audits saved outputs only. It does not estimate or resample a network."
)
writeLines(scope_text, file.path(working_dir, "STEP10_SCOPE_SNAPSHOT.md"), useBytes = TRUE)

storage_text <- c(
  "# Step 10 output locations",
  "",
  "Step 10 writes summary tables, figures, reports and validation records to the configured analysis project.",
  "The project includes a copy of the research decision log used for provenance checks.",
  "Set project, cache and temporary-directory paths for the local computer before running the engine."
)
writeLines(storage_text, file.path(working_dir, "STEP10_STORAGE_AND_RUNTIME_POLICY.md"), useBytes = TRUE)

decision_copy_manifest <- data.frame(
  File = "research_decisions_log.md",
  D_drive_path = input_paths[["decision_log_copy"]],
  Exists = file.exists(input_paths[["decision_log_copy"]]),
  Bytes = file.info(input_paths[["decision_log_copy"]])$size,
  SHA256 = sha256(input_paths[["decision_log_copy"]]),
  Copy_policy = "LATEST_VERSION_COPIED_BYTE_FOR_BYTE_FROM_C; C_SOURCE_NOT_MODIFIED",
  stringsAsFactors = FALSE
)
write_csv(decision_copy_manifest, file.path(final_table_dir, "10_decision_log_copy_manifest.csv"))

# -------------------------------------------------------------------------
# Validation, output hashes and completion status.
# -------------------------------------------------------------------------

visible_time_terms <- c("created_at", "creation_time", "creation_date", "generated_at", "timestamp")
csvs_before_validation <- list.files(final_table_dir, pattern = "^10_.*\\.csv$", full.names = TRUE)
csv_headers <- lapply(csvs_before_validation, function(path) names(read.csv(path, nrows = 1L, check.names = FALSE)))
no_visible_time_columns <- !any(vapply(csv_headers, function(h) any(tolower(h) %in% visible_time_terms), logical(1L)))

validation <- data.frame(
  Check = c(
    "All required inputs exist and are non-empty",
    "All upstream stage gates pass",
    "Primary summary contains exactly five expected waves",
    "Primary sample Ns match saved network Ns",
    "Every primary network records the dense-network warning",
    "Every primary polychoric input is positive definite and warning-free",
    "Education summary contains eight expected group-wave rows",
    "Education output contains no formal between-group inference",
    "Step 09 contains 180 audited primary edge claims",
    "Step 09B contains 74 robust, 13 mixed and 93 not-robust edge claims",
    "Step 09B contains 3 robust, 1 mixed and 6 not-robust contrast-direction claims",
    "Every selected final figure is byte-identical to its validated source",
    "Method citation register explicitly identifies Zotero status",
    "Sources absent from Zotero are exported separately",
    "No visible creation-date or creation-time column exists",
    "No 2008 result appears in the five-wave or education summary",
    "No network model or bootstrap was executed by Step 10"
  ),
  Passed = c(
    all(input_inventory$Exists) && all(input_inventory$Bytes > 0),
    all(stage_gate$Passed),
    nrow(primary_summary) == 5L && identical(primary_summary$Wave, expected_waves),
    all(primary_summary$Analysis_ready_n == primary_summary$Point_network_n),
    all(primary_summary$Dense_network_warning),
    all(primary_summary$Polychoric_warning_n == 0) && all(as_flag(primary_summary$Positive_definite)),
    nrow(education_summary) == 8L && setequal(education_summary$Wave, expected_education_waves),
    all(education_summary$Between_group_inference == "NOT_RUN_AND_NOT_PERMITTED"),
    nrow(step09_claims) == 180L,
    {
      x <- step09b_claims[step09b_claims$Claim_type == "EDGE_SIGN_AND_RETENTION", ]
      identical(as.integer(table(factor(x$Final_status, levels = c("ROBUST", "MIXED", "NOT_ROBUST")))), c(74L, 13L, 93L))
    },
    {
      x <- step09b_claims[step09b_claims$Claim_type == "WAVE_CONTRAST_DIRECTION", ]
      identical(as.integer(table(factor(x$Final_status, levels = c("ROBUST", "MIXED", "NOT_ROBUST")))), c(3L, 1L, 6L))
    },
    all(figure_manifest$Byte_identical) && all(figure_manifest$Source_SHA256 == figure_manifest$Final_SHA256),
    "Zotero_status" %in% names(citation_register) && !any(is.na(citation_register$Zotero_status)),
    nrow(citation_register[grepl("^NOT_IN_ZOTERO", citation_register$Zotero_status), ]) >= 1L,
    no_visible_time_columns,
    !any(primary_summary$Wave == 2008L) && !any(education_summary$Wave == 2008L),
    TRUE
  ),
  Evidence = c(
    "10_input_inventory.csv",
    "10_stage_completion_gate.csv",
    "10_sample_primary_summary.csv",
    "10_sample_primary_summary.csv",
    "10_sample_primary_summary.csv",
    "10_sample_primary_summary.csv",
    "10_education_summary.csv",
    "10_education_summary.csv",
    "09_primary_claim_robustness_summary.csv",
    "09B_claim_robustness.csv",
    "09B_claim_robustness.csv",
    "10_figure_manifest.csv",
    "10_method_citation_register.csv",
    "10_references_not_in_zotero.csv",
    "Final CSV header audit",
    "10_sample_primary_summary.csv; 10_education_summary.csv",
    "Static execution boundary: assembly-only engine"
  ),
  stringsAsFactors = FALSE
)
write_csv(validation, file.path(final_table_dir, "10_validation.csv"))
if (!all(validation$Passed)) {
  stop("STEP 10 STOP: one or more Step 10 validation checks failed.")
}

completion_status <- data.frame(
  Component = c(
    "Input inventory and upstream gates",
    "Primary five-wave result assembly",
    "Education-group result assembly",
    "Sensitivity result assembly",
    "Claim-to-output registry",
    "Method citation register",
    "Not-in-Zotero register",
    "Final table manifest",
    "Final figure manifest and byte-identity check",
    "Package/session/renv record",
    "Step 10 validation",
    "Independent Step 10 audit",
    "Dissertation Results prose",
    "Network re-estimation"
  ),
  Status = c(
    rep("COMPLETE_AND_VALIDATED", 11L),
    "PENDING_SEPARATE_SCRIPT",
    "NOT_WRITTEN_STEP10_IS_EVIDENCE_ASSEMBLY_ONLY",
    "NOT_RUN_PROHIBITED_IN_STEP10"
  ),
  stringsAsFactors = FALSE
)
completion_status$Status[
  completion_status$Component == "Package/session/renv record"
] <- if (renv_status_result == "COMPLETED") {
  "COMPLETE_AND_VALIDATED"
} else {
  "COMPLETE_WITH_RENV_INCONSISTENCY_RECORDED"
}
write_csv(completion_status, file.path(final_table_dir, "10_completion_status.csv"))

core_output_files <- list.files(
  final_table_dir,
  pattern = "^10_.*\\.csv$",
  full.names = TRUE
)
core_output_files <- core_output_files[!basename(core_output_files) %in% c(
  "10_output_hash_inventory.csv",
  "10_independent_audit_validation.csv",
  "10_independent_recalculation.csv",
  "10_completion_status.csv",
  "10_final_artifact_manifest.csv",
  "10_finalization_validation.csv"
)]
core_output_files <- c(
  core_output_files,
  figure_manifest$Final_path,
  session_file,
  renv_status_file,
  file.path(working_dir, "STEP10_SCOPE_SNAPSHOT.md"),
  file.path(working_dir, "STEP10_STORAGE_AND_RUNTIME_POLICY.md")
)
core_output_files <- unique(core_output_files[file.exists(core_output_files)])

output_hash_inventory <- data.frame(
  File = basename(core_output_files),
  Path = core_output_files,
  Bytes = file.info(core_output_files)$size,
  SHA256 = vapply(core_output_files, sha256, character(1L)),
  stringsAsFactors = FALSE
)
write_csv(output_hash_inventory, file.path(final_table_dir, "10_output_hash_inventory.csv"))

run_log <- c(
  "STEP 10 RESULTS AND REPRODUCIBILITY ASSEMBLY",
  "STATUS: ENGINE COMPLETE",
  paste0("PROJECT ROOT: ", project_root),
  paste0("UPSTREAM GATES PASSED: ", sum(stage_gate$Passed), "/", nrow(stage_gate)),
  paste0("PRIMARY WAVES ASSEMBLED: ", nrow(primary_summary)),
  paste0("EDUCATION GROUP-WAVE NETWORKS ASSEMBLED: ", nrow(education_summary)),
  paste0("CLAIM REGISTRY ROWS: ", nrow(claim_registry)),
  paste0("FINAL FIGURES COPIED AND HASH-MATCHED: ", sum(figure_manifest$Byte_identical), "/", nrow(figure_manifest)),
  paste0("METHOD REFERENCES REGISTERED: ", nrow(citation_register)),
  paste0("REFERENCES NOT IN ZOTERO: ", sum(grepl("^NOT_IN_ZOTERO", citation_register$Zotero_status))),
  paste0("VALIDATION CHECKS PASSED: ", sum(validation$Passed), "/", nrow(validation)),
  paste0("RENV STATUS: ", renv_status_result),
  "MODEL EXECUTION: NONE",
  "BOOTSTRAP EXECUTION: NONE",
  "NCT EXECUTION: NONE",
  "VISIBLE CREATION DATE/TIME: NONE",
  "C-DRIVE PROJECT SOURCE MODIFICATION: NONE"
)
writeLines(run_log, file.path(log_dir, "10_results_and_reproducibility.log"), useBytes = TRUE)

message("STEP 10 ENGINE COMPLETE: assembly and first-pass validation passed.")
