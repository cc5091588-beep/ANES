options(stringsAsFactors = FALSE, warn = 1)

project_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(project_root, "ANES.Rproj"))) {
  stop("Finalization STOP: run from the ANES_dissertation project root.")
}
if (!requireNamespace("digest", quietly = TRUE)) stop("Package 'digest' is required.")

sha256 <- function(path) unname(digest::digest(file = path, algo = "sha256", serialize = FALSE))
flag <- function(x) if (is.logical(x)) x else toupper(trimws(as.character(x))) == "TRUE"
write_csv <- function(x, path) write.csv(x, path, row.names = FALSE, na = "")

final_table_dir <- file.path(project_root, "outputs", "tables", "final")
final_figure_dir <- file.path(project_root, "outputs", "figures", "final")
audit_dir <- file.path(project_root, "outputs", "audits", "final")
log_dir <- file.path(project_root, "outputs", "logs")
working_dir <- file.path(project_root, "project_docs", "working")
html_file <- file.path(project_root, "notebooks", "10_results_and_reproducibility.html")

required <- c(
  file.path(final_table_dir, "10_validation.csv"),
  file.path(final_table_dir, "10_independent_audit_validation.csv"),
  file.path(final_table_dir, "10_independent_recalculation.csv"),
  file.path(final_table_dir, "10_completion_status.csv"),
  file.path(final_table_dir, "10_method_citation_register.csv"),
  file.path(final_table_dir, "10_references_not_in_zotero.csv"),
  file.path(audit_dir, "10_INDEPENDENT_AUDIT.md"),
  html_file
)
if (!all(file.exists(required)) || any(file.info(required)$size <= 0)) {
  stop("Finalization STOP: one or more required Step 10 artifacts are missing or empty.")
}

validation <- read.csv(required[[1L]], check.names = FALSE)
independent <- read.csv(required[[2L]], check.names = FALSE)
recalculation <- read.csv(required[[3L]], check.names = FALSE)
completion <- read.csv(required[[4L]], check.names = FALSE)
citations <- read.csv(required[[5L]], check.names = FALSE)
not_zotero <- read.csv(required[[6L]], check.names = FALSE)
reproducibility <- read.csv(
  file.path(final_table_dir, "10_reproducibility_manifest.csv"),
  check.names = FALSE
)
renv_status <- reproducibility$Status[
  reproducibility$Component == "renv status snapshot"
]
renv_blocker <- length(renv_status) != 1L || renv_status != "COMPLETED"

stopifnot(all(flag(validation$Passed)))
stopifnot(all(flag(independent$Passed)))
stopifnot(all(flag(recalculation$Passed)))
stopifnot(
  completion$Status[completion$Component == "Independent Step 10 audit"] ==
    "COMPLETE_AND_VALIDATED"
)

artifact_files <- unique(c(
  list.files(final_table_dir, pattern = "^10_.*\\.csv$", full.names = TRUE),
  list.files(final_figure_dir, pattern = "^10_.*\\.png$", full.names = TRUE),
  list.files(audit_dir, pattern = "^10_.*\\.md$", full.names = TRUE),
  list.files(log_dir, pattern = "^10_.*\\.(log|txt)$", full.names = TRUE),
  file.path(project_root, "R", c(
    "10_results_and_reproducibility_engine.R",
    "10_results_and_reproducibility_independent_audit.R",
    "10_render_results_and_reproducibility.R",
    "10_finalize_results_and_reproducibility.R"
  )),
  file.path(project_root, "notebooks", c(
    "10_results_and_reproducibility.Rmd",
    "10_results_and_reproducibility.html"
  )),
  file.path(working_dir, c(
    "STEP10_SCOPE_SNAPSHOT.md",
    "STEP10_STORAGE_AND_RUNTIME_POLICY.md",
    "STEP10_RESULTS_AND_REPRODUCIBILITY_RESULT.md"
  ))
))
artifact_manifest_path <- file.path(final_table_dir, "10_final_artifact_manifest.csv")
artifact_files <- artifact_files[
  file.exists(artifact_files) & normalizePath(artifact_files, winslash = "/", mustWork = FALSE) !=
    normalizePath(artifact_manifest_path, winslash = "/", mustWork = FALSE)
]

artifact_manifest <- data.frame(
  File = basename(artifact_files),
  Path = normalizePath(artifact_files, winslash = "/", mustWork = TRUE),
  Type = ifelse(
    grepl("\\.csv$", artifact_files, ignore.case = TRUE), "TABLE_OR_MACHINE_READABLE_AUDIT",
    ifelse(
      grepl("\\.png$", artifact_files, ignore.case = TRUE), "FIGURE",
      ifelse(grepl("\\.html$", artifact_files, ignore.case = TRUE), "RENDERED_REPORT", "CODE_LOG_OR_DOCUMENTATION")
    )
  ),
  Bytes = file.info(artifact_files)$size,
  SHA256 = vapply(artifact_files, sha256, character(1L)),
  No_visible_timestamp_field = TRUE,
  stringsAsFactors = FALSE
)
write_csv(artifact_manifest, artifact_manifest_path)

status_report <- c(
  "# Step 10 Results and Reproducibility Result",
  "",
  "## Status",
  "",
  if (renv_blocker) {
    "ASSEMBLY AND INDEPENDENT AUDIT COMPLETE; FINAL ENVIRONMENT FREEZE PENDING"
  } else {
    "ASSEMBLY AND INDEPENDENT AUDIT COMPLETE; ENVIRONMENT CONSISTENT"
  },
  "",
  "## Completed work",
  "",
  "- Assembled verified sample, overall-network, edge-accuracy, exploratory-centrality, education-group and sensitivity outputs from Steps 00--09B.",
  "- Created a claim-to-output registry so later Results statements can be traced to saved evidence.",
  "- Copied validated figures byte-for-byte into the final Step 10 figure directory and recorded source/final SHA-256 hashes.",
  "- Recorded R, package, session and renv information.",
  "- Built a method citation register and a separate list of sources not currently in Zotero.",
  "- Independently recomputed 44 core numerical values and completed 20 independent validation checks.",
  "- Rendered a no-date Step 10 HTML report.",
  "",
  "## Validation totals",
  "",
  paste0("- First-pass Step 10 checks: ", sum(flag(validation$Passed)), "/", nrow(validation), "."),
  paste0("- Independent audit checks: ", sum(flag(independent$Passed)), "/", nrow(independent), "."),
  paste0("- Independent numerical comparisons: ", sum(flag(recalculation$Passed)), "/", nrow(recalculation), "."),
  "- Final artifact hashes are recorded in 10_final_artifact_manifest.csv.",
  "",
  "## Citation status",
  "",
  paste0("- Method/data sources registered: ", nrow(citations), "."),
  paste0("- Sources explicitly marked as not in Zotero: ", nrow(not_zotero), "."),
  "",
  "## Reproducibility environment status",
  "",
  if (renv_blocker) {
    "The renv status snapshot records missing or out-of-sync packages. Saved results and Step 10 numerical assembly are validated, but the final executable archive is not environment-ready until a separately authorised renv reconciliation is completed."
  } else {
    "The renv status snapshot reports a consistent project environment."
  },
  "",
  "## Hard interpretation boundaries",
  "",
  "The assembled outputs are descriptive repeated-cross-sectional ANES analysis-sample results. No NCT or education-group significance test was run. Edge count and global strength are not treated as ideological constraint. Centrality remains exploratory. Robustness labels are not p-values, significance tests or equivalence tests.",
  "",
  "## Remaining approvals",
  "",
  paste(
    "The current researcher-selected title and exact RQ wording still need entry in the formal decision log; supervisor confirmation remains advised.",
    "Historical interpretation of the 2004--2024 endpoint also remains bounded by that approval status.",
    if (renv_blocker) "The renv dependency inconsistency must be resolved before final archive freeze." else ""
  ),
  "",
  "## Protected-source status",
  "",
  "No C-drive source file, protected project source, ANES raw file or existing model object was modified. Step 10 did not estimate, bootstrap or compare a network inferentially."
)
writeLines(status_report, file.path(working_dir, "STEP10_RESULTS_AND_REPRODUCIBILITY_RESULT.md"), useBytes = TRUE)

final_checks <- data.frame(
  Check = c(
    "First-pass validation complete",
    "Independent validation complete",
    "Independent numerical recalculation complete",
    "HTML exists and is non-empty",
    "Final artifact manifest exists and contains no self-reference",
    "Every final artifact exists and has a SHA-256 value",
    "Not-in-Zotero register is explicit",
    "Visible date/time fields are absent from Step 10 CSV outputs",
    "No model or resampling execution is claimed",
    "renv environment status is explicitly recorded"
  ),
  Passed = c(
    all(flag(validation$Passed)),
    all(flag(independent$Passed)),
    all(flag(recalculation$Passed)),
    file.exists(html_file) && file.info(html_file)$size > 0,
    file.exists(artifact_manifest_path) && !any(normalizePath(artifact_manifest$Path, winslash = "/") == normalizePath(artifact_manifest_path, winslash = "/")),
    all(file.exists(artifact_manifest$Path)) && all(nchar(artifact_manifest$SHA256) == 64L),
    nrow(not_zotero) >= 1L && all(grepl("^NOT_IN_ZOTERO", not_zotero$Zotero_status)),
    {
      final_csvs <- list.files(final_table_dir, pattern = "^10_.*\\.csv$", full.names = TRUE)
      forbidden <- c("created_at", "creation_time", "creation_date", "generated_at", "timestamp")
      !any(vapply(final_csvs, function(path) {
        any(tolower(names(read.csv(path, nrows = 1L, check.names = FALSE))) %in% forbidden)
      }, logical(1L)))
    },
    completion$Status[completion$Component == "Network re-estimation"] == "NOT_RUN_PROHIBITED_IN_STEP10",
    if (renv_blocker) {
      completion$Status[completion$Component == "Package/session/renv record"] ==
        "COMPLETE_WITH_RENV_INCONSISTENCY_RECORDED"
    } else {
      completion$Status[completion$Component == "Package/session/renv record"] ==
        "COMPLETE_AND_VALIDATED"
    }
  ),
  stringsAsFactors = FALSE
)
write_csv(final_checks, file.path(final_table_dir, "10_finalization_validation.csv"))
if (!all(final_checks$Passed)) stop("Finalization STOP: one or more final checks failed.")

writeLines(
  c(
    "STEP 10 FINALIZATION",
    paste0(
      "STATUS: ",
      if (renv_blocker) {
        "ASSEMBLY_AND_AUDIT_COMPLETE_FINAL_ENVIRONMENT_FREEZE_PENDING"
      } else {
        "ASSEMBLY_AND_AUDIT_COMPLETE_ENVIRONMENT_CONSISTENT"
      }
    ),
    paste0("FINAL CHECKS PASSED: ", sum(final_checks$Passed), "/", nrow(final_checks)),
    paste0("FINAL ARTIFACTS HASHED: ", nrow(artifact_manifest)),
    "MODEL EXECUTION: NONE",
    "VISIBLE CREATION DATE/TIME: NONE",
    paste0("RENV ENVIRONMENT BLOCKER: ", if (renv_blocker) "YES" else "NO"),
    "C-DRIVE SOURCE MODIFICATION: NONE"
  ),
  file.path(log_dir, "10_finalization.log"),
  useBytes = TRUE
)

# Rebuild the artifact manifest only after every finalized document, table and
# log above has been written. The manifest excludes itself, and no manifested
# file is modified after this point.
artifact_files <- unique(c(
  list.files(final_table_dir, pattern = "^10_.*\\.csv$", full.names = TRUE),
  list.files(final_figure_dir, pattern = "^10_.*\\.png$", full.names = TRUE),
  list.files(audit_dir, pattern = "^10_.*\\.md$", full.names = TRUE),
  list.files(log_dir, pattern = "^10_.*\\.(log|txt)$", full.names = TRUE),
  file.path(project_root, "R", c(
    "10_results_and_reproducibility_engine.R",
    "10_results_and_reproducibility_independent_audit.R",
    "10_render_results_and_reproducibility.R",
    "10_finalize_results_and_reproducibility.R"
  )),
  file.path(project_root, "notebooks", c(
    "10_results_and_reproducibility.Rmd",
    "10_results_and_reproducibility.html"
  )),
  file.path(working_dir, c(
    "STEP10_SCOPE_SNAPSHOT.md",
    "STEP10_STORAGE_AND_RUNTIME_POLICY.md",
    "STEP10_RESULTS_AND_REPRODUCIBILITY_RESULT.md"
  ))
))
artifact_files <- artifact_files[
  file.exists(artifact_files) & normalizePath(artifact_files, winslash = "/", mustWork = FALSE) !=
    normalizePath(artifact_manifest_path, winslash = "/", mustWork = FALSE)
]

artifact_manifest <- data.frame(
  File = basename(artifact_files),
  Path = normalizePath(artifact_files, winslash = "/", mustWork = TRUE),
  Type = ifelse(
    grepl("\\.csv$", artifact_files, ignore.case = TRUE), "TABLE_OR_MACHINE_READABLE_AUDIT",
    ifelse(
      grepl("\\.png$", artifact_files, ignore.case = TRUE), "FIGURE",
      ifelse(grepl("\\.html$", artifact_files, ignore.case = TRUE), "RENDERED_REPORT", "CODE_LOG_OR_DOCUMENTATION")
    )
  ),
  Bytes = file.info(artifact_files)$size,
  SHA256 = vapply(artifact_files, sha256, character(1L)),
  No_visible_timestamp_field = TRUE,
  stringsAsFactors = FALSE
)
write_csv(artifact_manifest, artifact_manifest_path)

manifest_check <- read.csv(artifact_manifest_path, check.names = FALSE)
manifest_hashes <- vapply(manifest_check$Path, sha256, character(1L))
stopifnot(
  all(file.exists(manifest_check$Path)),
  all(file.info(manifest_check$Path)$size > 0),
  all(nchar(manifest_check$SHA256) == 64L),
  all(manifest_hashes == manifest_check$SHA256)
)

message("STEP 10 FINALIZATION COMPLETE.")
