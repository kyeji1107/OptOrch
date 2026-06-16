\### OptOrch Local-Run Shiny App



This folder contains a local-run Shiny app for running two R-Gurobi optimization scenarios from the OptOrch manuscript reproduction workflow. The app allows users to run selected optimization settings through a graphical user interface without directly editing the R scripts.



\### Important safety note



Running the optimization from the Shiny app does not write, overwrite, or modify any files in the manuscript reproduction folders. Newly generated results are displayed only in the current Shiny session. Users can download the selected individuals table manually if needed.



\### Folder location



The expected repository structure is:



```text

OptOrch/

├── 03\_manuscript\_reproduction/

│   ├── 001\_simulated\_data/

│   ├── 002\_scenario1\_status\_number/

│   └── 003\_scenario2\_pollen\_contamination/

└── 04\_shiny\_app/

&#x20;   ├── app.R

&#x20;   └── README.md

```



The Shiny app should be launched from the OptOrch repository root:



```text

OptOrch/

```



\### Requirements



The app requires:



\* R

\* Shiny and other required R packages

\* A local Gurobi installation

\* A valid Gurobi license



\### Required R packages



Install the required CRAN packages in R:



```r

install.packages(c("shiny", "data.table", "Matrix", "ggplot2"))

```



The app also requires the Gurobi R package. The Gurobi R package is usually installed from the local Gurobi installation directory, not from CRAN.



\### Checking the Gurobi installation



Before running the Shiny app, check that the Gurobi R package and license work correctly. Academic users can use their own academic Gurobi license.



\### Launching the Shiny app



Open R or RStudio and set the working directory to the OptOrch repository root. For example:



```r

setwd("path/to/OptOrch")

shiny::runApp("04\_shiny\_app")

```



```r

```



If the working directory is already the repository root, run:



```r

shiny::runApp("04\_shiny\_app")

```



If the current working directory is already `04\_shiny\_app`, run:



```r

shiny::runApp(".")

```



\### What the app does



The app runs one selected dataset and one selected status number at a time. It currently supports two optimization scenarios:



\* Scenario 1: Status number



&#x20; \* Runs the status number constrained optimization.

&#x20; \* The internal contribution sum is fixed to 1.

&#x20; \* The quadratic constraint is `p'C p <= 1 / (2Ns)`.

\* Scenario 2: Pollen contamination



&#x20; \* Runs the optimization with pollen contamination.

&#x20; \* The internal contribution sum is adjusted according to the pollen contamination rate.

&#x20; \* The quadratic constraint is adjusted using the number of external pollen parents.

&#x20; \* The app calculates internal gain and total gain.



\### User interface



The left panel contains the user inputs. The right panel displays the run status, summary table, selected individuals, contribution plot, and Gurobi log.



\### Scenario



Use the `Scenario` menu to choose one of the two scenarios:



```text

Scenario 1: Status number

Scenario 2: Pollen contamination

```



Choose `Scenario 1: Status number` to run the basic status number constrained optimization. Choose `Scenario 2: Pollen contamination` to include pollen contamination in the optimization.



\### Status number



Use `Status number (Ns)` to select the target status number. Available values are:



```text

10

20

30

40

```



The app uses tuned Gurobi parameters for each status number.



\### Dataset number



Use `Dataset number` to select the simulation dataset. Available values are:



```text

1 to 30

```



The dataset number corresponds to the input files:



```text

rep1\_Gmatrix\_tuned\_all.csv

rep1\_GBLUP\_results.csv

rep2\_Gmatrix\_tuned\_all.csv

rep2\_GBLUP\_results.csv

...

rep30\_Gmatrix\_tuned\_all.csv

rep30\_GBLUP\_results.csv

```



For example, `Dataset number = 1` uses:



```text

rep1\_Gmatrix\_tuned\_all.csv

rep1\_GBLUP\_results.csv

```



\### Lower contribution bound



Use `Lower contribution bound` to set the minimum contribution allowed for a selected individual. The default value is:



```text

0.01

```



This means that if an individual is selected, its contribution must be at least 1%.



\### Upper contribution bound



Use `Upper contribution bound` to set the maximum contribution allowed for a selected individual. The default value is:



```text

0.15

```



This means that if an individual is selected, its contribution cannot exceed 15%.



\### Pollen contamination rate



This input appears only when `Scenario 2: Pollen contamination` is selected. The default value is:



```text

0.3

```



This represents a pollen contamination rate of 30%.



\### Number of external pollen parents



This input appears only when `Scenario 2: Pollen contamination` is selected. The default value is:



```text

100

```



This value is used to adjust the quadratic constraint under pollen contamination.



\### Print Gurobi log in R console



Use `Print Gurobi log in R console` to control whether the Gurobi optimization log is printed in the R console. If checked, the Gurobi log is printed while the optimization is running. If unchecked, the console output is reduced. For newly generated runs, the app stores the Gurobi log in a temporary file for display in the current Shiny session. It does not overwrite any existing `gurobi.log` file in the repository.



\### Run optimization



Click `Run optimization` to run the selected optimization. The app will:



\* Detect the OptOrch repository root automatically.

\* Read the simulated data for the selected dataset number.

\* Build the optimization model.

\* Run Gurobi locally.

\* Display the summary, selected individuals, contribution plot, and Gurobi log in the Shiny interface.

\* Avoid writing to or overwriting existing manuscript reproduction output folders.

&#x20; The newly generated result is not automatically saved into the repository output folders. To save the selected individuals table from the current Shiny session, use `Download selected individuals`.



\### Load existing outputs



Click `Load existing outputs` to inspect the manuscript reproduction results already included in the repository. This button reads existing outputs in read-only mode and does not run Gurobi.



\### Download selected individuals



Click `Download selected individuals` to download the selected individuals table as a CSV file. This works for both newly generated results and loaded existing outputs.

The downloaded file contains:



\* `ID`



&#x20; \* Selected individual ID.

\* `iter`



&#x20; \* Dataset number used internally.

\* `ns`



&#x20; \* Selected status number.

\* `bv`



&#x20; \* Breeding value of the selected individual.

\* `p`



&#x20; \* Optimized contribution.

\* `r`



&#x20; \* Binary selection variable.

&#x20;   The downloaded file name follows this pattern:



```text

selected\_individuals\_scenario\_1\_status\_number\_ns\_10\_rep\_1.csv

```



or:



```text

selected\_individuals\_scenario\_2\_pollen\_contamination\_ns\_10\_rep\_1.csv

```



\### Output tabs



The main panel contains five tabs.



\### Run status tab



The `Run status` tab displays the current state of the app. It shows messages such as:



```text

Choose a scenario and click 'Run optimization' or 'Load existing outputs'.

Optimization is running.

Finished.

Error:

...

```



If an error occurs, this tab shows the error message.



\### Summary tab



The `Summary` tab displays the run-level summary. For newly generated runs, this summary is generated in the current Shiny session. For existing outputs, this tab displays the summary loaded in read-only mode.

For Scenario 1, the summary includes:



\* `iter`



&#x20; \* Dataset number.

\* `ns`



&#x20; \* Status number.

\* `status`



&#x20; \* Gurobi optimization status.

\* `objval`



&#x20; \* Objective value.

\* `runtime`



&#x20; \* Gurobi runtime.

\* `n\_selected`



&#x20; \* Number of selected individuals.

&#x20;   For Scenario 2, the summary also includes:

\* `BV\_ext\_mean`



&#x20; \* Mean breeding value of the external pollen source population.

\* `sum\_p`



&#x20; \* Sum of internal contributions.

\* `Gain\_internal`



&#x20; \* Gain from internal seed orchard contributions.

\* `Gain\_total`



&#x20; \* Total gain including external pollen contribution.



\### Selected individuals tab



The `Selected individuals` tab displays the selected individuals and their optimized contributions. For newly generated runs, this table is generated in the current Shiny session. For existing outputs, this table is loaded in read-only mode.



\### Contribution plot tab



The `Contribution plot` tab shows a bar plot of optimized contributions for the selected individuals. The plot displays the selected individual ID and optimized contribution.



\### Gurobi log tab



The `Gurobi log` tab displays the Gurobi solver log. For newly generated runs, the log is read from a temporary file created during the current Shiny session. For existing outputs, the log is loaded in read-only mode if available.



\###



\### Troubleshooting



\### The app cannot find the repository root



Launch the app from the OptOrch repository root:



```r

setwd("path/to/OptOrch")

shiny::runApp("04\_shiny\_app")

```



The repository root should contain:



```text

03\_manuscript\_reproduction/

04\_shiny\_app/

```



\### The app cannot find the simulation data



Check that the simulated data are located in:



```text

03\_manuscript\_reproduction/001\_simulated\_data/mobps\_generated\_data/Heri\_0.2/

```



or:



```text

03\_manuscript\_reproduction/001\_simulated\_data/MoBPS\_generated\_data/Heri\_0.2/

```



\### Gurobi license error



If the app returns a Gurobi license error, first test Gurobi directly in R:



```r

library(gurobi)

model <- list(

&#x20; modelsense = "max",

&#x20; obj = c(1, 1),

&#x20; A = matrix(c(1, 2), nrow = 1),

&#x20; rhs = 4,

&#x20; sense = "<",

&#x20; vtype = c("C", "C"),

&#x20; lb = c(0, 0)

)

res <- gurobi(model, list(OutputFlag = 1))

res$status

```



If this test fails, the issue is with the local Gurobi installation or license, not with the Shiny app.



\### Missing R packages



If an error says that a required package is missing, install the missing package. For example:



```r

install.packages("shiny")

install.packages("data.table")

install.packages("Matrix")

install.packages("ggplot2")

```



The Gurobi R package must be installed separately from the local Gurobi installation directory.



\###



\### Notes



This Shiny app runs the optimization locally. It does not send data to a remote server. The optimization uses the user's local R environment and local Gurobi license. The `Run optimization` button does not modify existing manuscript reproduction outputs. This design avoids the need to host a public Gurobi-enabled web server and allows academic users to run the app using their own Gurobi academic license.



