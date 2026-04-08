# OptOrch: Advanced algorithmic deployment for seed orchards

This repository contains the materials provided as Supplementary File S1 for the optimization framework described in the manuscript, “OptOrch: Advanced algorithmic deployment for seed orchards”.

It provides the core AMPL optimization model, tailored model variants, a runnable AMPL example, and R scripts for simulation-based execution and output processing.

## Repository Structure

### 01_Core model

- `OptOrch.mod`: core AMPL model used in the main analyses.

### 02_Tailored models

Additional AMPL model files illustrating formulation variants and biological extensions discussed in the manuscript.

- `OptOrch_supp1.mod`: logical-operator formulation for selection-dependent bounds.
- `OptOrch_supp2.mod`: logical formulation for constraining pairwise coancestry.
- `OptOrch_supp3.mod`: linearized formulation for constraining pairwise coancestry.
- `OptOrch_supp4.mod`: formulation with separate female and male contributions.
- `OptOrch_supp5.mod`: explicit female-male formulation for pollen contamination.
- `OptOrch_supp6.mod`: aggregate formulation for pollen contamination.

### 03_Runnable example

A basic AMPL example is included to demonstrate the workflow with separated input files and an execution script.

- `b.dat`: input file containing breeding values.
- `l.dat`: input file containing lower contribution bounds.
- `u.dat`: input file containing upper contribution bounds.
- `c.dat`: input file containing the coancestry matrix.
- `OptOrch.dat`: integrated data file specifying the main scalar parameters for the example.
- `OptOrch.run`: AMPL run script for executing the runnable example.

### 04_R execution files

R scripts supporting simulation-based case studies and downstream result handling.

- `mobps.R`: data generation script using MoBPS.
- `OptOrch.R`: optimization execution and output processing script.

## Execution Options

### AMPL-based execution

The optimization can be run directly in AMPL using the supplied model, data, and run files. The runnable example in `03_Runnable example` provides a minimal execution setup using:

- `OptOrch.mod`
- `OptOrch.dat`
- `OptOrch.run`
- `b.dat`, `l.dat`, `u.dat`, and `c.dat`

The tailored model files in `02_Tailored models` can be used as alternative formulations for specific scenarios.

### R-based execution

The workflow can also be run through R. In this route, R is used to generate simulated populations, estimate breeding values, construct relationship matrices, execute the optimization, and process outputs.

- `mobps.R` provides the simulation and data generation workflow.
- `OptOrch.R` provides optimization execution and result processing.

## Software Notes

- AMPL-based execution requires AMPL and an optimization solver. 
- R-based execution requires the packages used in the scripts.
- The authors used a solver Gurobi for optimization.

## Contact
For any inquiries, please contact:

- Corresponding author: Prof. Milan Lstibůrek  
	E-mail: lstiburek@fld.czu.cz

- First author: Dr. Ye-Ji Kim  
	E-mail: kyeji1107@gmail.com
