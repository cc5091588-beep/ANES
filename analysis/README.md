# Analysis

## Check the saved results

From the repository folder, with R on PATH:

```text
Rscript --vanilla analysis/Run.R check
```

This checks 50 relationships in the saved CSV files, including sample flow, edge counts, global strength and interval summaries. It does not estimate models.

To check the current file hashes on Windows:

```text
powershell -NoProfile -ExecutionPolicy Bypass -File analysis/checks/Files.ps1
```

The execution-policy setting applies only to that command. `checks/Files.csv` is the current delivery manifest. Earlier manifests describe the original runs, not this reorganised copy.

Readers should run `Files.ps1`, not regenerate the manifest to make a failed download pass. Intentional changes to repository files require the maintainer to update the manifest after reviewing those changes; see the final section below.

## Regenerate figures and tables

The table generator requires `digest`; complete the environment setup below before using `tables`. These command-line routes were tested on Windows. The table script's project-library fallback is Windows-specific; on other systems `digest` must be available in the library seen by `Rscript --vanilla`.

```text
Rscript --vanilla analysis/Run.R figures
Rscript --vanilla analysis/Run.R tables
Rscript --vanilla analysis/Run.R precision
```

These commands read saved estimates and write new files under `runs/`. They stop if the destination already exists. To run again, supply a different destination as the next argument. They do not rerun networks or bootstrap analyses. Fonts and graphics devices may affect appearance.

`R/` contains the independent scripts. `notebooks/` contains the editable R Markdown files and existing HTML reports. `plotdata/` holds the exact data exports used for the manuscript figures. The original internal filenames are retained where they identify dependencies or historical records.

## First-time setup

Reading the appendix, figures and CSV files requires no R setup. The saved-result check uses base R; the table generator also needs `digest`. None of these saved-output operations requires the ANES respondent data. Restore the project environment before using `tables` or attempting to run the original analysis notebooks.

1. Install R 4.5.2 and RStudio. `renv` restores R packages, not R itself. Use a separate downloaded copy for any analysis rerun.
2. Open `analysis/ANES.Rproj` in RStudio. If prompted, allow the supplied `renv/activate.R` to install renv 1.2.0. This requires internet access unless the package is cached.
3. In the R console, with `analysis` as the working directory, run:

```r
stopifnot(file.exists("renv.lock"), file.exists("config/Submission"))
renv::restore(project = getwd(), prompt = FALSE)
renv::status(project = getwd())
source("checks/Environment.R")
stopifnot(
  isTRUE(environment_audit_result$r_matches),
  isTRUE(environment_audit_result$runtime_ready)
)
```

`restore()` installs the locked package versions; `status()` and `Environment.R` check them. If restoration or the checks fail, stop and retain the error message. Do not replace the lockfile with a new `snapshot()` or update packages to get past the checks. Source-package installation may require compiler/system dependencies. R Markdown rendering also requires Pandoc, which is normally supplied with RStudio. See the [renv setup documentation](https://rstudio.github.io/renv/articles/renv.html) and [restore reference](https://rstudio.github.io/renv/reference/restore.html).

Opening the project and restoring packages is environment preparation, not a successful analysis rerun. From an ordinary terminal, `Rscript --vanilla analysis/Run.R environment` deliberately skips the project profile and only inspects the libraries visible in that new session. Use the console check above to inspect the activated project library.

## Data and tested environment

Use R 4.5.2 and the versions in `renv.lock`. The lockfile has been converted to standard JSON without changing package versions. An isolated offline restore into an empty library succeeded on the author's Windows/R 4.5.2 computer; all 164 locked versions matched. The test used copies of locally cached packages, not downloads. Restoration on another computer and the complete analysis rebuild remain unverified. See `checks/Environment.txt`.

`Rscript --vanilla analysis/Run.R environment` compares available package versions with the lockfile. Under `--vanilla`, R skips the project profile; this command does not activate, install or restore packages.

Obtain the ANES Time Series Cumulative Data File release dated 5 February 2026 from the [ANES Data Center](https://electionstudies.org/data-center/anes-time-series-cumulative-data-file/). The required Stata file is `anes_timeseries_cdf_stata_20260205.dta`, 609440121 bytes, SHA-256:

```text
45323c30faee1e9e67c2351c4302c31472b117050bef240d9339a264e2f3e078
```

Copy `config/anes_cdf_path.txt.example` to `config/anes_cdf_path.txt`. Replace its contents with one line containing the full local path to that Stata file, using forward slashes and no quotes. The file may remain outside the repository. In the activated R console, check it before analysis:

```r
cdf_file <- trimws(readLines("config/anes_cdf_path.txt", warn = FALSE))
stopifnot(length(cdf_file) == 1L, nzchar(cdf_file), file.exists(cdf_file))
stopifnot(
  file.info(cdf_file)$size == 609440121,
  identical(
    digest::digest(file = cdf_file, algo = "sha256", serialize = FALSE),
    "45323c30faee1e9e67c2351c4302c31472b117050bef240d9339a264e2f3e078"
  )
)
```

Do not commit the data or the local path configuration. Selection audits also refer to official codebooks and wave documentation listed in `config/evidence_input_spec.csv` and `data/audit/node_wave_selection_inputs/`.

The decision records are in `project_docs/`. The supplied path settings point to that directory. The revised path helper refuses to fall back to the author's original project. Opening `ANES.Rproj` sets both project-root variables to this analysis directory.

## Before rebuilding the analysis

Use a separate working copy and first run:

```text
Rscript --vanilla analysis/Run.R preflight
```

This inventories files and current decision states. It is not a successful full-replay test and does not change approval records.

The dependencies follow this order, but the unresolved conditions below still prevent a complete rerun. This list is not yet a tested sequence of execution commands:

1. 00 to 06: environment, extraction, cleaning, sample preparation and correlation diagnostics.
2. The 2004 pilot in 07, then the weighted diagnostics in 06B.
3. The formal portion of 07, then 07A and 07B.
4. 08, 08A, 08B and 08C: descriptive comparisons and education networks.
5. 09 and 09B: sensitivity analyses; 10: results assembly.

01A and 01B document selection. They are not additional primary network models. 2008 is used only in the exclusion diagnostics.

The original notebooks do not yet provide a working complete rebuild, whether run together or one at a time:

- 06B still checks an earlier D15 state. The re-estimation branch of 07 checks an earlier D21 state. 07 also computes a pilot before its formal reuse flags.
- 09 checks earlier approval states and three historical support-file hashes. These checks have not been removed or made to pass by rewriting the history.
- 09B stops if its completion file already exists. A full replay needs a separate output route, not an overwritten completion record.
- Respondent-level inputs, bootstrap membership and some model objects are deliberately excluded. They must be regenerated locally before the branches that need them can run.

The revised paths and saved-output checks do not resolve these computational dependencies. Do not describe this delivery as a tested clean-session rebuild.

## Records and interpretation

The current candidate audit is `outputs/tables/supplement/candidate_pool_16_audit/`. Earlier candidate decisions in `node_wave_selection/` are historical and contain explanations corrected by 01B. Use the current audit and Appendix A for the submitted account.

`D11_warnings.csv` is a derivative of the original D11 condition log with case row numbers removed. It retains each warning record. It is not a byte-identical substitute for the historical log, and its provenance note records the original hash.

Existing HTML reports and stage manifests are records of earlier executions. Editing an Rmd file or a path does not mean its HTML has been rerendered. `checks/Changes.csv` describes the earlier package reorganisation; later Git commits record subsequent edits. `checks/Files.csv` checks the current distributed file contents.

## Updating the repository manifest

This is a maintainer operation, not part of reproducing the research. First pull any edits made on GitHub so the local files include them. Review the intended file changes and then, from the repository root, preview the manifest changes:

```text
powershell -NoProfile -ExecutionPolicy Bypass -File analysis/checks/Update.ps1
```

After confirming that the listed changes are intentional:

```text
powershell -NoProfile -ExecutionPolicy Bypass -File analysis/checks/Update.ps1 -Write
powershell -NoProfile -ExecutionPolicy Bypass -File analysis/checks/Files.ps1
```

`Update.ps1` updates only the current manifest entries. It stops if a listed file is missing and does not scan local data or package folders. A new public file must be added explicitly, for example with `-AddPaths results/New.pdf`. Check that it contains no private data before adding it. The manifest excludes itself because a file cannot contain its own final hash.

Commit the reviewed files and `Files.csv` together, then push. Download that commit into a fresh folder and run `Files.ps1` again. If a repository file is edited after this step, repeat the manifest update. Do not change the historical stage manifests or research results to fix a delivery-manifest mismatch.
