# 00–06 Blank-Session Reproduction Check

OVERALL_STATUS: PASS

Date: 2026-08-29  
Scope: Technical repair and reproduction of Steps 00–06 only. No GGM, EBICglasso, NCT, bootstrap, centrality, sensitivity model, or political-result interpretation was run.

## Execution method

Each notebook was rendered in a separate `Rscript --vanilla` process from the project root. The project renv library and the R 4.5.2 system library were set explicitly. Pandoc 3.6.3 was supplied from the local RStudio installation.

The following startup warnings occurred in every blank session:

- `Setting LC_COLLATE=C.UTF-8 failed`
- `Setting LC_CTYPE=C.UTF-8 failed`
- `Setting LC_MONETARY=C.UTF-8 failed`
- `Setting LC_TIME=C.UTF-8 failed`

These warnings did not stop rendering or change the verified data objects. They remain an environment caveat to record; they are not evidence of an analysis failure.

## Render results

| Step | Notebook | Result |
|---|---|---|
| 00 | `00_environment.Rmd` | PASS |
| 01 | `01_data_inventory.Rmd` | PASS |
| 02 | `02_data_extraction.Rmd` | PASS |
| 03 | `03_data_cleaning.Rmd` | PASS after the project-root repair |
| 04 | `04_analysis_ready_data.Rmd` | PASS after the YAML repair |
| 05 | `05_preliminary_data_suitability_audit.Rmd` | PASS |
| 06 | `06 Polychoric Input Diagnostics.Rmd` | PASS after the content-hash repair described below |

## Step-06 fail-closed event and repair

The first blank-session rerun of Step 06 stopped at its corrected-node-direction gate before estimating a polychoric matrix. The hard-coded expected SHA-256 referred to the compressed RDS file bytes. Re-saving the analysis-ready object changed the compressed-file hash even though:

- the pre-rerun and post-rerun deserialised objects were `identical()`;
- `all.equal(..., check.attributes = TRUE)` returned true;
- both objects had 16,766 rows and 18 columns;
- both objects had the same serialised-object SHA-256: `78e5c1cff278a6640834113b769ef4251807ab30659b6effcfd6a14db58ada6c`.

Step 06 was therefore minimally repaired to use the stable deserialised-object SHA-256 as its validation gate while retaining the current compressed-file SHA-256 as provenance metadata. After that repair, all 48 Step-06 execution units completed and the five saved polychoric matrices passed the notebook's formal pre-model gate.

## Output comparison

The comparison covers seven rendered HTML files and eight derived data/audit files. The detailed record is:

`outputs/logs/00_06_REPRODUCTION_COMPARISON.csv`

Results:

- all 15 expected files exist after rerendering;
- all eight derived RDS/CSV outputs are semantically equal to their pre-rerun counterparts, except for the intentional Step-06 hash-metadata schema migration;
- the extracted, cleaned, and analysis-ready RDS objects are exactly identical after deserialisation;
- all four audit CSV files are identical after parsing;
- the substantive Step-06 diagnostic components, warnings, matrix audits, and five matrices are identical;
- five files are byte-identical and ten have different file hashes because HTML was regenerated, RDS compression bytes changed, or Step-06 hash metadata was intentionally updated.

## Frozen-data checks retained

- Election years: 2004, 2012, 2016, 2020, 2024.
- Fixed node order: `VCF0806`, `VCF0809`, `VCF0838`, `VCF0839`, `VCF0879a`, `VCF0888`, `VCF0890`, `VCF0894`, `VCF9223`.
- Complete-case counts: 789, 4,353, 2,709, 5,390, and 3,525 respectively.
- Total analysis-ready N: 16,766.
- Five polychoric matrices: finite, symmetric, positive definite, correct node order, and zero recorded estimation warnings.
- 2008 remains excluded from this workflow.

## Technical files changed

| File | Before SHA-256 | After SHA-256 | Reason |
|---|---|---|---|
| `03_data_cleaning.Rmd` | `5055A431054DC589B7019A02EBF7209701FBBF773963BAD85080D7C1119E2A62` | `682A52BF3DA9ABD4D76C5F986311CEC313065FB6D759DFEF7DEF5E0E414964E0` | Portable project-root resolution |
| `04_analysis_ready_data.Rmd` | `600D0FA7F41DD7324057B79EA4D8FE00E5A16533CE2C21D6F201F104D67ACF8B` | `0F398DE1555AD765355F075BF32FEE6CC585875B3F7CBEA029435DE7800AD75B` | Remove duplicate YAML delimiter |
| `06 Polychoric Input Diagnostics.Rmd` | `9D0E9D93FFB06E91E7F2660A0CAF7B2B5E31882A3645019C223A38701997822E` | `1FDE43A17F0041816E1DAAAE353C696C66CE74EF72331391CF1B91752D060815` | Replace brittle compressed-file hash gate with content hash; retain file hash as provenance |
| `07_primary_network_estimation_and_stability.Rmd` | `F21A9857E23A7065E0D9C9291D2D66083C908B5D024A4860797F9A499002A204` | `990243F2421BA29A1B87404C522C88F2CF2401F97D4561306A4B47B0643319C5` | Dynamic registry checks, exact package validation, real artifact checks, fail-closed gate |
| `renv.lock` | `F4D4B8D8275D2356A524EBB932ECB508F687217C449DB2B55A5D3D4A7D54F947` | `F72CAC0C028FB0F28EAEFFFF075FB929E4489E654EE0EDF722CFA78E767862B4` | Preserve 97 records and add the 57-package non-base closure for `bootnet 1.9.1` |

Read-only pre-repair copies and the pre-rerun HTML/data outputs are stored under:

`backups/pre_07_technical_repair_20260829/`

## Method consistency

The reproduced Steps 00–06 remain consistent with the current five-wave, fixed nine-node, complete-case, ordinal/polychoric pre-analysis design. No formal model choice was executed or inferred from these checks. D15 and D21 remain unresolved in the canonical decision registry and continue to block formal Step-07 estimation.

## Protected files

No ANES raw file, protected source document, or literature full text was modified.
