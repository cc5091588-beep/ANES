# Results

These files display saved estimates; opening them does not run an analysis.

## Figures and tables

| Content | Figure or table | Values |
| --- | --- | --- |
| Five overall networks | [Networks.pdf](Networks.pdf) | [Edge weights](../analysis/plotdata/figures/Figure_4_1_source_edges.csv) |
| Edge weights across years | [Years.pdf](Years.pdf) | [Heatmap values](../analysis/plotdata/figures/Figure_4_2_source_matrix.csv) |
| Edge weights by education group | [Education.pdf](Education.pdf) | [Heatmap values](../analysis/plotdata/figures/Figure_4_3_source_matrix.csv) |
| Overall sample and network summary | [Samples.csv](Samples.csv) | [Full summary](../analysis/outputs/tables/final/10_sample_primary_summary.csv) |
| Education-group summary | [Education.csv](Education.csv) | [Full summary](../analysis/outputs/tables/final/10_education_summary.csv) |
| Year-comparison robustness | [Robustness.pdf](Robustness.pdf) | [Robustness.csv](Robustness.csv) |
| Selected edge intervals in 2004 and 2024 | [Intervals.csv](Intervals.csv) | [All overall edges and intervals](../analysis/outputs/tables/formal/08_overall_edges_with_accuracy.csv) |

`Intervals.csv` contains three selected edges in each of the two endpoint years, not the complete five-year interval table. Its limits are within-network 95% bootstrap percentile intervals, not intervals for differences between years.

## Further results

- [Overall edge estimates and precision](../analysis/outputs/tables/formal/08_overall_edges_with_accuracy.csv)
- [Education-group edge estimates and precision](../analysis/outputs/tables/formal/08C_education_edge_accuracy_review.csv)
- [Centrality stability](../analysis/outputs/tables/formal/08_overall_centrality_stability.csv)
- [Sensitivity results by year](../analysis/outputs/tables/sensitivity/09_sensitivity_summary_by_wave.csv)
- [Specificity and equal-sample-size comparisons](../analysis/outputs/tables/sensitivity/09B_contrast_robustness.csv)
- [Sixteen-candidate audit](../analysis/outputs/tables/supplement/candidate_pool_16_audit/candidate_pool_16_summary.csv)

[Index.csv](Index.csv) records source files and code. See the [analysis instructions](../analysis/README.md) to check the saved values or regenerate figures and tables. Existing HTML reports are historical execution records, not reruns of the subsequently edited Rmd files.
