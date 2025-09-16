# FPGAngster - Hardware SAT Solver

## Project Overview
FPGAngster is a hardware-level implementation of a tile-based SAT solver designed for FPGA deployment. This project implements a cycle-accurate, parameterized 3-SAT solver architecture in SystemVerilog.

## Architecture

### System Design
The solver uses a distributed tile-based architecture where multiple nodes work in parallel to solve 3-SAT problems. Each node processes and evaluates clauses independently, enabling scalable parallel computation.

### Current Implementation Status
- ✅ **Clause Memory Module**: Stores and manages 3-SAT clauses with read/write capabilities
- ✅ **Clause Evaluator Module**: Performs combinational evaluation of multiple clauses in parallel
- 🚧 **Input Interface**: Streaming clause assignments from neighboring nodes (planned)
- 🚧 **Node Integration**: Complete SAT solver node combining all components (planned)

## Module Documentation

### 1. Clause Memory (`clause_memory.sv`)

**Purpose**: Stores clauses for the SAT solver node with efficient read/write access.

**Features**:
- Parameterized storage capacity (default: 16 clauses)
- Single-cycle read/write operations with write-through capability
- 3 terms per clause (3-SAT)
- Each term contains:
  - 8-bit variable identifier
  - 2-bit value assignment (00=False, 01=True, 10=Unknown)
  - 1-bit negation flag

**Interface**:
```systemverilog
module clause_memory #(
    parameter NUM_CLAUSES = 16,
    parameter TERMS_PER_CLAUSE = 3,
    parameter VAR_ID_WIDTH = 8
)
```

### 2. Clause Evaluator (`clause_evaluator.sv`)

**Purpose**: Evaluates multiple 3-SAT clauses in parallel using purely combinational logic.

**Features**:
- Zero-latency combinational evaluation (no clock required)
- Parameterized number of clauses (1-16)
- Parallel evaluation architecture
- Three-state output: SAT, UNSAT, or UNKNOWN

**Evaluation Logic**:
- **Per-clause (OR)**: A clause is SAT if any term is TRUE
- **Overall (AND)**: Formula is SAT only if all clauses are SAT

**Interface**:
```systemverilog
module clause_evaluator #(
    parameter NUM_CLAUSES = 1,
    parameter TERMS_PER_CLAUSE = 3,
    parameter VALUE_WIDTH = 2
)
```

**Input Format**:
- Packed array: `[NUM_CLAUSES * 3 * 2 - 1:0]`
- Each clause: 6 bits (3 terms × 2 bits per term)

**Output Encoding**:
- `2'b00`: UNSAT (at least one clause evaluates to false)
- `2'b01`: SAT (all clauses satisfied)
- `2'b10`: UNKNOWN (contains unassigned variables)

**Combinational Logic Delay**:
Level 1: Term comparisons (parallel)
- Check if each term == TRUE, FALSE, or UNKNOWN

Level 2: Clause evaluation (OR reduction per clause)
- OR gates to determine if any term in clause is TRUE
- AND gates to check if all terms are FALSE

Level 3: Flag generation (OR reduction across all clauses)
- OR tree to check if any clause is UNSAT → has_unsat
- OR tree to check if any clause has UNKNOWN → has_unknown

Level 4: Final mux/selection
- 2:1 mux chain to select between UNSAT/UNKNOWN/SAT based on flags

So even with 16 clauses, you're looking at roughly:
- ~2 gates for clause evaluation
- ~log₂(16) = 4 gates for the reduction tree
- ~2 gates for final result selection

Total depth: ~8 gates maximum, which would typically synthesize to sub-nanosecond propagation delay on modern FPGAs.

## Value Encoding Convention

All modules use consistent 2-bit value encoding:
- `2'b00`: FALSE
- `2'b01`: TRUE
- `2'b10`: UNKNOWN (unassigned)
- `2'b11`: Reserved (unused)

## Testing

### Running Tests

To compile and run the clause evaluator testbench:
```bash
# Using iverilog
iverilog -g2012 -o clause_evaluator_tb clause_evaluator.sv clause_evaluator_tb.sv
vvp clause_evaluator_tb

# Using Verilator
verilator --binary -Wall clause_evaluator.sv clause_evaluator_tb.sv
./obj_dir/Vclause_evaluator_tb
```

To compile and run the clause memory testbench:
```bash
iverilog -g2012 -o clause_memory_tb clause_memory.sv clause_memory_tb.sv
vvp clause_memory_tb
```

### Test Coverage

The testbenches provide comprehensive coverage including:
- Single and multiple clause evaluation
- All result states (SAT, UNSAT, UNKNOWN)
- Edge cases and boundary conditions
- Timing verification for combinational behavior
- Parameterized configurations (1, 4, 16 clauses)

## Integration Guide

### Connecting Modules

Example integration of clause memory with evaluator:
```systemverilog
// Read clause data from memory
logic [32:0] clause_data;
clause_memory mem_inst (.read_data(clause_data), ...);

// Evaluate the clause
logic [5:0] eval_input = clause_data[32:22];  // Extract term values only
clause_evaluator eval_inst (.clause_values(eval_input), ...);
```

### Parameter Configuration

Adjust parameters based on problem size:
```systemverilog
// Small problem (4 clauses)
clause_evaluator #(.NUM_CLAUSES(4)) small_eval (...);

// Large problem (16 clauses)
clause_evaluator #(.NUM_CLAUSES(16)) large_eval (...);
```

## Future Development

### Planned Features
1. **Input Interface Module**: Stream variable assignments from neighboring nodes
2. **Node Controller**: Orchestrate clause memory updates and evaluation
3. **Multi-node Communication**: Inter-node message passing for distributed solving
4. **Conflict Analysis**: Detect and resolve assignment conflicts
5. **Backtracking Support**: Enable search tree exploration

### Optimization Opportunities
- Pipeline evaluation for higher throughput
- Implement caching for frequently evaluated clauses
- Add clause learning capabilities
- Optimize for specific FPGA architectures

## Development Guidelines

### Coding Standards
- **Modularity**: Each functional block as a separate module
- **Parameterization**: Use parameters for all configurable values
- **Documentation**: Comment all modules and non-obvious logic
- **Naming**: Use descriptive signal and module names

### Best Practices
- Prefer combinational logic where possible for lower latency
- Use generate blocks for scalable parallel structures
- Maintain consistent value encoding across all modules
- Include comprehensive testbenches for all modules

## License
[Specify your license here]

## Contact
[Add contact information]