# Resolve only the marked analysis directory supplied with this submission.
# This helper reads path metadata and does not create or alter files.
anes_project_root <- local({
  source_files <- as.character(unlist(lapply(sys.frames(), function(frame) frame$ofile),
                                     use.names = FALSE))
  helper_files <- source_files[basename(source_files) == "Paths.R"]
  helper_root <- if (length(helper_files)) {
    normalizePath(file.path(dirname(tail(helper_files, 1L)), ".."),
                  winslash = "/", mustWork = TRUE)
  } else character()

  marked_project <- function(path) {
    length(path) == 1L && nzchar(path) && dir.exists(path) &&
      file.exists(file.path(path, "config", "Submission")) &&
      file.exists(file.path(path, "renv.lock")) &&
      dir.exists(file.path(path, "notebooks")) &&
      dir.exists(file.path(path, "R"))
  }

  function(start = getwd()) {
    configured <- Sys.getenv("ANES_PROJECT_ROOT", unset = "")
    if (nzchar(configured)) {
      if (!marked_project(configured)) {
        stop("ANES_PROJECT_ROOT must point to the submission analysis directory containing config/Submission, renv.lock, notebooks and R; an unmarked original project is not allowed.")
      }
      return(normalizePath(configured, winslash = "/", mustWork = TRUE))
    }

    at <- normalizePath(start, winslash = "/", mustWork = TRUE)
    if (!dir.exists(at)) at <- dirname(at)
    candidates <- character()
    repeat {
      candidates <- c(candidates, at, file.path(at, "analysis"))
      parent <- dirname(at)
      if (identical(parent, at)) break
      at <- parent
    }
    candidates <- unique(c(candidates, helper_root))
    valid <- vapply(candidates, marked_project, logical(1))
    if (!any(valid)) {
      stop("No marked submission analysis directory found. Run from the extracted submission, or set ANES_PROJECT_ROOT to its analysis directory.")
    }
    normalizePath(candidates[which(valid)[1L]], winslash = "/", mustWork = TRUE)
  }
})
