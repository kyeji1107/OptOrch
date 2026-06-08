# Minimal AMPL example description
This folder provides a minimal AMPL example for running the core OptOrch optimization model.
The purpose of this example is to help users understand the basic AMPL-based workflow using a small set of separated input files.
## Files
- `OptOrch_core.mod`
	- Core AMPL model file.
	- This file defines the optimization variables, objective function, and constraints.
- `OptOrch.dat`
	- Main AMPL data file.
	- This file specifies scalar parameters and loads the separated input files.
- `OptOrch.run`
	- AMPL run script.
	- This file loads the model and data, sets the solver, solves the optimization problem, and displays selected outputs.
- `b.dat`
	- Input file containing breeding values.
- `l.dat`
	- Input file containing lower contribution bounds.
- `u.dat`
	- Input file containing upper contribution bounds.
- `c.dat`
	- Input file containing the coancestry matrix.
## Requirements
To run this example, users need:
- AMPL
- A solver that supports MIQP or MIQCP
	- The authors used Gurobi.
- A valid AMPL license
- A valid solver license, if required by the selected solver
## Installing AMPL and setting up licenses

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
## Running the example
1. Open a terminal or command prompt.
2. Move to this folder:
~~~text
cd 02_minimal_AMPL_example
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
## Expected workflow
The AMPL workflow in this folder follows these steps:
1. Load the core model from `OptOrch_core.mod`.
2. Load scalar parameters and input data from `OptOrch.dat`.
3. Read separated input files:
	- `b.dat`
	- `l.dat`
	- `u.dat`
	- `c.dat`
4. Set the solver.
5. Solve the optimization problem from `OptOrch.run`.
6. Display the optimized contribution values and selected candidates.
## Notes for users
- If AMPL cannot find the solver, check whether the solver is correctly installed and available to AMPL.
- If AMPL reports a license error, check whether the AMPL license has been activated.
- If the solver reports a license error, check the solver license separately.
- If file-loading errors occur, make sure that all files remain in the same folder as `OptOrch.run`.
  
