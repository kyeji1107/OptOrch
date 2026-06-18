# OptOrch Local-Run Shiny App

This folder contains a local-run Shiny app for running R-Gurobi seed orchard contribution optimization through a graphical user interface. The app allows users to run optimization with their own input data without directly editing the R scripts.

For a step-by-step visual guide, see:

```text
OptOrch_Shiny_App_Manual_EN_v1.pdf
```

## Important note

The Shiny app runs the optimization locally. It uses the user's local R environment and local Gurobi license. It does not send data to a remote server.

Newly generated results are displayed in the current Shiny session. Users can download the selected individuals table manually if needed.

## Folder location

The expected repository structure is:

```text
OptOrch/
├── 03_manuscript_reproduction/
└── 04_shiny_app/
    ├── app.R
    ├── README.md
    ├── OptOrch_Shiny_App_Manual_EN_v1.pdf
    └── Input_data/
        ├── BV.csv
        └── coMatrix.csv
```

The Shiny app should be launched from the OptOrch repository root:

```text
OptOrch/
```

## Requirements

The app requires:

- R
- Shiny and other required R packages
- A local Gurobi installation
- A valid Gurobi license

### Required R packages

Install the required CRAN packages in R:

```r
install.packages(c("shiny", "data.table", "Matrix", "ggplot2"))
```

The app also requires the Gurobi R package. The Gurobi R package is usually installed from the local Gurobi installation directory, not from CRAN.

### Checking the Gurobi installation

Before running the Shiny app, check that the Gurobi R package and license work correctly. Academic users can use their own academic Gurobi license.

## Input files

The app reads two input files from:

```text
04_shiny_app/Input_data/
```

The required files are:

```text
BV.csv
coMatrix.csv
```

### BV.csv

`BV.csv` contains the candidate IDs and breeding values.

Recommended format:

```csv
ID,BV
1,-0.096
2,0.334
3,0.049
```

Required columns:

- `ID`: individual identifier
- `BV`: breeding value used in the objective function

### coMatrix.csv

`coMatrix.csv` contains the pairwise coancestry matrix among the same candidate individuals in `BV.csv`.

Recommended format:

```csv
ID,1,2,3
1,0.498,0.002,0.001
2,0.002,0.492,0.003
3,0.001,0.003,0.498
```

The row and column IDs should match the `ID` values in `BV.csv`. The matrix must be square and symmetric.

If the available input is a genetic or genomic relationship matrix, scale it by 0.5 before saving it as `coMatrix.csv`.

## Launching the Shiny app

Open R or RStudio and set the working directory to the OptOrch repository root. For example:

```r
setwd("path/to/OptOrch")
shiny::runApp("04_shiny_app")
```

If the working directory is already the repository root, run:

```r
shiny::runApp("04_shiny_app")
```

If the current working directory is already `04_shiny_app`, run:

```r
shiny::runApp(".")
```

## What the app does

The app runs seed orchard contribution optimization using `BV.csv` and `coMatrix.csv` in `04_shiny_app/Input_data/`.

It currently supports two optimization scenarios:

- Scenario 1: Status number
	- Runs the status number constrained optimization.
	- The internal contribution sum is fixed to 1.
	- The quadratic constraint is `p'C p <= 1 / (2Ns)`.
- Scenario 2: Pollen contamination
	- Runs the optimization with pollen contamination.
	- The internal contribution sum is adjusted according to the pollen contamination rate.
	- The quadratic constraint is adjusted using the number of external pollen parents.
	- The app calculates internal gain and total gain.

## User interface

The left panel contains user inputs. The right panel displays the run status, summary table, selected individuals, contribution plot, and Gurobi log.

### Input data check

The `Input data check` box shows whether the required input files are available:

```text
Input data folder: FOUND
BV.csv: FOUND
coMatrix.csv: FOUND
Ready to run: YES
```

Click `Refresh input data status` after replacing or adding input files.

### Scenario

Use the `Scenario` menu to choose one of the two scenarios:

```text
Scenario 1: Status number
Scenario 2: Pollen contamination
```

Choose `Scenario 1: Status number` to run the basic status number constrained optimization. Choose `Scenario 2: Pollen contamination` to include pollen contamination in the optimization.

### Status number

Use `Status number (Ns)` to enter the target status number. The accepted range is:

```text
1 to 100
```

The status number is used in the quadratic coancestry constraint:

```text
p'C p <= 1 / (2Ns)
```

### Gurobi parameter setting

Use `Gurobi parameter setting` to choose the parameter set.

Available options are:

```text
Default
Tuned for Ns = 10
Tuned for Ns = 20
Tuned for Ns = 30
Tuned for Ns = 40
```

`Default` applies only the essential app parameters:

```text
OutputFlag = 1
NonConvex = 2
```

The tuned parameter sets are optional reproducibility aids based on the parameter settings used in the manuscript. They can be selected by users who want to try a tuned setting close to their chosen status number. The best parameter setting may vary depending on the dataset and model.

### Time limit

Use `Time limit` to set a maximum optimization time.

Available options are:

```text
None
1 hour
3 hours
6 hours
12 hours
24 hours
```

If the selected time limit is reached, Gurobi stops and the app reports:

```text
Run status: time limit reached
```

### MIPGap

Use `MIPGap (optional)` to enter a custom MIP gap.

Leave this field blank to use the Gurobi default.

Example:

```text
0.005
```

This means a 0.5% MIP gap tolerance.

### Lower contribution bound

Use `Lower contribution bound` to set the minimum contribution allowed for a selected individual. The default value is:

```text
0.01
```

This means that if an individual is selected, its contribution must be at least 1%.

### Upper contribution bound

Use `Upper contribution bound` to set the maximum contribution allowed for a selected individual. The default value is:

```text
0.15
```

This means that if an individual is selected, its contribution cannot exceed 15%.

### Pollen contamination rate

This input appears only when `Scenario 2: Pollen contamination` is selected. The default value is:

```text
0.3
```

This represents a pollen contamination rate of 30%.

### Number of external pollen parents

This input appears only when `Scenario 2: Pollen contamination` is selected. The default value is:

```text
100
```

This value is used to adjust the quadratic constraint under pollen contamination.

### Print Gurobi log in R console

Use `Print Gurobi log in R console while running` to control whether the Gurobi optimization log is printed in the R console.

If checked, the Gurobi log is printed while the optimization is running. If unchecked, console output is reduced. The app also stores the Gurobi log in a temporary file for display in the current Shiny session.

### Run optimization

Click `Run optimization` to run the selected optimization. The app will:

- Detect the OptOrch repository root automatically.
- Check the required input files in `04_shiny_app/Input_data/`.
- Read `BV.csv` and `coMatrix.csv`.
- Build the optimization model.
- Run Gurobi locally.
- Display the summary, selected individuals, contribution plot, and Gurobi log in the Shiny interface.

### Download selected individuals

Click `Download selected individuals` to download the selected individuals table as a CSV file.

The downloaded file contains:

- `ID`
	- Selected individual ID.
- `ns`
	- Selected status number.
- `bv`
	- Breeding value of the selected individual.
- `p`
	- Optimized contribution.
- `r`
	- Binary selection variable.

## Output tabs

The main panel contains five tabs.

### Run status tab

The `Run status` tab displays the current state of the app. It shows messages such as:

```text
Choose a scenario and click 'Run optimization'.
Optimization is running.
Run status: optimal solution found
Run status: not feasible
Run status: time limit reached
Error:
...
```

If an error occurs, this tab shows the error message.

### Summary tab

The `Summary` tab displays the run-level summary.

For Scenario 1, the summary includes:

- `ns`
	- Status number.
- `status`
	- Gurobi optimization status.
- `objval`
	- Objective value.
- `runtime`
	- Gurobi runtime.
- `n_selected`
	- Number of selected individuals.

For Scenario 2, the summary also includes:

- `BV_ext_mean`
	- Mean breeding value used for the external pollen source.
- `sum_p`
	- Sum of internal contributions.
- `Gain_internal`
	- Gain from internal seed orchard contributions.
- `Gain_total`
	- Total gain including external pollen contribution.

### Selected individuals tab

The `Selected individuals` tab displays the selected individuals and their optimized contributions.

### Contribution plot tab

The `Contribution plot` tab shows a bar plot of optimized contributions for the selected individuals. The plot displays the selected individual ID and optimized contribution.

### Gurobi log tab

The `Gurobi log` tab displays the Gurobi solver log. For newly generated runs, the log is read from a temporary file created during the current Shiny session.

## Troubleshooting

### The app cannot find the repository root

Launch the app from the OptOrch repository root:

```r
setwd("path/to/OptOrch")
shiny::runApp("04_shiny_app")
```

The repository root should contain:

```text
04_shiny_app/
```

### The app cannot find input files

Check that the input files are located in:

```text
04_shiny_app/Input_data/
```

The folder should contain:

```text
BV.csv
coMatrix.csv
```

The app also displays the input file status in the `Input data check` box.

### coMatrix.csv is not symmetric

If the app returns:

```text
coMatrix.csv must be a symmetric coancestry matrix.
```

check that the matrix is square and symmetric. Also check that row and column IDs match the IDs in `BV.csv`.


## Notes

This Shiny app runs the optimization locally. It does not send data to a remote server. The optimization uses the user's local R environment and local Gurobi license. This design avoids the need to host a public Gurobi-enabled web server and allows academic users to run the app using their own Gurobi academic license.
