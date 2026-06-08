\# Output file description: Scenario 1



This folder contains the optimization outputs for Scenario 1: status number constraint.



\## Folder structure



\- `ns\_10`, `ns\_20`, `ns\_30`, `ns\_40`

&#x09;- Output folders for each status number condition.

\- `rep\_1`, `rep\_2`, ..., `rep\_30`

&#x09;- Output folders for each simulation replicate.



\## Files in each replicate folder



\### `summary.csv`



Summary of the optimization result for the replicate.



Columns:



\- `iter`

&#x09;- Simulation replicate number.

\- `ns`

&#x09;- Status number constraint.

\- `status`

&#x09;- Gurobi optimization status.

\- `objval`

&#x09;- Optimized objective value.

\- `runtime`

&#x09;- Solver runtime in seconds.

\- `n\_selected`

&#x09;- Number of selected candidates.



\### `selected\_individuals.csv`



List of selected candidates with non-zero contributions.



Columns:



\- `ID`

&#x09;- Candidate identifier.

\- `iter`

&#x09;- Simulation replicate number.

\- `ns`

&#x09;- Status number constraint.

\- `bv`

&#x09;- Genomic breeding value of the candidate.

\- `p`

&#x09;- Optimized contribution.

\- `r`

&#x09;- Binary selection indicator.



\### `Csub\_rep\_{rep}\_ns\_{ns}.csv`



Coancestry submatrix among the selected candidates.



This matrix is extracted from the full coancestry matrix after optimization.



\### `p\_rep\_{rep}\_ns\_{ns}.rds`



RDS file containing the full vector of optimized contributions `p` for all 500 candidates.



\### `r\_rep\_{rep}\_ns\_{ns}.rds`



RDS file containing the full vector of binary selection indicators `r` for all 500 candidates.



