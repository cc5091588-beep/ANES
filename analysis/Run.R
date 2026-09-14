# Saved-output checks and reproduction of figures/tables. No model estimation.
args <- commandArgs(trailingOnly = TRUE)
task <- if (length(args)) args[1] else "check"
file_arg <- grep("^--file=", commandArgs(), value = TRUE)
if (length(file_arg) != 1L) stop("Run with Rscript --vanilla analysis/Run.R <task>")
project_root <- normalizePath(dirname(sub("^--file=", "", file_arg)), winslash = "/", mustWork = TRUE)
stopifnot(file.exists(file.path(project_root, "config", "Submission")))
repo <- dirname(project_root)
rscript <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
run <- function(script, arguments = character()) {
  status <- system2(rscript, c("--vanilla", shQuote(file.path(project_root, script)), shQuote(arguments)))
  if (!identical(status, 0L)) stop("Command failed: ", script, " (exit ", status, ")")
}
if (task == "check") {
  run("checks/Check.R", repo)
} else if (task == "preflight") {
  run("checks/Preflight.R", project_root)
} else if (task == "environment") {
  run("checks/Environment.R", paste0("--project=", project_root))
} else if (task %in% c("figures", "tables", "precision")) {
  out <- if (length(args) >= 2L) args[2] else file.path(repo, "runs", task)
  if (file.exists(out) || dir.exists(out)) stop("Choose a new output directory: ", out)
  if (task == "figures") run("R/Figures.R", c(project_root, out))
  if (task == "precision") run("R/Precision.R", c(project_root, out))
  if (task == "tables") {
    run("R/Tables.R", c(project_root, out))
    run("R/Robustness.R", c(file.path(project_root, "plotdata/tables/Table_4_3_year_contrast_robustness.csv"), file.path(out, "robustness")))
  }
} else {
  stop("Tasks: check, figures, tables, precision, environment, preflight. Full analysis replay is not implemented by this entry point.")
}
