# FPGAngster: Hardware-Accelerated SAT Solver

This project implements a cycle-accurate, hardware-optimized SAT solver. The architecture is designed to be tiled on an FPGA, where each node can solve a SAT problem independently or farm out branches to neighbors.

## Architecture Overview

The solver uses a modified DPLL algorithm optimized for streaming hardware:
- **Static Memory**: Stores CNF clauses as a literal matrix.
- **Dynamic Memory**: A bit-matrix tracking the "falseness" of literals in each clause.
- **BCP Engine**: A unit clause detector that triggers forced assignments.
- **Propagation Pipeline**: A 2-cycle-per-row pipeline that performs bitwise OR updates to propagate truth values.
- **Backtrack Controller**: A stack-based state machine that reconstructs the solver state after a conflict.

---

## 1. Python Simulation
The Python simulation is the source of truth for the cycle-accurate behavior.

### Run Sanity Tests
To run the included test suite (which includes SAT and UNSAT cases):
```bash
cd simulation
python3 test_runner.py
```

### Generate Ground Truth
To see a cycle-by-cycle trace of the solver's internal states for RTL verification:
```bash
python3 generate_ground_truth.py
```

---

## 2. RTL Implementation (SystemVerilog)
The RTL implementation is a 1:1 hardware mapping of the Python logic, modularized for FPGA synthesis.

### Prerequisites
- **Icarus Verilog** (`iverilog`)
- **Python 3** (for test data generation)

### Step 1: Convert CNF to Hardware Hex
Hardware requires a `.hex` file where literals are encoded as `2*var` (positive) and `2*var + 1` (negative).
```bash
python3 rtl/cnf_to_hex.py tests/test_sat_3var.cnf rtl/problem.hex
```

### Step 2: Compile and Run
Use the following command to compile the entire node and run the testbench:
```bash
iverilog -g2012 -o sat_sim 
    rtl/sat_pkg.sv 
    rtl/comparator.sv 
    rtl/clause_evaluator.sv 
    rtl/unit_detector.sv 
    rtl/heuristic_engine.sv 
    rtl/propagation_queue.sv 
    rtl/assignment_manager.sv 
    rtl/static_memory.sv 
    rtl/dynamic_memory.sv 
    rtl/sat_node.sv 
    rtl/tb_sat_node.sv

vvp sat_sim
```

### Step 3: Configuring for Larger Problems
The testbench (`rtl/tb_sat_node.sv`) has local parameters that must match your input:
- `NUM_VARS`: Total variables in the CNF.
- `NUM_ROWS`: Number of clauses in the CNF.
- `COLS_PER_ROW`: Max literals per clause (default 4).

---

## Data Encoding
- **Literal 0**: Padding / Null.
- **Literal 2**: $x_1$
- **Literal 3**: $
eg x_1$
- **Literal 4**: $x_2$
- **Literal 5**: $
eg x_2$
