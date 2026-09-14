#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
project_root <- if (length(args) >= 1L) args[[1L]] else getwd()
project_root <- normalizePath(project_root, winslash = "/", mustWork = TRUE)

project_library <- renv::paths$library(project = project_root)
.libPaths(c(project_library, .libPaths()))

bit64_loaded <- requireNamespace("bit64", quietly = TRUE)
data_table_loaded <- requireNamespace("data.table", quietly = TRUE)
bit64_operation <- bit64_loaded && identical(
  as.character(bit64::as.integer64(c("1", "2")) + 1),
  c("2", "3")
)
data_table_operation <- FALSE
if (data_table_loaded) {
  test_table <- data.table::data.table(x = c(1, 2), y = c(3, 4))
  data_table_operation <- identical(test_table[, sum(x + y)], 10)
}

status_after <- renv::status(project = project_root, sources = FALSE)
status_synchronised <- isTRUE(status_after$synchronized)

lock <- renv::lockfile_read(file.path(project_root, "renv.lock"))
locked_names <- names(lock$Packages)
installed <- installed.packages(lib.loc = .libPaths())
installed_names <- rownames(installed)
missing_locked <- setdiff(locked_names, installed_names)
common <- intersect(locked_names, installed_names)
locked_versions <- vapply(
  common,
  function(package) as.character(lock$Packages[[package]]$Version),
  character(1L)
)
version_mismatches <- common[locked_versions != installed[common, "Version"]]

validation <- data.frame(
  Check = c(
    "D-drive renv root configured",
    "D-drive renv sandbox configured",
    "bit64 loads and completes a minimal operation",
    "data.table loads and completes a minimal operation",
    "Every locked package is available on the active library paths",
    "Every installed locked-package version matches",
    "renv status reports synchronized"
  ),
  Passed = c(
    identical(Sys.getenv("RENV_PATHS_ROOT"), "D:/ANES_code/renv_global"),
    identical(Sys.getenv("RENV_PATHS_SANDBOX"), "D:/ANES_code/renv_global/sandbox"),
    bit64_loaded && bit64_operation,
    data_table_loaded && data_table_operation,
    length(missing_locked) == 0L,
    length(version_mismatches) == 0L,
    status_synchronised
  ),
  Detail = c(
    Sys.getenv("RENV_PATHS_ROOT"),
    Sys.getenv("RENV_PATHS_SANDBOX"),
    if (bit64_loaded) paste0(utils::packageVersion("bit64"), "; operation=", bit64_operation) else "not loadable",
    if (data_table_loaded) paste0(utils::packageVersion("data.table"), "; operation=", data_table_operation) else "not loadable",
    if (length(missing_locked)) paste(missing_locked, collapse = "; ") else paste0(length(locked_names), " locked packages installed"),
    if (length(version_mismatches)) paste(version_mismatches, collapse = "; ") else paste0(length(common), " versions match"),
    as.character(status_synchronised)
  ),
  stringsAsFactors = FALSE
)

output_dir <- file.path(project_root, "outputs", "tables", "final")
log_dir <- file.path(project_root, "outputs", "logs")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)

write.csv(
  validation,
  file.path(output_dir, "renv_submission_sync_validation.csv"),
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)
writeLines(
  c(
    "RENV SUBMISSION ENVIRONMENT VALIDATION",
    paste0("Project: ", project_root),
    paste0("renv root: ", Sys.getenv("RENV_PATHS_ROOT")),
    paste0("renv sandbox: ", Sys.getenv("RENV_PATHS_SANDBOX")),
    paste0("Locked package records: ", length(locked_names)),
    paste0("Missing locked packages: ", length(missing_locked)),
    paste0("Locked-version mismatches: ", length(version_mismatches)),
    paste0("renv synchronized: ", status_synchronised),
    "This validation confirms lockfile and active project-library synchronization.",
    "The separate clean-library replay is documented independently."
  ),
  file.path(log_dir, "renv_submission_sync.log"),
  useBytes = TRUE
)

print(validation)
stopifnot(all(validation$Passed))
