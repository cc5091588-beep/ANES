# Inventory only. This does not authorise estimation or bypass historical gates.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("Supply the analysis directory.")
root <- normalizePath(args[1], winslash = "/", mustWork = TRUE)
stopifnot(file.exists(file.path(root, "config", "Submission")))
paths <- c(
  "config/anes_cdf_path.txt",
  "project_docs/governance_audit/REVISED_PROPOSED_DECISION_REGISTRY_v5.csv",
  "project_docs/decisions/step07_pilot_authorisation.csv",
  "data/analysis_ready/anes_cdf_20260205_analysis_ready_nine_node_complete_case_2004_2012_2016_2020_2024.rds",
  "outputs/models/pilot/2004_pilot_network_gamma050.rds",
  "outputs/models/formal/07_formal_five_wave_networks_gamma050.rds",
  "outputs/models/sensitivity/09B_equalN_samples.rds",
  "data/audit/D11_PAIRWISE_20260828/D11_warnings.csv"
)
cat("Required local files (some respondent-level objects are deliberately excluded):\n")
print(data.frame(File = paths, Exists = file.exists(file.path(root, paths))), row.names = FALSE)
registry <- read.csv(file.path(root, paths[2]), check.names = FALSE, stringsAsFactors = FALSE)
id_column <- names(registry)[vapply(registry, function(x) any(as.character(x) %in% c("D15", "D21")), logical(1))][1]
if (!is.na(id_column)) {
  columns <- intersect(c(id_column, "decision_status", "implementation_status", "researcher_approval_status"), names(registry))
  print(registry[registry[[id_column]] %in% c("D15", "D21"), columns, drop = FALSE], row.names = FALSE)
}
cat("\nFull replay: NOT VERIFIED. Historical 06B/07/09 state gates and the 09 historical hash gate remain.\n")
cat("09B requires a new output destination. The 06B Stage 3A check depends on the 07 pilot.\n")
cat("Do not change approval records or input hashes to force a run to pass.\n")
cat("This inventory is not a successful model or environment test.\n")
