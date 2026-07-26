# MoBPS-generated data description

This folder contains simulation data generated using MoBPS and used for manuscript reproduction.

## Tips

- `Np1`
	- Parent population.
	- Phenotypically high-ranked trees selected from the foundation population.
- `No`
	- Offspring population.
	- Candidate population used for optimization.
- `Np2`
	- Pollen contaminants.
	- Randomly sampled external pollen donor population.
- `Nr`
	- Reference population.
	- Randomly sampled trees from the foundation population.
- `rep0`
	- Dataset iteration number.
	- In the actual files, `rep0` is replaced by `rep1`, `rep2`, ..., `rep30`.

## Files

### `rep0_GBLUP_results.csv`

This file contains GBLUP results for the simulated individuals.

Rows:

- Rows 2 to 101
	- `Np1`
	- Parent population.
- Rows 102 to 601
	- `No`
	- Offspring candidate population.
- Rows 602 to 1501
	- `Nr`
	- Randomly sampled trees from the foundation population.

### `rep0_Gmatrix_tuned_??.csv`

This file contains tuned genomic relationship matrices.
For optimization, the genomic relationship matrix is multiplied by 0.5 to obtain the coancestry matrix.

Available versions:

- `rep0_Gmatrix_tuned_all.csv`
	- Genomic relationship matrix for `Np1`, `No`, and `Nr`.
- `rep0_Gmatrix_tuned_Np2.csv`
	- Genomic relationship matrix for `Np2`.

### `rep0_??_Data.csv`

This file contains true phenotypes and breeding values for the corresponding population.

Columns:

- `Pheno`
	- True phenotype.
- `BV`
	- True breeding value.

Examples:

- `rep0_Np1_Data.csv`
	- Phenotype and breeding value data for `Np1`.
- `rep0_Np2_Data.csv`
	- Phenotype and breeding value data for `Np2`.
- `rep0_Offspring_Data.csv`
	- Phenotype and breeding value data for `No`.
- `rep0_Nr_Data.csv`
	- Phenotype and breeding value data for `Nr`.

## Simulation setting

- Heritability: `0.2`

## Note

- GBLUP was implemented using the founder population.
