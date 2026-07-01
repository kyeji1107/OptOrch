# AMPL model guide

This guide explains how to prepare input data, modify the AMPL model formulation, and run OptOrch using the minimal AMPL example.

AMPL files are plain text files. Although the file extensions may look unfamiliar, `.mod`, `.dat`, and `.run` files can be opened and edited using a standard text editor or the AMPL IDE.

In this repository, AMPL-related files have different roles:

- `.mod`
	- Model files defining the optimization formulation.
	- These files contain sets, parameters, decision variables, objective functions, and constraints.

- `.dat`
	- Data files providing numerical input values.
	- These files contain scalar parameters, breeding values, contribution bounds, or coancestry matrices.

- `.run`
	- Run files controlling model execution.
	- These files load the model and data, select the solver, solve the optimization problem, and display outputs.

## 1. Prepare input data

Users who want to apply OptOrch to their own dataset should first prepare the required input data files. Example input files are provided in:

~~~text
02_examples/001_minimal_AMPL_example/
~~~

These files can be used as templates for formatting user-specific datasets.

### `b.dat`

Breeding value input file.

This file contains the breeding values of candidate individuals. Users should replace the example values with breeding values estimated from their own candidate population.

Example structure:

~~~text
param b :=
1 0.241
2 0.185
3 0.132
4 0.097
;
~~~

In this structure:

- The first column indicates the candidate index.
- The second column indicates the breeding value of each candidate.
- The candidate indices should match the indices used in the other input files.

### `c.dat`

Coancestry matrix input file.

This file contains the pairwise coancestry or relationship matrix among candidate individuals. Users should replace the example matrix with a coancestry matrix, numerator relationship matrix, or genomic relationship matrix calculated from their own population.

Example structure:

~~~text
param c : 1      2      3      4 :=
1         0.500  0.125  0.031  0.040
2         0.125  0.500  0.060  0.025
3         0.031  0.060  0.500  0.110
4         0.040  0.025  0.110  0.500
;
~~~

In this structure:

- The values after `param c :` indicate the column candidate indices.
- The first value in each row indicates the row candidate index.
- The remaining values in each row indicate the pairwise coancestry or relationship values.
- The row and column indices should match the candidate indices used in `b.dat`, `l.dat`, and `u.dat`.
- The number of rows and columns should match the number of candidate individuals specified by `nc` in `OptOrch.dat`.

### `l.dat`

Lower contribution bound input file.

This file contains the lower contribution bound for each candidate. Users should modify this file if candidate-specific lower contribution limits are required.

Example structure:

~~~text
param l :=
1 0.01
2 0.01
3 0.01
4 0.01
;
~~~

In this structure:

- The first column indicates the candidate index.
- The second column indicates the lower contribution bound.
- A common lower bound may be repeated for all candidates, or candidate-specific values may be used.

### `u.dat`

Upper contribution bound input file.

This file contains the upper contribution bound for each candidate. Users should modify this file if candidate-specific upper contribution limits are required.

Example structure:

~~~text
param u :=
1 0.15
2 0.15
3 0.15
4 0.15
;
~~~

In this structure:

- The first column indicates the candidate index.
- The second column indicates the upper contribution bound.
- A common upper bound may be repeated for all candidates, or candidate-specific values may be used.

### `OptOrch.dat`

Main scalar parameter file.

This file defines the main scalar settings used in the minimal AMPL example.

Example structure:

~~~text
data;

param ns := 30;
param cu := 0.5;
param nc := 100;
param nd := 20;
~~~

In this structure:

- `ns`
	- Target status number.
	- This parameter controls the genetic diversity constraint.

- `cu`
	- Upper limit for acceptable pairwise coancestry among selected candidates.
	- This parameter is used when the model includes a pairwise coancestry constraint.
	- If two candidates are selected, their pairwise coancestry should not exceed this threshold.

- `nc`
	- Number of candidate individuals.
	- This value should match the number of candidates listed in `b.dat`, `l.dat`, `u.dat`, and the dimensions of `c.dat`.

- `nd`
	- Number of external pollen donors or external contributors.
	- This parameter is used in model variants involving external pollen contamination or external donor contributions.

Users should modify these scalar parameters according to their own optimization setting. The candidate-level input files, such as `b.dat`, `l.dat`, `u.dat`, and `c.dat`, should be prepared consistently with the value of `nc`.

## 2. Modify the model formulation

Users who want to change the optimization formulation itself may modify the AMPL model file.

The core AMPL formulation is provided in:

~~~text
01_models/001_core/OptOrch_core.mod
~~~

The model file defines the main optimization formulation, including the decision variables, objective function, and constraints.

Users may modify the `.mod` file if they want to:

- add or remove constraints;
- extend the model to a different seed orchard optimization setting.

For extensions of the core formulation, users should refer to the tailored AMPL models provided in:

~~~text
01_models/002_tailored_models/
~~~


## 3. Run the model

The minimal AMPL example can be executed through several AMPL interfaces.

We recommend using the AMPL IDE because it allows users to inspect the model file, data files, and run script in a single working environment.

### OptOrch.run 

The minimal example is executed using `OptOrch.run`.

Example structure:

~~~text
reset;
model OptOrch_core.mod;
data OptOrch.dat;

data b.dat;
data l.dat;
data u.dat;
data c.dat;

option solver GUROBI;
option gurobi_options 'outlev=1 mipgap=0.05';

solve;
display gain;
display p;
~~~

### Requirements
To run this example, users need:
- AMPL
- A solver that supports MIQP or MIQCP
	- The authors used Gurobi.
- A valid AMPL license
- A valid solver license, if required by the selected solver

### Installing AMPL and setting up licenses

Please refer to the official AMPL documentation for installation and license activation:

- AMPL website: https://ampl.com
- AMPL installation guide: https://ampl.com/ampl-install-guide/
- AMPL installation documentation: https://dev.ampl.com/ampl/install.html
- AMPL license troubleshooting: https://dev.ampl.com/help/dynamic-license-troubleshooting.html

If Gurobi is used as the solver, users also need a working Gurobi installation and license:

- Gurobi website: https://www.gurobi.com
- Gurobi documentation: https://docs.gurobi.com/
- Gurobi license setup guide: https://support.gurobi.com/hc/en-us/articles/12872879801105-How-do-I-retrieve-and-set-up-a-Gurobi-license

The authors used Gurobi as the optimization solver in the manuscript analyses.

#### Option 1. Run from the AMPL IDE

1. Open the AMPL IDE.

2. Open the example folder:

~~~text
02_examples/001_minimal_AMPL_example/
~~~

3. Inspect the model, data, and run files if needed:

- `OptOrch_core.mod`
- `OptOrch.dat`
- `OptOrch.run`
- `b.dat`
- `l.dat`
- `u.dat`
- `c.dat`

4. Execute the run script:

~~~text
include OptOrch.run;
~~~

The optimization problem will be solved using the solver specified in `OptOrch.run`.

#### Option 2. Run from a terminal or command prompt

1. Open a terminal or command prompt.

2. Move to the example folder:

~~~text
cd 02_examples/001_minimal_AMPL_example
~~~

3. Start AMPL:

~~~text
ampl
~~~

4. Run the example:

~~~text
include OptOrch.run;
~~~

The optimization problem will be solved using the solver specified in `OptOrch.run`.

#### Option 3. Run through an AMPL API

AMPL can also be called from programming environments using AMPL APIs.

For API-based execution, please refer to the official AMPL API documentation:

- AMPL APIs: https://dev.ampl.com/ampl/reference/apis.html
- AMPL MATLAB API: https://ampl.com/api/latest/matlab/index.html
- AMPL R API: https://rAMPL.ampl.com/

## Summary

Users who want to run OptOrch with their own data should usually begin by preparing the input data files:

- `b.dat`
- `c.dat`
- `l.dat`
- `u.dat`
- `OptOrch.dat`

Users who want to change the mathematical formulation can modify `OptOrch_core.mod` or refer to the tailored models in:

~~~text
01_models/002_tailored_models/
~~~

Users can then run the model using `OptOrch.run` through the AMPL IDE, a terminal or command prompt, or an AMPL API.
