# Presentation-only: read saved estimates; do not estimate any model or test.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("Usage: Rscript --vanilla R/Tables.R <analysis_directory> <new_output_directory>")
project <- normalizePath(args[1], winslash = "/", mustWork = TRUE)
output <- args[2]
if (file.exists(output) || dir.exists(output)) stop("Output directory already exists: ", output)
dir.create(file.path(output, "tables"), recursive = TRUE, showWarnings = FALSE)
files <- c(
  main = "outputs/tables/final/10_sample_primary_summary.csv",
  education = "outputs/tables/final/10_education_summary.csv",
  edges = "outputs/tables/formal/07_formal_five_wave_edge_weights.csv",
  education_edges = "outputs/tables/formal/08B_education_edge_weights.csv",
  contrasts = "outputs/tables/sensitivity/09B_contrast_robustness.csv",
  claims = "outputs/tables/sensitivity/09B_claim_robustness.csv",
  accuracy = "outputs/tables/formal/08_overall_edges_with_accuracy.csv",
  sensitivity = "outputs/tables/final/10_sensitivity_summary.csv"
)
inputs <- lapply(file.path(project, files), read.csv, check.names = FALSE)
names(inputs) <- names(files)
m <- inputs$main
e <- inputs$education
stopifnot(identical(m$Wave, c(2004L, 2012L, 2016L, 2020L, 2024L)),
          nrow(m) == 5L, nrow(e) == 8L,
          nrow(inputs$edges) == 180L, nrow(inputs$education_edges) == 288L,
          all(m$Analysis_ready_n == c(789,4353,2709,5390,3525)))
for (yr in m$Wave) {
  w <- inputs$edges$Edge_weight[inputs$edges$Wave == yr]
  j <- match(yr, m$Wave)
  stopifnot(length(w) == 36L, all(is.finite(w)),
            sum(w != 0) == m$Retained_edges[j],
            abs(sum(abs(w)) - m$Global_strength_descriptive[j]) < 1e-12)
}
for (key in e$Group_key) {
  w <- inputs$education_edges$Edge_weight[inputs$education_edges$Group_key == key]
  stopifnot(length(w) == 36L, sum(w != 0) == e$Retained_edges[e$Group_key == key])
}
t1 <- data.frame(
  Year = m$Wave, N = m$Analysis_ready_n,
  Complete_case_retention_percent = 100 * m$Analysis_ready_n / m$Cleaned_n,
  Retained_edges = m$Retained_edges,
  Global_strength = m$Global_strength_descriptive,
  Median_95_percentile_interval_width = m$Median_percentile_interval_width
)
t2 <- data.frame(
  Year = e$Wave, Education_group = e$Education_group, N = e$N,
  Retained_edges = e$Retained_edges,
  Median_95_percentile_interval_width = e$Median_percentile_CI_width
)
c <- inputs$claims[inputs$claims$Claim_type == "WAVE_CONTRAST_DIRECTION", ]
stopifnot(nrow(c) == 10L)
t3 <- data.frame(
  Earlier_year = c$Earlier_wave, Later_year = c$Later_wave,
  Metric = c$Metric, Primary_difference = NA_real_,
  Full_N_threshold_direction_match = c$A1_match,
  Equal_N_direction_match_proportion = c$A2_match_proportion,
  Equal_N_threshold_direction_match_proportion = c$A3_match_proportion,
  Joint_minimum_match = c$Minimum_match, Classification = c$Final_status
)
for (i in seq_len(nrow(t3))) {
  z <- inputs$contrasts[
    inputs$contrasts$Earlier_wave == t3$Earlier_year[i] &
      inputs$contrasts$Later_wave == t3$Later_year[i] &
      inputs$contrasts$Metric == t3$Metric[i], ]
  stopifnot(nrow(z) == 3L, setequal(z$Arm_ID, c("A1","A2","A3")),
            length(unique(z$Primary_difference)) == 1L)
  t3$Primary_difference[i] <- z$Primary_difference[1]
  stopifnot(z$Direction_match_proportion[z$Arm_ID == "A1"] ==
              as.integer(t3$Full_N_threshold_direction_match[i]),
            z$Direction_match_proportion[z$Arm_ID == "A2"] ==
              t3$Equal_N_direction_match_proportion[i],
            z$Direction_match_proportion[z$Arm_ID == "A3"] ==
              t3$Equal_N_threshold_direction_match_proportion[i])
  j1 <- match(t3$Earlier_year[i], m$Wave)
  j2 <- match(t3$Later_year[i], m$Wave)
  v <- if (t3$Metric[i] == "Retained_edge_count_difference") m$Retained_edges else m$Global_strength_descriptive
  stopifnot(abs(t3$Primary_difference[i] - (v[j2] - v[j1])) < 1e-12)
}
stopifnot(sum(t3$Classification == "ROBUST") == 3L,
          sum(t3$Classification == "MIXED") == 1L,
          sum(t3$Classification == "NOT_ROBUST") == 6L)
tables <- list(Table_4_1_main_results = t1, Table_4_2_education_results = t2,
               Table_4_3_year_contrast_robustness = t3)
for (nm in names(tables)) {
  path <- file.path(output, "tables", paste0(nm, ".csv"))
  write.csv(tables[[nm]], path, row.names = FALSE, fileEncoding = "UTF-8")
  check <- read.csv(path, check.names = FALSE)
  stopifnot(isTRUE(all.equal(tables[[nm]], check, check.attributes = FALSE,
                            tolerance = 1e-13)))
}
# Retain the actual percentile interval fields, not the separate +/-2 SD fields.
selected <- inputs$accuracy[
  inputs$accuracy$Wave %in% c(2004,2024) &
    inputs$accuracy$Edge_ID %in% c("VCF0879a--VCF9223", "VCF0838--VCF9223", "VCF0809--VCF0839"),
  c("Wave","Edge_ID","Point_edge","Percentile_2_5","Percentile_97_5")]
write.csv(selected, file.path(output, "tables", "Selected_edge_estimates_and_percentile_intervals.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
format_table <- function(x) {
  x <- as.data.frame(lapply(x, as.character), check.names = FALSE)
  c(paste0("| ", paste(names(x), collapse = " | "), " |"),
    paste0("| ", paste(rep("---",ncol(x)), collapse = " | "), " |"),
    apply(x,1,function(r) paste0("| ",paste(r,collapse=" | ")," |")))
}
display1 <- t1
display1$Complete_case_retention_percent <- sprintf("%.1f", t1$Complete_case_retention_percent)
display1$Global_strength <- sprintf("%.3f", t1$Global_strength)
display1$Median_95_percentile_interval_width <- sprintf("%.3f", t1$Median_95_percentile_interval_width)
names(display1) <- c("Year", "N", "Retention (%)", "Edges", "Global strength", "Median interval width")
display2 <- t2
display2$Education_group <- ifelse(display2$Education_group == "No college degree", "No degree", "Degree or higher")
display2$Median_95_percentile_interval_width <- sprintf("%.3f", t2$Median_95_percentile_interval_width)
names(display2) <- c("Year", "Education", "N", "Edges", "Median interval width")
display3 <- data.frame(
  Comparison = paste(t3$Earlier_year,t3$Later_year,sep="-"),
  Metric = ifelse(t3$Metric == "Retained_edge_count_difference", "Edge count", "Global strength"),
  Difference = ifelse(t3$Metric == "Retained_edge_count_difference", sprintf("%+d", as.integer(t3$Primary_difference)), sprintf("%+.3f",t3$Primary_difference)),
  A1 = ifelse(t3$Full_N_threshold_direction_match, "Yes", "No"),
  A2 = sprintf("%.1f%%", 100*t3$Equal_N_direction_match_proportion),
  A3 = sprintf("%.1f%%", 100*t3$Equal_N_threshold_direction_match_proportion),
  Status = t3$Classification
)
writeLines(c("Table 4.1", format_table(display1), "", "Table 4.2", format_table(display2),
             "", "Table 4.3", format_table(display3)),
           file.path(output,"tables","table_displays_en.md"), useBytes = TRUE)
lib <- file.path(project,"renv/library/windows/R-4.5/x86_64-w64-mingw32")
if (dir.exists(lib)) .libPaths(c(lib,.libPaths()))
stopifnot(requireNamespace("digest",quietly=TRUE))
inventory <- data.frame(Source = files, SHA256 = vapply(file.path(project,files),
  function(p) digest::digest(file=p,algo="sha256",serialize=FALSE),character(1)), row.names=NULL)
write.csv(inventory,file.path(output,"tables","source_sha256.csv"),row.names=FALSE)
print(display3, row.names = FALSE)
print(selected, row.names = FALSE)
cat("PASS: source arithmetic, contrast joins, classifications and table round trips\n")
