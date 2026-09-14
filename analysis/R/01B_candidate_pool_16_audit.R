# Retrospective evidence audit of a researcher-specified 16-item pool.
# This script does not discover the pool and never estimates a network.

run_candidate_pool_16_audit <- function(project_root, raw_file, codebook_file) {
  options(stringsAsFactors = FALSE)
  for (p in c("haven", "digest", "tidyselect")) {
    if (!requireNamespace(p, quietly = TRUE)) stop("Missing dependency: ", p)
  }
  root <- normalizePath(project_root, winslash = "/", mustWork = TRUE)
  raw_file <- normalizePath(raw_file, winslash = "/", mustWork = TRUE)
  codebook_file <- normalizePath(codebook_file, winslash = "/", mustWork = TRUE)
  rel <- function(...) file.path(root, ...)
  out <- rel("outputs", "tables", "supplement", "candidate_pool_16_audit")
  spec_file <- rel("config", "node_selection_spec.csv")
  evidence_file <- rel("config", "candidate_pool_16_codebook_evidence.csv")
  secondary_file <- rel("config", "candidate_pool_16_secondary_source_evidence.csv")
  legacy_file <- rel("data", "audit", "node_wave_selection_inputs",
                     "anes_year_item_comparability.csv")
  repair_file <- rel("data", "audit", "node_wave_selection_inputs",
                     "ANES_SOURCE_MAPPING_EVIDENCE_G02B.csv")
  protocol_file <- rel("project_docs", "working", "CANDIDATE_POOL_16_RETROSPECTIVE_AUDIT.md")
  script_file <- rel("R", "01B_candidate_pool_16_audit.R")
  notebook_file <- rel("notebooks", "01B_candidate_pool_16_audit.Rmd")
  required <- c(raw_file, codebook_file, spec_file, evidence_file, legacy_file,
                repair_file, protocol_file, script_file, notebook_file, secondary_file)
  stopifnot(all(file.exists(required)))
  sha <- function(x) digest::digest(file = x, algo = "sha256")
  protected_before <- vapply(required, sha, character(1))
  expected_raw_sha <- "45323c30faee1e9e67c2351c4302c31472b117050bef240d9339a264e2f3e078"
  if (!identical(unname(protected_before[[1L]]), expected_raw_sha)) {
    stop("CDF does not match the source frozen in 01_data_inventory.Rmd.")
  }
  read_csv <- function(x) {
    d <- read.csv(x, check.names = FALSE, fileEncoding = "UTF-8-BOM", na.strings = "")
    names(d)[1L] <- sub("^[^A-Za-z0-9_]+", "", names(d)[1L])
    d
  }
  spec <- read_csv(spec_file)
  evidence <- read_csv(evidence_file)
  secondary <- read_csv(secondary_file)
  stopifnot(nrow(spec) == 16L, !anyDuplicated(spec$cdf_variable),
            nrow(evidence) == 16L, !anyDuplicated(evidence$variable),
            setequal(spec$cdf_variable, evidence$variable))
  evidence <- evidence[match(spec$cdf_variable, evidence$variable), , drop = FALSE]
  metadata <- haven::read_dta(raw_file, n_max = 0)
  vars <- spec$cdf_variable
  stopifnot(all(c("VCF0004", vars) %in% names(metadata)))
  dat <- haven::read_dta(raw_file, col_select = tidyselect::all_of(c("VCF0004", vars)))
  years <- c(2004L, 2008L, 2012L, 2016L, 2020L, 2024L)
  primary <- setdiff(years, 2008L)
  yr <- as.integer(dat$VCF0004)
  # The inherited file contains mixed-encoding question text. Read it without
  # forced conversion and use only its ASCII identifiers and numeric counts.
  # Do not copy its extracted question strings as verified official wording.
  legacy <- read.csv(legacy_file, check.names = FALSE, na.strings = "")
  names(legacy)[1L] <- sub("^[^A-Za-z0-9_]+", "", names(legacy)[1L])
  stopifnot(!anyDuplicated(paste(legacy$variable_name, legacy$year)))
  needed_legacy <- as.vector(outer(vars, years, paste))
  stopifnot(all(needed_legacy %in% paste(legacy$variable_name, legacy$year)))
  availability <- list()
  frequencies <- list()
  label_rows <- list()
  count <- 0L
  fcount <- 0L
  lcount <- 0L

  for (i in seq_along(vars)) {
    v <- vars[[i]]
    codes <- as.numeric(strsplit(evidence$substantive_codes[[i]], "|", fixed = TRUE)[[1L]])
    stopifnot(length(codes) >= 2L, !anyNA(codes), !anyDuplicated(codes))
    labels <- attr(dat[[v]], "labels")
    label_for <- function(x) {
      m <- match(x, unname(labels))
      ans <- names(labels)[m]
      ans[is.na(ans)] <- "UNLABELLED_IN_DTA"
      ans[is.na(x)] <- "SYSTEM_MISSING"
      ans
    }
    if (length(labels)) {
      for (j in seq_along(labels)) {
        lcount <- lcount + 1L
        label_rows[[lcount]] <- data.frame(
          Variable = v, Raw_code = unname(labels[[j]]), DTA_value_label = names(labels)[[j]],
          In_substantive_scale = unname(labels[[j]]) %in% codes)
      }
    }
    for (y in years) {
      x <- as.numeric(dat[[v]][yr == y])
      valid <- !is.na(x) & x %in% codes
      observed <- sort(unique(x[!is.na(x)]))
      valid_values <- sort(unique(x[valid]))
      source <- evidence[[paste0("source_", y)]][[i]]
      if (is.na(source)) source <- "NOT_DOCUMENTED_IN_VARIABLE_SECTION"
      legacy_idx <- match(paste(v, y), paste(legacy$variable_name, legacy$year))
      old_n <- if (is.na(legacy_idx)) NA_real_ else suppressWarnings(as.numeric(legacy$valid_n[[legacy_idx]]))
      source_state <- if (startsWith(source, "NOT_DOCUMENTED")) {
        if (sum(valid) > 0L) "VALUES_PRESENT_SOURCE_GAP" else "NO_VALUES_OR_DOCUMENTED_SOURCE"
      } else if (startsWith(source, "INCOMPARABLE")) {
        "ALTERNATIVE_SCALE_DOCUMENTED_NOT_COMPARABLE"
      } else if (grepl("PRIOR_REPAIR", source, fixed = TRUE)) {
        "PRIOR_SINGLE_WAVE_REPAIR_NOT_RERUN"
      } else if (grepl("QUESTION_BLOCK", source, fixed = TRUE)) {
        "SOURCE_DOCUMENTED_IN_QUESTION_BLOCK"
      } else "SOURCE_DOCUMENTED_IN_CDF_SECTION"
      count <- count + 1L
      availability[[count]] <- data.frame(
        Variable = v, Year = y,
        Year_role = if (y == 2008L) "HISTORICAL_DIAGNOSTIC_ONLY" else "PRIMARY_YEAR",
        Total_n = length(x), Substantive_n = sum(valid),
        Substantive_pct = 100 * mean(valid), System_missing_n = sum(is.na(x)),
        Outside_substantive_scale_n = sum(!is.na(x) & !valid),
        Observed_substantive_categories = length(valid_values),
        Observed_substantive_codes = paste(valid_values, collapse = "|"),
        Specified_substantive_codes = paste(codes, collapse = "|"),
        Source_entry = source, Source_status = source_state,
        Codebook_PDF_pages = evidence$pdf_pages[[i]],
        Raw_availability_gate = sum(valid) > 0L && length(valid_values) >= 2L,
        Previous_audit_valid_n = old_n,
        Difference_from_previous_n = sum(valid) - old_n,
        Scope_note = "Raw availability is not proof of measurement comparability.")
      all_values <- c(observed, NA_real_)
      for (z in all_values) {
        n <- if (is.na(z)) sum(is.na(x)) else sum(x == z, na.rm = TRUE)
        if (n == 0L) next
        fcount <- fcount + 1L
        frequencies[[fcount]] <- data.frame(
          Variable = v, Year = y, Raw_code = z, Raw_label = label_for(z), N = n,
          Response_class = if (is.na(z)) "SYSTEM_MISSING" else if (z %in% codes) {
            "IN_SPECIFIED_SUBSTANTIVE_SCALE"
          } else "OUTSIDE_SPECIFIED_SUBSTANTIVE_SCALE")
      }
    }
  }
  availability <- do.call(rbind, availability)
  frequencies <- do.call(rbind, frequencies)
  label_rows <- do.call(rbind, label_rows)
  summary_rows <- lapply(seq_along(vars), function(i) {
    v <- vars[[i]]
    rows <- availability[availability$Variable == v & availability$Year %in% primary, ]
    data.frame(
      Candidate_order = spec$candidate_order[[i]], Variable = v,
      Label = spec$node_label[[i]], Construct = spec$construct_class[[i]],
      Pool_membership = "RESEARCHER_SPECIFIED_RECORDED_POOL",
      Variable_exists = v %in% names(metadata),
      Raw_gate_pass_years = sum(rows$Raw_availability_gate),
      Primary_years_checked = length(primary),
      Minimum_substantive_n = min(rows$Substantive_n),
      Maximum_substantive_n = max(rows$Substantive_n),
      Primary_year_source_gaps = paste(rows$Year[rows$Source_status %in%
        c("VALUES_PRESENT_SOURCE_GAP", "NO_VALUES_OR_DOCUMENTED_SOURCE")], collapse = "|"),
      Existing_project_role = spec$final_role[[i]],
      Existing_project_decision_status = spec$decision_status[[i]],
      Codebook_PDF_pages = evidence$pdf_pages[[i]],
      Evidence_review = evidence$review_status[[i]],
      Current_evidence_note = evidence$review_note[[i]],
      Automatic_final_node_selection = FALSE)
  })
  summary <- do.call(rbind, summary_rows)
  source_issues <- availability[availability$Source_status != "SOURCE_DOCUMENTED_IN_CDF_SECTION", ]
  legacy_diff <- availability[!is.na(availability$Difference_from_previous_n) &
                              availability$Difference_from_previous_n != 0, ]
  # Recompute the nine-node aggregate only as a check; no data objects are saved.
  primary_nodes <- spec$cdf_variable[spec$final_role == "PRIMARY_NODE"]
  cc <- lapply(primary, function(y) {
    selected <- yr == y
    ok <- rep(TRUE, sum(selected))
    for (v in primary_nodes) {
      codes <- as.numeric(strsplit(evidence$substantive_codes[match(v, evidence$variable)],
                                  "|", fixed = TRUE)[[1L]])
      x <- as.numeric(dat[[v]][selected])
      ok <- ok & !is.na(x) & x %in% codes
    }
    data.frame(Year = y, Original_nine_complete_case_n = sum(ok))
  })
  cc <- do.call(rbind, cc)
  expected_cc <- c(789L, 4353L, 2709L, 5390L, 3525L)
  # The 2024 pattern records observed co-missingness, not a newly established cause.
  d24 <- dat[yr == 2024L, , drop = FALSE]
  anchor <- !is.na(d24$VCF0806) & as.numeric(d24$VCF0806) == -1
  block_vars <- c("VCF0806", "VCF0809", "VCF9223", "VCF0888", "VCF0890", "VCF0894")
  missing_block <- do.call(rbind, lapply(block_vars, function(v) {
    x <- as.numeric(d24[[v]])
    flag <- if (v %in% block_vars[1:3]) !is.na(x) & x == -1 else is.na(x)
    data.frame(Year = 2024L, Variable = v,
      Observed_code_pattern = if (v %in% block_vars[1:3]) "-1" else "SYSTEM_NA",
      N = sum(flag), Same_set_as_VCF0806_negative_one = identical(flag, anchor),
      Interpretation = "Observed co-missingness only; no new causal mode attribution.")
  }))
  # Frequency totals are independently reconciled with raw sample totals.
  freq_totals <- aggregate(N ~ Variable + Year, frequencies, sum)
  total_idx <- match(paste(availability$Variable, availability$Year),
                     paste(freq_totals$Variable, freq_totals$Year))
  scale_freq <- frequencies[frequencies$Response_class == "IN_SPECIFIED_SUBSTANTIVE_SCALE", ]
  scale_totals <- aggregate(N ~ Variable + Year, scale_freq, sum)
  scale_idx <- match(paste(availability$Variable, availability$Year),
                     paste(scale_totals$Variable, scale_totals$Year))
  scale_n <- scale_totals$N[scale_idx]
  scale_n[is.na(scale_n)] <- 0L
  protected_after <- vapply(required, sha, character(1))
  check <- function(name, passed, detail) data.frame(Check = name, Passed = passed, Detail = detail)
  validation <- rbind(
    check("Registered raw CDF SHA256 matches", protected_before[[1L]] == expected_raw_sha, "Frozen source from 01_data_inventory.Rmd"),
    check("Specified pool has 16 unique variables", length(vars) == 16L && !anyDuplicated(vars), "Input completeness check; not an independent selection result"),
    check("All specified variables exist in raw CDF", all(vars %in% names(metadata)), paste(length(vars), "of", length(vars))),
    check("Every candidate has codebook evidence", all(nzchar(evidence$pdf_pages)) && all(nzchar(evidence$review_note)), "16 named variable sections; sources and caveats remain visible"),
    check("All six year-item cells per candidate present", nrow(availability) == length(vars) * length(years) && !anyDuplicated(paste(availability$Variable, availability$Year)), "Five primary years plus historical 2008"),
    check("Response partitions reconcile", all(with(availability, Total_n == Substantive_n + System_missing_n + Outside_substantive_scale_n)), "No respondent assigned to two response classes"),
    check("Frequency totals match raw sample sizes", all(availability$Total_n == freq_totals$N[total_idx]), "Independent aggregation of exported value frequencies"),
    check("Substantive frequency totals match", all(availability$Substantive_n == scale_n), "Independent aggregation by substantive class"),
    check("Nine-node complete-case counts match formal samples", identical(as.integer(cc$Original_nine_complete_case_n), expected_cc), paste(cc$Original_nine_complete_case_n, collapse = "|")),
    check("2024 co-missingness pattern reproduced", all(missing_block$N == 245L) && all(missing_block$Same_set_as_VCF0806_negative_one), "Six fields share the observed 245-person pattern; cause not inferred"),
    check("Historical 2008 not labelled primary", all(availability$Year_role[availability$Year == 2008L] == "HISTORICAL_DIAGNOSTIC_ONLY"), "No network is estimated"),
    check("No automatic final-node selection claimed", all(!summary$Automatic_final_node_selection), "Existing project role is read as context, not derived from this audit"),
    check("All audited source inputs remain unchanged", identical(unname(protected_before), unname(protected_after)), "SHA256 comparison before and after aggregate calculations")
  )
  if (!all(validation$Passed)) {
    print(validation)
    stop("Candidate audit failed computational validation; no result tables published.")
  }
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(out)) stop("Cannot create the dedicated audit output directory: ", out)
  tables <- list(
    candidate_pool_16_summary = summary,
    candidate_pool_16_year_availability = availability,
    candidate_pool_16_value_frequencies = frequencies,
    candidate_pool_16_value_labels = label_rows,
    candidate_pool_16_codebook_evidence = evidence,
    candidate_pool_16_secondary_source_evidence = secondary,
    candidate_pool_16_source_discrepancies = source_issues,
    candidate_pool_16_previous_count_differences = legacy_diff,
    candidate_pool_16_complete_case_validation = cc,
    candidate_pool_16_2024_missingness_pattern = missing_block,
    candidate_pool_16_validation = validation
  )
  written <- character()
  for (nm in names(tables)) {
    f <- file.path(out, paste0(nm, ".csv"))
    write.csv(tables[[nm]], f, row.names = FALSE, na = "", fileEncoding = "UTF-8")
    back <- read.csv(f, check.names = FALSE, fileEncoding = "UTF-8", na.strings = "")
    stopifnot(identical(names(back), names(tables[[nm]])), nrow(back) == nrow(tables[[nm]]))
    written <- c(written, f)
  }
  input_manifest <- data.frame(Input = required, SHA256 = unname(protected_before),
    Preserved = unname(protected_before) == unname(protected_after))
  manifest_file <- file.path(out, "candidate_pool_16_input_manifest.csv")
  write.csv(input_manifest, manifest_file, row.names = FALSE, fileEncoding = "UTF-8")
  written <- c(written, manifest_file)
  output_manifest <- data.frame(File = basename(written), Bytes = file.info(written)$size,
    SHA256 = vapply(written, sha, character(1)), Row_count = vapply(written,
      function(f) nrow(read.csv(f, check.names = FALSE)), integer(1)))
  write.csv(output_manifest, file.path(out, "candidate_pool_16_output_manifest.csv"),
            row.names = FALSE, fileEncoding = "UTF-8")
  log_file <- rel("outputs", "logs", "01B_candidate_pool_16_audit.log")
  dir.create(dirname(log_file), recursive = TRUE, showWarnings = FALSE)
  writeLines(c(
    "SPECIFIED_POOL_AUDIT_COMPLETE_WITH_DISCLOSED_SOURCE_LIMITATIONS",
    "Pool size: 16, specified by the existing list and current researcher instruction.",
    paste("Raw CDF rows:", nrow(dat)), paste("Raw CDF columns:", ncol(metadata)),
    paste("Year-item records:", nrow(availability)),
    paste("Computational validation:", sum(validation$Passed), "/", nrow(validation)),
    paste("Previous availability-count differences:", nrow(legacy_diff)),
    "No network/correlation estimation, bootstrap, centrality or tests were run.",
    "Original nomination history was not recovered. Source gaps are not silently treated as failure-free.",
    paste("R:", as.character(getRversion())),
    paste("haven:", as.character(utils::packageVersion("haven"))),
    paste("digest:", as.character(utils::packageVersion("digest")))
  ), log_file, useBytes = TRUE)
  invisible(list(summary = summary, availability = availability,
                 validation = validation, output_dir = out))
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 3L) stop("Usage: Rscript 01B_candidate_pool_16_audit.R PROJECT_ROOT CDF_DTA CODEBOOK_PDF")
  run_candidate_pool_16_audit(args[[1L]], args[[2L]], args[[3L]])
}
