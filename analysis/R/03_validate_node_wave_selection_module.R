#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
project_root <- if (length(args) == 1L) args[[1L]] else getwd()
project_root <- normalizePath(project_root, winslash = "/", mustWork = TRUE)
table_dir <- file.path(project_root, "outputs", "tables", "supplement", "node_wave_selection")

required_outputs <- c(
  "candidate_node_decisions.csv",
  "final_nine_node_map.csv",
  "node_wave_availability.csv",
  "final_five_wave_measurement_map.csv",
  "candidate_node_set_feasibility.csv",
  "wave_selection_decisions.csv",
  "2008_exclusion_evidence.csv",
  "2008_pairwise_cell_summary.csv",
  "2024_immigration_mapping_validation.csv",
  "source_mapping_evidence.csv",
  "evidence_input_inventory.csv",
  "node_wave_selection_validation.csv",
  "node_wave_selection_status.csv",
  "artifact_manifest.csv"
)

paths <- file.path(table_dir, required_outputs)
if (!all(file.exists(paths))) {
  stop("Missing outputs: ", paste(required_outputs[!file.exists(paths)], collapse = ", "))
}

validation <- read.csv(file.path(table_dir, "node_wave_selection_validation.csv"), check.names = FALSE)
status <- read.csv(file.path(table_dir, "node_wave_selection_status.csv"), check.names = FALSE)
manifest <- read.csv(file.path(table_dir, "artifact_manifest.csv"), check.names = FALSE)

hard <- validation[validation$severity == "HARD", , drop = FALSE]
stopifnot(
  nrow(hard) > 0L,
  all(hard$passed),
  identical(status$status[status$component == "technical_validation"], "PASS"),
  identical(status$status[status$component == "respondent_level_data_exported"], "NO"),
  nrow(manifest) > 0L,
  all(nchar(manifest$sha256) == 64L)
)

cat("NODE_WAVE_SELECTION_MODULE_VALIDATED\n")
cat("Submission readiness:", status$status[status$component == "submission_readiness"], "\n")

