# Read-only integrity checks of packaged aggregate outputs. Base R only.
args <- commandArgs(trailingOnly = TRUE)
file_arg <- grep("^--file=", commandArgs(), value = TRUE)
if (length(args) > 1L) stop("Usage: Rscript --vanilla analysis/checks/Check.R [repository_root]")
root <- if (length(args)) args[[1L]] else {
  if (length(file_arg) != 1L) stop("Supply the archive root when sourcing interactively")
  file.path(dirname(sub("^--file=", "", file_arg)), "..", "..")
}
root <- normalizePath(root, winslash = "/", mustWork = TRUE)
read_table <- function(relative) {
  path <- file.path(root, "analysis", relative)
  if (!file.exists(path)) stop("Missing packaged table: ", relative)
  read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
}
near <- function(x, y, tolerance = 1e-8) {
  length(x) == length(y) && all(is.finite(x)) && all(is.finite(y)) &&
    all(abs(x - y) <= tolerance)
}
results <- data.frame(Check = character(), Passed = logical())
check <- function(label, condition) {
  pass <- isTRUE(condition)
  results[nrow(results) + 1L, ] <<- list(label, pass)
  if (!pass) stop("FAIL: ", label, call. = FALSE)
}
edges <- read_table("outputs/tables/formal/07_formal_five_wave_edge_weights.csv")
primary <- read_table("outputs/tables/final/10_sample_primary_summary.csv")
education <- read_table("outputs/tables/formal/08B_education_edge_weights.csv")
education_summary <- read_table("outputs/tables/final/10_education_summary.csv")
accuracy <- read_table("outputs/tables/formal/08_overall_edges_with_accuracy.csv")
education_accuracy <- read_table("outputs/tables/formal/08C_education_edge_accuracy_review.csv")
check("Expected overall output dimensions", nrow(edges) == 180L && nrow(primary) == 5L)
check("Overall years agree", identical(sort(unique(edges$Wave)), sort(primary$Wave)))
check("Overall edge records are unique", !anyDuplicated(edges[c("Wave", "Node_1", "Node_2")]))
check("Overall weights finite", all(is.finite(edges$Edge_weight)))
check("Retained flag agrees with exact nonzero", all(edges$Retained_under_EBICglasso == (edges$Edge_weight != 0)))
for (i in seq_len(nrow(primary))) {
  wave <- primary$Wave[i]
  w <- edges$Edge_weight[edges$Wave == wave]
  a <- accuracy[accuracy$Wave == wave, ]
  check(paste(wave, "edge count and density"), length(w) == 36L &&
          sum(w != 0) == primary$Retained_edges[i] &&
          near(sum(w != 0) / length(w), primary$Density[i]))
  check(paste(wave, "global strength"), near(sum(abs(w)), primary$Global_strength_descriptive[i]))
  check(paste(wave, "sample flow"), primary$Cleaned_n[i] ==
          primary$Excluded_missing_nine_node_n[i] + primary$Analysis_ready_n[i] &&
          primary$Analysis_ready_n[i] == primary$Point_network_n[i])
  check(paste(wave, "percentile interval order"), nrow(a) == 36L &&
          all(is.finite(a$Percentile_2_5)) && all(is.finite(a$Percentile_97_5)) &&
          all(a$Percentile_97_5 >= a$Percentile_2_5))
  widths <- a$Percentile_97_5 - a$Percentile_2_5
  check(paste(wave, "precision summary"), near(median(widths), primary$Median_percentile_interval_width[i]) &&
          near(max(widths), primary$Maximum_percentile_interval_width[i]))
}
check("Education dimensions", nrow(education) == 288L && nrow(education_summary) == 8L)
check("Education groups agree", identical(sort(unique(education$Group_key)), sort(education_summary$Group_key)))
check("Education edge records unique", !anyDuplicated(education[c("Group_key", "Node_1", "Node_2")]))
check("Education weights finite", all(is.finite(education$Edge_weight)))
for (i in seq_len(nrow(education_summary))) {
  key <- education_summary$Group_key[i]
  e <- education[education$Group_key == key, ]
  a <- education_accuracy[education_accuracy$Group_key == key, ]
  check(paste(key, "N and retained edges"), nrow(e) == 36L &&
          all(e$N == education_summary$N[i]) &&
          sum(e$Edge_weight != 0) == education_summary$Retained_edges[i])
  widths <- a$Percentile_CI_97_5 - a$Percentile_CI_2_5
  check(paste(key, "percentile precision summary"), nrow(a) == 36L && all(is.finite(widths)) &&
          all(widths >= 0) && near(median(widths), education_summary$Median_percentile_CI_width[i]) &&
          near(max(widths), education_summary$Maximum_percentile_CI_width[i]))
}
print(results, row.names = FALSE)
cat("PASS:", nrow(results), "saved-output consistency checks. No models were run.\n")
