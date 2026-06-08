# Output file description: Scenario 2

This folder contains the optimization outputs for Scenario 2: pollen contamination.

## Folder structure

- `ns_10`, `ns_20`, `ns_30`, `ns_40`
	- Output folders for each status number condition.
- `rep_1`, `rep_2`, ..., `rep_30`
	- Output folders for each simulation replicate.

## Files in each replicate folder

### `summary.csv`

Summary of the optimization result for the replicate.

Columns:

- `iter`
	- Simulation replicate number.
- `ns`
	- Status number constraint.
- `status`
	- Gurobi optimization status.
- `objval`
	- Optimized objective value.
- `runtime`
	- Solver runtime in seconds.
- `n_selected`
	- Number of selected candidates.
- `sum_p`
	- Sum of optimized internal orchard contributions.
- `BV_ext_mean`
	- Mean breeding value of external pollen donors.
- `Gain_internal`
	- Genetic gain from internal orchard parents.
- `Gain_total`
	- Total expected genetic gain after adding the external pollen contribution.

### `selected_individuals.csv`

List of selected candidates with non-zero contributions.

Columns:

- `ID`
	- Candidate identifier.
- `iter`
	- Simulation replicate number.
- `ns`
	- Status number constraint.
- `bv`
	- Genomic breeding value of the candidate.
- `p`
	- Optimized contribution.
- `r`
	- Binary selection indicator.

### `Csub_rep_{rep}_ns_{ns}.csv`

Coancestry submatrix among the selected candidates.

This matrix is extracted from the full coancestry matrix after optimization.

### `p_rep_{rep}_ns_{ns}.rds`

RDS file containing the full vector of optimized contributions `p` for all 500 candidates.

### `r_rep_{rep}_ns_{ns}.rds`

RDS file containing the full vector of binary selection indicators `r` for all 500 candidates.
