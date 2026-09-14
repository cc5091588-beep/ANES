# Retrospective candidate-pool completeness audit
# IMPORTANT: This is a post-hoc provenance repair. It does not claim that the
# rules below were the original or preregistered candidate-selection rules.

options(stringsAsFactors = FALSE)

find_project_root <- function(start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (file.exists(file.path(current, "ANES.Rproj"))) return(current)
    parent <- dirname(current)
    if (identical(parent, current)) stop("Cannot locate ANES.Rproj")
    current <- parent
  }
}

args <- commandArgs(trailingOnly = TRUE)
project_root <- Sys.getenv("ANES_PROJECT_ROOT", unset = "")
if (!nzchar(project_root)) project_root <- find_project_root()
project_root <- normalizePath(project_root, winslash = "/", mustWork = TRUE)

input_file <- if (length(args) >= 1L && nzchar(args[[1L]])) {
  args[[1L]]
} else {
  Sys.getenv("ANES_CDF_DTA", unset = "")
}
if (!nzchar(input_file)) {
  stop(
    "Provide the authorised CDF .dta as the first command-line argument or ",
    "set ANES_CDF_DTA. The respondent-level CDF is not distributed in this module."
  )
}
input_file <- normalizePath(input_file, winslash = "/", mustWork = TRUE)

output_dir <- if (length(args) >= 2L && nzchar(args[[2L]])) {
  args[[2L]]
} else {
  file.path(
    project_root, "outputs", "tables", "supplement", "node_wave_selection",
    "retrospective_candidate_audit"
  )
}
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

stopifnot(file.exists(input_file))
stopifnot(requireNamespace("haven", quietly = TRUE))
stopifnot(requireNamespace("tidyselect", quietly = TRUE))

meta <- haven::read_dta(input_file, n_max = 0)
variable_names <- names(meta)
variable_labels <- vapply(
  meta,
  function(x) {
    label <- attr(x, "label")
    if (is.null(label)) "" else as.character(label)
  },
  character(1)
)
stopifnot(length(variable_names) == 1030L)

# Stage A: deliberately broad and over-inclusive policy/attitude label retrieval.
# Terms cover direct policy preferences, normative political attitudes, and policy-
# related beliefs. Identity/religion boundary variables are handled separately.
include_pattern <- paste0(
  "(government (assistance|health|services|ensure|should|cut|too strong|do more|handle)|",
  "guaranteed jobs|civil rights|segregation|desegregation|school busing|open housing|",
  "aid to blacks|aid to black|rights of the accused|equal rights amendment|women equal role|",
  "women stay out|abortion|term limits|cooperation with u\\.s\\.s\\.r|",
  "environmental regulation|defen[cs]e spending|military spending|use military force|",
  "moral behavior|traditional values|moral standards|affirmative action|",
  "law to protect homosexual|gays|lesbians|immigrants|immigration|federal spending|",
  "equal opportunity|equal chance|more chance|how equal people|treated equally|fair jobs for blacks|",
  "conditions make it difficult for blacks|special favors|blacks must try harder|",
  "blacks gotten less|school prayer|less government|free market|government too involved|",
  "govt handle|govt too involved|federal government encourage|",
  "placing limits on imports|tortur|death penalty|buy a gun|",
  "unconcerned with rest of world|getting involved in war|proceed in current war)"
)

# Exclude labels that concern political actors' positions, affect/evaluations, or
# issue salience rather than the respondent's own policy attitude/belief.
exclude_pattern <- paste0(
  "(thermometer|democratic|republican|president|candidate|which party|party would|",
  "federal government on|incumbent|challenger|how important|importance of|",
  "performance|job has the government done|issue placement for)"
)

stage_a_hit <- grepl(include_pattern, variable_labels, ignore.case = TRUE) &
  !grepl(exclude_pattern, variable_labels, ignore.case = TRUE)

all_fields <- data.frame(
  variable = variable_names,
  label = unname(variable_labels),
  broad_policy_label_hit = stage_a_hit,
  stringsAsFactors = FALSE
)

broad_hits <- all_fields[all_fields$broad_policy_label_hit, c("variable", "label")]
stopifnot(nrow(broad_hits) == 80L)

# Stage B: provisional raw five-wave screen. This is not a measurement-
# comparability decision. It only checks whether each broad hit has at least one
# provisional substantive response and at least two provisional substantive
# categories in every final wave.
final_years <- c(2004L, 2012L, 2016L, 2020L, 2024L)
analysis_data <- haven::read_dta(
  input_file,
  col_select = tidyselect::all_of(c("VCF0004", broad_hits$variable))
)

missing_label_pattern <- paste0(
  "(^|[; .])NA([; .]|$)|DK|don't know|inap|no post|no pre|refus|",
  "no opinion|not sure|depends|other|haven't thought|not ascertained|not asked|",
  "no interest|no data|programming error|half sample administration"
)

screen_rows <- vector("list", length(broad_hits$variable) * length(final_years))
row_index <- 0L
for (variable in broad_hits$variable) {
  value_labels <- attr(analysis_data[[variable]], "labels")
  labelled_admin_values <- if (is.null(value_labels)) {
    numeric(0)
  } else {
    unname(value_labels[
      grepl(missing_label_pattern, names(value_labels), ignore.case = TRUE)
    ])
  }

  # -1 is explicitly excluded because it is an official structural-inapplicable
  # value for affected 2024 fields but is absent from parts of the CDF labels.
  administrative_values <- unique(c(labelled_admin_values, -1))

  for (year in final_years) {
    row_index <- row_index + 1L
    values <- as.numeric(analysis_data[[variable]][analysis_data$VCF0004 == year])
    substantive <- !is.na(values) & !(values %in% administrative_values)
    substantive_values <- sort(unique(values[substantive]))
    screen_rows[[row_index]] <- data.frame(
      variable = variable,
      label = variable_labels[[variable]],
      year = year,
      provisional_substantive_n = sum(substantive),
      provisional_category_count = length(substantive_values),
      provisional_values = paste(substantive_values, collapse = "|"),
      stringsAsFactors = FALSE
    )
  }
}
five_wave_long <- do.call(rbind, screen_rows)

minimums <- aggregate(
  cbind(provisional_substantive_n, provisional_category_count) ~ variable + label,
  data = five_wave_long,
  FUN = min
)
names(minimums)[3:4] <- c(
  "minimum_provisional_substantive_n",
  "minimum_provisional_category_count"
)
minimums$passes_provisional_five_wave_gate <-
  minimums$minimum_provisional_substantive_n > 0L &
  minimums$minimum_provisional_category_count >= 2L

recorded_16 <- c(
  "VCF0806", "VCF0809", "VCF0830", "VCF0838", "VCF0839", "VCF0843",
  "VCF0879a", "VCF0888", "VCF0890", "VCF0894", "VCF9047", "VCF9049",
  "VCF9223", "VCF0301", "VCF0803", "VCF0846"
)
minimums$in_recorded_16 <- minimums$variable %in% recorded_16
provisional_survivors <- minimums[
  minimums$passes_provisional_five_wave_gate,
  c(
    "variable", "label", "minimum_provisional_substantive_n",
    "minimum_provisional_category_count", "in_recorded_16"
  )
]
provisional_survivors <- provisional_survivors[order(provisional_survivors$variable), ]
stopifnot(nrow(provisional_survivors) == 32L)

# Context for the 21 provisional survivors outside the recorded pool. These
# labels explain how the fields relate to the now-frozen bounded estimand; they
# are not reconstructed historical exclusion reasons or final eligibility tests.
alternative_representation <- c("VCF0867", "VCF0867a", "VCF0876", "VCF0876a", "VCF0879")
outside_three_domain_scope <- c("VCF0823", "VCF0878", "VCF9231", "VCF9236")
values_broaden_estimand <- c(
  "VCF0852", "VCF0853", "VCF9013", "VCF9016", "VCF9017", "VCF9018",
  "VCF9039", "VCF9040", "VCF9041", "VCF9042"
)
overlap_parsimony_alternative <- c("VCF0886", "VCF9131")

provisional_survivors$retrospective_context <- ifelse(
  provisional_survivors$in_recorded_16,
  "RECORDED_16_ITEM_POOL_SEE_FINAL_DISPOSITION",
  ifelse(
    provisional_survivors$variable %in% alternative_representation,
    "ALTERNATIVE_OR_STRENGTH_REPRESENTATION_OF_SAME_CONSTRUCT",
    ifelse(
      provisional_survivors$variable %in% outside_three_domain_scope,
      "WOULD_BROADEN_BEYOND_FROZEN_THREE_DOMAIN_SUBSYSTEM",
      ifelse(
        provisional_survivors$variable %in% values_broaden_estimand,
        "VALUE_OR_POLICY_RELATED_BELIEF_WOULD_BROADEN_ESTIMAND",
        ifelse(
          provisional_survivors$variable %in% overlap_parsimony_alternative,
          "OVERLAP_OR_PARSIMONY_ALTERNATIVE",
          "RETROSPECTIVE_CONTEXT_REVIEW_REQUIRED"
        )
      )
    )
  )
)
stopifnot(!any(provisional_survivors$retrospective_context == "RETROSPECTIVE_CONTEXT_REVIEW_REQUIRED"))
provisional_survivors$interpretive_status <- ifelse(
  provisional_survivors$in_recorded_16,
  "REFER_TO_RECORDED_CANDIDATE_DECISION",
  "PROVISIONAL_RAW_SURVIVOR_OUTSIDE_RECORDED_POOL_NOT_A_HISTORICAL_EXCLUSION_REASON"
)

# Reproduce the VCF9049 feasibility evidence directly from the CDF. Code 7 is
# counted as a substantive VCF9049 response for this diagnostic only; no recode
# or network is estimated.
final_nine_valid_codes <- list(
  VCF0806 = 1:7,
  VCF0809 = 1:7,
  VCF0838 = 1:4,
  VCF0839 = 1:7,
  VCF0879a = c(1, 3, 5),
  VCF0888 = 1:3,
  VCF0890 = 1:3,
  VCF0894 = 1:3,
  VCF9223 = 1:4
)
is_valid_on <- function(data, code_map) {
  valid <- rep(TRUE, nrow(data))
  for (variable in names(code_map)) {
    valid <- valid & !is.na(data[[variable]]) & as.numeric(data[[variable]]) %in% code_map[[variable]]
  }
  valid
}

vcf9049_rows <- lapply(final_years, function(year) {
  year_data <- analysis_data[analysis_data$VCF0004 == year, , drop = FALSE]
  complete_nine <- is_valid_on(year_data, final_nine_valid_codes)
  valid_vcf9049 <- !is.na(year_data$VCF9049) & as.numeric(year_data$VCF9049) %in% c(1, 2, 3, 7)
  data.frame(
    year = year,
    nine_node_complete_case_n = sum(complete_nine),
    nine_nodes_plus_vcf9049_n = sum(complete_nine & valid_vcf9049),
    additional_complete_case_loss = sum(complete_nine) - sum(complete_nine & valid_vcf9049),
    vcf9049_code7_overall_n = sum(as.numeric(year_data$VCF9049) == 7, na.rm = TRUE),
    vcf9049_code7_among_nine_node_complete_cases_n = sum(
      complete_nine & as.numeric(year_data$VCF9049) == 7,
      na.rm = TRUE
    ),
    evidence_status = "FEASIBILITY_ONLY_NO_NETWORK_ESTIMATED",
    stringsAsFactors = FALSE
  )
})
vcf9049_feasibility <- do.call(rbind, vcf9049_rows)
expected_nine <- c(789L, 4353L, 2709L, 5390L, 3525L)
expected_ten <- c(779L, 4334L, 2704L, 5384L, 3512L)
stopifnot(
  identical(vcf9049_feasibility$nine_node_complete_case_n, expected_nine),
  identical(vcf9049_feasibility$nine_nodes_plus_vcf9049_n, expected_ten)
)

utils::write.csv(
  all_fields,
  file.path(output_dir, "all_1030_cdf_fields_retrospective_inventory.csv"),
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  broad_hits,
  file.path(output_dir, "broad_policy_label_retrieval_80.csv"),
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  five_wave_long,
  file.path(output_dir, "broad_hits_five_wave_raw_screen_long.csv"),
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  provisional_survivors,
  file.path(output_dir, "provisional_five_wave_survivors_32.csv"),
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  vcf9049_feasibility,
  file.path(output_dir, "vcf9049_complete_case_feasibility.csv"),
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)

summary_table <- data.frame(
  component = c(
    "cdf_fields_enumerated",
    "broad_label_hits",
    "provisional_five_wave_survivors",
    "survivors_outside_recorded_16",
    "original_16_item_rule_recovered",
    "audit_design_status",
    "network_results_used_for_screening",
    "respondent_level_rows_exported"
  ),
  value = c(
    nrow(all_fields),
    nrow(broad_hits),
    nrow(provisional_survivors),
    sum(!provisional_survivors$in_recorded_16),
    "NO",
    "RETROSPECTIVE_POST_HOC_COMPLETENESS_AUDIT",
    "NO",
    "NO"
  ),
  interpretation = c(
    "All fields in the February 2026 CDF were enumerated.",
    "An intentionally inclusive label rule retrieved possible policy attitudes and related beliefs.",
    "These fields passed only a provisional raw five-wave presence/category screen.",
    "These fields were not in the surviving recorded 16-item project list.",
    "The exact contemporaneous search and screening rule was not preserved.",
    "The new rules document a retrospective provenance repair, not the original nomination process.",
    "No edge, density, centrality or other network output entered this audit.",
    "Only variable metadata and aggregate counts were written."
  ),
  stringsAsFactors = FALSE
)

validation <- data.frame(
  check_id = c(
    "R01_CDF_HAS_1030_FIELDS",
    "R02_BROAD_RETRIEVAL_HAS_80_FIELDS",
    "R03_PROVISIONAL_SCREEN_HAS_32_FIELDS",
    "R04_21_SURVIVORS_OUTSIDE_RECORDED_16",
    "R05_ORIGINAL_RULE_NONRECOVERY_DISCLOSED",
    "R06_NO_RESPONDENT_ROWS_EXPORTED",
    "R07_VCF9049_FEASIBILITY_COUNTS_REPRODUCED"
  ),
  passed = c(
    nrow(all_fields) == 1030L,
    nrow(broad_hits) == 80L,
    nrow(provisional_survivors) == 32L,
    sum(!provisional_survivors$in_recorded_16) == 21L,
    identical(summary_table$value[summary_table$component == "original_16_item_rule_recovered"], "NO"),
    identical(summary_table$value[summary_table$component == "respondent_level_rows_exported"], "NO"),
    identical(vcf9049_feasibility$nine_node_complete_case_n, expected_nine) &&
      identical(vcf9049_feasibility$nine_nodes_plus_vcf9049_n, expected_ten)
  ),
  details = c(
    paste("Observed", nrow(all_fields)),
    paste("Observed", nrow(broad_hits)),
    paste("Observed", nrow(provisional_survivors)),
    paste("Observed", sum(!provisional_survivors$in_recorded_16)),
    "Historical non-recovery is retained as an explicit limitation.",
    "Outputs contain metadata and aggregate counts only.",
    "Nine-node and nine-plus-VCF9049 complete-case counts match the independently registered values."
  ),
  stringsAsFactors = FALSE
)

utils::write.csv(
  summary_table,
  file.path(output_dir, "retrospective_candidate_audit_summary.csv"),
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)
utils::write.csv(
  validation,
  file.path(output_dir, "retrospective_candidate_audit_validation.csv"),
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)

if (!all(validation$passed)) {
  stop(
    "Retrospective candidate completeness audit failed: ",
    paste(validation$check_id[!validation$passed], collapse = ", ")
  )
}

cat("All CDF fields:", nrow(all_fields), "\n")
cat("Broad label hits:", nrow(broad_hits), "\n")
cat("Provisional five-wave survivors:", nrow(provisional_survivors), "\n")
cat(
  "Survivors outside recorded 16:",
  sum(!provisional_survivors$in_recorded_16),
  "\n"
)
cat("RETROSPECTIVE_CANDIDATE_COMPLETENESS_AUDIT_COMPLETE\n")
