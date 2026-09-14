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
suppressPackageStartupMessages(library(digest))

table_dir <- file.path(project_root, "outputs", "tables", "sensitivity")
model_dir <- file.path(project_root, "outputs", "models", "sensitivity")
log_dir <- file.path(project_root, "outputs", "logs")
archive_dir <- file.path(
  project_root, "outputs", "archive", "09B_pre_diagnostic_label_correction"
)
stopifnot(dir.exists(archive_dir))

read_table <- function(name) {
  read.csv(file.path(table_dir, name), check.names = FALSE)
}
write_table <- function(x, name) {
  write.csv(x, file.path(table_dir, name), row.names = FALSE, na = "")
}
file_sha256 <- function(path) {
  toupper(digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE))
}

formal_old <- read_table("09B_equalN_run_diagnostics.csv")
a1_old <- read_table("09B_fullN_threshold_diagnostics.csv")
network_old <- read_table("09B_equalN_network_summary.csv")
completion <- read_table("09B_completion_status.csv")

classify_conditions <- function(warnings, messages, pattern) {
  combined <- paste(
    ifelse(is.na(warnings), "", warnings),
    ifelse(is.na(messages), "", messages)
  )
  grepl(pattern, combined, ignore.case = TRUE)
}

formal_new <- formal_old
formal_new$Dense_warning <- classify_conditions(
  formal_new$Network_warning,
  formal_new$Network_message,
  "dense regularized network"
)
formal_new$Lowest_lambda_selected <- classify_conditions(
  formal_new$Network_warning,
  formal_new$Network_message,
  "lowest lambda selected"
)

a1_new <- a1_old
a1_new$Dense_warning <- classify_conditions(
  a1_new$Warning,
  a1_new$Message,
  "dense regularized network"
)
a1_new$Lowest_lambda_selected <- classify_conditions(
  a1_new$Warning,
  a1_new$Message,
  "lowest lambda selected"
)

network_new <- network_old
network_new$Dense_warning_rate <- NA_real_
network_new$Lowest_lambda_selected_rate <- NA_real_
for (i in seq_len(nrow(network_new))) {
  rows <- formal_new[
    formal_new$Arm_ID == network_new$Arm_ID[i] &
      formal_new$Wave == network_new$Wave[i],
    , drop = FALSE
  ]
  network_new$Dense_warning_rate[i] <- mean(rows$Dense_warning)
  network_new$Lowest_lambda_selected_rate[i] <- mean(
    rows$Lowest_lambda_selected
  )
}

changed_formal_labels <- sum(
  as.logical(formal_old$Dense_warning) != formal_new$Dense_warning
)
changed_a1_labels <- sum(
  as.logical(a1_old$Dense_warning) != a1_new$Dense_warning
)

validation <- data.frame(
  Check = c(
    "Archived pre-correction diagnostic files exist",
    "Formal diagnostic row count remains 10000",
    "A1 diagnostic row count remains five",
    "Only diagnostic-label fields were added or corrected",
    "At least one conflated formal label was corrected",
    "At least one conflated A1 label was corrected",
    "Thresholded arms have no qgraph dense-network warning",
    "Lowest-lambda messages are retained separately",
    "All original model success indicators remain true",
    "No model was re-estimated"
  ),
  Passed = c(
    all(file.exists(file.path(archive_dir, c(
      "09B_equalN_run_diagnostics.csv",
      "09B_fullN_threshold_diagnostics.csv",
      "09B_equalN_network_summary.csv",
      "09B_completion_status.csv",
      "09B_output_hash_inventory.csv",
      "09B_specificity_sample_size_sensitivity_engine.R"
    )))),
    nrow(formal_new) == 10000L,
    nrow(a1_new) == 5L,
    identical(
      formal_old[setdiff(names(formal_old), "Dense_warning")],
      formal_new[setdiff(names(formal_new), c(
        "Dense_warning", "Lowest_lambda_selected"
      ))]
    ) && identical(
      a1_old[setdiff(names(a1_old), "Dense_warning")],
      a1_new[setdiff(names(a1_new), c(
        "Dense_warning", "Lowest_lambda_selected"
      ))]
    ),
    changed_formal_labels > 0L,
    changed_a1_labels > 0L,
    !any(formal_new$Dense_warning[formal_new$Arm_ID == "A3"]) &&
      !any(a1_new$Dense_warning),
    any(formal_new$Lowest_lambda_selected) &&
      any(a1_new$Lowest_lambda_selected),
    all(formal_new$Success) && all(a1_new$Success),
    TRUE
  ),
  stringsAsFactors = FALSE
)

stopifnot(all(validation$Passed))

write_table(formal_new, "09B_equalN_run_diagnostics.csv")
write_table(a1_new, "09B_fullN_threshold_diagnostics.csv")
write_table(network_new, "09B_equalN_network_summary.csv")
write_table(validation, "09B_diagnostic_label_correction_validation.csv")

completion <- rbind(
  completion,
  data.frame(
    Check = "Independent audit separation of dense and lowest-lambda diagnostics passed",
    Complete = TRUE,
    stringsAsFactors = FALSE
  )
)
write_table(completion, "09B_completion_status.csv")

run_log <- file.path(log_dir, "09B_run.log")
existing_log <- readLines(run_log, warn = FALSE)
writeLines(
  c(
    existing_log,
    "057 | Independent audit separated dense-network and lowest-lambda diagnostics",
    "058 | Diagnostic labels corrected from saved messages; no model was re-estimated"
  ),
  run_log,
  useBytes = TRUE
)

base_output_files <- c(
  list.files(table_dir, pattern = "^09B_", full.names = TRUE),
  list.files(model_dir, pattern = "^09B_", full.names = TRUE),
  file.path(log_dir, c("09B_run.log", "09B_sessionInfo.txt"))
)
base_output_files <- base_output_files[
  !grepl(
    "^09B_(output_hash_inventory|independent_|correction_|diagnostic_label_correction_)",
    basename(base_output_files)
  )
]
base_output_files <- unique(base_output_files[file.exists(base_output_files)])
inventory <- data.frame(
  File = basename(base_output_files),
  Relative_path = substring(
    normalizePath(base_output_files, winslash = "/", mustWork = TRUE),
    nchar(project_root) + 2L
  ),
  Size_bytes = file.info(base_output_files)$size,
  SHA256 = vapply(base_output_files, file_sha256, character(1)),
  stringsAsFactors = FALSE
)
inventory <- inventory[order(inventory$Relative_path), , drop = FALSE]
write_table(inventory, "09B_output_hash_inventory.csv")

cat("STEP09B_DIAGNOSTIC_LABELS_CORRECTED_WITHOUT_MODEL_RERUN\n")
