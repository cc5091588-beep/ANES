options(stringsAsFactors = FALSE, warn = 1)

# Independent Step 10 audit. This script recomputes core values directly from
# saved pre-Step-10 CSVs and compares them with the Step 10 outputs. It does
# not source the Step 10 engine and does not estimate or resample a network.

locate_project_root <- function(start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = TRUE)
  candidates <- unique(c(current, dirname(current)))
  hit <- candidates[file.exists(file.path(candidates, "ANES.Rproj"))]
  if (length(hit) != 1L) stop("Independent audit STOP: project root not identified uniquely.")
  hit[[1L]]
}

project_root <- locate_project_root()
formal_dir <- file.path(project_root, "outputs", "tables", "formal")
sensitivity_dir <- file.path(project_root, "outputs", "tables", "sensitivity")
final_dir <- file.path(project_root, "outputs", "tables", "final")
audit_dir <- file.path(project_root, "outputs", "audits", "final")
log_dir <- file.path(project_root, "outputs", "logs")
engine_file <- file.path(project_root, "R", "10_results_and_reproducibility_engine.R")
rmd_file <- file.path(project_root, "notebooks", "10_results_and_reproducibility.Rmd")

dir.create(audit_dir, recursive = TRUE, showWarnings = FALSE)

if (!requireNamespace("digest", quietly = TRUE)) stop("Package 'digest' is required.")
sha256 <- function(path) unname(digest::digest(file = path, algo = "sha256", serialize = FALSE))
read_csv <- function(path) {
  if (!file.exists(path) || file.info(path)$size <= 0) stop("Missing audit input: ", path)
  read.csv(path, check.names = FALSE, na.strings = c("NA"))
}
write_csv <- function(x, path) write.csv(x, path, row.names = FALSE, na = "")
flag <- function(x) if (is.logical(x)) x else toupper(trimws(as.character(x))) == "TRUE"
near <- function(x, y, tolerance = 1e-10) all(abs(as.numeric(x) - as.numeric(y)) <= tolerance)

sample_source <- read_csv(file.path(
  project_root, "data", "audit",
  "anes_cdf_20260205_sample_flow_nine_node_complete_case_2004_2012_2016_2020_2024.csv"
))
overall_source <- read_csv(file.path(formal_dir, "08_overall_wave_summary.csv"))
accuracy_source <- read_csv(file.path(formal_dir, "07A_edge_accuracy_by_wave.csv"))
centrality_source <- read_csv(file.path(formal_dir, "08_overall_centrality_stability.csv"))
education_source <- read_csv(file.path(formal_dir, "08C_education_result_readiness.csv"))
sensitivity_source <- read_csv(file.path(sensitivity_dir, "09_sensitivity_summary_by_wave.csv"))
step09_claim_source <- read_csv(file.path(sensitivity_dir, "09_primary_claim_robustness_summary.csv"))
step09b_claim_source <- read_csv(file.path(sensitivity_dir, "09B_claim_robustness.csv"))

primary_final <- read_csv(file.path(final_dir, "10_sample_primary_summary.csv"))
education_final <- read_csv(file.path(final_dir, "10_education_summary.csv"))
sensitivity_final <- read_csv(file.path(final_dir, "10_sensitivity_summary.csv"))
claim_final <- read_csv(file.path(final_dir, "10_result_claim_registry.csv"))
citation_final <- read_csv(file.path(final_dir, "10_method_citation_register.csv"))
not_zotero_final <- read_csv(file.path(final_dir, "10_references_not_in_zotero.csv"))
figure_manifest <- read_csv(file.path(final_dir, "10_figure_manifest.csv"))
hash_inventory <- read_csv(file.path(final_dir, "10_output_hash_inventory.csv"))
validation_final <- read_csv(file.path(final_dir, "10_validation.csv"))
completion_final <- read_csv(file.path(final_dir, "10_completion_status.csv"))

sample_source$Wave <- as.integer(sample_source$Election_year)
overall_source$Wave <- as.integer(overall_source$Wave)
accuracy_source$Wave <- as.integer(accuracy_source$Wave)
centrality_source$Wave <- as.integer(centrality_source$Wave)
education_source$Wave <- as.integer(education_source$Wave)
primary_final$Wave <- as.integer(primary_final$Wave)
education_final$Wave <- as.integer(education_final$Wave)

primary_recomputed <- merge(sample_source, overall_source, by = "Wave")
primary_recomputed <- merge(primary_recomputed, accuracy_source, by = "Wave")
primary_recomputed <- primary_recomputed[order(primary_recomputed$Wave), ]
primary_final <- primary_final[order(primary_final$Wave), ]

if (!all(primary_recomputed$Retained_edges.x == primary_recomputed$Retained_edges.y)) {
  stop("Independent audit STOP: Step 08 and Step 07A retained-edge counts disagree.")
}
primary_recomputed$Retained_edges <- primary_recomputed$Retained_edges.x

edge_counts <- table(step09b_claim_source$Claim_type, step09b_claim_source$Final_status)
step09_counts <- table(step09_claim_source$Final_robustness_status)

final_sensitivity_units <- function(evidence_type, module_or_claim_type, status) {
  hit <- sensitivity_final[
    sensitivity_final$Evidence_type == evidence_type &
      sensitivity_final$Module_or_claim_type == module_or_claim_type &
      sensitivity_final$Status == status,
    ,
    drop = FALSE
  ]
  if (nrow(hit) != 1L || is.na(hit$Units[[1L]])) {
    stop(
      paste0(
        "Independent audit STOP: final sensitivity count is missing or non-unique for ",
        evidence_type, " / ", module_or_claim_type, " / ", status, "."
      )
    )
  }
  as.numeric(hit$Units[[1L]])
}

recalculation <- data.frame(
  Metric = c(
    paste0("Analysis_ready_n_", primary_recomputed$Wave),
    paste0("Retained_edges_", primary_recomputed$Wave),
    paste0("Global_strength_", primary_recomputed$Wave),
    paste0("Median_edge_CI_width_", primary_recomputed$Wave),
    paste0("Education_N_", education_source$Group_key),
    paste0("Education_retained_edges_", education_source$Group_key),
    "Step09_UNCHANGED_claims",
    "Step09_CHANGED_claims",
    "Step09B_edge_ROBUST",
    "Step09B_edge_MIXED",
    "Step09B_edge_NOT_ROBUST",
    "Step09B_contrast_ROBUST",
    "Step09B_contrast_MIXED",
    "Step09B_contrast_NOT_ROBUST"
  ),
  Source_value = c(
    primary_recomputed$Analysis_ready_n,
    primary_recomputed$Retained_edges,
    primary_recomputed$Global_strength_descriptive,
    primary_recomputed$Median_percentile_interval_width,
    education_source$N,
    education_source$Retained_edges,
    unname(step09_counts["UNCHANGED"]),
    unname(step09_counts["CHANGED"]),
    edge_counts["EDGE_SIGN_AND_RETENTION", "ROBUST"],
    edge_counts["EDGE_SIGN_AND_RETENTION", "MIXED"],
    edge_counts["EDGE_SIGN_AND_RETENTION", "NOT_ROBUST"],
    edge_counts["WAVE_CONTRAST_DIRECTION", "ROBUST"],
    edge_counts["WAVE_CONTRAST_DIRECTION", "MIXED"],
    edge_counts["WAVE_CONTRAST_DIRECTION", "NOT_ROBUST"]
  ),
  Step10_value = c(
    primary_final$Analysis_ready_n,
    primary_final$Retained_edges,
    primary_final$Global_strength_descriptive,
    primary_final$Median_percentile_interval_width,
    education_final$N[match(education_source$Group_key, education_final$Group_key)],
    education_final$Retained_edges[match(education_source$Group_key, education_final$Group_key)],
    final_sensitivity_units("STEP09_PRIMARY_CLAIM_AUDIT", "EDGE_RETENTION_AND_SIGN", "UNCHANGED"),
    final_sensitivity_units("STEP09_PRIMARY_CLAIM_AUDIT", "EDGE_RETENTION_AND_SIGN", "CHANGED"),
    final_sensitivity_units("STEP09B_JOINT_ROBUSTNESS_AUDIT", "EDGE_SIGN_AND_RETENTION", "ROBUST"),
    final_sensitivity_units("STEP09B_JOINT_ROBUSTNESS_AUDIT", "EDGE_SIGN_AND_RETENTION", "MIXED"),
    final_sensitivity_units("STEP09B_JOINT_ROBUSTNESS_AUDIT", "EDGE_SIGN_AND_RETENTION", "NOT_ROBUST"),
    final_sensitivity_units("STEP09B_JOINT_ROBUSTNESS_AUDIT", "WAVE_CONTRAST_DIRECTION", "ROBUST"),
    final_sensitivity_units("STEP09B_JOINT_ROBUSTNESS_AUDIT", "WAVE_CONTRAST_DIRECTION", "MIXED"),
    final_sensitivity_units("STEP09B_JOINT_ROBUSTNESS_AUDIT", "WAVE_CONTRAST_DIRECTION", "NOT_ROBUST")
  ),
  stringsAsFactors = FALSE
)
recalculation$Absolute_difference <- abs(as.numeric(recalculation$Source_value) - as.numeric(recalculation$Step10_value))
recalculation$Passed <- recalculation$Absolute_difference <= 1e-10
write_csv(recalculation, file.path(final_dir, "10_independent_recalculation.csv"))

current_hashes <- vapply(hash_inventory$Path, function(path) {
  if (!file.exists(path)) NA_character_ else sha256(path)
}, character(1L))

engine_text <- readLines(engine_file, warn = FALSE, encoding = "UTF-8")
rmd_text <- readLines(rmd_file, warn = FALSE, encoding = "UTF-8")
prohibited_patterns <- c(
  "estimateNetwork\\s*\\(",
  "EBICglasso\\s*\\(",
  "bootnet\\s*\\(",
  "NCT\\s*\\(",
  "NetworkComparisonTest\\s*::",
  "cor_auto\\s*\\(",
  "lavCor\\s*\\("
)
prohibited_hits <- vapply(prohibited_patterns, function(p) {
  any(grepl(p, c(engine_text, rmd_text), perl = TRUE))
}, logical(1L))

time_terms <- c("created_at", "creation_time", "creation_date", "generated_at", "timestamp")
final_csvs <- list.files(final_dir, pattern = "^10_.*\\.csv$", full.names = TRUE)
headers <- lapply(final_csvs, function(path) names(read.csv(path, nrows = 1L, check.names = FALSE)))
visible_time_field <- any(vapply(headers, function(h) any(tolower(h) %in% time_terms), logical(1L)))

audit <- data.frame(
  Check = c(
    "Independent recalculation matches every listed core value",
    "Primary wave set is exactly 2004, 2012, 2016, 2020 and 2024",
    "Primary N, retained-edge and global-strength values match source outputs",
    "Edge-accuracy widths match source outputs",
    "Expected Influence and Strength each have five CS records",
    "All centrality records retain exploratory interpretation boundaries",
    "Education result contains exactly eight expected group-wave rows",
    "Education result contains no between-group inferential output",
    "Step 09 claim counts are 149 unchanged and 31 changed",
    "Step 09B edge counts are 74 robust, 13 mixed and 93 not robust",
    "Step 09B contrast counts are 3 robust, 1 mixed and 6 not robust",
    "Every final figure exists, is non-empty and SHA-identical to its source",
    "Every inventoried Step 10 output hash still matches",
    "Every Step 10 first-pass validation check passed",
    "Method citation register contains Zotero-status and evidence-status fields",
    "Every not-in-Zotero row is a subset of the citation register",
    "No visible creation-date or time column exists",
    "No 2008 result appears in Step 10 summaries or claim registry",
    "No prohibited model, bootstrap, correlation-estimation or NCT call appears",
    "Completion table correctly keeps dissertation prose and model rerun outside Step 10"
  ),
  Passed = c(
    all(recalculation$Passed),
    identical(primary_final$Wave, c(2004L, 2012L, 2016L, 2020L, 2024L)),
    all(primary_final$Analysis_ready_n == primary_recomputed$Analysis_ready_n) &&
      all(primary_final$Retained_edges == primary_recomputed$Retained_edges) &&
      near(primary_final$Global_strength_descriptive, primary_recomputed$Global_strength_descriptive),
    near(primary_final$Median_percentile_interval_width, primary_recomputed$Median_percentile_interval_width) &&
      near(primary_final$Maximum_percentile_interval_width, primary_recomputed$Maximum_percentile_interval_width),
    sum(centrality_source$Statistic == "expectedInfluence") == 5L && sum(centrality_source$Statistic == "strength") == 5L,
    all(grepl("NO_CROSS_WAVE_CENTRALITY_TEST", centrality_source$Interpretation_boundary, fixed = TRUE)),
    nrow(education_final) == 8L && setequal(education_final$Wave, c(2012L, 2016L, 2020L, 2024L)),
    all(education_final$Between_group_inference == "NOT_RUN_AND_NOT_PERMITTED"),
    sum(step09_claim_source$Final_robustness_status == "UNCHANGED") == 149L &&
      sum(step09_claim_source$Final_robustness_status == "CHANGED") == 31L &&
      final_sensitivity_units("STEP09_PRIMARY_CLAIM_AUDIT", "EDGE_RETENTION_AND_SIGN", "UNCHANGED") == 149L &&
      final_sensitivity_units("STEP09_PRIMARY_CLAIM_AUDIT", "EDGE_RETENTION_AND_SIGN", "CHANGED") == 31L,
    edge_counts["EDGE_SIGN_AND_RETENTION", "ROBUST"] == 74L &&
      edge_counts["EDGE_SIGN_AND_RETENTION", "MIXED"] == 13L &&
      edge_counts["EDGE_SIGN_AND_RETENTION", "NOT_ROBUST"] == 93L &&
      final_sensitivity_units("STEP09B_JOINT_ROBUSTNESS_AUDIT", "EDGE_SIGN_AND_RETENTION", "ROBUST") == 74L &&
      final_sensitivity_units("STEP09B_JOINT_ROBUSTNESS_AUDIT", "EDGE_SIGN_AND_RETENTION", "MIXED") == 13L &&
      final_sensitivity_units("STEP09B_JOINT_ROBUSTNESS_AUDIT", "EDGE_SIGN_AND_RETENTION", "NOT_ROBUST") == 93L,
    edge_counts["WAVE_CONTRAST_DIRECTION", "ROBUST"] == 3L &&
      edge_counts["WAVE_CONTRAST_DIRECTION", "MIXED"] == 1L &&
      edge_counts["WAVE_CONTRAST_DIRECTION", "NOT_ROBUST"] == 6L &&
      final_sensitivity_units("STEP09B_JOINT_ROBUSTNESS_AUDIT", "WAVE_CONTRAST_DIRECTION", "ROBUST") == 3L &&
      final_sensitivity_units("STEP09B_JOINT_ROBUSTNESS_AUDIT", "WAVE_CONTRAST_DIRECTION", "MIXED") == 1L &&
      final_sensitivity_units("STEP09B_JOINT_ROBUSTNESS_AUDIT", "WAVE_CONTRAST_DIRECTION", "NOT_ROBUST") == 6L,
    all(file.exists(figure_manifest$Final_path)) && all(file.info(figure_manifest$Final_path)$size > 0) &&
      all(vapply(figure_manifest$Final_path, sha256, character(1L)) == figure_manifest$Final_SHA256) &&
      all(figure_manifest$Source_SHA256 == figure_manifest$Final_SHA256),
    all(!is.na(current_hashes)) && all(current_hashes == hash_inventory$SHA256),
    all(flag(validation_final$Passed)),
    all(c("Zotero_status", "Full_text_or_official_source_status") %in% names(citation_final)),
    all(not_zotero_final$Reference_ID %in% citation_final$Reference_ID) &&
      all(grepl("^NOT_IN_ZOTERO", not_zotero_final$Zotero_status)),
    !visible_time_field,
    !any(primary_final$Wave == 2008L) && !any(education_final$Wave == 2008L) &&
      !any(grepl("2008", claim_final$Analysis_scope, fixed = TRUE)),
    !any(prohibited_hits),
    completion_final$Status[completion_final$Component == "Dissertation Results prose"] == "NOT_WRITTEN_STEP10_IS_EVIDENCE_ASSEMBLY_ONLY" &&
      completion_final$Status[completion_final$Component == "Network re-estimation"] == "NOT_RUN_PROHIBITED_IN_STEP10"
  ),
  Evidence = c(
    "10_independent_recalculation.csv",
    "10_sample_primary_summary.csv",
    "Direct source/Step10 join",
    "07A_edge_accuracy_by_wave.csv compared with 10_sample_primary_summary.csv",
    "08_overall_centrality_stability.csv",
    "08_overall_centrality_stability.csv",
    "08C_education_result_readiness.csv compared with 10_education_summary.csv",
    "10_education_summary.csv",
    "09_primary_claim_robustness_summary.csv compared with 10_sensitivity_summary.csv",
    "09B_claim_robustness.csv compared with 10_sensitivity_summary.csv",
    "09B_claim_robustness.csv compared with 10_sensitivity_summary.csv",
    "10_figure_manifest.csv and independent hashes",
    "10_output_hash_inventory.csv",
    "10_validation.csv",
    "10_method_citation_register.csv",
    "10_references_not_in_zotero.csv",
    "All 10_ CSV headers",
    "10_sample_primary_summary.csv; 10_education_summary.csv; 10_result_claim_registry.csv",
    "Static scan of Step 10 engine and Rmd",
    "10_completion_status.csv"
  ),
  stringsAsFactors = FALSE
)
write_csv(audit, file.path(final_dir, "10_independent_audit_validation.csv"))

if (!all(audit$Passed)) {
  failed <- paste(audit$Check[!audit$Passed], collapse = "; ")
  writeLines(c("STEP 10 INDEPENDENT AUDIT FAILED", failed), file.path(log_dir, "10_independent_audit.log"))
  stop("Independent Step 10 audit failed: ", failed)
}

completion_final$Status[completion_final$Component == "Independent Step 10 audit"] <- "COMPLETE_AND_VALIDATED"
write_csv(completion_final, file.path(final_dir, "10_completion_status.csv"))

audit_report <- c(
  "# Step 10 Independent Audit",
  "",
  "Status: COMPLETE AND VALIDATED",
  "",
  paste0("Independent checks passed: ", sum(audit$Passed), "/", nrow(audit)),
  paste0("Independent numerical comparisons passed: ", sum(recalculation$Passed), "/", nrow(recalculation)),
  "",
  "The audit independently re-read the pre-Step-10 source CSVs, recomputed the core sample, network, accuracy, education and robustness values, checked figure and output hashes, scanned the Step 10 code for prohibited modelling calls, and checked that no visible creation-date or time field was introduced.",
  "",
  "No ANES raw data were read or modified. No network was estimated, bootstrapped or compared inferentially."
)
writeLines(audit_report, file.path(audit_dir, "10_INDEPENDENT_AUDIT.md"), useBytes = TRUE)

writeLines(
  c(
    "STEP 10 INDEPENDENT AUDIT",
    "STATUS: COMPLETE_AND_VALIDATED",
    paste0("CHECKS PASSED: ", sum(audit$Passed), "/", nrow(audit)),
    paste0("NUMERICAL COMPARISONS PASSED: ", sum(recalculation$Passed), "/", nrow(recalculation)),
    "MODEL EXECUTION: NONE",
    "BOOTSTRAP EXECUTION: NONE",
    "NCT EXECUTION: NONE",
    "VISIBLE CREATION DATE/TIME: NONE",
    "PROTECTED SOURCE MODIFICATION: NONE"
  ),
  file.path(log_dir, "10_independent_audit.log"),
  useBytes = TRUE
)

message("STEP 10 INDEPENDENT AUDIT COMPLETE: all checks passed.")
