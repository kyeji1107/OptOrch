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
## Installing AMPL
1. Download AMPL from the official AMPL website:
	- https://ampl.com
2. Install AMPL following the instructions for your operating system.
3. Make sure that the AMPL executable is available from your terminal or command prompt.
4. Check that AMPL runs correctly by opening a terminal and typing:
~~~text
ampl
~~~
If AMPL starts successfully, the AMPL prompt will appear:
~~~text
ampl:
~~~
## License setup
AMPL requires a valid license for full functionality.
If you received a license UUID, activate it from within AMPL using:
~~~text
shell "amplkey activate --uuid <license-uuid>";
~~~
Replace `<license-uuid>` with your own AMPL license UUID.
Academic users may be eligible for an AMPL academic license through the AMPL license portal.
Solver licenses are managed separately. For example, if Gurobi is used as the solver, a working Gurobi installation and license are required.
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
5. Solve the optimization problem.
6. Display the optimized contribution values and selected candidates.
## Notes for users
- If AMPL cannot find the solver, check whether the solver is correctly installed and available to AMPL.
- If AMPL reports a license error, check whether the AMPL license has been activated.
- If the solver reports a license error, check the solver license separately.
- If file-loading errors occur, make sure that all files remain in the same folder as `OptOrch.run`.
- This example is intended as a small standalone demonstration. The manuscript reproduction analyses are provided separately in `03_manuscript_reproduction/`.
