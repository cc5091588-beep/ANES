# Research decisions log

## 2026-08-31 — Step-09B specificity and unequal-sample-size sensitivity completed

- **Issue:** Determine whether retained-edge, density, global-strength and edge-state descriptions from the five primary overall networks depend materially on unequal wave sample sizes or on the optional qgraph high-specificity threshold.
- **Alternatives considered:** Report unequal N and dense-network warnings only; replace the primary estimator; test many tuning values and select favourable results; or run a pre-result-frozen four-arm audit that changes only sample size and `threshold` while retaining the nine nodes, complete-case samples, polychoric input, EBICglasso, gamma `0.50` and unweighted treatment.
- **Evidence:** `STEP09B_SPECIFICITY_SAMPLE_SIZE_SENSITIVITY_FREEZE.md`; `step09b_primary_claim_registry.csv`; `step09b_arm_specification.csv`; `09B_equalN_run_diagnostics.csv`; `09B_equalN_network_summary.csv`; `09B_equalN_edge_summary.csv`; `09B_contrast_robustness.csv`; `09B_claim_robustness.csv`; the two correction-validation files; `09B_independent_audit_validation.csv`; and the rendered Step-09B HTML.
- **Decision:** Record Step 09B as **COMPLETE AND INDEPENDENTLY AUDITED**. Retain the Step-07 full-N, unthresholded polychoric EBICglasso networks as the primary models. Treat A1–A3 strictly as sensitivity evidence. Do not use raw retained-edge counts as the sole evidence of historical structural change, and qualify consecutive-wave narratives according to the Step-09B robustness results.
- **Rationale:** All 10,000 formal equal-N wave-arm runs were estimable; A2 and A3 used identical inputs for every repetition; all input hashes remained unchanged; and the final independent audit passed 20/20 checks. The audit found that only 74 of 180 edge-state claims met the stringent joint robustness rule, while the 2004–2024 directions for retained-edge count and global strength were reproduced robustly. The exact common N, repetition count and robustness thresholds are researcher design choices, not literature mandates.
- **Audit corrections:** Independent audit identified two errors confined to derived reporting fields: scalar rather than vector edge-state matching, and conflation of dense-network with lowest-lambda messages. Pre-correction files were archived. Affected summaries were recomputed from saved RDS arrays and condition messages; no network model was re-estimated.
- **Consequences:** Results may report the Step-09B sensitivity audit, but `ROBUST`, `MIXED` and `NOT_ROBUST` are descriptive reproducibility labels rather than p-values or equivalence tests. A threshold-deleted edge is not established to be false. Endpoint direction does not establish causal change, population inference, measurement invariance or ideological constraint.
- **Sensitivity analysis required:** No additional specificity or equal-N model is required for the minimum dissertation. Further gamma values, nonregularised models or formal tests would require a new decision.
- **Researcher approval:** Explicitly authorised by the user instruction to create, run and audit Step 09B.
- **Supervisor confirmation required:** Advised for the final prominence and wording of the Step-09B findings, but not required to retain the validated technical outputs.
- **Status:** **STEP-09B COMPLETE AND INDEPENDENTLY AUDITED; PRIMARY MODEL UNCHANGED; RESULTS WORDING MUST BE QUALIFIED.**

## 2026-08-30 — Step-09 minimum sensitivity analysis completed and validated

- **Issue:** Determine whether the five authorised Step-09 sensitivity modules could be completed under the frozen specifications and whether every preregistered primary edge claim could be evaluated without expanding the analysis scope.
- **Alternatives considered:** Stop after individual modules; alter a failed input or estimator; add optional sensitivities; or complete only the authorised modules under fail-closed diagnostics and retain all warnings and disagreements.
- **Evidence:** `09_completion_status.csv`; `09_sensitivity_summary_by_wave.csv`; `09_sensitivity_comparison_long.csv`; `09_claim_robustness_audit.csv`; `09_primary_claim_robustness_summary.csv`; module-specific validation and conditions tables; `09_output_hash_inventory.csv`; `09_sensitivity_execution.log`; and the rendered `09_sensitivity_analyses.html`.
- **Decision:** Record Step 09 as **COMPLETE AND VALIDATED WITH RECORDED WARNINGS**. All five D11 waves, five D20A gamma-0.25 waves, five D20A no-VCF0839 waves, ten reuse-only D15 weighted variants and four D19 all-internet waves completed. All 180 preregistered wave-edge claims were evaluable: 149 were unchanged and 31 changed retained/nonretained status in at least one applicable sensitivity; no commonly retained edge reversed sign.
- **Rationale:** Every hard input, node-order, matrix, estimator, reuse, output-existence and hash gate passed in the final run. Warnings were retained rather than treated as evidence of failure. The completed modules test distinct analytical dependencies and do not replace the Step-07 primary models.
- **Consequences:** Step 09 may support a bounded Results robustness subsection. `CHANGED` is a mechanical retention-status label, not a significance, equivalence or substantive-importance judgement. D11 does not correct complete-case selection; D15 is not complex-survey population-network inference; D19 does not identify a causal mode effect; and the eight-node sensitivity is compared only on its 28 shared edges.
- **Sensitivity analysis required:** None beyond the approved minimum set. Any 2008, NCT, education sensitivity, Spearman GGM, unregularised GGM, bootstrap, centrality, weighted resampling or significance test would require a new decision and authorisation.
- **Researcher approval:** Execution explicitly approved in the active Codex task on 2026-08-30.
- **Supervisor confirmation required:** Advised for the wording and interpretation of sensitivity findings in the submitted dissertation; not required to retain the validated technical outputs.
- **Status:** **STEP-09 COMPLETE AND VALIDATED WITH RECORDED WARNINGS; READY FOR STEP-10 RESULTS AND REPRODUCIBILITY ASSEMBLY.**

## 2026-08-30 — Step-09 minimum sensitivity execution authorised

- **Issue:** Authorise execution of the already frozen Step-09 minimum sensitivity family without reopening excluded estimators, waves, inference procedures or result-dependent specification choices.
- **Alternatives considered:** Keep Step 09 unexecuted; authorise only individual modules; broaden the scope; or execute exactly the five frozen modules with fail-closed diagnostics.
- **Evidence:** `STEP09_SENSITIVITY_ANALYSIS_FREEZE.md`; `step09_sensitivity_scope.csv`; completed D11 diagnostics; validated D15 Stage-3B objects; frozen D20A specifications; official ANES mode evidence; completed Step-07 and Step-08 primary outputs.
- **Decision:** Authorise D11 five-wave pairwise-available polychoric point networks; D20A five-wave gamma `0.25` point networks; D20A five-wave no-`VCF0839` eight-node point networks on the original nine-node complete-case samples; reuse-only D15 weighted point-network summaries; and D19 2012–2024 all-internet diagnostics and point networks. Add `NOT_EVALUABLE` and establish a primary-claim registry before any model runs.
- **Prohibited:** 2008; NCT; education-group sensitivity; Spearman or unregularised GGM; bootstrap; centrality; weighted resampling; significance testing; matrix repair; category merging; alternative models after failure.
- **Consequences:** A new `09_sensitivity_analyses.Rmd` may be created and executed module by module. A failed wave is recorded as `NOT_ESTIMABLE`; a claim that cannot be assessed is `NOT_EVALUABLE`. Disagreement with the primary analysis is retained and reported.
- **Researcher approval:** Explicitly approved in the active Codex task on 2026-08-30.
- **Supervisor confirmation required:** Advised for final interpretation only; not an execution gate.
- **Status:** **STEP-09 EXECUTION AUTHORISED; PRIMARY-CLAIM REGISTRY REQUIRED BEFORE MODEL EXECUTION.**

## 2026-08-30 — D19 and D27 Step-09 minimum sensitivity scope frozen

- **Issue:** Freeze the smallest sensitivity family needed to test the principal overall-network conclusions without reopening excluded waves, inferential comparisons or optional model families.
- **Alternatives considered:** Run every sensitivity named in earlier drafts; use only limitation statements; include D11, the two approved D20A models and D15 reuse while deferring survey mode; or add a bounded all-internet recent-wave point-network sensitivity.
- **Evidence:** The frozen D11 specification and completed five-wave pairwise diagnostics; the validated D15 Stage 0–3D point-network pilot; the approved but unexecuted D20A gamma and node-removal choices; official CDF `VCF0017` mode coding; `FINAL_SURVEY_MODE_COUNTS_G02A_20260828.csv`; `COMPLETE_CASE_SELECTION_AUDIT_G02A_20260828.csv`; the official 2017 ANES Board mode report; and completed Step-07/Step-08 primary outputs.
- **Decision:** Freeze Step 09 to five modules: (1) D11 pairwise-available polychoric EBICglasso networks for the five primary overall waves at gamma `0.50`; (2) the five-wave gamma `0.25` sensitivity; (3) the five-wave eight-node sensitivity excluding `VCF0839`, using the original nine-node complete-case respondent sets and gamma `0.50`; (4) reuse, without re-estimation, of the validated D15 `W_CDF` and `W_POST_COMPAT` point networks; and (5) D19 all-internet point networks for 2012, 2016, 2020 and 2024 using `VCF0017 == 4`, complete cases, the nine ordered nodes, unweighted polychoric EBICglasso and gamma `0.50`. Exclude 2008, NCT, education-group sensitivities, Spearman GGM, unregularised GGM and weighted bootstrap/centrality/NCT.
- **Rationale:** D11, D20A and D15 target distinct documented decisions: missing-data denominator, regularisation conservatism, node-set dependence and weight dependence. The all-internet complete-case samples are nonzero and substantial (`N = 3,062`, `1,914`, `5,094` and `2,823`), warranting diagnostic-gated D19 estimation; N alone does not establish ordinal-network estimability. Mode composition is a substantial comparability risk, so a bounded point-network stress test is more informative than limitation-only wording. Because 2004 has no internet cases and mode is entangled with recruitment and composition, D19 cannot identify a causal mode effect or produce a mode-controlled 2004–2024 endpoint.
- **Consequences:** `STEP09_SENSITIVITY_ANALYSIS_FREEZE.md` and `step09_sensitivity_scope.csv` become the controlling Step-09 specifications. Every new model is point-estimate only; existing D15 models are reuse-only. Module-specific identity, category, cell, association-type, warning and positive-definiteness checks must pass. Disagreement with the primary results must be reported and may not be resolved by choosing a favourable specification.
- **Sensitivity analysis required:** Exactly the five included modules above. No other sensitivity is part of the minimum dissertation unless a new evidence-backed decision reopens it.
- **Researcher approval:** Approved by the explicit 2026-08-30 instruction to execute the Step-09 scope-freeze stage and decide D19.
- **Supervisor confirmation required:** Advised for final interpretation of mode-confounded historical differences; not required to prepare the bounded point-network sensitivity.
- **Status:** **D19 AND D27 FROZEN; STEP-09 EXECUTION NOT AUTHORISED; NO SENSITIVITY MODEL RUN.**

No `09_sensitivity_analyses.Rmd` was created in this stage. No GGM, bootstrap, centrality, NCT, sensitivity result or political interpretation was produced. No protected source file, ANES raw file or literature paper was modified.

## 2026-08-30 — D25 Stage-13 education polychoric input diagnostics completed and validated

- **Issue:** Determine whether each of the eight frozen education-group inputs passes the result-blind category, pairwise-cell and polychoric-matrix gates required before education-network estimation.
- **Alternatives considered:** Treat sample size alone as sufficient; exclude any group with a zero cell; repair or smooth problematic matrices; or apply the prespecified diagnostic gates without altering the inputs.
- **Evidence:** `08A_category_frequencies.csv`; `08A_pairwise_cell_diagnostics.csv`; `08A_polychoric_conditions.csv`; `08A_polychoric_matrix_diagnostics.csv`; `08A_stage14_readiness.csv`; the round-trip validation; the prohibited-call scan; and the rendered Stage-13 notebook.
- **Decision:** Record Stage 13 as `STAGE_13_COMPLETE_AND_VALIDATED`. All eight group inputs are technically ready for a separately authorised Stage 14.
- **Rationale:** Every expected marginal category was observed; all eight direct `lavaan::lavCor` estimations completed with zero captured warnings and zero errors; every matrix was 9 by 9, correctly ordered, finite, symmetric, unit diagonal, strictly bounded off diagonal and positive definite. No matrix smoothing, repair, category merging or node deletion was used.
- **Consequences:** Stage 14 is technically reachable but remains unauthorised. Sparse cells remain an explicit precision risk: the 2012, 2016 and 2020 college/advanced groups contained 6, 5 and 2 zero cells respectively, and all eight groups contained cells with counts 1–4. These flags must be carried into model warnings and the later 1,000-repetition edge-bootstrap audit.
- **Sensitivity analysis required:** None was run or selected from these diagnostics.
- **Researcher approval:** Covered by the explicit instruction to proceed to the next stage.
- **Supervisor confirmation required:** Not required for this technical gate; advised for final substantive interpretation under D24.
- **Status:** **STAGE_13_COMPLETE_AND_VALIDATED; 8/8 GROUPS TECHNICALLY READY FOR A SEPARATELY AUTHORISED STAGE 14.**

The initial render stopped before polychoric estimation because the Stage-12 bundle stored category values as doubles while the check specified integer vectors. The check was corrected to compare numeric contents and order while ignoring storage type; no category, sample or statistical criterion changed. No GGM, bootstrap, centrality, NCT, sensitivity analysis or political interpretation was run. No protected source file or ANES raw file was modified.

## 2026-08-30 — D25 Stage-13 education polychoric input diagnostics authorised

- **Issue:** Whether the eight Stage-12 education samples may proceed to result-blind ordinal-input and polychoric-matrix diagnostics.
- **Alternatives considered:** Authorise the whole education-network module; skip subgroup-specific input checks; or authorise Stage 13 only.
- **Evidence:** The validated Step-06 polychoric diagnostic implementation; the frozen D08A and D24 education scope; the Stage-12 education bundle and validation records; and the researcher's instruction to proceed to the next stage.
- **Decision:** Authorise Stage 13 only for the eight prespecified samples: 2012, 2016, 2020 and 2024 crossed with `VCF0110` codes 1–3 versus code 4. Retain the frozen nine-node order and ordered levels. Record marginal category frequencies, all 36 pairwise contingency-cell diagnostics per sample, the actual correlation implementation, all warnings/messages/errors, matrix structure, eigenvalues, positive definiteness and condition number. Use unweighted `lavaan::lavCor` with `missing = "listwise"`, `estimator = "two.step"`, `meanstructure = FALSE`, `cor_smooth = FALSE` and `output = "cor"`.
- **Rationale:** Group-specific matrices must be shown usable before any education GGM is estimated. The diagnostic specification reproduces the validated primary implementation while exposing subgroup sparsity and estimator conditions without selecting methods according to substantive results.
- **Consequences:** Zero and 1–4-frequency cells are audit flags, not automatic exclusion thresholds. No category may be merged and no non-positive-definite matrix may be repaired. An error, warning or failed hard matrix check blocks the affected group from Stage 14 pending explicit review. Stage-13 completion does not complete D08A.
- **Sensitivity analysis required:** None in Stage 13.
- **Researcher approval:** Explicitly approved by the instruction to proceed to the next stage.
- **Supervisor confirmation required:** Not required for technical diagnostics; advised later for substantive interpretation under D24.
- **Status:** **AUTHORISED_STAGE_13_ONLY.**

This authorisation excludes EBICglasso/GGM estimation, bootstrap, centrality, NCT, sensitivity analysis, education-group comparison and political interpretation. No protected source file or ANES raw file was modified.

## 2026-08-30 — D24 Step-08 stages 1–12 completed and validated

- **Issue:** Determine whether the bounded Step-08 stages 1–12 completed without re-estimating the five overall networks or entering unauthorised later modules.
- **Alternatives considered:** Treat successful rendering as sufficient; accept partial outputs; or require the saved tables, figures, hashes, sample partitions and explicit prohibited-call scan to agree.
- **Evidence:** `08_stage1_12_completion_status.csv`; `08_overall_validation.csv`; `08_education_group_validation.csv`; `08_education_wave_partition_validation.csv`; `08_education_bundle_validation.csv`; `08_forbidden_call_scan.csv`; `08_input_inventory.csv`; the rendered HTML; and the execution log.
- **Decision:** Record D24 stages 1–12 as `STAGES_1_TO_12_COMPLETE_AND_VALIDATED`.
- **Rationale:** All 12 required components passed. The five validated Step-07 network objects were reused without re-estimation; five common-layout figures, five descriptive edge contrasts and five descriptive global-strength contrasts were produced; existing 07A/07B evidence was linked; and eight education-group samples were constructed with the prespecified counts and frozen ordinal levels.
- **Consequences:** The overall descriptive module is technically available for a separate Results evidence audit. The eight education samples are inputs only. Stages 13 onward still require a new gate and are not implied by this completion record.
- **Sensitivity analysis required:** None was run or newly authorised.
- **Researcher approval:** Covered by the explicit instruction to execute stages 1–12.
- **Supervisor confirmation required:** Advised for final substantive interpretation, not for this technical completion record.
- **Status:** **STAGES_1_TO_12_COMPLETE_AND_VALIDATED.**

No overall network was re-estimated. No education network, education bootstrap, NCT, sensitivity model or political interpretation was run. No ANES raw file, protected source file or literature PDF was modified.

## 2026-08-30 — D24 Step-08 stages 1–12 authorised for bounded execution

- **Issue:** Whether the frozen descriptive Step-08 design may proceed through its overall-network reuse and education-sample construction stages.
- **Alternatives considered:** Leave execution unopened; authorise the entire Step-08 notebook including education-network estimation; or authorise only stages 1–12.
- **Evidence:** The frozen D24 scope; validated Step-07 overall network objects; validated Step-07A edge-accuracy outputs; validated Step-07B centrality-stability outputs; the analysis-ready CDF object; and the researcher's explicit instruction to execute stages 1–12.
- **Decision:** Authorise only Step-08 stages 1–12. These stages may reuse the five validated overall networks, create common-layout descriptive figures and tables, link existing uncertainty and centrality evidence, and construct and validate the eight prespecified education-group samples for 2012, 2016, 2020 and 2024.
- **Rationale:** This bounded run completes the descriptive overall-network module and establishes validated inputs for the later education module without estimating any new education network or reopening excluded inferential methods.
- **Consequences:** Stages 13 onward remain unauthorised. This entry does not authorise education polychoric estimation, education GGMs, education bootstrap, NCT, sensitivity analyses, cross-wave significance claims or political interpretation.
- **Sensitivity analysis required:** None in this execution.
- **Researcher approval:** Explicitly approved by the instruction to execute stages 1–12.
- **Supervisor confirmation required:** Not required for technical execution; advised for the final interpretation scope already recorded under D24.
- **Status:** **AUTHORISED_STAGES_1_TO_12.**

No ANES raw file, protected source file or literature PDF was modified by this authorisation entry.

## 2026-08-30 — D24 Step-08 descriptive network-comparison scope frozen; D04, D08 and D18 aligned

- **Issue:** Freeze the Step-08 comparison design after completion of the five overall point networks, edge-accuracy review and exploratory centrality-stability analysis, without assuming that availability of NCT software establishes validity for the exact ordinal ANES application.
- **Alternatives considered:** All ten pairwise wave NCTs; the earlier three-contrast temporal/education NCT family; one exploratory 2004–2024 endpoint NCT; or a bounded descriptive comparison of validated point estimates and uncertainty, with education networks also descriptive.
- **Evidence:** Supervisor network-analysis guidance and reading list; van Borkulo et al. (2023) full text; current `NetworkComparisonTest` documentation; five Step-06 positive-definite polychoric matrices; zero cross-wave respondent overlap; Step-07 five-wave point-network and edge-bootstrap validation; Step-07A edge-accuracy results; Step-07B case-dropping results; the unexecuted ordinal-NCT calibration record; subgroup feasibility evidence; and the researcher's explicit instruction to freeze the Step-08 plan. The NCT method paper did not validate ordinal data in its simulations. The prospective endpoint contrast has a sample-size ratio of approximately `4.47:1`, all five observed point networks generated the dense-network specificity warning, and no approved project-specific ordinal-calibration criterion exists.
- **Decision:** Freeze Step 08 as a **descriptive** comparison of the validated overall networks for 2004, 2012, 2016, 2020 and 2024. Use a fixed layout and common scale; report retained edges, all edge weights, descriptive global strength, within-wave edge accuracy and the already authorised exploratory Expected Influence/Strength outputs. Produce descriptive signed and absolute edge-difference tables for the four consecutive contrasts and the 2004–2024 endpoint. Do not make between-wave significance claims. Exclude 2008 from all later primary, education and sensitivity network analyses while retaining its diagnostics as historical audit evidence. Restrict education networks to descriptive two-group analyses in 2012, 2016, 2020 and 2024, subject to their own input and 1,000-repetition edge-bootstrap gates; exclude 2004 and 2008 from the education module. Omit formal education comparisons and NCT from the current bounded design.
- **Rationale:** The descriptive plan answers what the validated estimates show without attaching inferential meaning that the available evidence does not secure. Omitting NCT is project-specific and does not assert that the method is generally invalid. The education restriction preserves the feasible recent-period comparisons while avoiding the weakest 2004 subgroup and the 2008 split-form problem within an MSc-scale design.
- **Consequences:** A future `08_network_comparisons.Rmd` may reuse the five validated overall network objects and generate descriptive comparison tables and common-layout figures after passing a new preflight. It must not call NCT. The education module may estimate eight group networks only after validating node order, categories, pairwise cells and polychoric matrices and must run 1,000 edge bootstraps before interpreting edges. The title and education research question must use descriptive or exploratory wording unless a separately justified inferential method is later approved. D05B continues to govern the strength of historical interpretation, and D19 and the approved sensitivity families retain separate gates.
- **Sensitivity analysis required:** No new Step-08 sensitivity is created. D11 pairwise-polychoric, D15 weighted point networks, D20A gamma `0.25` and no-`VCF0839`, and D19 survey-mode treatment remain separate. The 2008 sensitivity is withdrawn.
- **Researcher approval:** Explicitly approved through the researcher's instruction to enter and freeze the Step-08 network-comparison plan, together with the prior explicit decision to exclude 2008 completely.
- **Supervisor confirmation required:** Advised for final title/RQ wording, omission of inferential education comparisons and the strength of historical interpretation; not recorded as obtained.
- **Status:** **DESIGN FROZEN; EXECUTION NOT STARTED.**

No NCT, GGM, bootstrap, centrality, education-group network or sensitivity model was run during this decision update. No ANES raw file, protected source file or literature PDF was modified.

## 2026-08-30 — D23 five-wave exploratory centrality stability completed and validated

- **Issue:** Determine whether D23 can be closed after the formal five-wave case-dropping runs and the subsequent reuse-only verification render.
- **Alternatives considered:** Treat a successful process exit as sufficient; retain the technical-pilot-only status; or require the saved bootstrap objects, diagnostics, validation tables, CS coefficients, figures and reuse gate to agree.
- **Evidence:** Five formal case-dropping bootstrap objects containing 1,000 returned networks per wave (`5,000/5,000` in total); `60/60` formal validation checks passed; no retries or captured bootstrap-level warnings; all ten one-step Expected Influence and Strength CS coefficients were finite; five stability plots were created and inspected; and `07B_completion_status.csv` confirmed reuse of the validated outputs without rerunning the models. In every wave, both authorised metrics reached the maximum examined CS level of approximately `0.75`. The 2012, 2016, 2020 and 2024 logs retained the estimator message that the lowest lambda was selected and the sparsity assumption might be violated; this was not recorded as an estimation failure.
- **Decision:** Record D23 as `COMPLETE_AND_VALIDATED` for the authorised five overall-wave analyses only: exploratory one-step Expected Influence, auxiliary raw Strength and 1,000-repetition case-dropping stability assessment per wave.
- **Rationale:** Completion is supported by concordant saved model objects and explicit output-level validation, not by console completion alone. The reuse-only render also verified that the formal outputs can be loaded and audited without recomputation.
- **Consequences:** These centrality outputs may proceed to a separate, evidence-linked Results audit. Interpretation remains exploratory, coding-dependent and conditional on the selected nine-node networks. The result does not authorise education-group centrality, Bridge Expected Influence, closeness, betweenness, NCT, cross-wave centrality significance tests, or causal and political-importance claims. The CS result must be reported as reaching the maximum examined level of approximately `0.75`, not as proving an exact population CS of `0.75`.
- **Sensitivity analysis required:** Strength remains an auxiliary reference for the authorised Expected Influence analysis; it must not be used to switch metrics according to which produces a more favourable substantive pattern.
- **Researcher approval:** The bounded D23 specification was approved by the researcher, and the researcher subsequently instructed that the validated completion status be registered.
- **Supervisor confirmation required:** Advised for the final interpretation and reporting scope; not recorded as obtained.
- **Status:** **COMPLETE_AND_VALIDATED.**

No ANES raw file, protected source file or literature PDF was modified, and no bootstrap or network model was rerun during this status update.

## 2026-08-30 — D21 Step-07 bounded formal execution completed and validated

- **Issue:** Determine whether the authorised five-wave point-network and edge-accuracy run completed without extending the analysis into separately governed modules.
- **Alternatives considered:** Record completion from the process exit code alone; accept partial wave outputs; or require all registered input, graph and bootstrap checks to pass.
- **Evidence:** `project_docs/working/STEP07_FORMAL_EXECUTION_RESULT.md`; five formal point-network objects; five 1,000-replicate bootstrap objects; `5/5` input checks, `35/35` point-network checks and `45/45` bootstrap checks; wave-specific logs; and the captured session information.
- **Decision:** Record D21 complete for the authorised scope only. All five point networks reproduced their audited polychoric-input graphs exactly. Each wave returned 1,000/1,000 finite bootstrap graphs, with no retries or captured bootstrap-level warnings.
- **Rationale:** Completion is supported by saved model objects and explicit structural validation rather than by console success alone.
- **Consequences:** The formal primary point estimates and edge-accuracy outputs are available for a read-only result audit. All five point estimations recorded a dense-regularised-network warning, so the smallest retained edges require caution. Centrality, case-dropping bootstrap, NCT, education groups, sensitivities and political interpretation remain unexecuted and unauthorised under this entry.
- **Sensitivity analysis required:** None executed here. Previously approved sensitivity families retain their separate gates.
- **Researcher approval:** Covered by the bounded D21 authorisation dated 2026-08-30.
- **Supervisor confirmation required:** Deferred by the researcher; not recorded as obtained.
- **Status:** **COMPLETE AND VALIDATED FOR FIVE PRIMARY POINT NETWORKS AND FIVE 1,000-REPLICATE EDGE BOOTSTRAPS ONLY.**

No ANES raw file, protected source file or literature PDF was modified. The command-line environment lacked Pandoc, so the Rmd was executed with `knitr` and produced an execution Markdown record; this did not alter the analysis.

## 2026-08-30 — D21 bounded formal Step-07 execution authorised

- **Issue:** Authorise the first formal five-wave execution after D15 adjudication without implicitly authorising later comparison, centrality or sensitivity modules.
- **Alternatives considered:** Keep D21 blocked; authorise the entire remaining analysis plan; or authorise only the frozen primary point networks and edge-accuracy bootstrap.
- **Evidence:** D09B/G02B source mapping and G02A recoding repair are reproduced; D10B analysis-ready inputs and Step 00–06 diagnostics passed; D13 fixes the polychoric EBICglasso estimator; D14 fixes primary gamma `0.50`; D15 now permits unweighted primary networks under a restricted analytic-sample estimand; and D22 fixes `1,000` nonparametric edge-weight bootstrap resamples.
- **Decision:** Authorise formal Step 07 for the five overall complete-case samples in 2004, 2012, 2016, 2020 and 2024. Estimate the frozen nine-node unweighted polychoric EBICglasso point network at gamma `0.50` and run `1,000` nonparametric edge-weight bootstrap resamples per wave with fixed recorded seeds. Save validation, warnings, timing, model objects and session information.
- **Rationale:** These components are frozen, technically preflighted and directly required to establish the primary point estimates and edge accuracy. Restricting D21 prevents the execution gate from being treated as blanket permission for unresolved or separately governed analyses.
- **Consequences:** Step 07 may create formal network and edge-bootstrap outputs. This entry does not authorise centrality, case-dropping bootstrap, NCT, education-group networks, pairwise-missing, gamma, no-`VCF0839`, survey-mode, 2008 or weighted-network sensitivity execution, nor substantive political interpretation before output audit.
- **Sensitivity analysis required:** None in this execution. Approved sensitivity families remain separately gated.
- **Researcher approval:** Explicitly authorised by the researcher’s 2026-08-30 instruction to resolve D21 and start the formal five-wave Step 07 analysis after D15 selection.
- **Supervisor confirmation required:** Not required for this bounded execution; methodological confirmation for final reporting is deferred by the researcher.
- **Status:** **AUTHORISED FOR FIVE-WAVE PRIMARY POINT NETWORKS AND 1,000-REPLICATE EDGE BOOTSTRAPS ONLY.**

No protected source file, ANES raw file or literature PDF was modified when this execution scope was registered.

## 2026-08-30 — D15 final survey-weight scheme selected after blind pilot

- **Issue:** Resolve D15 after the prospectively bounded five-wave pilot while retaining the requested intermediate state `PILOT COMPLETE; FINAL DECISION PENDING` in the audit trail.
- **Alternatives considered:** Weighted primary networks; unweighted primary networks with weighted descriptives only; unweighted primary networks plus bounded weighted point-network sensitivity; or postponement for a fully design-based network method.
- **Evidence:** Official ANES weight documentation; locally inspected Epskamp and Fried (2018), Epskamp, Borsboom and Fried (2018), and Burger et al. (2023); `wCorr` documentation; all Stage 0–3D pilot validation and comparison outputs; and `project_docs/working/D15_SURVEY_WEIGHT_PILOT_RESULT.md`.
- **Decision:** Use unweighted primary nine-node complete-case networks, with primary inference restricted to the analysed ANES samples. Use `VCF0009z` for five-wave weighted descriptive statistics. Retain both pre-registered weighted point-network candidates (`W_CDF` and `W_POST_COMPAT`) as supplementary sensitivity analyses only. Do not use Kish ESS as EBICglasso `n`, and do not claim design-consistent weighted network inference.
- **Rationale:** Weighted polychoric point estimation was technically reproducible and revealed non-zero sensitivity, but the inspected evidence does not validate carrying ANES weights, strata and PSUs through EBIC model selection and nonparametric network bootstrap. The selected scheme acknowledges the sample design without overstating what the implemented network method can infer.
- **Consequences:** D15 no longer blocks the bounded unweighted Step 07 primary analysis. Weighted point networks remain sensitivity evidence and cannot be presented as a second primary or fully design-based population analysis. Weighted bootstrap, weighted centrality and weighted NCT are not authorised.
- **Sensitivity analysis required:** Later report both registered weighted point-network candidates if the sensitivity module is authorised; do not select between them according to substantive results.
- **Researcher approval:** The researcher explicitly instructed Codex on 2026-08-30 to make the critical selection and then proceed to D21.
- **Supervisor confirmation required:** **DEFERRED BY RESEARCHER**; it is not recorded as obtained.
- **Status:** **FROZEN FOR CURRENT EXECUTION. HISTORICAL PRE-DECISION STATUS RETAINED AS: PILOT COMPLETE; FINAL DECISION PENDING.**

No protected source file, ANES raw file or literature PDF was modified during the D15 adjudication.

## 2026-08-30 — G01 canonical framework adopted for execution only

- **Issue:** Resolve the governance prerequisite needed by D21 without treating adoption as permission to clean up, delete, move, rename or supersede project files.
- **Alternatives considered:** Leave G01 unresolved; activate every cleanup proposal; or adopt the version-5 decision registry only as the current machine-readable execution authority.
- **Evidence:** The revised read-only governance audit package and the researcher’s request to process D21 and begin formal Step 07.
- **Decision:** Adopt `REVISED_PROPOSED_DECISION_REGISTRY_v5.csv` as the current execution registry only. Do not execute cleanup, mark files superseded, or alter historical evidence.
- **Rationale:** Formal code needs one current source for execution gates, while cleanup and archival changes are materially separate operations.
- **Consequences:** D21 may rely on the version-5 registry after individual decisions pass. Historical and conflicting files remain unchanged and must not be treated as silently corrected.
- **Sensitivity analysis required:** None.
- **Researcher approval:** Implied by and limited to the explicit request to resolve D21 and start Step 07 on 2026-08-30.
- **Supervisor confirmation required:** Not required for this internal execution-control choice.
- **Status:** **ACTIVE FOR EXECUTION ONLY; CLEANUP NOT AUTHORISED.**

No cleanup, deletion, move, rename or `SUPERSEDED` marking was performed.

## 2026-08-29 — D15 five-wave result-blind survey-weight pilot authorised

- **Issue:** Authorise the bounded D15 pilot after its evidence boundary, candidate families, diagnostics, failure rules and prohibited analyses were prospectively recorded.
- **Alternatives considered:** Keep the pilot unapproved; authorise only the source audit; authorise the complete bounded point-estimate pilot; or treat the authorisation as permission for formal five-wave analysis.
- **Evidence:** The prospectively specified `project_docs/working/D15_SURVEY_WEIGHT_PILOT_PLAN.md`; official ANES weight documentation; weighted-polychoric software documentation; the documented source gap for end-to-end complex-survey EBICglasso/bootstrap/NCT inference; and the researcher’s exact written authorisation on 2026-08-29.
- **Decision:** Authorise the five-wave D15 pilot strictly for official weight-source auditing, weighted descriptive diagnostics, weighted-polychoric implementation cross-checking and diagnostic point-network comparison. The pilot must follow the fixed nine-node complete-case samples and the result-blind failure and decision rules already recorded.
- **Rationale:** The bounded pilot can determine whether the official weights and weighted-correlation implementations are usable and whether point estimates are method-sensitive, while keeping the unresolved population-estimand and complex-design uncertainty questions visible.
- **Consequences:** A separate `06B_D15_survey_weight_pilot.Rmd` may be prepared and run in stages. This authorisation does not approve formal Step 07, and D15 remains unresolved until pilot outputs are audited and a new final decision is explicitly approved.
- **Implementation prerequisite:** The environment audit found that `wCorr` is not installed or recorded in `renv.lock`. Stage 0 and descriptive Stage 1 preparation may proceed, but Stage 2 cross-implementation checking and Stage 3 diagnostics must stop until a separately recorded dependency installation/lockfile update is completed. No package installation is authorised implicitly by this entry.
- **Sensitivity analysis required:** None beyond the authorised D15 candidate comparisons. Any additional weight trimming, calibration, category change, alternative node set, subgroup or design-based resampling requires a new prospective decision.
- **Researcher approval:** Explicitly approved on 2026-08-29 using the full bounded authorisation statement.
- **Supervisor confirmation required:** Required for the final weight/estimand boundary, not for executing this non-interpretive pilot.
- **Status:** **PILOT AUTHORISED; NOT YET EXECUTED; FINAL D15 DECISION PENDING.**

No protected source file, ANES raw file or literature PDF was modified. No weighted correlation, diagnostic point network or prohibited analysis was run when this authorisation was registered.

## 2026-08-29 — D15 survey-weight decision changed to a result-blind pilot requirement

- **Issue:** Decide whether the five primary overall-wave networks should remain unweighted, use a survey-weighted association matrix, or use weighting only as a bounded sensitivity, without selecting the option that produces the most attractive political result.
- **Alternatives considered:** Immediately freeze weighted descriptives plus unweighted primary GGM; directly insert `VCF0009z` into the network workflow; attempt a fully design-based weighted GGM; or conduct a prospectively specified point-estimate pilot before freezing D15.
- **Evidence:** Official ANES documentation identifies both a cumulative full-sample weight (`VCF0009z`) and, where available, a post-election full-sample weight (`VCF9999`), while the retained nine-node set includes a post-election item. Official weighted-correlation documentation supports weighted polychoric estimation, but the inspected `qgraph`/`bootnet` interfaces do not provide a validated end-to-end ANES complex-survey pipeline incorporating weights, strata and PSUs. `EBICglasso` also requires an analysis `n`, and no inspected source validates replacing that value with Kish effective sample size. Existing complete-case diagnostics show materially different weight dispersion across the five waves, so a 2004-only check would be insufficient.
- **Decision:** D15 is not frozen. Before a final choice, prepare a result-blind five-wave pilot that audits the applicable official weight, compares unweighted and weighted category distributions and polychoric matrices, independently checks the weighted-correlation implementation, and treats weighted EBICglasso point networks only as diagnostic stress tests. The pilot will not use bootstrap, centrality, NCT, education-group networks or political interpretation.
- **Rationale:** Survey weighting changes the estimand rather than merely tuning computation. The pilot may establish technical feasibility and quantify sensitivity, but it cannot by itself validate design-consistent population-network inference. Selection will therefore use pre-registered technical and inferential criteria, not the direction, size or desirability of substantive findings.
- **Consequences:** D15 continues to block D21 formal five-wave execution. Current Methodology wording that presents `VCF0009z` descriptives and unweighted primary networks as final is provisional. D05A (2024 inclusion in the primary descriptive/GGM design) is not reopened by this decision.
- **Sensitivity analysis required:** To be determined only after the bounded pilot and source audit. Kish-effective-N variants may be inspected only as stress tests and must not be treated as validated candidates.
- **Researcher approval:** The researcher explicitly required a pilot-before-freeze approach on 2026-08-29; the exact bounded execution scope was subsequently authorised on the same date.
- **Supervisor confirmation required:** Required for the final weight/estimand boundary; survey-methods advice is advised if the full-sample and post-election weight conventions disagree materially or if weighted and unweighted matrices diverge materially.
- **Status:** **PILOT AUTHORISED; FINAL DECISION PENDING; PILOT NOT YET EXECUTED.**

No protected source file, ANES raw file or literature PDF was modified. No model or weighted correlation was run when this decision was recorded.

## 2026-08-29 — D22 edge-weight bootstrap repetitions frozen at 1,000

- **Issue:** Select the formal nonparametric edge-weight bootstrap repetition count after the authorised 2004 parameter pilot, without extending that decision to case-dropping bootstrap, centrality, NCT or formal five-wave execution.
- **Alternatives considered:** Use 1,000 repetitions; use 2,500 repetitions; or leave the count unresolved pending a later run.
- **Evidence:** Epskamp, Borsboom and Fried (2018, inspected full text, especially PDF pp. 5 and 9–10) describe 1,000 nonparametric resamples as the `bootnet` default and report that 1,000 may often be sufficient, while using 2,500 in an example for smoother output; Burger et al. (2023, inspected full text, especially PDF p. 9 and worked examples on pp. 14–15) require the bootstrap type and count to be reported but do not prescribe a universal minimum. In the authorised 2004 same-seed pilot, both runs completed without retries or captured warnings: 1,000/1,000 networks in 97.61 seconds and 2,500/2,500 in 246.97 seconds. Across 36 edges, the mean absolute difference in bootstrap means was 0.000805 (maximum 0.002616), and no edge changed the descriptive zero-inclusion status of its empirical interval; this status was not used as a significance test. Because both runs used seed `20260829`, this was a nested Monte Carlo convergence check rather than an independent replication.
- **Decision:** Freeze **1,000 nonparametric edge-weight bootstrap resamples per network whose edge estimates are substantively interpreted**. This decision fixes edge-accuracy repetitions only. It does not set the number of case-dropping resamples or authorise centrality analysis.
- **Rationale:** The 1,000-repetition setting is consistent with published methodological practice, completed cleanly in the weakest-wave computational pilot, and produced edge summaries broadly similar to the 2,500-repetition run at about 39.5% of its elapsed time. It is a project-specific precision–workload choice, not a universal sufficiency threshold and not a result selected because one run produced more desirable political findings.
- **Consequences:** Formal Step-07 code, once separately authorised, must use 1,000 nonparametric edge-weight resamples, recorded fixed seeds, the frozen ordinal/polychoric estimator chain, and complete warning/retry/output logs. The 2,500 run remains pilot evidence only. It will not be run automatically in the formal workflow; any later increase requires a documented, result-blind technical reason and a new decision-log entry.
- **Sensitivity analysis required:** None for the repetition-count decision. Case-dropping stability remains separately conditional on retaining exploratory Strength under D16/D22.
- **Researcher approval:** Explicitly approved by the researcher on 2026-08-29.
- **Supervisor confirmation required:** Not required to register the computational count; advice remains appropriate for the final reporting scope.
- **Status:** **FROZEN; PILOT COMPLETE; FORMAL EDGE BOOTSTRAP NOT YET EXECUTED.** D15 and D21 remain unresolved and continue to block formal analysis.

No protected source file, ANES raw file or literature PDF was modified. No new model was run when this decision was recorded.

## 2026-08-29 — P07 bounded 2004 bootstrap-parameter pilot authorised

- **Issue:** Permit a computationally bounded Step-07 pilot for choosing between literature-supported nonparametric edge-bootstrap repetition counts without falsely approving D15 survey weights or D21 formal analysis.
- **Alternatives considered:** Keep all model estimation blocked until D15/D21 are resolved; approve the five-wave formal analysis; bypass the existing gate manually; or establish a separate pilot-only authorisation with an explicit scope and prohibitions.
- **Evidence:** The researcher’s explicit approval dated 2026-08-29; the completed 00–06 reproduction and technical preflight; the saved 2004 nine-node complete-case ordered input (`n = 789`); Epskamp, Borsboom and Fried’s nonparametric-bootstrap guidance for ordinal networks; and the installed `bootnet` 1.9.1 interface.
- **Decision:** Authorise only the 2004 overall-sample parameter pilot using the nine ordered nodes, complete cases, polychoric correlations, EBICglasso, gamma `0.50`, an unweighted network, and nonparametric edge-weight bootstraps of 10, 1,000 and 2,500 repetitions. The 10-repetition run is a technical test; the 1,000- and 2,500-repetition runs are compared only for execution failure, elapsed time and Monte Carlo stability.
- **Rationale:** A separate gate allows the approved computational check to proceed while preserving the unresolved inferential and governance questions. Bootstrap settings must not be selected according to edge strength, apparent significance, political interpretation or agreement with expectations.
- **Consequences:** The Step-07 notebook may estimate one 2004 pilot network and the three approved edge-bootstrap runs after all technical checks pass. It may not batch-estimate the five primary waves or generate dissertation Results. D15 and D21 remain unchanged and continue to block formal analysis.
- **Sensitivity analysis required:** None authorised. Gamma `0.25`, no-`VCF0839`, pairwise-polychoric, survey-mode and other sensitivities remain outside this pilot.
- **Researcher approval:** Explicitly approved on 2026-08-29 using the full bounded authorisation statement.
- **Supervisor confirmation required:** Not required to conduct this non-inferential technical pilot; existing supervisor-confirmation requirements for D15 and formal interpretation remain.
- **Status:** **PILOT AUTHORISED; NOT YET EXECUTED. FORMAL ANALYSIS REMAINS BLOCKED.**

No protected source file, ANES raw file or literature PDF was modified. No model was run when this authorisation was recorded.

## 2026-08-28 — D20A minimum sensitivity set approved and separated from D04

- **Issue:** Resolve the three remaining D20A candidates without conflating them with the independently governed 2008 sensitivity or authorising model execution.
- **Alternatives considered:** Retain all three candidates in D20A; approve gamma `0.25` only; approve no-`VCF0839` only; retain 2008 in D20A; or approve a bounded two-part D20A set while returning 2008 to D04.
- **Evidence:** The registered primary design and method evidence; node-overlap rationale for testing `VCF0839`; prior gamma review; prior 2008 split-form and feasibility diagnostics; the researcher’s explicit instruction dated 2026-08-28.
- **Decision:** Freeze gamma `0.25` as the **sole gamma sensitivity**. Freeze a five-primary-wave overall no-`VCF0839` sensitivity at γ = `0.50`, using in each wave the respondent set already defined by complete cases on the original nine nodes. This estimates an eight-node network without changing respondents. Remove 2008 from D20A; D04 alone governs the optional 2008 overall sensitivity, which may be deferred.
- **Rationale:** Separating association/regularisation robustness from the special 2008 split-form design keeps each sensitivity tied to a distinct methodological concern. Holding the original nine-node complete-case respondent set fixed ensures that the no-`VCF0839` comparison reflects node removal rather than a simultaneous sample change.
- **Consequences:** D20A is specified and approved, but neither D20A model is executed. Pairwise polychoric remains under D11; Spearman and unregularised GGM remain separate unresolved decisions under D20B and D20C. The primary nine-node model and γ = `0.50` remain unchanged.
- **Sensitivity analysis required:** When later authorised, gamma `0.25` and no-`VCF0839` as specified above. The 2008 analysis is optional under D04 rather than required by D20A.
- **Researcher approval:** Approved by explicit instruction dated 2026-08-28.
- **Supervisor confirmation required:** Existing advice remains for final presentation of optional sensitivities; no new confirmation is required to register this bounded set.
- **Status:** **FROZEN; NOT EXECUTED.** D21 formal-analysis authorisation remains required.

## 2026-08-28 — G02A repair and D11 diagnostics-only execution

- **Issue:** Bring the already verified 2024 `-1` provenance into the R/05 Gate 1 implementation and test whether the five approved pairwise-polychoric correlation inputs are mathematically usable, without crossing into network estimation.
- **Alternatives considered:** Leave R/05 inconsistent; make a broader recoding change; rerun the full analysis; run D11 networks immediately; or perform only the authorised minimal repair, reproduction tests and pre-estimation diagnostics.
- **Evidence:** Official 2024 source metadata and User Guide/Codebook; exact 5,521-case raw-to-CDF matching; preserved pre-repair hash and read-only backup; isolated pre/post Gate 1 outputs; pairwise N, contingency-cell, correlation-type, matrix, eigenvalue and condition logs for 2004, 2012, 2016, 2020 and 2024.
- **Decision:** Repair only the R/05 classification of 2024 raw `-1` on `VCF0806`, `VCF0809` and `VCF9223` to `official structural inapplicability`, while preserving missing recoding and analytic exclusion. Run unweighted D11 diagnostics only, with all nine nodes explicitly declared as ordered factors. Do not invoke EBICglasso, NCT, bootstrap, centrality or any D20A model.
- **Rationale:** The repair synchronises implementation with source-verified metadata and has no numerical effect because the values were already excluded. The diagnostics isolate pairwise denominator variation, sparse cells, correlation type, eigenvalues and software conditions before any model is authorised.
- **Consequences:** G02A completed with 23/23 tests passed and no complete-case or education-count change. D11 diagnostics completed with 30/30 tests passed: all 180 unique pairs were polychoric and all five input matrices were finite and positive definite. Each wave retains review flags for sparse cells and/or respondents missing all nine nodes. No pairwise network was estimated.
- **Sensitivity analysis required:** The D11 sensitivity network remains pending D21. The approved D20A sensitivities remain unexecuted.
- **Researcher approval:** G02A and the five-wave D11 diagnostics-only run were expressly authorised on 2026-08-28.
- **Supervisor confirmation required:** Not required for the bounded repair or diagnostic execution; existing advice on final method presentation remains.
- **Status:** **G02A COMPLETE; D11 INPUT DIAGNOSTICS COMPLETE WITH REVIEW FLAGS; ALL NETWORK MODELS NOT RUN.**

No protected source file, ANES raw file or literature PDF was modified.

## 2026-08-28 — G02B bounded R/04 source-mapping repair and reproduction

- **Issue:** Synchronise `R/04_final_measurement_matrix.R` and a versioned measurement-matrix output with the independently verified single-wave source mappings, while preserving the original script state and original audit output.
- **Alternatives considered:** Leave the known mappings unresolved; retain the conflicting CDF source identifiers; alter only the two 2024 immigration entries; or repair all seven source fields supported by official single-wave documentation.
- **Evidence:** Official ANES single-wave and CDF documentation for the seven affected cells; 2024 raw Time Series data and February 2026 CDF data joined by 5,521 unique case identifiers; the pre-repair script hash and read-only backup; versioned output comparison.
- **Decision:** Repair exactly seven `source_variable` fields: 2008 `VCF0888→V083144`; 2012 `VCF0894→fedspend_welfare`; 2016 `VCF0894→V161209`; 2020 `VCF0894→V201312`; 2024 `VCF0894→V241273`; 2024 `VCF0879a→V242227`; and 2024 `VCF9223→V242228`. Add assertions for 54 unique year-node keys, absence of unresolved source identifiers and the seven approved mappings.
- **Rationale:** The single-wave codebooks identify the relevant source questions. For the two 2024 immigration variables, casewise harmonisation reproduced both CDF variables for all 5,521 cases with zero mismatches. For 2008 `VCF0888`, the single-wave codebook identifies `V083144` as crime spending and shows that the CDF-listed `V083148` is aid to the poor; no claim is made that ANES issued a dedicated erratum.
- **Consequences:** The source-variable identifier field is complete for all 54 year-node cells, and the versioned measurement output differs from the preserved prior output in exactly those seven cells. This repair does not fill 18 blank exact-wording cells for the three spending items and does not by itself complete every questionnaire-placement, order, battery or routing field in the wider measurement-comparability record.
- **Sensitivity analysis required:** None caused by this factual metadata repair.
- **Researcher approval:** Approved by the explicit instruction dated 2026-08-28.
- **Supervisor confirmation required:** Not required for the factual source mapping. Interpretation of cross-wave measurement differences remains subject to the existing limitations.
- **Status:** **COMPLETE AND REPRODUCED.** No formal GGM, bootstrap, NCT, centrality or Results analysis was run.

## 2026-08-28 — D11 pairwise-available polychoric sensitivity specification

- **Issue:** Register one exact, auditable pairwise sensitivity specification without leaving it conditionally bundled with unrelated D20A sensitivities.
- **Alternatives considered:** Complete-case analysis only; pairwise estimation as a second primary analysis; multiple imputation; an unspecified pairwise sensitivity; or a bounded, diagnostic-gated sensitivity for the five primary overall waves.
- **Evidence:** Epskamp and Fried (2018, inspected full text, especially PDF pp. 9 and 14) support ordinal/polychoric association estimation and warn that pairwise polychoric matrices may be non-positive-definite; Burger et al. (2023, inspected full text, especially PDF pp. 8 and 12) require transparent missing-data reporting and document pairwise correlation handling in applicable GGM workflows. The installed `bootnet` 1.9.1 and `qgraph` 1.10.1 interfaces were inspected directly to verify the registered arguments and the arithmetic-mean definition of `sampleSize="pairwise_average"`. The choice of complete cases as primary and pairwise estimation as sensitivity remains a project-specific researcher decision rather than a universal result of those papers.
- **Decision:** Retain complete cases as primary. Register a pairwise-available polychoric EBICglasso sensitivity for the overall networks in 2004, 2012, 2016, 2020 and 2024 only, with the identical nine nodes, coding, order, estimator and primary gamma. Use explicit ordered factors and `default="EBICglasso"`, `corMethod="cor_auto"`, `missing="pairwise"`, `sampleSize="pairwise_average"`, `tuning=0.50`, `corArgs=list(forcePD=FALSE)` and `nonPositiveDefinite="stop"`. Do not impute structural non-administration and do not repair a non-positive-definite matrix.
- **Rationale:** This bounded sensitivity tests whether the descriptive edge pattern materially depends on the common-sample complete-case rule while retaining the same substantive network definition. It is not a correction for complete-case selection because different correlations may use different respondent sets.
- **Consequences:** Pair-specific sample-size matrices, category/cell diagnostics, warnings and matrix diagnostics are mandatory. Non-finite or non-positive-definite input is reported as not estimable; sparse cells or estimator warnings without mathematical failure are retained as warnings rather than converted into an invented universal cutoff. The sensitivity has not been run and cannot be described in the past tense. No pairwise NCT or education-group pairwise analysis is authorised by this decision.
- **Sensitivity analysis required:** The registered D11 sensitivity itself, after D21 formal-analysis authorisation. Gamma 0.25, no-`VCF0839` and 2008 overall remain separate, unresolved D20A candidates.
- **Researcher approval:** Approved by the explicit instruction dated 2026-08-28.
- **Supervisor confirmation required:** Advised for final presentation of the missing-data strategy, but not required to register the reproducible specification.
- **Status:** **FROZEN AND REGISTERED; NOT EXECUTED.**

No protected source file, ANES raw file or literature PDF was modified. No formal network model was run.

## 2026-08-18 — ANES feasibility audit recommendation

- **Issue:** Select a feasible time/item/subgroup design for the dissertation.
- **Alternatives considered:** Design A historical (1984–2004); Design B balanced (2004–2024); Design C recent-rich (2004, 2012, 2016, 2020, 2024); policy-only versus policy-plus-symbolic nodes; two- versus three-group education.
- **Evidence:** Supervisor direction and reading list; reviewed political and method evidence cards; official ANES cumulative CSV/Stata products and February 5, 2026 codebook/Appendix; item-level comparability and subgroup audits in `D:\ANES_Dissertation_Data\audit\`.
- **Decision:** No design is frozen. Codex recommends Design B, a reduced policy-only common node set and one education comparison as the minimum viable candidate.
- **Rationale:** It best balances supervisor alignment, temporal coverage, item breadth, subgroup feasibility and MSc workload while avoiding unsupported claims about race, region, elites or causal network structure.
- **Consequences:** Final node wording, complete-case N, education grouping, estimator, weight treatment, missing-data rule, comparison family and 2024 erratum use remain open.
- **Sensitivity analysis required:** Alternative time design (A or C), symbolic-node inclusion, education Option B, node-set/coding choices, weight/correlation treatment and endpoint/2008 sensitivity.
- **Researcher approval:** Required before any cleaning, pilot model or design freeze.
- **Supervisor confirmation required:** Advised if symbolic identity becomes primary, race/region become main analyses, or the estimator/comparison plan changes materially.
- **Status:** Pending researcher approval.

No protected source file was modified and no network model was estimated.

## 2026-08-18 — 2008 Design B go/no-go diagnostic

- **Issue:** Whether 2008 should remain in Design B with 2004, 2012, 2016, 2020 and 2024.
- **Alternatives considered:** Keep 2008 in Design B; drop 2008 and use Design C′; retain 2008 only as a restricted sensitivity wave.
- **Evidence:** Official Cumulative Codebook split-version notes for `VCF0806`, `VCF0809`, `VCF0838` and `VCF0839`; complete-case and category diagnostics; maximum-likelihood polychoric feasibility matrices for 2008 and the 2012 benchmark.
- **Decision:** No researcher decision has been made. Codex data-based recommendation is **DROP 2008 — DESIGN C′ PREFERRED**.
- **Rationale:** 2008 has 724 all-nine complete cases and 179 college/advanced-degree complete cases. The matrices are estimable and positive definite, but the four split variables represent a restricted OLD-version subset and the college+ sample has zero cells in 17/36 pairwise contingency tables and below-five cells in 35/36.
- **Consequences:** Main candidate waves become 2004, 2012, 2016, 2020 and 2024 if approved. Retaining 2008 would require explicit restricted-version interpretation and later stability testing.
- **Sensitivity analysis required:** If 2008 is retained, treat it as a sensitivity wave and pilot edge/centrality stability before substantive comparison.
- **Researcher approval:** Required.
- **Supervisor confirmation required:** Advised because dropping 2008 changes the recommended temporal design.
- **Status:** Pending researcher approval.

No GGM, EBICglasso, NCT or bootstrap was run, and no raw file was modified.

## 2026-08-19 — Independent design revalidation

- **Issue:** Independently test whether 2004, 2012, 2016, 2020 and 2024 should be primary waves with 2008 as an overall sensitivity, without treating the prior recommendation as evidence.
- **Alternatives considered:** Design A historical extension; Design B all six candidate waves; Design C′ five primary waves; C′ plus 2008 overall sensitivity; Chen-style 2000–2020 common-core extension.
- **Evidence:** Official ANES Cumulative Codebook and Appendix materials; newly regenerated all-wave complete-case, category, pairwise-cell and polychoric diagnostics; political full texts including Baldassarri & Gelman, Layman & Carsey, Kozlowski & Murphy, Hare, Fishman & Davis, DellaPosta, Chen et al.; locally inspected method evidence from Epskamp & Fried, Epskamp et al., Burger et al., Borsboom & Cramer, Dalege et al. and Golino & Epskamp.
- **Decision:** Provisional recommendation is **CURRENT DESIGN MODIFIED**: primary 2004, 2012, 2016, 2020 and 2024; 2008 overall-only sensitivity; no primary 2008 education comparison by default.
- **Rationale:** 2008 has documented OLD/NEW split forms on four candidate nodes and the weakest college+ sparsity (`N=179`; 17/36 zero-cell pairs; 35/36 pairs with cells below five). Its overall matrix is nevertheless finite and positive definite (`N=724`), so an explicitly labelled sensitivity is more evidence-consistent than either unqualified inclusion or total deletion. All other candidate waves also require codebook-qualified sensitivity reporting.
- **Consequences:** The earlier no-2008 primary recommendation is revised. No estimator, weight rule, node reduction, or final design is frozen.
- **Sensitivity analysis required:** Approved estimator pilot; edge-accuracy and centrality-stability diagnostics; alternative ordinal association; weighted-correlation sensitivity; restricted-form/overall 2008 sensitivity; any 8-/7-node alternative.
- **Researcher approval:** Required before data cleaning or final model estimation.
- **Supervisor confirmation required:** Advised because the temporal design and 2008 role have been modified.
- **Status:** Pending researcher approval.

No protected source file or ANES raw file was modified. No final network, EBICglasso, NCT, EGA or bootstrap was run.

## 2026-08-30 — D26 bounded D08A education-network and edge-accuracy execution authorised

- **Issue:** D08A remained incomplete after the Stage 13 input gate because no education-group point network or 1,000-repetition edge-weight bootstrap had been run.
- **Alternatives considered:** Run the design-consistent gamma 0.50 and 1,000-bootstrap specification; increase to 2,500 bootstrap samples; lower gamma to 0.25; force equal group sizes through downsampling; or defer all subgroup estimation.
- **Evidence:** Supervisor guidance and reading list; full local texts of Epskamp and Fried (2018), Epskamp, Borsboom and Fried (2018), and Burger et al. (2023); Foygel and Drton (2010); official `bootnet` and `qgraph` documentation; completed Stage 12 sample and Stage 13 input diagnostics; validated Step 07 implementation.
- **Decision:** Authorise eight descriptive education-group networks for 2012, 2016, 2020 and 2024 using the frozen nine ordered nodes, actual group-specific complete-case N, unweighted polychoric EBICglasso with gamma 0.50, `refit = FALSE`, `threshold = FALSE`, `nlambda = 100` and `lambda.min.ratio = 0.01`. First run a 10-repetition technical bootstrap for the pre-specified weakest group (`2016__college_or_advanced`); after it passes, run 1,000 nonparametric edge-only bootstraps for each of the eight networks using pre-registered seeds.
- **Rationale:** This specification preserves exact comparability with the primary overall networks, follows the supervisor's expected estimation and accuracy framework, and avoids choosing tuning or resampling settings after observing subgroup results. One thousand repetitions are a defensible practical accuracy setting, not a universal theoretical optimum.
- **Consequences:** Stage 14–15 may create point-network and within-network edge-accuracy outputs only. Education-group networks remain descriptive; unequal group N and sparse cells must be reported as precision and comparison limitations.
- **Sensitivity analysis required:** None within D08A. Gamma 0.25 remains separately governed and cannot be selected from these results.
- **Researcher approval:** Explicitly approved by the instruction to complete the outstanding D08A estimation and 1,000-repetition bootstrap tasks on 2026-08-30.
- **Supervisor confirmation required:** Advised for the final substantive reporting scope, not required for this bounded technical execution.
- **Status:** **AUTHORISED — STAGE 14–15 BOUNDED EXECUTION NOT YET COMPLETED.** No NCT, centrality, weighted network, sensitivity analysis or political interpretation is authorised.

No protected source file, ANES raw file, literature paper or Zotero record was modified when this authorisation was recorded.

## 2026-08-30 — D26 D08A education-network and edge-accuracy execution completed

- **Issue:** Execute and independently validate the bounded Stage 14–15 module authorised under D26.
- **Alternatives considered:** No post-result alternative was selected. Gamma 0.25, 2,500 repetitions, equal-N downsampling, category merging, node deletion and threshold changes remained excluded under the pre-execution freeze.
- **Evidence:** `08B_education_network_estimation_and_edge_accuracy.Rmd`; its rendered HTML; 8 point-model RDS files; 8 edge-bootstrap RDS files; combined point and bootstrap RDS files; 72-row point validation; 96-row bootstrap validation; 8-row diagnostics tables; 104-row output hash inventory; execution log; session information; independent spreadsheet-import and RDS-structure audits.
- **Decision:** Mark D08A and D26 complete and validated within their descriptive scope.
- **Rationale:** Eight of eight point networks were estimated, all exactly reproduced the graphs from the saved Stage 13 matrices, the pre-specified technical pilot passed, and all eight formal runs returned 1,000 valid nonparametric edge-bootstrap networks. All structural checks passed with zero bootstrap retries, warnings or errors.
- **Consequences:** Descriptive education-group network and within-network edge-accuracy outputs may now be used for later audited Results preparation. They do not establish formal group differences. Every point network retained the known dense-network warning, and subgroup sparse-cell evidence remains a precision limitation.
- **Sensitivity analysis required:** None added. Gamma 0.25 and other sensitivities remain separately governed and unexecuted.
- **Researcher approval:** Execution was explicitly requested and bounded on 2026-08-30.
- **Supervisor confirmation required:** Advised for final reporting and interpretation scope; not required to establish technical completion.
- **Status:** **D08A AND D26 COMPLETE_AND_VALIDATED. D08B REMAINS OUTSIDE CURRENT SCOPE.** No NCT, centrality, weighted network, sensitivity analysis or political interpretation was run.

No protected source file, ANES raw file, literature paper or Zotero record was modified.

## 2026-08-24 — ANES archive storage and release-container policy

- **Issue:** Whether the dissertation archive must retain or newly download a release ZIP when the relevant extracted official data artifact is already independently verified and readable.
- **Alternatives considered:** Retain both ZIP and extracted file for archive symmetry; retain a single verified readable official artifact; retain a ZIP only when it contains unique required content or is necessary to establish otherwise unavailable provenance.
- **Evidence:** Explicit researcher instruction; exact expected-hash verification for `anes_timeseries_2024_stata_20260519.dta`; recorded release version and provenance; local CDF container-member inventories; final archive-readiness review.
- **Decision:** “Redundant release ZIP archives are not required when the extracted official artifact has already been independently verified. The project prioritises a single verified readable official artifact to reduce storage duplication and file-selection ambiguity.” The missing 2024 Stata ZIP is `RESEARCHER_INTENTIONALLY_NOT_RETAINED`, with analysis effect `NONE`, repair effect `NONE`, and archive effect `NONBLOCKING`.
- **Rationale:** The policy reduces duplicate storage and prevents ambiguity over which technically different file is the primary analysis artifact while preserving a directly readable, hash-recorded official DTA.
- **Consequences:** Do not download or archive the 2024 Stata ZIP solely for completeness. Do not treat its absence as an analysis, R/04, R/05, reproducibility, or archive blocker. Reopen only if the retained DTA fails later provenance/hash verification. This decision does not assert that the ZIP and DTA have identical hashes.
- **Sensitivity analysis required:** None; this is a storage/project-governance decision, not a statistical or data-processing choice.
- **Researcher approval:** Explicitly approved in the final archive-readiness instruction.
- **Supervisor confirmation required:** No.
- **Status:** Approved and recorded. No archive operation was executed.

No protected source file, ANES raw file, official documentation or analysis code was modified. No file was downloaded, copied, moved, renamed or deleted, and no formal analysis was run.

## 2026-08-22 — Independent post-provenance rerun boundary

- **Issue:** Determine whether the official resolution of the 2024 `-1` value requires rerunning Gate 1, Gate 2, downstream feasibility diagnostics or ordinal NCT calibration.
- **Alternatives considered:** Rerun all 2024-dependent outputs; rerun Gate 1 only; rerun nothing; treat ordinal NCT as a core blocker; omit or retain NCT only conditionally.
- **Evidence:** Official 2024 ANES user guide/codebook and questionnaire; CDF documentation; verified provenance audit; direct inspection of `R/03_final_all_wave_validation.R` and `R/05_preanalysis_validation_gates.R`; read-only inspection of seven audit CSVs; full van Borkulo et al. NCT paper.
- **Decision:** After researcher approval, rerun Gate 1 only to correct the label/provenance note and pass/fail status. Do not rerun complete-case, category, pairwise-cell or polychoric diagnostics because their inputs are unchanged. Retain the all-internet analysis as a later, independently motivated sensitivity. Treat ordinal NCT as optional and exploratory; calibrate only if the researcher chooses to retain it.
- **Rationale:** Both validation scripts already excluded `-1` through valid-code whitelists. The official correction changes the exclusion reason, not the analytic sample. The NCT paper does not validate ordinal NCT for this design or state that a local calibration makes it confirmatory.
- **Consequences:** 2024 is numerically feasible but remains conditional until the targeted Gate 1 record is updated and approved. NCT is not a blocker to a core analysis that omits it.
- **Sensitivity analysis required:** Later all-internet 2012–2024 sensitivity; ordinal-NCT calibration only if NCT is retained.
- **Researcher approval:** Required before creating/running `R/08_post_provenance_gate1_revalidation.R`.
- **Supervisor confirmation required:** Advised for final omission or exploratory retention of NCT and for interpretation of mode-confounded temporal comparisons.
- **Status:** Independent review complete; targeted Gate 1 plan awaiting approval; no rerun executed.

No protected source file, ANES raw file or literature paper was modified. No final model or substantive analysis was run.

## 2026-08-22 — Targeted Gate 1 classification correction

- **Issue:** Correct the documented treatment of 2024 raw value `-1` without changing raw data, analytic recodes, samples or models.
- **Alternatives considered:** Retain the undocumented-category label; recode `-1` as a substantive value; classify it as generic respondent missingness; classify it as official structural inapplicability and preserve analytic exclusion.
- **Evidence:** Direct read of official 2024 Stata labelled/numeric values; 2024 user guide/codebook PDF pp. 113, 115 and 447; questionnaire PDF pp. 103–104, 107–108 and 337; CDF codebook PDF pp. 346–348 and 590; direct CDF count across six waves and nine nodes; validation-script logic and original audit records.
- **Decision:** For 2024 only, classify `-1` on `VCF0806`, `VCF0809` and `VCF9223` as official structural inapplicability. Retain raw `-1`, keep it outside valid substantive codes and preserve its exclusion from analytic recoding. Create a new audit rather than overwrite the original.
- **Rationale:** Official single-wave metadata explicitly labels `-1` as Inapplicable, questionnaire routing supports mode non-administration, and the CDF metadata omission explains the earlier undocumented classification. Existing code already excluded these values.
- **Consequences:** Gate 1 classification/status is corrected with no numerical change to complete-case, education or feasibility results. The 2024 provenance blocker is cleared; no node, wave, estimator, gamma, research-object or centrality decision changes.
- **Sensitivity analysis required:** None caused by this classification correction. Existing survey-mode and other approved sensitivities remain separate.
- **Researcher approval:** Approved by the explicit TARGETED GATE 1 CORRECTION instruction.
- **Supervisor confirmation required:** Not required for the source classification; existing advice on survey-mode interpretation remains.
- **Status:** Complete. No model analysis performed.

No protected source file, ANES raw file or original audit file was modified.

## 2026-08-21 — ANES cumulative-file provenance and 2024 `-1` resolution

- **Issue:** Verify whether earlier decisions used the actual ANES Time Series Cumulative Data File and establish the provenance of 245 cases coded `-1` on `VCF0806`, `VCF0809` and `VCF9223` in 2024.
- **Alternatives considered:** Cumulative harmonisation artifact; local conversion artifact; official single-wave missing/routing code; unresolved provenance.
- **Evidence:** SHA-256 identity between the newly supplied and previously archived February 2026 CDF ZIPs; SHA-256 identity of the extracted CDF `.dta` and the previously analysed `.dta`; direct data reads in `R/01`, `R/03`, `R/05` and `R/06`; exact joins of 5,521 CDF and raw 2024 cases; exact Stata/SPSS comparisons; official 2024 raw value labels; 2024 user guide/codebook pages 113, 115 and 447; questionnaire pages 103–104, 107–108 and 337.
- **Decision:** Record that cumulative raw data were previously used. Classify `-1` on the three source variables as official Inapplicable values caused by PAPI non-administration of CAPI/Web questions. Record the CDF omission of the `-1` label as a metadata/documentation loss, not a newly created value. Keep 2024 conditional and make no method, node, wave or coding change in this task.
- **Rationale:** All 245 cases carry `-1` on all three raw and cumulative fields, all are pre-election PAPI, and there are zero raw-to-CDF or Stata-to-SPSS mismatches. The cumulative codebook omission explains the earlier stop but does not override the official single-wave definition.
- **Consequences:** The core node/wave evidence does not require reconstruction. The 2024 recoding-frequency, complete-case, category, pairwise-cell, polychoric and education/mode-sensitivity gates must be regenerated with the corrected provenance before formal analysis. The ordinal-NCT calibration remains independently unresolved.
- **Sensitivity analysis required:** Existing all-internet 2012–2024 feasibility/sensitivity requirement remains; no new model sensitivity is authorised here.
- **Researcher approval:** Required before changing the recoding metadata/rules or rerunning downstream validation scripts.
- **Supervisor confirmation required:** Advised for the continuing interpretation of mode-composition differences, but not required to establish the raw-data provenance.
- **Status:** **PROVENANCE CONFIRMED; 2024 CONDITIONAL PENDING TARGETED REVALIDATION.**

No protected source file, ANES raw file or literature paper was modified. No GGM, NCT, bootstrap or formal network analysis was run.

## 2026-08-21 — Full-text methodology review and pre-analysis gate decision

- **Issue:** Convert the seven unresolved methodology questions into a page-level evidence decision and determine whether formal analysis can begin.
- **Alternatives considered:** Primary versus exploratory/rejected centrality metrics; all-pairwise, endpoint-only and bounded endpoint-plus-education NCT families; broad versus bounded research-object wording; weighted versus unweighted network estimation; confirmatory versus conditional ordinal NCT; alternative education-wave scopes; unrestricted versus mode-qualified historical interpretation; continuation versus stopping after an unexpected raw code.
- **Evidence:** All pages of seven verified full texts (211 PDF pages total): Converse; Epskamp and Fried; Burger et al.; van Borkulo et al.; Bringmann et al.; Christensen and Golino; Epskamp, Borsboom and Fried. Official ANES CDF codebook entries for weights, mode, education and all nine nodes. Read-only recoding-frequency, complete-case-selection and weakest-subgroup bootstrap gates.
- **Decision:** Freeze the estimand as the selected policy-attitude/belief network in analysed ANES samples; use weighted descriptives and an unweighted analytic-sample GGM with an explicit population-inference limitation; demote centrality to exploratory stable Strength only; omit EI, closeness, betweenness, EGA and Bridge EI. Retain 2012/2016/2020 as primary education waves, 2024 conditionally, 2004 sensitivity and 2008 excluded. Retain a three-contrast NCT family only conditionally and exploratory after recoding and ordinal calibration.
- **Rationale:** The centrality sources do not validate causal/political importance; the NCT method paper validates continuous and narrower binary conditions but explicitly not ordinal functionality; the nine nodes do not cover the entire political belief system; the reviewed method corpus does not validate design-weighted ordinal GGM/NCT inference; survey modes differ materially across waves.
- **Consequences:** Gate 1 failed for 2024 because `VCF0806`, `VCF0809` and `VCF9223` each contain 245 cases with undocumented raw value `-1`. All 2024 networks and dependent NCT calibration are stopped. Gate 2 passed with selection limitations. Gate 3 passed with a dense-network warning and limited-replication caveat. Gate 4 was not run and is `INSUFFICIENT EVIDENCE`.
- **Sensitivity analysis required:** Pairwise polychoric; gamma 0.25; Spearman GGM; unregularised GGM; no-`VCF0839`; 2008 overall; all-internet 2012–2024; formal nonparametric bootstrap; any later ordinal-NCT calibration.
- **Researcher approval:** The user requested the independent adjudication; implementation remains blocked by the explicit gate rule.
- **Supervisor confirmation required:** Narrowed object/title; weighted-descriptive/unweighted-network split; centrality removal; education-wave scope; whether ordinal NCT should remain; handling of `-1` only after official ANES clarification.
- **Status:** **PARTIALLY FROZEN — FORMAL ANALYSIS NOT AUTHORISED.** A conditional Methodology draft may begin, but 2024 and NCT must be labelled unresolved.

No protected source file, ANES raw file or literature PDF was modified. No formal network, formal centrality ranking, substantive NCT or Results analysis was run.

## 2026-08-21 — Independent methodology re-audit and conditional freeze

- **Issue:** Reassess without deference to prior defaults the waves, nodes, missing-data procedure, GGM/MGM choice, EBIC gamma, survey weights, centrality, NCT, coding, respondent inclusion and resampling plan.
- **Alternatives considered:** Complete-case, pairwise polychoric, multiple imputation and FIML; polychoric GGM, MGM and other ordinal models; gamma 0.50 versus 0.25; strength, Expected Influence and Bridge Expected Influence; endpoint, adjacent and all-pairwise NCT families; weighted, unweighted and sensitivity-only network estimation; full-sample versus mode-restricted designs.
- **Evidence:** Full local method papers by Epskamp and Fried, Epskamp et al., Burger et al. and van Borkulo et al.; full official NeurIPS text by Foygel and Drton; complete author-hosted Robinaugh et al. text; political full texts and evidence cards; official February 2026 CDF codebook/Appendix; official 2024 ANES questionnaire, variable list and Guide; all-wave feasibility diagnostics; bounded read-only checks of `VCF0006a`, `VCF0009z` and `VCF0017`.
- **Decision:** Retain the nine-node, five-wave overall design and 2012–2024 education scope. Use complete cases as primary and pairwise polychoric as sensitivity; exclude MI/interpolation. Use polychoric EBICglasso GGM with gamma 0.50 primary and gamma 0.25, Spearman, unregularized GGM and no-`VCF0839` sensitivities. Use `VCF0009z` for descriptions and unweighted primary networks. Demote centrality to exploratory strength with optional EI sensitivity and omit Bridge EI. Permit NCT only after an ordinal calibration pilot and restrict it to 2004–2024 overall plus within-wave education contrasts in 2012 and 2024. Require an all-internet 2012–2024 sensitivity.
- **Rationale:** The retained nodes are homogeneous ordinal items and the complete-case samples are adequate, so one coherent latent-threshold GGM is more interpretable than a multinomial MGM. Gamma 0.50 is a conservative loss-function choice, not a theorem for this nine-node setting. The NCT method paper explicitly did not validate ordinal functionality. Official ANES documentation supports descriptive weighting but the inspected network sources do not establish design-weighted ordinal GGM/NCT inference. Survey mode changes materially across the period.
- **Consequences:** Earlier files that made centrality primary or authorised a broad NCT family are superseded for methodology choices. Claims are limited to selected policy-attitude/belief networks in analysed samples. A 2004–2024 difference cannot be attributed solely to historical attitude change because survey mode and sampling composition also changed. Education NCTs do not test an education-by-time interaction.
- **Sensitivity analysis required:** Pairwise polychoric; gamma 0.25; Spearman GGM; unregularized GGM; eight nodes without `VCF0839`; 2012–2024 all-internet networks; 2008 overall only; stability-gated centrality if reported.
- **Researcher approval:** Pending explicit acceptance of centrality demotion, the narrowed NCT family and the selected-policy-network wording.
- **Supervisor confirmation required:** Advised for unweighted primary network inference, conditional ordinal NCT, 2012–2024 education scope and interpretation of the mode-confounded long-run endpoint.
- **Status:** Method specification conditionally frozen. Cleaning/final estimation remains unauthorised until the recode, missingness, weakest-subgroup and ordinal-NCT gates pass.

No protected source file or ANES raw file was modified. No final network, EBICglasso, NCT, EGA or bootstrap was run.

## 2026-08-21 — Original-PDF evidence audit and bounded design re-freeze

- **Issue:** Reassess the node set, identity boundary, 2008 role and primary waves using the actual local PDFs, official ANES codebook and regenerated feasibility diagnostics, and identify which earlier “frozen” method choices lack controlling evidence.
- **Alternatives considered:** Nine-node versus reduced node sets; policy-only versus policy-plus-identity nodes; 2008 primary, sensitivity or excluded; 2000 extension; full versus partial method freeze.
- **Evidence:** Twenty-two verified local full texts; official February 2026 ANES cumulative codebook; all-wave complete-case and matrix-feasibility summaries; 2008 split-form, category and pairwise-cell diagnostics; exact comparisons of alternative fixed node sets. The supplied 2015 van Borkulo depression paper was identified as the wrong NCT source, and the correct van Borkulo et al. NCT paper was found locally.
- **Decision:** Retain the nine-node policy-related primary set; exclude party and ideological identity from both primary and sensitivity node sets; use 2004, 2012, 2016, 2020 and 2024 as primary overall waves subject to a 2024 documentation gate; use 2008 as overall-only sensitivity; use 2012–2024 for primary education comparisons. Treat the estimator, missing-data procedure, survey-weight sensitivity, Expected Influence, ordinal NCT implementation, multiplicity plan and resampling settings as not frozen.
- **Rationale:** Every retained node adds a distinguishable policy attitude or policy-related belief, while identity would change the estimand from issue–issue organisation toward issue partisanship/sorting. The 2008 overall matrix is computable, but four split-form items and unverified complete-case representativeness make it unsuitable for primary inference; the college+ sample is especially sparse. Original method sources do not justify treating gamma, resampling counts, ordinal NCT or weighted estimation as automatic defaults.
- **Consequences:** The controlling pre-analysis status is now **partially frozen**, not fully analysis-ready. Thirty-two of 59 recorded decisions remain non-frozen. The prior 2026-08-20 freeze remains an audit trail but is superseded where it conflicts with `PRE_ANALYSIS_DESIGN_FREEZE_STATUS.md` and `REMAINING_DESIGN_DECISIONS.csv`.
- **Sensitivity analysis required:** Eight-node set without `VCF0839`; approved ordinal-association alternative; gamma alternatives after a primary gamma is justified; weighted-association sensitivity if implementation is validated; 2008 overall-only analysis; stability-gated optional 2004 education description.
- **Researcher approval:** The node, identity, 2008 and wave decisions are approved through the explicit request for this final audit. Method choices remain subject to later approval after the stated gates.
- **Supervisor confirmation required:** Advised for the bounded estimand, exclusion of identities, 2008 role, education-wave restriction and any proposed ordinal NCT implementation.
- **Status:** Node/wave boundary frozen; method design partially frozen; final analysis not authorised.

No protected source file or ANES raw file was modified. No final network, EBICglasso, NCT, EGA or bootstrap was run.

## 2026-08-20 — Final research design freeze

- **Issue:** Freeze the final nodes, policy/identity boundary, waves, education comparison, missing-data strategy, survey-weight role and network pipeline before analysis.
- **Alternatives considered:** Policy-only versus policy-plus-identity networks; nine-node versus reduced node sets; complete-case, pairwise and imputed data; weighted versus unweighted network estimation; GGM, MGM and Ising models; 2004–2024 versus restricted education comparisons; EGA/bridge analysis versus a bounded edge/global-strength/Expected-Influence design.
- **Evidence:** Supervisor guidance and reading list; official ANES cumulative codebook and all-wave validation/measurement audits; `INDEPENDENT_DESIGN_REEVALUATION.md`; full-text political evidence from Converse, Dalege et al., Baldassarri and Gelman, Boutyline and Vaisey, Brandt and Sleegers, and Brandt, Sibley and Osborne; method evidence from Epskamp and Fried, Epskamp, Borsboom and Fried, Robinaugh, Millner and McNally, Burger et al. and van Borkulo et al. The eight newly supplied `(1).md` files were treated only as short guides, not full papers.
- **Decision:** Freeze a nine-node policy-only primary network; primary overall waves 2004, 2012, 2016, 2020 and 2024; primary education contrasts in 2012–2024 only; 2004 education exploratory; 2008 overall sensitivity only. Primary missing-data handling is complete case. Weighted estimates are used for population descriptives, while primary polychoric GGM/NCT estimation is unweighted. Primary model is polychoric EBICglasso GGM with gamma 0.50, gamma 0.25/0 sensitivity, bootstrapped accuracy/stability, stability-gated one-step Expected Influence and a pre-specified NCT family. EGA and bridge centrality are omitted.
- **Rationale:** The policy-only boundary preserves issue–issue organisation and avoids blending it with issue partisanship. All nine nodes add distinct selected policy content, while a planned eight-node sensitivity tests overlap from the broad services/spending item. Complete cases keep a common respondent base within a network. The education restriction responds to the severe 2004/2008 college+ pairwise sparsity without deleting the 2004 overall baseline.
- **Consequences:** Claims are narrowed from the entire American political belief system to selected policy-attitude networks. Education is attainment, not elites or sophistication. Repeated-cross-sectional and non-causal interpretations are mandatory. No result may be used to select waves, nodes, gamma or comparison families retrospectively.
- **Sensitivity analysis required:** Spearman association; gamma 0/0.25; eight-node network excluding `VCF0839`; pairwise-polychoric descriptive network; 2008 overall-only analysis; weighted-polychoric sensitivity only if implementation is validated.
- **Researcher approval:** Approved through the explicit request to produce the final design freeze.
- **Supervisor confirmation required:** Advised for the narrowed estimand, 2008 role, education period and ordinal NCT implementation risk.
- **Status:** Frozen for implementation subject to the pre-analysis validation gates in `FINAL_RESEARCH_DESIGN_FREEZE.md`.

No protected source file or ANES raw file was modified. No final network, EBICglasso, NCT, EGA or bootstrap was run.
## 2026-08-29 — D15 Stage 1 weight-candidate rule approval

- **Issue:** Stage 0 confirmed that `VCF0009z` is available and positive for all five complete-case samples, while `VCF9999` is available in 2004, 2016, 2020 and 2024 but absent for all 4,353 complete cases in 2012. A prospectively registered 2012 rule was required before descriptive diagnostics.
- **Alternatives considered:** Use only five-wave `VCF0009z`; restrict the post-election candidate to four waves; silently substitute another 2012 weight; stop pending supervisor advice; or explicitly register a wave-specific official-weight candidate alongside the uniform CDF candidate.
- **Evidence:** `d15_weight_source_audit.csv`, `d15_raw_weight_variable_metadata.csv`, `d15_stage0_validation.csv`, the official February 2026 CDF codebook source map and the exact 16,766-case Stage 0 join.
- **Decision:** Approve two result-blind Stage 1 candidates. `W_CDF` uses `VCF0009z` in 2004, 2012, 2016, 2020 and 2024. `W_POST_COMPAT` uses `VCF9999` in 2004, 2016, 2020 and 2024 and official `VCF0009z` (`weight_full`) as an explicitly labelled wave-specific substitute in 2012.
- **Rationale:** The paired candidates preserve a uniform five-wave CDF benchmark while testing a post-election-compatible official-weight convention without concealing the 2012 source difference. The rule is fixed before any weighted descriptions, correlations or network comparisons are inspected.
- **Consequences:** Stage 1 may report weight distributions, extreme-weight diagnostics, Kish effective sample size as a dispersion diagnostic, and weighted-versus-unweighted category proportions. `W_POST_COMPAT` must never be described as one uniform CDF variable. D15 remains unresolved and continues to block final estimand approval and formal Step 07 execution.
- **Sensitivity analysis required:** None selected from political or network results. Later Stage 2 and Stage 3 remain separately gated and cannot be used to choose a candidate for substantive attractiveness.
- **Researcher approval:** Explicitly approved on 2026-08-29.
- **Supervisor confirmation required:** Still required for the final D15 weight/estimand decision, not for running the bounded Stage 1 descriptive audit.
- **Status:** **STAGE 0 COMPLETE; STAGE 1 AUTHORISED BUT NOT EXECUTED; D15 NOT FROZEN.**

No protected source file, ANES raw file or literature paper was modified. No weighted correlation, network, bootstrap, centrality, NCT, education-group analysis or political interpretation was run.

## 2026-08-30 — 08C education-result readiness and precision classification completed

- **Issue:** Determine whether the already estimated D08A education-group networks and their saved edge-weight bootstrap results are sufficiently precise for bounded descriptive reporting, without reopening estimation or conducting education-group inference.
- **Alternatives considered:** Report all retained edges without an accuracy screen; suppress all subgroup edge descriptions; use the saved percentile intervals to classify within-network descriptive readiness; or perform an unauthorised formal between-group comparison.
- **Evidence:** Eight frozen 08B point-network and bootstrap outputs; 288 saved group-edge records; the saved `q2.5` and `q97.5` bootstrap percentiles; point-model and bootstrap diagnostics; D08A sparse-cell diagnostics; 08C source-hash, structural, prohibited-call, figure and output-integrity gates.
- **Decision:** Use the saved 95% percentile interval as a descriptive precision screen. A retained edge whose interval excludes zero is eligible for cautious description within that single network; a retained edge whose interval includes zero is not eligible for signed interpretation; a zero edge not retained under EBICglasso must not be described as absent. Rank the five widest intervals per group for audit visibility only. Use one fixed node order, circular layout and common visual scales across all eight groups. Do not make education-group significance claims from these outputs.
- **Rationale:** This rule exposes edge uncertainty while preserving the boundary between within-network description and between-group inference. The fixed display specification reduces avoidable visual differences without turning graphical contrasts into statistical tests.
- **Consequences:** Of 288 group-edge records, 166 are eligible for cautious within-network description, 78 retained edges have insufficient precision for signed interpretation, and 44 edges were not retained under regularisation. All eight networks are `READY_FOR_CAUTIOUS_WITHIN_NETWORK_DESCRIPTION_WITH_LIMITATIONS`. Dense-network and sparse-cell warnings remain visible. This decision does not activate D08B or establish any education-group difference.
- **Sensitivity analysis required:** None added by 08C. Any formal education-group comparison would require a separately approved D08B design and cannot be inferred from overlapping or non-overlapping edge intervals.
- **Researcher approval:** The researcher explicitly requested creation and execution of the bounded 08C readiness workflow on 2026-08-30.
- **Supervisor confirmation required:** Not required for the technical readiness audit; advice remains appropriate before deciding whether any formal education-group comparison should enter the dissertation.
- **Status:** **08C COMPLETE AND VALIDATED; D08A RESULTS READY FOR CAUTIOUS WITHIN-NETWORK DESCRIPTION; D08B REMAINS OUT OF CURRENT SCOPE.**

No protected source file, ANES raw file, literature paper or 08B input was modified. No network, bootstrap, centrality, NCT or education-group significance analysis was run.
## 2026-08-30 — D23 exploratory Expected Influence and case-dropping stability authorised

- **Issue:** Resolve the previously frozen Strength-only centrality rule after verifying the original Expected Influence source, the supervisor's explicit requirement for case-dropping centrality stability, the five-wave edge-sign pattern and the `bootnet` 1.9.1 implementation.
- **Alternatives considered:** Omit centrality; retain exploratory raw Strength only; use one-step Expected Influence only; use one-step Expected Influence with Strength as an auxiliary reference; or add closeness, betweenness, Bridge Expected Influence, education-group centrality or cross-wave centrality tests.
- **Evidence:** Supervisor project guidance requires case-dropping subset bootstrap for centrality indices. Epskamp, Borsboom and Fried (2018) define the case-dropping stability procedure and CS coefficient; Burger et al. (2023) require stability-gated interpretation and reporting of raw centrality values, case-dropping plots and CS coefficients; Bringmann et al. (2019) require the metric to match the research question and caution against causal or generic-importance interpretations; Robinaugh, Millner and McNally (2016) define one-step Expected Influence as the signed sum of incident edge weights. The completed Step-07 edge table contains retained positive and negative edges in every primary wave.
- **Decision:** For the five primary overall networks (2004, 2012, 2016, 2020 and 2024), freeze one-step Expected Influence as the exploratory signed centrality metric and calculate raw Strength as an auxiliary reference. Run 1,000 case-dropping bootstrap samples per wave with `caseMin = 0.05`, `caseMax = 0.75`, `caseN = 10` and calculate CS coefficients at `cor = 0.70`. The frozen primary estimator chain remains nine-node complete-case ordered data, polychoric correlations, EBICglasso, gamma 0.50 and unweighted estimation. A 10-repetition 2004 run is authorised only as a technical code test.
- **Rationale:** Every primary network contains negative retained edges, so a signed metric is relevant. Strength is retained only as an auxiliary, coding-direction-invariant reference. Because node coding was aligned for interpretability rather than shown to form a common ideological scale, Expected Influence is interpreted only as net signed conditional connectivity under the pre-specified coding. It is not causal influence, political importance, public salience or an intervention target.
- **Consequences:** Create a separate `07B_centrality_stability.Rmd` workflow. Do not change or rerun the completed edge-weight bootstrap. Do not run education-group centrality, Bridge Expected Influence, closeness, betweenness, NCT, cross-wave centrality significance tests or political interpretation. Interpretive rules are pre-specified: CS below 0.25 means no ranking interpretation; CS from 0.25 to below 0.50 permits only restricted exploratory description; CS at or above 0.50 permits cautious exploratory ranking interpretation. Instability does not remove a wave from the main network analysis.
- **Sensitivity analysis required:** Strength is calculated in the same case-dropping workflow as an auxiliary reference. No post-result switching of the focal centrality metric is permitted. Any change to case-dropping limits after estimation failure requires a new documented decision.
- **Researcher approval:** Explicitly approved by the researcher on 2026-08-30, including the scope, parameters, thresholds and exclusions.
- **Supervisor confirmation required:** Advice remains appropriate for final reporting scope, but is not required for the authorised bounded technical execution.
- **Status:** **FROZEN; 2004 TEN-REPETITION TECHNICAL TEST AUTHORISED; FORMAL FIVE-WAVE CASE-DROPPING NOT YET EXECUTED.** This entry supersedes only the Strength-only metric clause in D16 and the unresolved case-dropping clause in D22. D22's completed 1,000-repetition nonparametric edge-weight bootstrap decision remains unchanged.

## 2026-09-05 — VCF9049 final disposition resolved by a current scope decision

- **Issue:** Resolve the missing item-specific disposition for `VCF9049` (federal spending on Social Security), which appeared in the recorded candidate pool but was not included in the frozen nine-node network.
- **Historical evidence boundary:** The surviving records establish that `VCF9049` was considered and that the final network omitted it, but they do not preserve the contemporaneous item-specific reason for that omission. The decision below is therefore a current retrospective governance and scope decision. It must not be presented as a recovered historical rationale.
- **Alternatives considered:** Add `VCF9049` as a tenth primary node and rerun the full analytical pipeline; substitute it for an existing spending node; add a post hoc ten-node sensitivity analysis; or retain the already frozen nine-node boundary.
- **Evidence:** The official CDF codebook identifies `VCF9049` as a substantive policy-attitude item and lists sources for 2004, 2012, 2016, 2020 and 2024. It does not list a 2008 source, although the cumulative field contains substantive 2008 values, leaving the 2008 provenance unresolved in the original design context. In 2004, the CDF retains a separate substantive code `7` ("cut out entirely [volunteered]"), observed for 3 respondents overall and 2 respondents in the current nine-node complete-case set; only codes `1`–`3` occur substantively in 2012–2024. Adding the item would cause only modest complete-case losses (`789→779`, `4,353→4,334`, `2,709→2,704`, `5,390→5,384`, `3,525→3,512`), so sample feasibility is not a defensible exclusion reason. The fixed network already contains three issue-specific federal-spending nodes and is acknowledged to be concentrated on government responsibility and public spending. No network result, edge weight, significance test or substantive finding was used for this adjudication.
- **Decision:** Retain `VCF9049` outside the final network and classify it as `EXCLUDED_SCOPE_AND_MEASUREMENT_BOUNDARY`. The exclusion preserves the previously frozen nine-node conditioning set and avoids redefining every conditional association after completion of the principal analyses.
- **Rationale:** The decision rests jointly on preservation of the pre-result analytical boundary, the unresolved 2008 provenance present when 2008 was still part of the planned design, the 2004-versus-later response-category difference, and the bounded scope of an already spending-heavy node set. The rare 2004 code `7` is a supporting measurement consideration, not the sole or automatic basis for exclusion. `VCF9049` is not judged invalid, unavailable in the five final waves, substantively meaningless or completely redundant with the retained nodes.
- **Consequences:** Existing nine-node analyses are not re-estimated. The dissertation and appendix must describe the estimand as a selected nine-node policy-attitude and policy-related-belief subsystem and disclose that Social Security spending is outside that boundary. The missing historical reason remains disclosed as an archival limitation, but it no longer blocks the current submission because a new decision is explicitly recorded.
- **Sensitivity analysis required:** None for the current dissertation. A ten-node or substitution analysis would constitute a new estimand and may be undertaken only under a separately justified, prospectively registered extension; it must not be added merely to obtain a preferred result.
- **Researcher approval:** The researcher instructed that the unresolved blocker be resolved and the appendix/additional-material package completed. Record this entry as the operative current decision, not as evidence of the original historical intention.
- **Supervisor confirmation required:** Not required to preserve the bounded existing analysis; advice may be sought if the supervisor prefers a ten-node redesign.
- **Status:** **FROZEN_BY_CURRENT_RESEARCHER_DECISION; HISTORICAL_ITEM_SPECIFIC_RATIONALE_NOT_RECOVERED.**
