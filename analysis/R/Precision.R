options(encoding = "UTF-8")
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("Usage: Rscript --vanilla R/Precision.R <analysis_directory> <new_output_directory>")
project <- normalizePath(args[1], winslash = "/", mustWork = TRUE)
src <- file.path(project, "outputs/tables/formal/08_overall_edges_with_accuracy.csv")
out <- args[2]
if (file.exists(out) || dir.exists(out)) stop("Output directory already exists: ", out)
dir.create(out, recursive = TRUE, showWarnings = FALSE)
d <- read.csv(src, check.names = FALSE)
zall <- d[d$Wave %in% c(2012, 2016, 2020), ]
stopifnot(nrow(zall) == 108L, !anyNA(zall[c("Point_edge", "Percentile_2_5", "Percentile_97_5")]),
          all(zall$Percentile_2_5 <= zall$Percentile_97_5),
          all(zall$Percentile_2_5 >= -0.25), all(zall$Percentile_97_5 <= 0.55),
          all(zall$Retained_under_EBICglasso == (zall$Point_edge != 0)))
for (year in c(2012, 2016, 2020)) {
  z <- zall[zall$Wave == year, ]
  z <- z[order(z$Point_edge, z$Edge_ID), ]
  stopifnot(nrow(z) == 36L)
  y <- seq_len(nrow(z))
  col <- ifelse(z$Retained_under_EBICglasso, "#0072B2", "#666666")
  pch <- ifelse(z$Retained_under_EBICglasso, 16L, 1L)
  png(file.path(out, paste0("precision_",year,"_print.png")), width = 159.2/25.4,
      height = 8, units = "in", res = 300, type = "cairo", bg = "white", pointsize = 10)
  par(mai = c(0.62, 1.74, 0.38, 0.10), family = "serif", mgp = c(2.6, 0.5, 0), tcl = -0.25)
  plot(NA, xlim = c(-0.25,0.55), ylim=c(0.4,36.6), xaxs="i", yaxs="i", xlab="", ylab="", axes=FALSE)
  abline(v=0,lty=2,col="#888888",lwd=0.7)
  segments(z$Percentile_2_5,y,z$Percentile_97_5,y,col=col,lwd=1)
  points(z$Point_edge,y,col=col,pch=pch,cex=0.72)
  axis(1,at=seq(-0.2,0.5,0.1),cex.axis=0.95)
  axis(2,at=y,labels=z$Edge_ID,las=1,tick=FALSE,cex.axis=0.87)
  box(col="#777777",lwd=0.5)
  mtext("Regularised partial-correlation edge weight",side=1,line=2.8,cex=0.95)
  mtext(paste0(year," edge-weight accuracy"),side=3,line=0.7,cex=1,font=2)
  legend("bottomright",legend=c("Retained", "Not retained"),pch=c(16,1),
         col=c("#0072B2","#666666"),bty="n",cex=0.88,inset=0.015)
  dev.off()
}
write.csv(zall[c("Wave","Edge_ID","Point_edge","Retained_under_EBICglasso","Percentile_2_5","Percentile_97_5")],
          file.path(out,"precision_display_values.csv"),row.names=FALSE)
cat("PASS: all 108 saved estimates and percentile intervals preserved; no model fitted.\n")
