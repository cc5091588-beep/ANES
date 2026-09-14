# Presentation only: replot saved ANES estimates; no estimation or resampling.
# Usage: Rscript --vanilla plot_results_figures.R <analysis_project> <output_dir> [--replace-generated]
# Source inputs are read-only. Existing outputs require explicit replacement.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) %in% c(2L, 3L))
replace_generated <- length(args) == 3L && identical(args[3], "--replace-generated")
if (length(args) == 3L) stopifnot(replace_generated)
project <- normalizePath(args[1], winslash = "/", mustWork = TRUE)
out <- args[2]
if (!dir.exists(out)) dir.create(out, recursive = TRUE)
out <- normalizePath(out, winslash = "/", mustWork = TRUE)
options(stringsAsFactors = FALSE, scipen = 10)

sources <- c(
  overall = "outputs/tables/formal/07_formal_five_wave_edge_weights.csv",
  education = "outputs/tables/formal/08B_education_edge_weights.csv",
  coordinates = "outputs/tables/formal/08_common_layout_coordinates.csv",
  overall_summary = "outputs/tables/final/10_sample_primary_summary.csv",
  education_summary = "outputs/tables/final/10_education_summary.csv"
)
source_paths <- file.path(project, sources)
stopifnot(all(file.exists(source_paths)))
source_md5_before <- tools::md5sum(source_paths)
read_source <- function(name) read.csv(file.path(project, sources[[name]]), check.names = FALSE)
overall <- read_source("overall")
education <- read_source("education")
coords <- read_source("coordinates")
overall_summary <- read_source("overall_summary")
education_summary <- read_source("education_summary")
nodes <- c("VCF0806", "VCF0809", "VCF0838", "VCF0839", "VCF0879a", "VCF0888", "VCF0890", "VCF0894", "VCF9223")
abbr <- c("HEA", "JOB", "ABO", "SER", "IMM", "CRI", "SCH", "WEL", "LJT")
short <- c("Health", "Jobs", "Abortion", "Services", "Immigration", "Crime", "Schools", "Welfare", "Less job threat")
names(abbr) <- names(short) <- nodes
mapping <- data.frame(
  Node = nodes, Abbreviation = unname(abbr), Short_label = unname(short),
  Higher_values_mean = c(
    "Greater support for government health insurance",
    "Greater government responsibility for jobs and living standards",
    "More permissive abortion policy", "More government services and spending",
    "Greater support for increasing immigration",
    "Greater support for increased federal crime spending",
    "Greater support for increased federal public-school spending",
    "Greater support for increased federal welfare spending",
    "Lower perceived likelihood that immigration takes jobs"
  )
)
waves <- c(2004, 2012, 2016, 2020, 2024)
edu_keys <- as.vector(rbind(paste0(waves[-1], "__no_college_degree"), paste0(waves[-1], "__college_or_advanced")))
coords <- coords[match(nodes, coords$Node), ]
stopifnot(identical(coords$Node, nodes), all(is.finite(as.matrix(coords[c("x", "y")]))))
# Fixed combinatorial order groups every edge by its first node.
pair_idx <- t(combn(seq_along(nodes), 2))
pairs <- data.frame(Node_1 = nodes[pair_idx[, 1]], Node_2 = nodes[pair_idx[, 2]])
pair_key <- function(a, b) paste(pmin(match(a, nodes), match(b, nodes)), pmax(match(a, nodes), match(b, nodes)), sep = "|")
pairs$Pair_key <- pair_key(pairs$Node_1, pairs$Node_2)
pairs$Edge_label <- paste(abbr[pairs$Node_1], abbr[pairs$Node_2], sep = " - ")
overall$Pair_key <- pair_key(overall$Node_1, overall$Node_2)
education$Pair_key <- pair_key(education$Node_1, education$Node_2)
stopifnot(nrow(overall) == 180L, nrow(education) == 288L,
          all(is.finite(overall$Edge_weight)), all(is.finite(education$Edge_weight)),
          max(abs(c(overall$Edge_weight, education$Edge_weight))) <= 0.5,
          all(overall$Retained_under_EBICglasso == (overall$Edge_weight != 0)),
          all(education$Retained_under_EBICglasso == (education$Edge_weight != 0)))

matrix_for <- function(data, groups, group_col) {
  ans <- matrix(NA_real_, 36, length(groups), dimnames = list(pairs$Edge_label, groups))
  for (g in seq_along(groups)) {
    d <- data[data[[group_col]] == groups[g], ]
    stopifnot(nrow(d) == 36L, !anyDuplicated(d$Pair_key), setequal(d$Pair_key, pairs$Pair_key))
    ans[, g] <- d$Edge_weight[match(pairs$Pair_key, d$Pair_key)]
  }
  stopifnot(all(is.finite(ans)))
  ans
}
main_mat <- matrix_for(overall, waves, "Wave")
edu_mat <- matrix_for(education, edu_keys, "Group_key")
main_n <- overall_summary$Analysis_ready_n[match(waves, overall_summary$Wave)]
edu_n <- education_summary$N[match(edu_keys, education_summary$Group_key)]
stopifnot(identical(as.integer(main_n), c(789L, 4353L, 2709L, 5390L, 3525L)),
          identical(as.integer(edu_n), c(2773L, 1531L, 1478L, 1216L, 2624L, 2691L, 1729L, 1781L)))

file_stems <- c("Figure_4_1_primary_networks", "Figure_4_2_year_edge_heatmap", "Figure_4_3_education_edge_heatmap")
output_names <- c(as.vector(outer(file_stems, c(".pdf", ".png"), paste0)),
                  "figure_node_key.csv", "figure_edge_row_order.csv", "Figure_4_1_source_edges.csv",
                  "Figure_4_1_source_coordinates.csv", "Figure_4_2_source_matrix.csv",
                  "Figure_4_3_source_matrix.csv", "Figure_4_3_source_edges.csv",
                  "figure_validation.csv", "figure_source_inventory.csv", "figure_export_manifest.csv")
if (!replace_generated) stopifnot(!any(file.exists(file.path(out, output_names))))
write.csv(mapping, file.path(out, "figure_node_key.csv"), row.names = FALSE)
write.csv(pairs, file.path(out, "figure_edge_row_order.csv"), row.names = FALSE)
write.csv(overall, file.path(out, "Figure_4_1_source_edges.csv"), row.names = FALSE)
write.csv(coords, file.path(out, "Figure_4_1_source_coordinates.csv"), row.names = FALSE)
write.csv(cbind(pairs, main_mat), file.path(out, "Figure_4_2_source_matrix.csv"), row.names = FALSE)
write.csv(cbind(pairs, edu_mat), file.path(out, "Figure_4_3_source_matrix.csv"), row.names = FALSE)
write.csv(education, file.path(out, "Figure_4_3_source_edges.csv"), row.names = FALSE)

blue <- "#0072B2"
orange <- "#D55E00"
ink <- "#182A36"
palette <- grDevices::colorRampPalette(c(orange, "#FFFFFF", blue), space = "Lab")(1001)
weight_colour <- function(w) palette[pmax(1L, pmin(1001L, round((w + 0.5) * 1000) + 1L))]
lum <- function(col) {
  z <- grDevices::col2rgb(col) / 255
  z <- ifelse(z <= 0.04045, z / 12.92, ((z + 0.055) / 1.055)^2.4)
  drop(c(0.2126, 0.7152, 0.0722) %*% z)
}
text_colour <- function(col) ifelse(lum(col) < 0.179, "white", "#151515")
fmt_weight <- function(w) {
  ans <- sprintf("%.2f", w)
  ans[w == 0] <- "-"
  tiny <- w != 0 & abs(w) < 0.005
  ans[tiny] <- sprintf("%.3f", w[tiny])
  extremely_tiny <- w != 0 & abs(w) < 0.0005
  ans[extremely_tiny] <- sprintf("%.4f", w[extremely_tiny])
  beyond_four_dp <- w != 0 & abs(w) < 0.00005
  ans[beyond_four_dp] <- formatC(w[beyond_four_dp], format = "e", digits = 1)
  ans
}

export_plot <- function(stem, draw, width, height) {
  grDevices::cairo_pdf(file.path(out, paste0(stem, ".pdf")), width = width, height = height,
                       family = "Arial", bg = "white", pointsize = 10)
  draw()
  grDevices::dev.off()
  grDevices::png(file.path(out, paste0(stem, ".png")), width = width, height = height,
                 units = "in", res = 400, type = "cairo", bg = "white", pointsize = 10)
  draw()
  grDevices::dev.off()
}

draw_networks <- function() {
  par(mfrow = c(3, 2), mar = c(0.2, 0.2, 2, 0.2), oma = c(1.6, 0, 2.1, 0),
      family = "sans", xpd = NA, cex = 1)
  for (j in seq_along(waves)) {
    plot.new()
    plot.window(xlim = c(-1.24, 1.24), ylim = c(-1.2, 1.2), asp = 1)
    title(main = sprintf("%s  |  N = %s", waves[j], format(main_n[j], big.mark = ",")),
          cex.main = 1.05, col.main = ink, line = 0.5)
    w <- main_mat[, j]
    # Thin retained edges remain drawn; the only omission is an exact saved zero.
    for (k in order(abs(w))) if (w[k] != 0) {
      p <- pair_idx[k, ]
      segments(coords$x[p[1]], coords$y[p[1]], coords$x[p[2]], coords$y[p[2]],
               col = if (w[k] > 0) blue else orange,
               lty = if (w[k] > 0) 1 else 2, lwd = 0.35 + 4.65 * abs(w[k]) / 0.5)
    }
    symbols(coords$x, coords$y, circles = rep(0.137, 9), inches = FALSE,
            add = TRUE, bg = "white", fg = ink, lwd = 0.8)
    text(coords$x, coords$y, abbr, cex = 0.77, font = 2, col = ink)
  }
  plot.new()
  plot.window(xlim = c(0, 1), ylim = c(0, 1))
  text(0.03, 0.98, "Node key", adj = c(0, 1), font = 2, cex = 1.05, col = ink)
  labels <- c("HEA  Government health insurance", "JOB  Government jobs responsibility",
              "ABO  Abortion policy", "SER   Government services / spending",
              "IMM  Immigration level", "CRI   Federal crime spending",
              "SCH  Federal public-school spending", "WEL Federal welfare spending",
              "LJT   Lower immigration job threat")
  for (i in seq_along(labels)) text(0.03, 0.895 - (i - 1) * 0.066, labels[i],
                                  adj = c(0, 0.5), cex = 0.84, col = ink)
  segments(0.03, 0.23, 0.21, 0.23, col = blue, lwd = 2.7)
  text(0.25, 0.23, "Positive edge", adj = 0, cex = 0.84)
  segments(0.03, 0.165, 0.21, 0.165, col = orange, lwd = 2.7, lty = 2)
  text(0.25, 0.165, "Negative edge", adj = 0, cex = 0.84)
  text(0.03, 0.08, "Common edge-width maximum: |w| = 0.50\nExact zero: not retained; no line drawn.",
       adj = c(0, 0.5), cex = 0.79, col = ink)
  mtext("Figure 4.1  Policy-attitude networks across five election years", outer = TRUE,
        side = 3, line = 0.55, cex = 0.96, font = 2, col = ink)
  mtext("Saved point estimates; common node positions and edge-width scale in every panel.",
        outer = TRUE, side = 1, line = 0.35, cex = 0.75, col = ink)
}

grid_text <- function(label, x, y, size = 8.5, col = ink, just = "centre", bold = FALSE) {
  grid::grid.text(label, x = x, y = y, just = just,
                  gp = grid::gpar(fontfamily = "Arial", fontsize = size, col = col,
                                   fontface = if (bold) "bold" else "plain"))
}
draw_heatmap <- function(mat, education_plot = FALSE) {
  grid::grid.newpage()
  nr <- nrow(mat)
  nc <- ncol(mat)
  title <- if (education_plot) "Figure 4.3  Edge weights by education group" else "Figure 4.2  Edge weights across election years"
  grid_text(title, 0.04, 0.973, size = 11.5, just = "left", bold = TRUE)
  grid_text("All 36 node pairs; saved regularised conditional-association estimates", 0.04, 0.95,
            size = 9, just = "left")
  left <- 0.19
  right <- 0.97
  top <- 0.867
  bottom <- 0.236
  dx <- (right - left) / nc
  dy <- (top - bottom) / nr
  xpos <- left + (seq_len(nc) - 0.5) * dx
  ypos <- top - (seq_len(nr) - 0.5) * dy
  grid_text("Node pair", left - 0.012, 0.887, size = 9, just = "right", bold = TRUE)
  if (!education_plot) {
    for (j in seq_len(nc)) {
      grid_text(waves[j], xpos[j], 0.915, size = 10.5, bold = TRUE)
      grid_text(paste0("N = ", format(main_n[j], big.mark = ",")), xpos[j], 0.89, size = 8.5)
    }
  } else {
    for (g in 1:4) grid_text(waves[g + 1], mean(xpos[(2 * g - 1):(2 * g)]), 0.925, size = 10.5, bold = TRUE)
    for (j in seq_len(nc)) {
      grid_text(if (j %% 2 == 1) "No degree" else "Degree", xpos[j], 0.903, size = 8.4)
      grid_text(paste0("N = ", format(edu_n[j], big.mark = ",")), xpos[j], 0.884, size = 7.8)
    }
  }
  for (i in seq_len(nr)) {
    grid_text(rownames(mat)[i], left - 0.012, ypos[i], size = 8.4, just = "right")
    for (j in seq_len(nc)) {
      fill <- if (is.na(mat[i, j])) "#808080" else weight_colour(mat[i, j])
      grid::grid.rect(xpos[j], ypos[i], width = dx, height = dy,
                      gp = grid::gpar(fill = fill, col = "#E4E8EA", lwd = 0.45))
      lab <- if (is.na(mat[i, j])) "NA" else fmt_weight(mat[i, j])
      grid_text(lab, xpos[j], ypos[i], size = if (education_plot) 7.7 else 8.5,
                col = text_colour(fill))
    }
  }
  if (education_plot) for (g in 1:3) grid::grid.lines(
    x = rep(left + 2 * g * dx, 2), y = c(bottom, top),
    gp = grid::gpar(col = "#687780", lwd = 1.1))
  # Horizontal separators follow the fixed first-node grouping; no clustering.
  for (i in cumsum(8:2)) grid::grid.lines(x = c(left, right), y = rep(top - i * dy, 2),
                                        gp = grid::gpar(col = "#A9B3B8", lwd = 0.75))
  legend_left <- 0.31
  legend_right <- 0.87
  colour_vals <- seq(-0.5, 0.5, length.out = 300)
  for (k in seq_along(colour_vals)) grid::grid.rect(
    x = legend_left + (k - 0.5) * (legend_right - legend_left) / 300,
    y = 0.198, width = (legend_right - legend_left) / 300 + 0.0001, height = 0.011,
    gp = grid::gpar(fill = weight_colour(colour_vals[k]), col = NA))
  for (val in c(-0.5, -0.25, 0, 0.25, 0.5)) grid_text(
    sprintf("%.2f", val), legend_left + (val + 0.5) * (legend_right - legend_left), 0.182, size = 8)
  grid_text("Signed edge weight", 0.59, 0.216, size = 8.5)
  grid_text("- = exact zero (not retained).  Small nonzero weights are kept; no cells are missing.",
            0.04, 0.155, size = 8.1, just = "left")
  legend <- c("HEA: government health insurance; JOB: government jobs / living-standards responsibility;",
              "ABO: abortion policy; SER: government services / spending; IMM: immigration level;",
              "CRI: crime spending; SCH: public-school spending; WEL: welfare spending;",
              "LJT: lower perceived likelihood that immigration takes jobs.")
  for (i in seq_along(legend)) grid_text(legend[i], 0.04, 0.128 - (i - 1) * 0.017,
                                        size = 7.9, just = "left")
  if (education_plot) grid_text("No degree: VCF0110 = 1-3.  Degree: college / advanced degree (VCF0110 = 4).",
                                0.04, 0.046, size = 7.9, just = "left")
  grid_text("Common colour limits: -0.50 to +0.50. Cell labels are rounded; exact values accompany the figure.",
            0.04, 0.026, size = 7.7, just = "left")
}

export_plot(file_stems[1], draw_networks, width = 6, height = 9.5)
export_plot(file_stems[2], function() draw_heatmap(main_mat), width = 6, height = 10)
export_plot(file_stems[3], function() draw_heatmap(edu_mat, TRUE), width = 6, height = 10)

source_md5_after <- tools::md5sum(source_paths)
validation <- data.frame(
  Check = c("All 180 overall edges plotted", "All 288 education edges plotted", "All 36 pairs preserved",
            "No missing weights", "All weights within common +/-0.50 scale", "Exact zero matches saved retention",
            "Saved node coordinates preserved", "Source files unchanged", "Overall edge count matches saved summary",
            "Overall global strength matches saved summary", "Education edge counts match saved summary"),
  Passed = c(length(main_mat) == 180L, length(edu_mat) == 288L, nrow(main_mat) == 36L && nrow(edu_mat) == 36L,
             !anyNA(main_mat) && !anyNA(edu_mat), max(abs(c(main_mat, edu_mat))) <= 0.5,
             all(overall$Retained_under_EBICglasso == (overall$Edge_weight != 0)) && all(education$Retained_under_EBICglasso == (education$Edge_weight != 0)),
             identical(coords, read_source("coordinates")[match(nodes, read_source("coordinates")$Node), ]),
             identical(source_md5_before, source_md5_after),
             identical(as.integer(colSums(main_mat != 0)), as.integer(overall_summary$Retained_edges[match(waves, overall_summary$Wave)])),
             max(abs(colSums(abs(main_mat)) - overall_summary$Global_strength_descriptive[match(waves, overall_summary$Wave)])) < 1e-12,
             identical(as.integer(colSums(edu_mat != 0)), as.integer(education_summary$Retained_edges[match(edu_keys, education_summary$Group_key)])))
)
stopifnot(all(validation$Passed))
write.csv(validation, file.path(out, "figure_validation.csv"), row.names = FALSE)
write.csv(data.frame(Source_role = names(sources), Relative_path = unname(sources),
                     MD5_before = unname(source_md5_before), MD5_after = unname(source_md5_after)),
          file.path(out, "figure_source_inventory.csv"), row.names = FALSE)
write.csv(data.frame(Figure = file_stems, Width_inches = 6, Height_inches = c(9.5, 10, 10),
                     PNG_DPI = 400, PNG_width_px = 2400, PNG_height_px = c(3800, 4000, 4000),
                     Vector_format = "PDF (Cairo)", Common_absolute_edge_limit = 0.5,
                     Positive_colour = blue, Negative_colour = orange, R_version = R.version.string,
                     Model_reestimated = FALSE, New_test_performed = FALSE),
          file.path(out, "figure_export_manifest.csv"), row.names = FALSE)
print(validation, row.names = FALSE)
cat("PASS: presentation-only export of three figures from saved estimates\n")
