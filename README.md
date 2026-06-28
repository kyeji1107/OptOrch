# OptOrch: A modular optimization toolkit for forest tree seed orchard deployment
This repository contains the materials provided as supplementary files for the optimization framework described in the manuscript, “OptOrch: A modular optimization toolkit for forest tree seed orchard
deployment”.
OptOrch provides a modular optimization framework for seed orchard deployment. The repository includes the core AMPL optimization model, six tailored AMPL model variants, a minimal AMPL example, and R-based materials for reproducing the simulation-based analyses and figures 2–3 presented in the manuscript.
## Repository overview
The repository is organized into three main parts.
- `01_models/`
	- Contains the core AMPL formulation and six tailored AMPL model variants.
- `02_examples/`
	- Provides a small standalone AMPL example for users who want to inspect and run the algebraic formulation directly.
- `03_manuscript_reproduction/`
	- Contains R-only materials for reproducing the simulation-based manuscript scenarios and figures 2–3.
 - `04_shiny_app/`
	- Provides a local-run Shiny app for running two optimization scenarios in the manuscript through a graphical user interface.

## Requirements
### AMPL-based example
- AMPL: https://ampl.com
- Solver supporting MIQP/MIQCP
	- The authors used Gurobi.
### R-based manuscript reproduction
The R scripts require an R environment with the packages used in each script.

For simulation data generation:
- `MoBPS`
- `RandomFieldsUtils`
- `miraculix`
- `ASRgenomics`
- `ASRemL-R`
  
For scenario optimization:
- `slam`
- `gurobi`
- `Matrix`
- `data.table`
  
For figure generation:
- `data.table`
- `ggplot2`
- `patchwork`
- `tidyverse`
  
Note: `ASRemL-R` and `gurobi` require separate installation and licensing.
### Local-run Shiny app
The Shiny app requires:
* R
* `shiny`
* `data.table`
* `Matrix`
* `ggplot2`
* `gurobi`

Note: The app also requires a local Gurobi installation and a valid Gurobi license. The Shiny app runs locally and uses the user's local R environment and local Gurobi license.

## Repository structure
~~~text
OptOrch/
├── README.md
├── 01_models/
│   ├── AMPL_model_guide.md
│   ├── 001_core/
│   │   └── OptOrch_core.mod
│   └── 002_tailored_models/
│       ├── OptOrch_supp1.mod
│       ├── OptOrch_supp2.mod
│       ├── OptOrch_supp3.mod
│       ├── OptOrch_supp4.mod
│       ├── OptOrch_supp5.mod
│       └── OptOrch_supp6.mod
├── 02_examples/
│   ├── AMPL_example_guide.md
│   └── 001_minimal_AMPL_example/
│       ├── OptOrch_core.mod
│       ├── OptOrch.dat
│       ├── OptOrch.run
│       ├── b.dat
│       ├── c.dat
│       ├── l.dat
│       ├── u.dat
│       └── output
│           └── selected_individuals.csv
├── 03_manuscript_reproduction/
│   ├── 001_simulated_data/
│   │   ├── simulate_MoBPS_population.R
│   │   └── MoBPS_generated_data/
│   │       ├── file_description.md
│   │       └── Heri_0.2/
│   ├── 002_scenario1_status_number/
│   │   ├── run_scenario1_status_number.R
│   │   └── outputs/
│   │       ├── file_description.md
│   │       ├── ns_10/
│   │       ├── ns_20/
│   │       ├── ns_30/
│   │       └── ns_40/
│   ├── 003_scenario2_pollen_contamination/
│   │   ├── run_scenario2_pollen_contamination.R
│   │   └── outputs/
│   │       ├── file_description.md
│   │       ├── ns_10/
│   │       ├── ns_20/
│   │       ├── ns_30/
│   │       └── ns_40/
│   └── 004_figures/
│       ├── figure2_contributions/
│       │   ├── make_figure2_contributions.R
│       │   └── outputs/
│       │       ├── figure2_data_Ns10.csv
│       │       ├── figure2_data_Ns40.csv
│       │       └── figure2_contributions.pdf
│       └── figure3_genetic_response/
│           ├── make_figure3_genetic_response.R
│           └── outputs/
│               ├── figure3_data.csv
│               └── figure3_genetic_response.pdf
├── 04_shiny_app/
│   ├── app.R
│   └── README.md
└── LICENSE
~~~
## 01_models
This directory contains the AMPL model files used by OptOrch.

A detailed guide for preparing AMPL input data, modifying model formulations, and running the minimal AMPL example is provided in:

~~~text
01_models/AMPL_model_guide.md
~~~

The guide explains the roles and formats of AMPL-related files, including `.mod`, `.dat`, and `.run` files, and describes how users can adapt the example input files such as `b.dat`, `c.dat`, `l.dat`, `u.dat`, and `OptOrch.dat` for their own datasets.

### Core model
The core AMPL model is provided in:
~~~text
01_models/001_core/OptOrch_core.mod
~~~
This file contains the main optimization formulation used by OptOrch.
### Tailored model variants
Additional AMPL model files are provided in:
~~~text
01_models/002_tailored_models/
~~~
The tailored models illustrate formulation variants and biological extensions discussed in the manuscript.
- `OptOrch_supp1.mod`
	- Logical-operator formulation for selection-dependent lower and upper contribution bounds.
- `OptOrch_supp2.mod`
	- Logical formulation for constraining pairwise coancestry.
- `OptOrch_supp3.mod`
	- Linearized formulation for constraining pairwise coancestry.
- `OptOrch_supp4.mod`
	- Formulation with separate female and male contributions.
- `OptOrch_supp5.mod`
	- Explicit female-male formulation for pollen contamination.
- `OptOrch_supp6.mod`
	- Aggregate formulation for pollen contamination.
## 02_examples

This directory contains example files for running OptOrch.

### Minimal AMPL example

A minimal AMPL example is included to demonstrate the basic AMPL workflow with separated input files and an execution script.
The example is located in:

```text
02_examples/001_minimal_AMPL_example/
```

Files included:

* `OptOrch_core.mod`

  * Core AMPL model file used for the example.
* `OptOrch.dat`

  * Integrated data file specifying the main scalar parameters for the example.
* `OptOrch.run`

  * AMPL run script for executing the example.
* `b.dat`

  * Input file containing breeding values.
* `l.dat`

  * Input file containing lower contribution bounds.
* `u.dat`

  * Input file containing upper contribution bounds.
* `c.dat`

  * Input file containing the coancestry matrix.

Further details on AMPL installation, license setup, solver requirements, file roles, and the execution workflow are provided in:

~~~text
02_examples/AMPL_example_guide.md
~~~

## 03_manuscript_reproduction
This directory contains R-only materials for reproducing the simulation-based manuscript analyses and figures 2–3.
The manuscript reproduction workflow is organized as follows.
### Step 1. Simulated data
Simulation code and MoBPS-generated data are provided in:
~~~text
03_manuscript_reproduction/001_simulated_data/
~~~
Files and folders:
- `simulate_MoBPS_population.R`
	- R script used to generate simulated populations and related data using MoBPS.
- `MoBPS_generated_data/`
	- Folder containing MoBPS-generated data used by the scenario scripts.
- `MoBPS_generated_data/file_description.md`
	- Description of the generated data files.
- `MoBPS_generated_data/Heri_0.2/`
	- Simulation outputs generated under heritability 0.2.
The generated data include replicate-level files such as:
- `rep*_Np1_Data.csv`
- `rep*_Np2_Data.csv`
- `rep*_Offspring_Data.csv`
- `rep*_Nr_Data.csv`
- `rep*_GBLUP_results.csv`
- `rep*_Gmatrix_tuned_all.csv`
- `rep*_Gmatrix_tuned_Np2.csv`
### Step 2. Scenario 1: status number constraint
Scenario 1 is provided in:
~~~text
03_manuscript_reproduction/002_scenario1_status_number/
~~~
Files and folders:
- `run_scenario1_status_number.R`
	- R script for running Scenario 1.
	- The script repeats the optimization for `ns = 10, 20, 30, 40`.
- `outputs/`
	- Optimization outputs for Scenario 1.
- `outputs/file_description.md`
	- Description of the output files.
The output folders are organized by status number and replicate:
~~~text
outputs/
├── ns_10/
├── ns_20/
├── ns_30/
└── ns_40/
~~~
Each status-number folder contains replicate folders such as:
~~~text
rep_1/
rep_2/
...
rep_30/
~~~

### Step 3. Scenario 2: pollen contamination
Scenario 2 is provided in:
~~~text
03_manuscript_reproduction/003_scenario2_pollen_contamination/
~~~
Files and folders:
- `run_scenario2_pollen_contamination.R`
	- R script for running Scenario 2.
	- The script repeats the optimization for `ns = 10, 20, 30, 40` under pollen contamination.
- `outputs/`
	- Optimization outputs for Scenario 2.
- `outputs/file_description.md`
	- Description of the output files.
The output folders follow the same structure as Scenario 1.

### Gurobi tuning parameters
The tuned Gurobi parameter settings used in the manuscript reproduction scripts are defined directly in the two scenario scripts:
- `03_manuscript_reproduction/002_scenario1_status_number/run_scenario1_status_number.R`
- `03_manuscript_reproduction/003_scenario2_pollen_contamination/run_scenario2_pollen_contamination.R`
In both scripts, the tuned configurations are stored in the object `tuned_params_by_ns <- list()`. This object contains the parameter values for each status-number level (`ns = 10, 20, 30, 40`). During execution, the script selects the parameter set corresponding to the specified `ns` value and passes it to the Gurobi optimizer. These tuned settings correspond to the Gurobi parameters summarized in Table 1 of the manuscript.

### Step 4. Figure 2 reproduction
Figure 2 can be reproduced using:
~~~text
03_manuscript_reproduction/004_figures/figure2_contributions/make_figure2_contributions.R
~~~
Expected files in the `outputs/` folder:
- `figure2_data_Ns10.csv`
- `figure2_data_Ns40.csv`
- `figure2_contributions.pdf`
### Step 5. Figure 3 reproduction
Figure 3 can be reproduced using:
~~~text
03_manuscript_reproduction/004_figures/figure3_genetic_response/make_figure3_genetic_response.R
~~~
Expected files in the `outputs/` folder:
- `figure3_data.csv`
- `figure3_genetic_response.pdf`

## 04_shiny_app
This directory contains a local-run Shiny app for running two optimization scenarios through a graphical user interface.
The app is provided in:
```text
04_shiny_app/app.R
```
A detailed guide for launching and using the app is provided in:
```text
04_shiny_app/README.md
```
The app currently supports:
* Scenario 1: status number constraint
* Scenario 2: pollen contamination
The Shiny app runs one selected dataset and one selected status number at a time. It displays the run status, summary table, selected individuals, contribution plot, and Gurobi log in the Shiny interface.
Importantly, the `Run optimization` button does not write, overwrite, or modify any files in the manuscript reproduction folders. Newly generated results are displayed only in the current Shiny session. Users can manually download the selected individuals table if needed.
To launch the app, open R or RStudio from the OptOrch repository root and run:
```r
shiny::runApp("04_shiny_app")
```

## Running the R scripts
Each R script uses relative paths based on the current working directory.
Before running a script, set the working directory to the folder containing that script.
For example, to run Scenario 1:
~~~r
setwd("03_manuscript_reproduction/002_scenario1_status_number")
source("run_scenario1_status_number.R")
~~~
To run Scenario 2:
~~~r
setwd("03_manuscript_reproduction/003_scenario2_pollen_contamination")
source("run_scenario2_pollen_contamination.R")
~~~
To reproduce figure 2:
~~~r
setwd("03_manuscript_reproduction/004_figures/figure2_contributions")
source("make_figure2_contributions.R")
~~~
To reproduce figure 3:
~~~r
setwd("03_manuscript_reproduction/004_figures/figure3_genetic_response")
source("make_figure3_genetic_response.R")
~~~
## Software notes
- The AMPL example requires AMPL and an optimization solver.
- The R-based scenario scripts require the R package `gurobi` and a working Gurobi installation.
- The simulation script requires MoBPS and ASRemL-R.
- The scenario and figure scripts use relative paths. Run each script from its own folder.
- The authors used Gurobi as the optimization solver.
- The local-run Shiny app requires `shiny`, `data.table`, `Matrix`, `ggplot2`, `gurobi`, and a working local Gurobi license.
## Contact
For any inquiries, please contact:
- Corresponding author: Prof. Milan Lstibůrek
	- E-mail: lstiburek@fld.czu.cz
- First author: Dr. Ye-Ji Kim
	- E-mail: kyeji1107@gmail.com
