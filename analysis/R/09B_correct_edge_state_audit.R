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
erp_root <- project_root
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
  project_root, "outputs", "archive", "09B_pre_independent_audit_correction"
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
state_matches <- function(primary_weight, sensitivity_weight) {
  stopifnot(length(primary_weight) == 1L)
  if (primary_weight == 0) {
    return(sensitivity_weight == 0)
  }
  if (primary_weight > 0) {
    return(sensitivity_weight > 0)
  }
  sensitivity_weight < 0
}

results <- readRDS(file.path(model_dir, "09B_equalN_results.rds"))
claims_registry <- read.csv(
  file.path(
    erp_root, "project_docs", "decisions", "step09b_primary_claim_registry.csv"
  ),
  check.names = FALSE
)
edge_summary_old <- read_table("09B_equalN_edge_summary.csv")
a1_edge <- read_table("09B_fullN_threshold_edge_comparison.csv")
network_summary <- read_table("09B_equalN_network_summary.csv")
contrast_summary <- read_table("09B_contrast_robustness.csv")
completion <- read_table("09B_completion_status.csv")

stopifnot(
  nrow(claims_registry) == 205L,
  nrow(edge_summary_old) == 360L,
  nrow(a1_edge) == 180L,
  all(vapply(
    results$edge_weights,
    function(x) identical(dim(x), c(1000L, 36L, 5L)),
    logical(1)
  ))
)

edge_summary_new <- edge_summary_old
for (i in seq_len(nrow(edge_summary_new))) {
  arm <- edge_summary_new$Arm_ID[i]
  wave <- as.character(edge_summary_new$Wave[i])
  edge <- edge_summary_new$Edge_ID[i]
  edge_number <- match(edge, dimnames(results$edge_weights[[arm]])[[2]])
  values <- results$edge_weights[[arm]][, edge_number, wave]
  values <- values[is.finite(values)]
  edge_summary_new$Primary_state_match_proportion[i] <- mean(state_matches(
    edge_summary_new$Primary_edge_weight[i],
    values
  ))
}

unchanged_columns <- setdiff(
  names(edge_summary_old),
  "Primary_state_match_proportion"
)
unchanged_numeric <- vapply(
  unchanged_columns,
  function(column) {
    x <- edge_summary_old[[column]]
    y <- edge_summary_new[[column]]
    if (is.numeric(x)) {
      all((is.na(x) & is.na(y)) | abs(x - y) <= 1e-12, na.rm = TRUE)
    } else {
      identical(x, y)
    }
  },
  logical(1)
)

changed_state_rows <- sum(
  abs(
    edge_summary_old$Primary_state_match_proportion -
      edge_summary_new$Primary_state_match_proportion
  ) > 1e-12
)

success_threshold <- 0.95
claim_rows <- vector("list", nrow(claims_registry))
for (i in seq_len(nrow(claims_registry))) {
  claim <- claims_registry[i, , drop = FALSE]
  if (claim$Claim_type == "EDGE_SIGN_AND_RETENTION") {
    edge_id <- paste(claim$Node_1, claim$Node_2, sep = "--")
    a1 <- a1_edge[
      a1_edge$Wave == claim$Wave & a1_edge$Edge_ID == edge_id,
      , drop = FALSE
    ]
    a2 <- edge_summary_new[
      edge_summary_new$Arm_ID == "A2" &
        edge_summary_new$Wave == claim$Wave &
        edge_summary_new$Edge_ID == edge_id,
      , drop = FALSE
    ]
    a3 <- edge_summary_new[
      edge_summary_new$Arm_ID == "A3" &
        edge_summary_new$Wave == claim$Wave &
        edge_summary_new$Edge_ID == edge_id,
      , drop = FALSE
    ]
    evaluable <- nrow(a1) == 1L && nrow(a2) == 1L && nrow(a3) == 1L &&
      a2$Success_rate >= success_threshold && a3$Success_rate >= success_threshold
    minimum_match <- if (evaluable) min(
      as.numeric(a1$State_matches_primary),
      a2$Primary_state_match_proportion,
      a3$Primary_state_match_proportion
    ) else NA_real_
    final_status <- if (!evaluable) {
      "NOT_EVALUABLE"
    } else if (!isTRUE(a1$State_matches_primary)) {
      "NOT_ROBUST"
    } else if (minimum_match >= 0.90) {
      "ROBUST"
    } else if (minimum_match >= 0.75) {
      "MIXED"
    } else {
      "NOT_ROBUST"
    }
    claim_rows[[i]] <- data.frame(
      Claim_ID = claim$Claim_ID,
      Claim_type = claim$Claim_type,
      Wave = claim$Wave,
      Earlier_wave = NA_integer_,
      Later_wave = NA_integer_,
      Metric = claim$Metric,
      A1_match = a1$State_matches_primary,
      A2_match_proportion = a2$Primary_state_match_proportion,
      A3_match_proportion = a3$Primary_state_match_proportion,
      Minimum_match = minimum_match,
      Final_status = final_status,
      Interpretation = "MECHANICAL_EDGE_STATE_AUDIT_NOT_SIGNIFICANCE",
      stringsAsFactors = FALSE
    )
  } else if (claim$Claim_type == "WAVE_NETWORK_DESCRIPTOR") {
    a2 <- network_summary[
      network_summary$Arm_ID == "A2" & network_summary$Wave == claim$Wave,
      , drop = FALSE
    ]
    a3 <- network_summary[
      network_summary$Arm_ID == "A3" & network_summary$Wave == claim$Wave,
      , drop = FALSE
    ]
    metric_column <- switch(
      claim$Metric,
      Retained_edges = "Median_retained_edges",
      Density = "Median_density",
      Global_strength = "Median_global_strength"
    )
    claim_rows[[i]] <- data.frame(
      Claim_ID = claim$Claim_ID,
      Claim_type = claim$Claim_type,
      Wave = claim$Wave,
      Earlier_wave = NA_integer_,
      Later_wave = NA_integer_,
      Metric = claim$Metric,
      A1_match = NA,
      A2_match_proportion = as.numeric(a2[[metric_column]]),
      A3_match_proportion = as.numeric(a3[[metric_column]]),
      Minimum_match = NA_real_,
      Final_status = "DESCRIPTIVE_AUDIT_COMPLETE",
      Interpretation = "A2_AND_A3_COLUMNS_STORE_MEDIANS_NOT_MATCH_PROPORTIONS",
      stringsAsFactors = FALSE
    )
  } else {
    rows <- contrast_summary[
      contrast_summary$Earlier_wave == claim$Earlier_wave &
        contrast_summary$Later_wave == claim$Later_wave &
        contrast_summary$Metric == claim$Metric,
      , drop = FALSE
    ]
    a1 <- rows[rows$Arm_ID == "A1", , drop = FALSE]
    a2 <- rows[rows$Arm_ID == "A2", , drop = FALSE]
    a3 <- rows[rows$Arm_ID == "A3", , drop = FALSE]
    evaluable <- nrow(a1) == 1L && nrow(a2) == 1L && nrow(a3) == 1L &&
      a2$Successful_pairs >= 950L && a3$Successful_pairs >= 950L
    minimum_match <- if (evaluable) min(
      a1$Direction_match_proportion,
      a2$Direction_match_proportion,
      a3$Direction_match_proportion
    ) else NA_real_
    final_status <- if (!evaluable) {
      "NOT_EVALUABLE"
    } else if (a1$Direction_match_proportion < 1) {
      "NOT_ROBUST"
    } else if (minimum_match >= 0.90) {
      "ROBUST"
    } else if (minimum_match >= 0.75) {
      "MIXED"
    } else {
      "NOT_ROBUST"
    }
    claim_rows[[i]] <- data.frame(
      Claim_ID = claim$Claim_ID,
      Claim_type = claim$Claim_type,
      Wave = NA_integer_,
      Earlier_wave = claim$Earlier_wave,
      Later_wave = claim$Later_wave,
      Metric = claim$Metric,
      A1_match = a1$Direction_match_proportion == 1,
      A2_match_proportion = a2$Direction_match_proportion,
      A3_match_proportion = a3$Direction_match_proportion,
      Minimum_match = minimum_match,
      Final_status = final_status,
      Interpretation = "DIRECTION_REPRODUCIBILITY_NOT_SIGNIFICANCE_OR_EQUIVALENCE",
      stringsAsFactors = FALSE
    )
  }
}

claims_new <- do.call(rbind, claim_rows)
claim_summary_new <- as.data.frame(with(
  claims_new,
  table(Claim_type, Final_status, useNA = "ifany")
))
names(claim_summary_new) <- c("Claim_type", "Final_status", "Count")
claim_summary_new <- claim_summary_new[
  claim_summary_new$Count > 0L,
  , drop = FALSE
]

correction_validation <- data.frame(
  Check = c(
    "Archived pre-correction outputs exist",
    "Saved model arrays were reused without re-estimation",
    "Only primary-state match proportions changed in the edge summary",
    "At least one incorrect scalar match value was corrected",
    "Corrected edge summary contains 360 unique arm-wave-edge rows",
    "Corrected claim audit contains 205 unique claims",
    "No claim is not evaluable",
    "Contrast and network-descriptor classifications were preserved"
  ),
  Passed = c(
    all(file.exists(file.path(archive_dir, c(
      "09B_equalN_edge_summary.csv",
      "09B_claim_robustness.csv",
      "09B_claim_robustness_summary.csv",
      "09B_completion_status.csv",
      "09B_output_hash_inventory.csv",
      "09B_specificity_sample_size_sensitivity_engine.R"
    )))),
    TRUE,
    all(unchanged_numeric),
    changed_state_rows > 0L,
    nrow(edge_summary_new) == 360L && !anyDuplicated(paste(
      edge_summary_new$Arm_ID,
      edge_summary_new$Wave,
      edge_summary_new$Edge_ID
    )),
    nrow(claims_new) == 205L && !anyDuplicated(claims_new$Claim_ID),
    !any(claims_new$Final_status == "NOT_EVALUABLE"),
    all(
      claims_new$Final_status[claims_new$Claim_type != "EDGE_SIGN_AND_RETENTION"] ==
        read_table("09B_claim_robustness.csv")$Final_status[
          read_table("09B_claim_robustness.csv")$Claim_type != "EDGE_SIGN_AND_RETENTION"
        ]
    )
  ),
  stringsAsFactors = FALSE
)

stopifnot(all(correction_validation$Passed))

write_table(edge_summary_new, "09B_equalN_edge_summary.csv")
write_table(claims_new, "09B_claim_robustness.csv")
write_table(claim_summary_new, "09B_claim_robustness_summary.csv")
write_table(correction_validation, "09B_correction_validation.csv")

completion <- rbind(
  completion,
  data.frame(
    Check = "Independent audit correction of vectorised edge-state matching passed",
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
    "055 | Independent audit identified scalar edge-state matching in derived summaries",
    "056 | Derived summaries corrected from saved RDS arrays; no model was re-estimated"
  ),
  run_log,
  useBytes = TRUE
)

base_output_files <- c(
  list.files(
    table_dir,
    pattern = "^09B_",
    full.names = TRUE
  ),
  list.files(
    model_dir,
    pattern = "^09B_",
    full.names = TRUE
  ),
  file.path(log_dir, c("09B_run.log", "09B_sessionInfo.txt"))
)
base_output_files <- base_output_files[
  !grepl("^09B_(output_hash_inventory|independent_|correction_)", basename(base_output_files))
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

cat("STEP09B_DERIVED_SUMMARIES_CORRECTED_WITHOUT_MODEL_RERUN\n")
