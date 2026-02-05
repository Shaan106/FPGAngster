import os
import numpy as np
import pandas as pd
from sat_node import SatNode

# Try to import a standard solver, fallback to a simple DPLL if not available
try:
    from pysat.solvers import Glucose3
    USE_PYSAT = True
except ImportError:
    USE_PYSAT = False

def solve_ground_truth(num_vars, clauses):
    """Provides a reference result using pysat or a simple DPLL fallback."""
    if USE_PYSAT:
        with Glucose3() as solver:
            for clause in clauses:
                solver.add_clause(clause)
            return "SAT" if solver.solve() else "UNSAT"
    else:
        # Simple DPLL Fallback for small problems
        return dpll_fallback(clauses, {})

def dpll_fallback(clauses, assignment):
    """Extremely simple recursive DPLL for reference when pysat is missing."""
    # 1. Simplify clauses
    new_clauses = []
    for c in clauses:
        resolved = False
        new_c = []
        for lit in c:
            val = assignment.get(abs(lit))
            if val is not None:
                if (lit > 0 and val == True) or (lit < 0 and val == False):
                    resolved = True # Clause is satisfied
                    break
            else:
                new_c.append(lit)
        if not resolved:
            if not new_c: return "UNSAT" # Empty clause
            new_clauses.append(new_c)
    
    if not new_clauses: return "SAT" # All clauses satisfied
    
    # 2. Pick a variable
    var = abs(new_clauses[0][0])
    
    # 3. Branch
    for val in [True, False]:
        res = dpll_fallback(new_clauses, {**assignment, var: val})
        if res == "SAT": return "SAT"
    
    return "UNSAT"

def parse_dimacs(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    clauses = []
    num_vars = 0
    for line in content.splitlines():
        line = line.strip()
        if not line or line.startswith('c'): continue
        if line.startswith('p cnf'):
            parts = line.split()
            num_vars = int(parts[2])
            continue
        parts = [int(x) for x in line.split()]
        if parts and parts[-1] == 0: parts.pop()
        if parts: clauses.append(parts)
    return num_vars, clauses

def clauses_to_matrix(clauses, num_vars):
    if not clauses: return np.zeros((0, 0), dtype=int)
    max_len = max(len(c) for c in clauses)
    matrix = np.zeros((len(clauses), max_len), dtype=int)
    for i, clause in enumerate(clauses):
        for j, lit in enumerate(clause):
            matrix[i, j] = (2 * lit) if lit > 0 else (2 * abs(lit) + 1)
    return matrix

def verify_assignment(clauses, assignment):
    for clause in clauses:
        satisfied = False
        for lit in clause:
            var = abs(lit)
            val = assignment.get(var)
            if val is not None and ((lit > 0 and val == True) or (lit < 0 and val == False)):
                satisfied = True
                break
        if not satisfied: return False, clause
    return True, None

def run_tests():
    if not os.path.exists("tests"):
        print("No 'tests' directory found.")
        return
    test_files = sorted([f for f in os.listdir("tests") if f.endswith(".cnf")])
    if not test_files:
        print("No .cnf files found in 'tests/'.")
        return

    results = []
    print(f"Running {len(test_files)} tests (Reference: {'pysat' if USE_PYSAT else 'DPLL Fallback'})...\n")
    
    for filename in test_files:
        path = os.path.join("tests", filename)
        num_vars, clauses = parse_dimacs(path)
        
        # 1. Get Reference Truth
        ground_truth = solve_ground_truth(num_vars, clauses)
        
        # 2. Run our SatNode
        matrix = clauses_to_matrix(clauses, num_vars)
        node = SatNode(matrix, num_vars)
        node_result, assignment = node.solve()
        
        # 3. Validation
        status = "PASS"
        if node_result != ground_truth:
            status = f"FAIL (Mismatch)"
        elif node_result == "SAT":
            is_valid, _ = verify_assignment(clauses, assignment)
            if not is_valid: status = "FAIL (Invalid Logic)"
        
        results.append({
            "File": filename,
            "SatNode": node_result,
            "Reference": ground_truth,
            "Status": status,
            "Cycles": node.cycle_count
        })

    df = pd.DataFrame(results)
    print(df.to_string(index=False))

if __name__ == "__main__":
    run_tests()