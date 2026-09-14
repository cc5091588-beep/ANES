# Independent raw-frequency verification. Does not read the main evidence code map.
validate_candidate_pool_16_independently <- function(project_root, raw_file) {
  for (p in c("haven", "tidyselect", "digest")) {
    if (!requireNamespace(p, quietly = TRUE)) stop("Missing package: ", p)
  }
  # Independently transcribed from the official variable sections.
  code_map <- list(
    VCF0806 = 1:7, VCF0809 = 1:7, VCF0830 = 1:7, VCF0838 = 1:4,
    VCF0839 = 1:7, VCF0843 = 1:7, VCF0888 = 1:3, VCF0890 = 1:3,
    VCF0894 = 1:3, VCF9047 = c(1, 2, 3, 7), VCF9049 = c(1, 2, 3, 7),
    VCF0879a = c(1, 3, 5), VCF9223 = 1:4, VCF0301 = 1:7,
    VCF0803 = 1:7, VCF0846 = c(1, 2)
  )
  years <- c(2004L, 2008L, 2012L, 2016L, 2020L, 2024L)
  out <- file.path(project_root, "outputs", "tables", "supplement", "candidate_pool_16_audit")
  stopifnot(dir.exists(out), file.exists(raw_file))
  raw_hash <- digest::digest(file = raw_file, algo = "sha256")
  stopifnot(raw_hash == "45323c30faee1e9e67c2351c4302c31472b117050bef240d9339a264e2f3e078")
  d <- haven::read_dta(raw_file, col_select = tidyselect::all_of(c("VCF0004", names(code_map))))
  av <- read.csv(file.path(out, "candidate_pool_16_year_availability.csv"))
  freq <- read.csv(file.path(out, "candidate_pool_16_value_frequencies.csv"))
  summary <- read.csv(file.path(out, "candidate_pool_16_summary.csv"))
  counts <- list()
  raw_frequency <- list()
  k <- 0L
  for (v in names(code_map)) for (y in years) {
    k <- k + 1L
    x <- as.numeric(d[[v]][as.integer(d$VCF0004) == y])
    counts[[k]] <- data.frame(Variable = v, Year = y, Independent_n =
      length(which(x %in% code_map[[v]])), Independent_total = length(x))
    z <- as.data.frame(table(x, useNA = "ifany"), stringsAsFactors = FALSE)
    names(z) <- c("Raw_code_text", "Independent_n")
    z$Variable <- v
    z$Year <- y
    raw_frequency[[k]] <- z
  }
  counts <- do.call(rbind, counts)
  raw_frequency <- do.call(rbind, raw_frequency)
  count_key <- function(v, y) paste(v, y, sep = "__")
  freq_key <- function(v, y, z) paste(v, y, ifelse(is.na(z), "SYSTEM_NA", as.character(z)), sep = "__")
  ci <- match(count_key(av$Variable, av$Year), count_key(counts$Variable, counts$Year))
  key_ind <- freq_key(raw_frequency$Variable, raw_frequency$Year, raw_frequency$Raw_code_text)
  key_main <- freq_key(freq$Variable, freq$Year, freq$Raw_code)
  fi <- match(key_main, key_ind)
  count_detail <- data.frame(Variable = av$Variable, Year = av$Year,
    Main_n = av$Substantive_n, Independent_n = counts$Independent_n[ci],
    Difference = av$Substantive_n - counts$Independent_n[ci])
  checks <- data.frame(
    Check = c("Independent substantive counts match", "Complete raw-frequency key set matches",
              "Independent raw-code counts match", "All sample totals match",
              "Summary is the specified unique pool", "No automatic selection assertion",
              "Frequency export contains aggregate fields only", "Raw source unchanged"),
    Passed = c(nrow(count_detail) == 96L && !anyNA(ci) && all(count_detail$Difference == 0),
               !anyDuplicated(key_main) && !anyDuplicated(key_ind) && setequal(key_main, key_ind),
               !anyNA(fi) && all(freq$N == raw_frequency$Independent_n[fi]),
               all(av$Total_n == counts$Independent_total[ci]),
               nrow(summary) == 16L && !anyDuplicated(summary$Variable) && setequal(summary$Variable, names(code_map)),
               all(!summary$Automatic_final_node_selection),
               identical(names(freq), c("Variable", "Year", "Raw_code", "Raw_label", "N", "Response_class")),
               raw_hash == digest::digest(file = raw_file, algo = "sha256")),
    Detail = c(paste(sum(count_detail$Difference == 0), "of", nrow(count_detail), "year-item counts"),
               paste(nrow(freq), "of", nrow(raw_frequency), "positive-frequency cells"),
               "Compared with independent table() aggregation of the original DTA",
               "All 96 year-item total denominators agree", "16 is the specified audit scope",
               "Existing final-node roles were not independently selected",
               "No respondent identifier or respondent-level rows", raw_hash)
  )
  print(checks)
  if (!all(checks$Passed)) stop("Independent candidate-pool validation failed")
  write.csv(count_detail, file.path(out, "candidate_pool_16_independent_count_comparison.csv"), row.names = FALSE)
  write.csv(checks, file.path(out, "candidate_pool_16_independent_validation.csv"), row.names = FALSE)
  invisible(checks)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 2L) stop("Usage: Rscript 01B_validate_candidate_pool_16_independently.R PROJECT_ROOT CDF_DTA")
  validate_candidate_pool_16_independently(args[[1L]], args[[2L]])
}
