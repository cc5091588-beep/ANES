options(stringsAsFactors = FALSE)

find_project_root <- function(start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (file.exists(file.path(current, "ANES.Rproj"))) {
      return(current)
    }
    parent <- dirname(current)
    if (identical(parent, current)) {
      stop("Cannot locate ANES.Rproj from: ", start)
    }
    current <- parent
  }
}

project_root <- Sys.getenv("ANES_PROJECT_ROOT", unset = "")
if (!nzchar(project_root)) {
  project_root <- find_project_root()
}
project_root <- normalizePath(project_root, winslash = "/", mustWork = TRUE)

path_in_project <- function(...) file.path(project_root, ...)

config_dir <- path_in_project("config")
input_dir <- path_in_project("data", "audit", "node_wave_selection_inputs")
table_dir <- path_in_project("outputs", "tables", "supplement", "node_wave_selection")
figure_dir <- path_in_project("outputs", "figures", "supplement", "node_wave_selection")
log_dir <- path_in_project("outputs", "logs")

dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)

required_files <- c(
  node_spec = file.path(config_dir, "node_selection_spec.csv"),
  wave_spec = file.path(config_dir, "wave_selection_spec.csv"),
  node_sets = file.path(config_dir, "candidate_node_sets.csv"),
  evidence_spec = file.path(config_dir, "evidence_input_spec.csv"),
  comparability = file.path(input_dir, "anes_year_item_comparability.csv"),
  measurement_map = file.path(input_dir, "FINAL_ALL_WAVE_MEASUREMENT_G02B.csv"),
  mapping_2024 = file.path(input_dir, "ANES2024_SOURCE_MAPPING_G02B.csv"),
  mapping_evidence = file.path(input_dir, "ANES_SOURCE_MAPPING_EVIDENCE_G02B.csv"),
  complete_case_2008 = file.path(input_dir, "2008_complete_case_diagnostic.csv"),
  split_form_2008 = file.path(input_dir, "2008_split_form_patterns.csv"),
  pairwise_cells_2008 = file.path(input_dir, "2008_2012_polychoric_pairwise_cell_diagnostic.csv"),
  polychoric_2008 = file.path(input_dir, "2008_2012_polychoric_feasibility_summary.csv"),
  cleaned_data = path_in_project("data", "cleaned", "anes_cdf_20260205_cleaned_2004_2012_2016_2020_2024.rds"),
  analysis_ready = path_in_project("data", "analysis_ready", "anes_cdf_20260205_analysis_ready_nine_node_complete_case_2004_2012_2016_2020_2024.rds")
)

retrospective_dir <- file.path(table_dir, "retrospective_candidate_audit")
required_files <- c(
  required_files,
  retrospective_summary = file.path(retrospective_dir, "retrospective_candidate_audit_summary.csv"),
  retrospective_validation = file.path(retrospective_dir, "retrospective_candidate_audit_validation.csv"),
  retrospective_inventory = file.path(retrospective_dir, "all_1030_cdf_fields_retrospective_inventory.csv"),
  retrospective_broad_hits = file.path(retrospective_dir, "broad_policy_label_retrieval_80.csv"),
  retrospective_survivors = file.path(retrospective_dir, "provisional_five_wave_survivors_32.csv"),
  retrospective_vcf9049 = file.path(retrospective_dir, "vcf9049_complete_case_feasibility.csv")
)

missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files)) {
  stop(
    "Required node/wave-selection inputs are missing:\n",
    paste(names(missing_files), missing_files, sep = " = ", collapse = "\n")
  )
}

read_csv <- function(path) {
  out <- read.csv(
    path,
    check.names = FALSE,
    stringsAsFactors = FALSE,
    na.strings = c("", "NA")
  )
  # Some inherited audit CSVs begin with a UTF-8 byte-order mark but also
  # contain legacy bytes that cannot be converted reliably by fileEncoding.
  # Read in the platform encoding, then remove only a non-ASCII prefix from
  # the first header (for example, the visible BOM prefix before "year").
  names(out)[1L] <- sub("^[^A-Za-z0-9_]+", "", names(out)[1L])
  out
}

write_csv <- function(x, path) {
  write.csv(x, path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
}

node_spec <- read_csv(required_files[["node_spec"]])
wave_spec <- read_csv(required_files[["wave_spec"]])
node_sets <- read_csv(required_files[["node_sets"]])
evidence_spec <- read_csv(required_files[["evidence_spec"]])
comparability <- read_csv(required_files[["comparability"]])
measurement_map <- read_csv(required_files[["measurement_map"]])
mapping_2024 <- read_csv(required_files[["mapping_2024"]])
mapping_evidence <- read_csv(required_files[["mapping_evidence"]])
cc_2008 <- read_csv(required_files[["complete_case_2008"]])
split_2008 <- read_csv(required_files[["split_form_2008"]])
cells_2008 <- read_csv(required_files[["pairwise_cells_2008"]])
poly_2008 <- read_csv(required_files[["polychoric_2008"]])
retrospective_summary <- read_csv(required_files[["retrospective_summary"]])
retrospective_validation <- read_csv(required_files[["retrospective_validation"]])

final_nodes <- node_spec[node_spec$final_role == "PRIMARY_NODE", , drop = FALSE]
final_nodes <- final_nodes[order(final_nodes$final_order), , drop = FALSE]
expected_nodes <- c(
  "VCF0806", "VCF0809", "VCF0838", "VCF0839", "VCF0879a",
  "VCF0888", "VCF0890", "VCF0894", "VCF9223"
)
primary_years <- as.integer(wave_spec$year[wave_spec$overall_role == "PRIMARY_OVERALL"])
primary_years <- sort(primary_years[is.finite(primary_years)])
expected_years <- c(2004L, 2012L, 2016L, 2020L, 2024L)

candidate_years <- c(2000L, 2004L, 2008L, 2012L, 2016L, 2020L, 2024L)
candidate_variables <- node_spec$cdf_variable
node_wave_availability <- comparability[
  comparability$variable_name %in% candidate_variables &
    as.integer(comparability$year) %in% candidate_years,
  ,
  drop = FALSE
]
node_wave_availability <- node_wave_availability[
  order(match(node_wave_availability$variable_name, candidate_variables), as.integer(node_wave_availability$year)),
  ,
  drop = FALSE
]
node_wave_availability$recorded_candidate_pool <- TRUE

final_measurement_map <- measurement_map[
  as.integer(measurement_map$year) %in% primary_years &
    measurement_map$variable_name %in% expected_nodes,
  ,
  drop = FALSE
]
final_measurement_map$final_order <- match(final_measurement_map$variable_name, expected_nodes)
final_measurement_map <- final_measurement_map[
  order(as.integer(final_measurement_map$year), final_measurement_map$final_order),
  ,
  drop = FALSE
]
final_measurement_map$selection_status <- "PRIMARY_NODE"

cleaned <- readRDS(required_files[["cleaned_data"]])
analysis_ready <- readRDS(required_files[["analysis_ready"]])
cleaned <- as.data.frame(cleaned, check.names = FALSE)
analysis_ready <- as.data.frame(analysis_ready, check.names = FALSE)

split_nodes <- function(x) strsplit(x, "|", fixed = TRUE)[[1L]]
feasibility_rows <- list()
for (set_index in seq_len(nrow(node_sets))) {
  set_nodes <- split_nodes(node_sets$node_variables[[set_index]])
  absent <- setdiff(set_nodes, names(cleaned))
  if (length(absent)) {
    stop("Candidate set contains variables absent from cleaned data: ", paste(absent, collapse = ", "))
  }
  for (year in primary_years) {
    year_data <- cleaned[as.integer(cleaned$VCF0004) == year, set_nodes, drop = FALSE]
    feasibility_rows[[length(feasibility_rows) + 1L]] <- data.frame(
      set_id = node_sets$set_id[[set_index]],
      set_role = node_sets$set_role[[set_index]],
      year = year,
      node_count = length(set_nodes),
      complete_case_n = sum(stats::complete.cases(year_data)),
      source = "Recomputed from the final five-wave cleaned RDS",
      stringsAsFactors = FALSE
    )
  }
}
candidate_set_feasibility <- do.call(rbind, feasibility_rows)

expected_feasibility <- data.frame(
  set_id = rep(c("PRIMARY_9", "NO_VCF0839", "NO_VCF9223", "NO_VCF0839_OR_VCF9223"), each = 5L),
  year = rep(expected_years, times = 4L),
  expected_n = c(
    789L, 4353L, 2709L, 5390L, 3525L,
    863L, 4680L, 2953L, 5867L, 3814L,
    791L, 4365L, 2715L, 5390L, 3527L,
    865L, 4693L, 2960L, 5868L, 3816L
  ),
  stringsAsFactors = FALSE
)
candidate_set_feasibility <- merge(
  candidate_set_feasibility,
  expected_feasibility,
  by = c("set_id", "year"),
  all.x = TRUE,
  sort = FALSE
)
candidate_set_feasibility$matches_registered_count <-
  candidate_set_feasibility$complete_case_n == candidate_set_feasibility$expected_n
candidate_set_feasibility <- candidate_set_feasibility[
  order(match(candidate_set_feasibility$set_id, node_sets$set_id), candidate_set_feasibility$year),
  ,
  drop = FALSE
]

get_step_n <- function(step_name) {
  value <- cc_2008$n[cc_2008$step == step_name]
  if (length(value) != 1L) return(NA_integer_)
  as.integer(value)
}

pairwise_2008 <- cells_2008[as.integer(cells_2008$year) == 2008L, , drop = FALSE]
sample_names_2008 <- c("overall", "no_college", "college_plus")
cell_summary_rows <- lapply(sample_names_2008, function(sample_name) {
  x <- pairwise_2008[pairwise_2008$sample == sample_name, , drop = FALSE]
  data.frame(
    sample = sample_name,
    node_pairs = nrow(x),
    pairs_with_zero_cells = sum(as.integer(x$zero_cells) > 0L),
    pairs_with_cells_below_5 = sum(as.integer(x$cells_below_5) > 0L),
    stringsAsFactors = FALSE
  )
})
cell_summary_2008 <- do.call(rbind, cell_summary_rows)

split_all_four <- split_2008[split_2008$row_type == "summary" & split_2008$pattern == "ALL_FOUR_VALID", , drop = FALSE]
split_all_nine <- split_2008[split_2008$row_type == "summary" & split_2008$pattern == "ALL_NINE_POLICY_VALID", , drop = FALSE]
poly_overall_2008 <- poly_2008[as.integer(poly_2008$year) == 2008L & poly_2008$sample == "overall", , drop = FALSE]

exclusion_2008_summary <- data.frame(
  indicator = c(
    "total_2008_sample",
    "valid_on_all_four_split_form_nodes",
    "nine_node_complete_cases",
    "nine_nodes_plus_valid_education",
    "no_college_complete_cases",
    "college_plus_complete_cases",
    "overall_pairs_with_zero_cells",
    "overall_pairs_with_cells_below_5",
    "college_plus_pairs_with_zero_cells",
    "college_plus_pairs_with_cells_below_5",
    "overall_polychoric_matrix_positive_definite",
    "overall_polychoric_estimation_warnings",
    "final_analytical_role"
  ),
  value = c(
    as.character(get_step_n("total_sample")),
    if (nrow(split_all_four) == 1L) as.character(split_all_four$n) else NA_character_,
    if (nrow(split_all_nine) == 1L) as.character(split_all_nine$n) else NA_character_,
    as.character(get_step_n("all_9_nodes_plus_valid_education")),
    as.character(get_step_n("education_option_A_no_college")),
    as.character(get_step_n("education_option_A_college_plus")),
    as.character(cell_summary_2008$pairs_with_zero_cells[cell_summary_2008$sample == "overall"]),
    as.character(cell_summary_2008$pairs_with_cells_below_5[cell_summary_2008$sample == "overall"]),
    as.character(cell_summary_2008$pairs_with_zero_cells[cell_summary_2008$sample == "college_plus"]),
    as.character(cell_summary_2008$pairs_with_cells_below_5[cell_summary_2008$sample == "college_plus"]),
    if (nrow(poly_overall_2008) == 1L) as.character(poly_overall_2008$positive_definite) else NA_character_,
    if (nrow(poly_overall_2008) == 1L) as.character(poly_overall_2008$estimation_warnings) else NA_character_,
    "EXCLUDED_DIAGNOSTICS_ONLY"
  ),
  interpretation = c(
    "All 2008 CDF respondents.",
    "Only respondents with substantive responses on VCF0806, VCF0809, VCF0838 and VCF0839.",
    "The uniquely restricted nine-node complete-case subset used only for historical feasibility auditing.",
    "Nine-node complete cases with valid education coding.",
    "Historical education diagnostic only.",
    "Historical education diagnostic only; this small group is not analysed in the dissertation.",
    "Sparse-cell diagnostic, not an automatic exclusion threshold.",
    "Sparse-cell diagnostic, not an automatic exclusion threshold.",
    "Evidence of severe subgroup sparsity.",
    "Evidence of severe subgroup sparsity.",
    "Confirms that 2008 was not excluded because the overall matrix was mathematically unusable.",
    "Confirms that matrix estimation did not itself trigger the final exclusion.",
    "Researcher-approved comparability and scope decision; the former 2008 sensitivity was withdrawn."
  ),
  stringsAsFactors = FALSE
)

mapping_check <- mapping_2024[
  mapping_2024$cdf_variable %in% c("VCF0879a", "VCF9223"),
  ,
  drop = FALSE
]
mapping_check <- mapping_check[match(c("VCF0879a", "VCF9223"), mapping_check$cdf_variable), , drop = FALSE]

validation_rows <- list()
add_check <- function(check_id, severity, passed, details) {
  validation_rows[[length(validation_rows) + 1L]] <<- data.frame(
    check_id = check_id,
    severity = severity,
    passed = isTRUE(passed),
    details = as.character(details),
    stringsAsFactors = FALSE
  )
}

add_check("V01_REQUIRED_INPUTS_EXIST", "HARD", length(missing_files) == 0L, "All configured aggregate evidence and local RDS inputs exist.")
add_check("V02_RECORDED_CANDIDATE_POOL_HAS_16_UNIQUE_ITEMS", "HARD", nrow(node_spec) == 16L && !anyDuplicated(node_spec$cdf_variable), paste("Rows:", nrow(node_spec)))
add_check("V03_FINAL_NINE_AND_ORDER_MATCH_FROZEN_SPEC", "HARD", identical(final_nodes$cdf_variable, expected_nodes), paste(final_nodes$cdf_variable, collapse = "|"))
add_check("V04_PRIMARY_YEARS_MATCH_FROZEN_SPEC", "HARD", identical(primary_years, expected_years), paste(primary_years, collapse = "|"))
add_check("V05_ANALYSIS_READY_DATA_EXCLUDES_2008", "HARD", identical(sort(unique(as.integer(analysis_ready$VCF0004))), expected_years), paste(sort(unique(as.integer(analysis_ready$VCF0004))), collapse = "|"))
add_check("V06_ANALYSIS_READY_DATA_HAS_16766_COMPLETE_CASES", "HARD", nrow(analysis_ready) == 16766L && all(stats::complete.cases(analysis_ready[, expected_nodes, drop = FALSE])), paste("N:", nrow(analysis_ready)))
add_check("V07_ALTERNATIVE_SET_COUNTS_REPRODUCED", "HARD", all(candidate_set_feasibility$matches_registered_count), paste("Matched:", sum(candidate_set_feasibility$matches_registered_count), "of", nrow(candidate_set_feasibility)))
add_check("V08_FINAL_MEASUREMENT_MAP_HAS_45_ROWS", "HARD", nrow(final_measurement_map) == 45L, paste("Rows:", nrow(final_measurement_map)))
add_check("V09_2024_IMMIGRATION_MAPPING_VERIFIED", "HARD", nrow(mapping_check) == 2L && identical(mapping_check$raw_variable, c("V242227", "V242228")) && all(mapping_check$status == "PASS") && all(as.integer(mapping_check$mismatches) == 0L), paste(mapping_check$cdf_variable, mapping_check$raw_variable, mapping_check$status, collapse = " | "))
role_2008 <- unname(wave_spec$overall_role[which(as.integer(wave_spec$year) == 2008L)])
add_check(
  "V10_2008_ROLE_IS_EXCLUDED_DIAGNOSTICS_ONLY",
  "HARD",
  length(role_2008) == 1L && identical(role_2008, "EXCLUDED_DIAGNOSTICS_ONLY"),
  "The former 2008 sensitivity is withdrawn."
)
add_check("V11_2008_OVERALL_MATRIX_WAS_ESTIMABLE", "HARD", nrow(poly_overall_2008) == 1L && isTRUE(as.logical(poly_overall_2008$positive_definite)) && as.integer(poly_overall_2008$failed_correlations) == 0L, "Exclusion must not be described as matrix failure.")
add_check("V12_NO_VERIFICATION_REQUIRED_IN_FINAL_MAP", "HARD", !any(grepl("VERIFICATION REQUIRED", unlist(final_measurement_map), fixed = TRUE), na.rm = TRUE), "All final five-wave source mappings are populated.")
vcf9049_row <- node_spec[node_spec$cdf_variable == "VCF9049", , drop = FALSE]
add_check(
  "V13_VCF9049_CURRENT_SCOPE_DECISION_RECORDED",
  "SUBMISSION_BLOCKER",
  nrow(vcf9049_row) == 1L &&
    identical(vcf9049_row$final_role, "EXCLUDED_SCOPE_AND_MEASUREMENT_BOUNDARY") &&
    identical(vcf9049_row$decision_status, "FROZEN_BY_CURRENT_RESEARCHER_DECISION"),
  "The historical item-specific rationale remains unrecovered; the exclusion is transparently registered as a current scope-and-measurement-boundary decision."
)
summary_value <- function(component) {
  value <- retrospective_summary$value[retrospective_summary$component == component]
  if (length(value) != 1L) return(NA_character_)
  as.character(value)
}
add_check(
  "V14_RETROSPECTIVE_COMPLETENESS_AUDIT_REPRODUCED",
  "HARD",
  all(retrospective_validation$passed) &&
    identical(summary_value("cdf_fields_enumerated"), "1030") &&
    identical(summary_value("broad_label_hits"), "80") &&
    identical(summary_value("provisional_five_wave_survivors"), "32") &&
    identical(summary_value("survivors_outside_recorded_16"), "21"),
  "The post-hoc audit reproducibly enumerates 1,030 fields, retrieves 80 broad label hits and identifies 32 provisional five-wave survivors, including 21 outside the recorded 16."
)
add_check(
  "V15_ORIGINAL_16_ITEM_RULE_NONRECOVERY_DISCLOSED",
  "TRANSPARENCY_DISCLOSURE",
  identical(summary_value("original_16_item_rule_recovered"), "NO") &&
    identical(summary_value("audit_design_status"), "RETROSPECTIVE_POST_HOC_COMPLETENESS_AUDIT"),
  "The exact contemporaneous rule remains unavailable; the new audit is explicitly labelled retrospective and post hoc."
)

validation <- do.call(rbind, validation_rows)
hard_pass <- all(validation$passed[validation$severity == "HARD"])
submission_ready <- hard_pass && all(validation$passed[validation$severity == "SUBMISSION_BLOCKER"])

status <- data.frame(
  component = c("technical_validation", "submission_readiness", "network_models_run", "respondent_level_data_exported"),
  status = c(
    if (hard_pass) "PASS" else "FAIL",
    if (submission_ready) "READY_WITH_DISCLOSED_RETROSPECTIVE_LIMITATION" else "NOT_READY_RESEARCHER_DECISION_REQUIRED",
    "NO",
    "NO"
  ),
  stringsAsFactors = FALSE
)

write_csv(node_spec, file.path(table_dir, "candidate_node_decisions.csv"))
write_csv(final_nodes, file.path(table_dir, "final_nine_node_map.csv"))
write_csv(node_wave_availability, file.path(table_dir, "node_wave_availability.csv"))
write_csv(final_measurement_map, file.path(table_dir, "final_five_wave_measurement_map.csv"))
write_csv(candidate_set_feasibility, file.path(table_dir, "candidate_node_set_feasibility.csv"))
write_csv(wave_spec, file.path(table_dir, "wave_selection_decisions.csv"))
write_csv(exclusion_2008_summary, file.path(table_dir, "2008_exclusion_evidence.csv"))
write_csv(cell_summary_2008, file.path(table_dir, "2008_pairwise_cell_summary.csv"))
write_csv(mapping_check, file.path(table_dir, "2024_immigration_mapping_validation.csv"))
write_csv(mapping_evidence, file.path(table_dir, "source_mapping_evidence.csv"))
write_csv(evidence_spec, file.path(table_dir, "evidence_input_inventory.csv"))
write_csv(validation, file.path(table_dir, "node_wave_selection_validation.csv"))
write_csv(status, file.path(table_dir, "node_wave_selection_status.csv"))

draw_selection_flow <- function() {
  plot.new()
  plot.window(xlim = c(0, 1), ylim = c(0, 1))
  labels <- c(
    "Recorded 16-item project pool (historical rules not recovered)",
    "Retrospective completeness audit: 1,030 fields to 80 broad hits to 32 provisional survivors",
    "Fixed-wave availability and source audit",
    "Wording, categories and ordinal comparability",
    "Estimand boundary: policy attitudes and related beliefs",
    "Complete-case and input-feasibility audit",
    "Frozen nine-node primary set",
    "Boundary sensitivity: remove VCF0839"
  )
  ys <- seq(0.93, 0.07, length.out = length(labels))
  for (i in seq_along(labels)) {
    rect(0.12, ys[[i]] - 0.045, 0.88, ys[[i]] + 0.045, col = "#F4F7FB", border = "#355C7D", lwd = 1.5)
    text(0.5, ys[[i]], labels[[i]], cex = 0.9)
    if (i < length(labels)) {
      arrows(0.5, ys[[i]] - 0.05, 0.5, ys[[i + 1L]] + 0.05, length = 0.08, col = "#355C7D")
    }
  }
  mtext("Node-selection evidence chain", side = 3, line = 1, cex = 1.2, font = 2)
  mtext("Theoretical boundary decisions are registered; code reproduces the empirical audits.", side = 1, line = 1, cex = 0.75)
}

png(file.path(figure_dir, "node_selection_flow.png"), width = 2000, height = 1600, res = 220)
draw_selection_flow()
dev.off()
pdf(file.path(figure_dir, "node_selection_flow.pdf"), width = 9, height = 7)
draw_selection_flow()
dev.off()

draw_wave_selection_flow <- function() {
  plot.new()
  plot.window(xlim = c(0, 1), ylim = c(0, 1))
  labels <- c(
    "Fixed nine-node estimand",
    "Pre-2004 excluded: VCF9223 unavailable",
    "2004: earliest primary overall wave",
    "2008 audited separately: estimable but split-form restricted",
    "2008 excluded from all reported networks; diagnostics retained",
    "2012, 2016, 2020 and 2024 retained as primary overall waves",
    "Education-group module: 2012, 2016, 2020 and 2024"
  )
  ys <- seq(0.91, 0.09, length.out = length(labels))
  fills <- c("#EAF1F8", "#F8F1E8", "#EAF5EA", "#FFF4E5", "#FBEAEA", "#EAF5EA", "#EEF0FA")
  for (i in seq_along(labels)) {
    rect(0.08, ys[[i]] - 0.045, 0.92, ys[[i]] + 0.045, col = fills[[i]], border = "#355C7D", lwd = 1.5)
    text(0.5, ys[[i]], labels[[i]], cex = 0.82)
    if (i < length(labels)) {
      arrows(0.5, ys[[i]] - 0.05, 0.5, ys[[i + 1L]] + 0.05, length = 0.08, col = "#355C7D")
    }
  }
  mtext("Election-wave selection evidence chain", side = 3, line = 1, cex = 1.2, font = 2)
  mtext("2008 was excluded by a registered comparability and scope decision, not by matrix failure.", side = 1, line = 1, cex = 0.72)
}

png(file.path(figure_dir, "wave_selection_flow.png"), width = 2000, height = 1600, res = 220)
draw_wave_selection_flow()
dev.off()
pdf(file.path(figure_dir, "wave_selection_flow.pdf"), width = 9, height = 7)
draw_wave_selection_flow()
dev.off()

session_lines <- c(
  "Node and wave selection audit",
  paste("R:", R.version.string),
  paste("Platform:", R.version$platform),
  paste("Project root:", project_root),
  "Timestamp fields intentionally omitted from generated content.",
  "No network model, bootstrap, centrality, NCT or sensitivity model was run.",
  "No respondent-level data were exported."
)
writeLines(session_lines, file.path(log_dir, "01A_node_wave_selection_session_info.txt"), useBytes = TRUE)

manifest_paths <- c(
  list.files(config_dir, pattern = "(node_selection_spec|wave_selection_spec|candidate_node_sets|evidence_input_spec)[.]csv$", full.names = TRUE),
  list.files(table_dir, full.names = TRUE),
  list.files(figure_dir, full.names = TRUE),
  path_in_project("R", "01A_node_and_wave_selection_engine.R"),
  path_in_project("notebooks", "01A_node_and_wave_selection_audit.Rmd"),
  file.path(log_dir, "01A_node_wave_selection_session_info.txt")
)
manifest_paths <- unique(manifest_paths[file.exists(manifest_paths)])
manifest_paths <- manifest_paths[!file.info(manifest_paths)$isdir]
# A manifest cannot contain a stable hash of itself because writing that hash
# changes the file. Validate and hash the manifest separately at packaging.
manifest_paths <- manifest_paths[basename(manifest_paths) != "artifact_manifest.csv"]
if (!requireNamespace("digest", quietly = TRUE)) {
  stop("Package 'digest' is required to write the SHA-256 artifact manifest.")
}
artifact_manifest <- data.frame(
  relative_path = substring(normalizePath(manifest_paths, winslash = "/"), nchar(project_root) + 2L),
  bytes = as.numeric(file.info(manifest_paths)$size),
  sha256 = vapply(manifest_paths, digest::digest, character(1L), file = TRUE, algo = "sha256"),
  stringsAsFactors = FALSE
)
artifact_manifest <- artifact_manifest[order(artifact_manifest$relative_path), , drop = FALSE]
write_csv(artifact_manifest, file.path(table_dir, "artifact_manifest.csv"))

if (!hard_pass) {
  failed <- validation$check_id[validation$severity == "HARD" & !validation$passed]
  stop("Hard node/wave-selection validation failed: ", paste(failed, collapse = ", "))
}

message("NODE_WAVE_SELECTION_AUDIT_COMPLETE")
message("Technical validation: PASS")
message("Submission readiness: ", status$status[status$component == "submission_readiness"])
