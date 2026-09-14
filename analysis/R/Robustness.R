# English three-rule table from the previously validated year-contrast CSV.
# Rscript --vanilla build_table5_english.R <source_csv> <output_directory>
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2L)
src <- normalizePath(args[1], winslash = "/", mustWork = TRUE)
out <- args[2]
if (!dir.exists(out)) dir.create(out, recursive = TRUE)
before <- tools::md5sum(src)
d <- read.csv(src, check.names = FALSE, stringsAsFactors = FALSE)
stopifnot(nrow(d) == 10L,
          sum(d$Classification == "ROBUST") == 3,
          sum(d$Classification == "MIXED") == 1,
          sum(d$Classification == "NOT_ROBUST") == 6)
rows <- data.frame(
  Year_comparison = paste(d$Earlier_year, d$Later_year, sep = "-"),
  Measure = ifelse(d$Metric == "Retained_edge_count_difference", "Retained edges", "Global strength"),
  Primary_difference = ifelse(d$Metric == "Retained_edge_count_difference",
    ifelse(d$Primary_difference == 0, "0", sprintf("%+d", as.integer(d$Primary_difference))),
    sprintf("%+.3f", d$Primary_difference)),
  A1_direction_match = ifelse(d$Full_N_threshold_direction_match, "Yes", "No"),
  A2_matching_proportion = sprintf("%.3f", d$Equal_N_direction_match_proportion),
  A3_matching_proportion = sprintf("%.3f", d$Equal_N_threshold_direction_match_proportion),
  Classification = d$Classification, check.names = FALSE
)
title <- "Table 5. Robustness of between-year network comparisons"
headers <- c("Year\ncomparison", "Measure", "Primary\ndifference", "A1\nDirection\nmatch",
             "A2\nMatching\nproportion", "A3\nMatching\nproportion", "Classification")
notes <- c(
  "Note. Differences are calculated as the later year minus the earlier year.",
  "A1: full-sample networks with threshold = TRUE. A2 and A3: equal-N analyses with threshold = FALSE and",
  "threshold = TRUE, respectively. Each equal-N analysis used 1,000 repetitions with N = 789 per later-year",
  "sample; the 2004 sample remained fixed. Matching means reproducing the primary difference's positive,",
  "negative or zero direction; a primary difference of zero requires a repeated difference of zero.",
  "Classifications combine A1-A3 under the criteria specified in Methods; they are not significance tests."
)
stem <- "Table_5_between_year_robustness_EN"
paths <- file.path(out, paste0(stem, c(".png", ".pdf", ".rtf", ".csv")))
stopifnot(!any(file.exists(paths)))
weights <- c(.135, .17, .12, .10, .135, .135, .205)
weights <- weights / sum(weights)
draw <- function() {
  grid::grid.newpage()
  txt <- function(x, y, label, size = 10.3, bold = FALSE, just = "centre") {
    grid::grid.text(label, x, y, just = just,
      gp = grid::gpar(fontfamily = "Times New Roman", fontsize = size,
                      fontface = if (bold) "bold" else "plain", col = "black", lineheight = 1.05))
  }
  left <- .035; right <- .965
  edges <- left + c(0, cumsum(weights)) * (right - left)
  centers <- (head(edges, -1) + tail(edges, -1)) / 2
  txt(left, .945, title, size = 13, bold = TRUE, just = "left")
  for (y in c(.884, .755, .375)) {
    grid::grid.lines(c(left, right), rep(y, 2),
      gp = grid::gpar(col = "black", lwd = if (y == .755) .8 else 1.5))
  }
  for (j in seq_along(headers)) txt(centers[j], .820, headers[j], size = 10, bold = TRUE)
  for (i in seq_len(10)) for (j in seq_len(7)) {
    txt(if (j == 2) edges[j] + .008 else centers[j],
        .755 - (i - .5) * .038, rows[i, j], size = 10.1,
        just = if (j == 2) "left" else "centre")
  }
  for (i in seq_along(notes)) txt(left, .325 - (i - 1) * .033, notes[i], size = 9.3, just = "left")
}
grDevices::cairo_pdf(paths[2], width = 8.4, height = 5.4, family = "Times New Roman", bg = "white")
draw(); grDevices::dev.off()
grDevices::png(paths[1], width = 3360, height = 2160, units = "px", res = 400, type = "cairo", bg = "white")
draw(); grDevices::dev.off()

# Native RTF table: no vertical or internal horizontal borders, except the header rule.
# Each horizontal rule is formed by adjoining cell borders, as in a Word table.
esc <- function(x) {
  x <- gsub("\\", "\\\\", x, fixed = TRUE)
  x <- gsub("{", "\\{", x, fixed = TRUE)
  x <- gsub("}", "\\}", x, fixed = TRUE)
  gsub("\n", "\\line ", x, fixed = TRUE)
}
stops <- round(cumsum(weights) * 10800)
rtf <- c("{\\rtf1\\ansi\\deff0{\\fonttbl{\\f0 Times New Roman;}}",
         "\\paperw12240\\paperh15840\\margl720\\margr720\\margt720\\margb720",
         paste0("\\pard\\f0\\fs24\\b ", esc(title), "\\b0\\par\\pard\\sa160\\par"))
for (i in 0:10) {
  cell_specs <- vapply(seq_len(7), function(j) {
    paste0("\\clvertalc",
      if (i == 0) "\\clbrdrt\\brdrs\\brdrw20\\clbrdrb\\brdrs\\brdrw10" else "",
      if (i == 10) "\\clbrdrb\\brdrs\\brdrw20" else "",
      "\\cellx", stops[j])
  }, character(1))
  vals <- if (i == 0) headers else as.character(rows[i, ])
  cell_text <- vapply(seq_len(7), function(j) {
    paste0("\\pard\\intbl", if (j == 2 && i != 0) "\\ql" else "\\qc",
      "\\f0\\fs20\\sb90\\sa90", if (i == 0) "\\b " else "\\b0 ", esc(vals[j]), "\\cell")
  }, character(1))
  rtf <- c(rtf, paste0("\\trowd\\trgaph60\\trleft0", if (i == 0) "\\trhdr" else "",
                      paste(cell_specs, collapse = ""), paste(cell_text, collapse = ""), "\\row"))
}
rtf <- c(rtf, paste0("\\pard\\f0\\fs19\\b0\\sb160\\sa0 ", esc(paste(notes, collapse = " ")), "\\par"), "}")
writeLines(rtf, paths[3], useBytes = TRUE)
write.csv(rows, paths[4], row.names = FALSE)
stopifnot(identical(before, tools::md5sum(src)), all(file.info(paths)$size > 0),
          identical(read.csv(paths[4], colClasses = "character", check.names = FALSE), rows))
cat("PASS: ten rows, three-rule export, unchanged source; PNG/PDF preview and editable RTF created\n")
