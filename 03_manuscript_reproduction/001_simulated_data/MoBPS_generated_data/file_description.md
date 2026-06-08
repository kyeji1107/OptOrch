\# MoBPS-generated data description

This folder contains simulation data generated using MoBPS and used for manuscript reproduction.

\## Tips

\- `Np1`

&#x09;- Parents population.

&#x09;- Phenotypically high-ranked trees selected from the foundation population.

\- `No`

&#x09;- Offspring population.

&#x09;- Candidate population used for optimization.

\- `Np2`

&#x09;- Pollen contaminants.

&#x09;- Randomly sampled external pollen donor population.

\- `Nr`

&#x09;- Randomly sampled trees from the foundation population.

\- `rep0`

&#x09;- Dataset iteration number.

&#x09;- In the actual files, `rep0` is replaced by `rep1`, `rep2`, ..., `rep30`.

\## Files

\### `rep0\_GBLUP\_results.csv`

This file contains GBLUP results for the simulated individuals.

Rows:

\- Rows 2 to 101

&#x09;- `Np1`

&#x09;- Parents population.

\- Rows 102 to 601

&#x09;- `No`

&#x09;- Offspring candidate population.

\- Rows 602 to 1501

&#x09;- `Nr`

&#x09;- Randomly sampled trees from the foundation population.

\### `rep0\_Gmatrix\_tuned\_??.csv`

This file contains tuned genomic relationship matrices.

Available versions:

\- `rep0\_Gmatrix\_tuned\_all.csv`

&#x09;- Genomic relationship matrix for `Np1`, `No`, and `Nr`.

\- `rep0\_Gmatrix\_tuned\_Np2.csv`

&#x09;- Genomic relationship matrix for `Np2`.

\### `rep0\_??\_Data.csv`

This file contains true phenotypes and breeding values for the corresponding population.

Columns:

\- `Pheno`

&#x09;- True phenotype.

\- `BV`

&#x09;- True breeding value.

Examples:

\- `rep0\_Np1\_Data.csv`

&#x09;- Phenotype and breeding value data for `Np1`.

\- `rep0\_Np2\_Data.csv`

&#x09;- Phenotype and breeding value data for `Np2`.

\- `rep0\_Offspring\_Data.csv`

&#x09;- Phenotype and breeding value data for `No`.

\- `rep0\_Nr\_Data.csv`

&#x09;- Phenotype and breeding value data for `Nr`.

\## Simulation setting

\- Heritability: `0.2`

\## Note

\- GBLUP was implemented using the founder population.

