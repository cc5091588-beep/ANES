#!/usr/bin/env Rscript

# Reproduces aggregate data-cleaning and sparsity evidence used to evaluate 2008.
# It does not estimate a GGM, EBICglasso model, bootstrap, centrality or NCT.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop("Usage: Rscript 02_2008_exclusion_diagnostic.R <CDF_DTA_PATH> <OUTPUT_DIRECTORY>")
}

input_dta <- normalizePath(args[[1]], winslash = "/", mustWork = TRUE)
output_dir <- normalizePath(args[[2]], winslash = "/", mustWork = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

if (!requireNamespace("haven", quietly = TRUE)) {
  stop("Package 'haven' is required to read the official CDF Stata file.")
}
if (!requireNamespace("tidyselect", quietly = TRUE)) {
  stop("Package 'tidyselect' is required for bounded column selection.")
}

nodes <- c(
  "VCF0806", "VCF0809", "VCF0838", "VCF0839", "VCF0888",
  "VCF0890", "VCF0894", "VCF0879a", "VCF9223"
)
split_form_nodes <- c("VCF0806", "VCF0809", "VCF0838", "VCF0839")
read_vars <- c("VCF0004", "VCF0110", nodes)

valid_codes <- list(
  VCF0806 = 1:7,
  VCF0809 = 1:7,
  VCF0838 = 1:4,
  VCF0839 = 1:7,
  VCF0888 = 1:3,
  VCF0890 = 1:3,
  VCF0894 = 1:3,
  VCF0879a = c(1, 3, 5),
  VCF9223 = 1:4,
  VCF0110 = 1:4
)

raw <- haven::read_dta(input_dta, col_select = tidyselect::all_of(read_vars))
raw <- as.data.frame(lapply(raw, as.numeric), check.names = FALSE)
raw <- raw[as.integer(raw$VCF0004) == 2008L, read_vars, drop = FALSE]
if (nrow(raw) != 2322L) {
  stop("Expected 2,322 CDF records in 2008; observed ", nrow(raw), ".")
}

clean <- raw
for (variable in c(nodes, "VCF0110")) {
  clean[[variable]][!(clean[[variable]] %in% valid_codes[[variable]])] <- NA_real_
}

cc9 <- stats::complete.cases(clean[, nodes, drop = FALSE])
education_valid <- !is.na(clean$VCF0110)
no_college <- cc9 & education_valid & clean$VCF0110 %in% 1:3
college_plus <- cc9 & education_valid & clean$VCF0110 == 4

sample_flow <- data.frame(
  step = c(
    "total_sample", "all_9_nodes_complete", "all_9_nodes_plus_valid_education",
    "education_no_college", "education_college_plus"
  ),
  n = c(
    nrow(clean), sum(cc9), sum(cc9 & education_valid),
    sum(no_college), sum(college_plus)
  ),
  percent_of_2008 = 100 * c(
    nrow(clean), sum(cc9), sum(cc9 & education_valid),
    sum(no_college), sum(college_plus)
  ) / nrow(clean),
  stringsAsFactors = FALSE
)

availability <- as.data.frame(lapply(clean[, split_form_nodes, drop = FALSE], function(x) as.integer(!is.na(x))))
availability$pattern <- apply(availability, 1L, paste0, collapse = "")
split_patterns <- as.data.frame(table(availability$pattern), stringsAsFactors = FALSE)
names(split_patterns) <- c("pattern", "n")
split_patterns$percent_of_2008 <- 100 * split_patterns$n / nrow(clean)
split_patterns$definition <- "1=substantive valid response; 0=non-substantive or structurally unavailable"

pairwise_cells <- function(data, sample_name) {
  rows <- list()
  counter <- 0L
  for (i in seq_len(length(nodes) - 1L)) {
    for (j in (i + 1L):length(nodes)) {
      variable_1 <- nodes[[i]]
      variable_2 <- nodes[[j]]
      contingency <- table(
        factor(data[[variable_1]], levels = valid_codes[[variable_1]]),
        factor(data[[variable_2]], levels = valid_codes[[variable_2]])
      )
      positive <- contingency[contingency > 0L]
      counter <- counter + 1L
      rows[[counter]] <- data.frame(
        sample = sample_name,
        variable_1 = variable_1,
        variable_2 = variable_2,
        n = nrow(data),
        cells = length(contingency),
        zero_cells = sum(contingency == 0L),
        minimum_positive_cell = if (length(positive)) min(positive) else 0L,
        cells_below_5 = sum(contingency < 5L),
        stringsAsFactors = FALSE
      )
    }
  }
  do.call(rbind, rows)
}

pairwise_output <- rbind(
  pairwise_cells(clean[cc9, nodes, drop = FALSE], "overall"),
  pairwise_cells(clean[no_college, nodes, drop = FALSE], "no_college"),
  pairwise_cells(clean[college_plus, nodes, drop = FALSE], "college_plus")
)

category_rows <- list()
for (sample_name in c("overall", "no_college", "college_plus")) {
  index <- switch(sample_name, overall = cc9, no_college = no_college, college_plus = college_plus)
  for (variable in nodes) {
    counts <- table(factor(clean[[variable]][index], levels = valid_codes[[variable]]))
    category_rows[[length(category_rows) + 1L]] <- data.frame(
      sample = sample_name,
      sample_n = sum(index),
      variable = variable,
      category = names(counts),
      frequency = as.integer(counts),
      stringsAsFactors = FALSE
    )
  }
}
category_frequencies <- do.call(rbind, category_rows)

write.csv(sample_flow, file.path(output_dir, "2008_sample_flow.csv"), row.names = FALSE, na = "")
write.csv(split_patterns, file.path(output_dir, "2008_split_form_patterns.csv"), row.names = FALSE, na = "")
write.csv(pairwise_output, file.path(output_dir, "2008_pairwise_cell_diagnostics.csv"), row.names = FALSE, na = "")
write.csv(category_frequencies, file.path(output_dir, "2008_category_frequencies.csv"), row.names = FALSE, na = "")

validation <- data.frame(
  check_id = c(
    "TOTAL_N_2322", "NINE_NODE_COMPLETE_N_724", "EDUCATION_VALID_N_721",
    "NO_COLLEGE_N_542", "COLLEGE_PLUS_N_179", "ALL_FOUR_SPLIT_FORM_N_756",
    "NO_RESPONDENT_LEVEL_OUTPUT"
  ),
  passed = c(
    nrow(clean) == 2322L,
    sum(cc9) == 724L,
    sum(cc9 & education_valid) == 721L,
    sum(no_college) == 542L,
    sum(college_plus) == 179L,
    sum(availability$pattern == "1111") == 756L,
    TRUE
  ),
  stringsAsFactors = FALSE
)
write.csv(validation, file.path(output_dir, "2008_exclusion_diagnostic_validation.csv"), row.names = FALSE, na = "")

if (!all(validation$passed)) {
  stop("One or more 2008 exclusion-diagnostic validations failed.")
}

cat("2008_EXCLUSION_DIAGNOSTIC_COMPLETE\n")

