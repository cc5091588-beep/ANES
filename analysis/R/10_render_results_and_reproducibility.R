options(stringsAsFactors = FALSE, warn = 1)

paths_file <- local({
  sources <- as.character(unlist(lapply(sys.frames(), function(frame) frame$ofile), use.names = FALSE))
  command_file <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE))
  starts <- unique(c(dirname(sources), dirname(command_file), getwd()))
  candidates <- unique(unlist(lapply(starts, function(at) {
    c(file.path(at, "Paths.R"), file.path(at, "R", "Paths.R"),
      file.path(at, "..", "R", "Paths.R"), file.path(at, "analysis", "R", "Paths.R"))
  }), use.names = FALSE))
  valid <- vapply(candidates, function(path) {
    file.exists(path) &&
      file.exists(file.path(dirname(path), "..", "config", "Submission"))
  }, logical(1))
  if (!any(valid)) stop("Cannot find Paths.R in a marked submission analysis directory.")
  normalizePath(candidates[which(valid)[1L]], winslash = "/", mustWork = TRUE)
})
source(paths_file, local = TRUE)
project_root <- anes_project_root()

if (!requireNamespace("rmarkdown", quietly = TRUE)) {
  stop("Render STOP: package 'rmarkdown' is unavailable.")
}

# ANES_PANDOC may identify a Pandoc executable or its containing directory.
# Otherwise use RStudio's configuration or an executable available on PATH.
pandoc_config <- Sys.getenv("ANES_PANDOC", unset = "")
if (nzchar(pandoc_config)) {
  pandoc_name <- if (.Platform$OS.type == "windows") "pandoc.exe" else "pandoc"
  pandoc_file <- if (dir.exists(pandoc_config)) {
    file.path(pandoc_config, pandoc_name)
  } else pandoc_config
  if (!file.exists(pandoc_file) || dir.exists(pandoc_file)) {
    stop("Render STOP: ANES_PANDOC must identify an existing Pandoc executable or its directory.")
  }
  Sys.setenv(RSTUDIO_PANDOC = dirname(normalizePath(
    pandoc_file, winslash = "/", mustWork = TRUE
  )))
}
if (!rmarkdown::pandoc_available()) {
  stop("Render STOP: Pandoc was not found. Install Pandoc or set ANES_PANDOC to its executable directory; a local installation is not bundled.")
}

input_file <- file.path(project_root, "notebooks", "10_results_and_reproducibility.Rmd")
output_file <- file.path(project_root, "notebooks", "10_results_and_reproducibility.html")

rmarkdown::render(
  input = input_file,
  output_file = basename(output_file),
  output_dir = dirname(output_file),
  params = list(
    execute_engine = FALSE,
    execute_independent_audit = FALSE
  ),
  envir = new.env(parent = globalenv()),
  clean = TRUE,
  quiet = FALSE
)

if (!file.exists(output_file) || file.info(output_file)$size <= 0) {
  stop("Render STOP: Step 10 HTML was not created.")
}

message("STEP 10 HTML RENDER COMPLETE.")
