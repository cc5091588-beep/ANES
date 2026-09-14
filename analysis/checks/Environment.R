# Read-only package and startup-path audit. No install, restore, activation or model run.
# From the submission root: Rscript --vanilla analysis/checks/Environment.R
# From analysis/: Rscript --vanilla checks/Environment.R
# Optional: --project=/path/to/analysis

environment_check <- function(project = NULL) {
  args <- commandArgs(trailingOnly = TRUE)
  selected <- sub("^--project=", "", grep("^--project=", args, value = TRUE))
  if (is.null(project) && length(selected)) project <- selected[[1L]]
  if (is.null(project)) {
    script <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE))
    if (length(script) && basename(script[[1L]]) == "Environment.R") {
      project <- dirname(dirname(normalizePath(script[[1L]], winslash = "/")))
    } else {
      frames <- lapply(sys.frames(), function(frame) frame$ofile)
      frames <- Filter(function(path) is.character(path) && length(path) == 1L,
                       frames)
      if (length(frames)) {
        project <- dirname(dirname(normalizePath(tail(frames, 1L)[[1L]],
                                                winslash = "/")))
      } else if (file.exists("renv.lock")) {
        project <- getwd()
      } else {
        project <- file.path(getwd(), "analysis")
      }
    }
  }
  project <- normalizePath(project, winslash = "/", mustWork = TRUE)
  lock_path <- file.path(project, "renv.lock")
  profile_path <- file.path(project, ".Rprofile")
  activation_path <- file.path(project, "renv", "activate.R")
  if (!file.exists(lock_path)) stop("Missing project lockfile: ", lock_path)

  has_jsonlite <- requireNamespace("jsonlite", quietly = TRUE)
  has_renv <- requireNamespace("renv", quietly = TRUE)
  if (!has_jsonlite && !has_renv) {
    stop("Neither jsonlite nor renv is installed in the current library paths. ",
         "Lockfile parsing is NOT CHECKED. This script does not install packages.")
  }
  text <- paste(readLines(lock_path, warn = FALSE, encoding = "UTF-8"),
                collapse = "\n")
  strict_json <- if (has_jsonlite) jsonlite::validate(text) else NA
  if (identical(strict_json, FALSE)) stop("Lockfile is not valid standard JSON.")
  lock <- if (has_renv) renv::lockfile_read(lock_path) else {
    jsonlite::fromJSON(text, simplifyVector = FALSE)
  }
  records <- lock$Packages
  if (!is.list(records) || !length(records) || is.null(names(records)) ||
      anyDuplicated(names(records))) stop("Missing or duplicate package records.")
  if (!all(vapply(names(records), function(name) {
    identical(records[[name]]$Package, name) &&
      is.character(records[[name]]$Version) && length(records[[name]]$Version) == 1L
  }, logical(1)))) stop("Invalid package identity or version in lockfile.")

  field <- function(record, name) {
    value <- record[[name]]
    if (is.null(value) || !length(value)) NA_character_ else as.character(value[[1L]])
  }
  audit_library <- function(paths) {
    paths <- paths[dir.exists(paths)]
    inventories <- lapply(paths, function(path) {
      utils::installed.packages(lib.loc = path, noCache = TRUE,
                                fields = c("Repository", "RemoteType", "RemoteUrl"))
    })
    inventories <- Filter(function(x) nrow(x) > 0L, inventories)
    installed <- if (length(inventories)) do.call(rbind, inventories) else NULL
    rows <- lapply(names(records), function(name) {
      record <- records[[name]]
      index <- if (is.null(installed)) NA_integer_ else match(name, installed[, "Package"])
      version <- repository <- library <- NA_character_
      if (!is.na(index)) {
        version <- installed[index, "Version"]
        repository <- installed[index, "Repository"]
        library <- installed[index, "LibPath"]
      }
      expected_repository <- field(record, "Repository")
      source_status <- if (is.na(index)) "NOT_INSTALLED" else if (
        is.na(repository) || !nzchar(repository) || is.na(expected_repository)
      ) "NOT_RECORDED" else if (identical(repository, expected_repository)) {
        "MATCH"
      } else "DIFFERENT"
      data.frame(Package = name, Locked = record$Version, Installed = version,
                 Status = if (is.na(index)) "MISSING" else if (
                   identical(version, record$Version)
                 ) "MATCH" else "VERSION_DIFFERENT",
                 Locked_source = field(record, "Source"),
                 Locked_repository = expected_repository,
                 Installed_repository = repository, Source_status = source_status,
                 Library = library, stringsAsFactors = FALSE)
    })
    do.call(rbind, rows)
  }

  runtime <- audit_library(.libPaths())
  project_library <- if (has_renv) renv::paths$library(project = project) else NA_character_
  isolated <- if (!is.na(project_library)) audit_library(project_library) else NULL
  profile_exists <- file.exists(profile_path)
  profile_text <- if (profile_exists) {
    readLines(profile_path, warn = FALSE, encoding = "UTF-8")
  } else character()
  expected_source <- 'source("renv/activate.R")'
  profile_relative <- any(trimws(profile_text) == expected_source) ||
    any(trimws(profile_text) == "source('renv/activate.R')")
  profile_parseable <- profile_exists && !inherits(
    tryCatch(parse(profile_path), error = identity), "error")
  startup_paths <- data.frame(
    Item = c("Project", "Lockfile", "Project profile", "Activation source",
             "R executable directory", "Expected project library"),
    Path = c(project, lock_path, profile_path, activation_path,
             R.home("bin"), project_library), stringsAsFactors = FALSE)
  startup_paths$Exists <- vapply(startup_paths$Path, function(path) {
    !is.na(path) && file.exists(path)
  }, logical(1))
  inherited <- Sys.getenv(c("R_PROFILE", "R_PROFILE_USER", "R_ENVIRON",
                           "R_ENVIRON_USER", "RENV_PROJECT", "RENV_PATHS_ROOT",
                           "RENV_PATHS_CACHE", "RENV_PATHS_LIBRARY"))
  loaded_names <- intersect(names(records), loadedNamespaces())
  loaded <- do.call(rbind, lapply(loaded_names, function(name) {
    data.frame(Package = name,
               Loaded_version = as.character(getNamespaceVersion(name)),
               Locked = records[[name]]$Version,
               Namespace_path = getNamespaceInfo(asNamespace(name), "path"),
               stringsAsFactors = FALSE)
  }))
  loaded_match <- is.null(loaded) || all(loaded$Loaded_version == loaded$Locked)
  r_matches <- identical(as.character(getRversion()), lock$R$Version)
  runtime_ready <- r_matches && all(runtime$Status == "MATCH") && loaded_match &&
    !any(runtime$Source_status == "DIFFERENT")
  project_ready <- !is.null(isolated) && all(isolated$Status == "MATCH") &&
    !any(isolated$Source_status == "DIFFERENT")

  cat("Read-only environment audit\n")
  print(startup_paths, row.names = FALSE)
  cat("\nStandard JSON: ", if (is.na(strict_json)) {
    "NOT CHECKED (jsonlite unavailable; renv parser succeeded)"
  } else "VALID", "\n", sep = "")
  cat("Locked packages: ", length(records), "; current R: ",
      as.character(getRversion()), "; locked R: ", lock$R$Version,
      "; R match: ", r_matches, "\n", sep = "")
  cat("Profile parses: ", profile_parseable,
      "; relative activation source: ", profile_relative,
      "; activation file exists: ", file.exists(activation_path), "\n", sep = "")
  cat("Current library paths:\n", paste(.libPaths(), collapse = "\n"), "\n", sep = "")
  cat("Current-runtime exact versions: ", sum(runtime$Status == "MATCH"), "/",
      nrow(runtime), "; runtime version/source readiness: ", runtime_ready, "\n", sep = "")
  differences <- runtime[runtime$Status != "MATCH" | runtime$Source_status == "DIFFERENT", ]
  if (nrow(differences)) {
    print(differences[, c("Package", "Locked", "Installed", "Status", "Source_status")],
          row.names = FALSE)
  }
  cat("Repository/source provenance unrecorded for ",
      sum(runtime$Source_status == "NOT_RECORDED"), " installed packages.\n", sep = "")
  if (!is.null(isolated)) {
    cat("Project-library exact versions: ", sum(isolated$Status == "MATCH"), "/",
        nrow(isolated), "; project-library readiness: ", project_ready, "\n", sep = "")
  }
  if (!is.null(loaded)) {
    cat("\nLoaded locked-package namespaces (including parser packages):\n")
    print(loaded, row.names = FALSE)
  }
  if (any(nzchar(inherited))) {
    cat("\nInherited startup and renv path settings (not changed):\n")
    print(inherited[nzchar(inherited)])
  }
  cat("\nThe script did not source a profile, activate renv, install packages, or restore.\n",
      "Under --vanilla the project profile is normally skipped. Missing project packages\n",
      "mean the isolated library is not ready; they do not demonstrate a failed restore.\n",
      "Version matches do not verify package binary integrity, clean restoration, or model replay.\n",
      "Audit completion and environment readiness are separate results.\n", sep = "")
  invisible(list(project = project, strict_json = strict_json, startup_paths = startup_paths,
                 profile_parseable = profile_parseable, profile_relative = profile_relative,
                 r_matches = r_matches, runtime = runtime, project_library = isolated,
                 loaded = loaded, runtime_ready = runtime_ready, project_ready = project_ready))
}

environment_audit_result <- environment_check()
