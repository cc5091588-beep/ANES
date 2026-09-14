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

## Regenerate figures and tables

```text
Rscript --vanilla analysis/Run.R figures
Rscript --vanilla analysis/Run.R tables
Rscript --vanilla analysis/Run.R precision
```

These commands read saved estimates and write new files under `runs/`. They stop if the destination already exists. To run again, supply a different destination as the next argument. They do not rerun networks or bootstrap analyses. Fonts and graphics devices may affect appearance.

`R/` contains the independent scripts. `notebooks/` contains the editable R Markdown files and existing HTML reports. `plotdata/` holds the exact data exports used for the manuscript figures. The original internal filenames are retained where they identify dependencies or historical records.

## Data and software

Use R 4.5.2 and the versions in `renv.lock`. The lockfile has been converted to standard JSON without changing package versions. An isolated offline restore into an empty library succeeded on the author's Windows/R 4.5.2 computer; all 164 locked versions matched. The test used copies of locally cached packages, not downloads. Restoration on another computer and the complete analysis rebuild remain unverified. See `checks/Environment.txt`.

`Rscript --vanilla analysis/Run.R environment` compares available package versions with the lockfile. Under `--vanilla`, R skips the project profile; this command does not activate, install or restore packages.

Obtain the ANES Time Series Cumulative Data File release dated 5 February 2026 from the [ANES Data Center](https://electionstudies.org/data-center/anes-time-series-cumulative-data-file/). The required Stata file is `anes_timeseries_cdf_stata_20260205.dta`, 609440121 bytes, SHA-256:

```text
45323c30faee1e9e67c2351c4302c31472b117050bef240d9339a264e2f3e078
```

Enter its local path in `config/anes_cdf_path.txt`, using the example provided. Do not commit that local configuration or the data. Selection audits also refer to official codebooks and wave documentation listed in `config/evidence_input_spec.csv` and `data/audit/node_wave_selection_inputs/`.

The decision records are in `project_docs/`. The supplied path settings point to that directory. The revised path helper refuses to fall back to the author's original project. Opening `ANES.Rproj` sets both project-root variables to this analysis directory.

## Before rebuilding the analysis

Use a separate working copy and first run:

```text
Rscript --vanilla analysis/Run.R preflight
```

This inventories files and current decision states. It is not a successful full-replay test and does not change approval records.

The dependency order is:

1. 00 to 06: environment, extraction, cleaning, sample preparation and correlation diagnostics.
2. The 2004 pilot in 07, then the weighted diagnostics in 06B.
3. The formal portion of 07, then 07A and 07B.
4. 08, 08A, 08B and 08C: descriptive comparisons and education networks.
5. 09 and 09B: sensitivity analyses; 10: results assembly.

01A and 01B document selection. They are not additional primary network models. 2008 is used only in the exclusion diagnostics.

The original notebooks are not yet a single-command rebuild:

- 06B still checks an earlier D15 state. The re-estimation branch of 07 checks an earlier D21 state. 07 also computes a pilot before its formal reuse flags.
- 09 checks earlier approval states and three historical support-file hashes. These checks have not been removed or made to pass by rewriting the history.
- 09B stops if its completion file already exists. A full replay needs a separate output route, not an overwritten completion record.
- Respondent-level inputs, bootstrap membership and some model objects are deliberately excluded. They must be regenerated locally before the branches that need them can run.

The revised paths and saved-output checks do not resolve these computational dependencies. Do not describe this delivery as a tested clean-session rebuild.

## Records and interpretation

The current candidate audit is `outputs/tables/supplement/candidate_pool_16_audit/`. Earlier candidate decisions in `node_wave_selection/` are historical and contain explanations corrected by 01B. Use the current audit and Appendix A for the submitted account.

`D11_warnings.csv` is a derivative of the original D11 condition log with case row numbers removed. It retains each warning record. It is not a byte-identical substitute for the historical log, and its provenance note records the original hash.

Existing HTML reports and stage manifests are records of earlier executions. Editing an Rmd file or a path does not mean its HTML has been rerendered. `checks/Changes.csv` records the files changed for this copy.
