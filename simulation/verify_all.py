import os
import subprocess
import re
import shutil
from sat_node import SatNode

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

def run_python_model(num_vars, clauses):
    # Convert clauses to matrix format expected by SatNode
    max_len = max(len(c) for c in clauses) if clauses else 0
    import numpy as np
    matrix = np.zeros((len(clauses), max_len), dtype=int)
    for i, clause in enumerate(clauses):
        for j, lit in enumerate(clause):
            matrix[i, j] = (2 * lit) if lit > 0 else (2 * abs(lit) + 1)
            
    node = SatNode(matrix, num_vars)
    res, assign = node.solve()
    return res, assign, node.cycle_count

def run_rtl_model(test_path, num_vars, num_rows, lit_width=6, debug=False):
    # 1. Convert to Hex
    hex_path = "rtl/problem.hex"
    cmd_hex = f"python3 rtl/cnf_to_hex.py {test_path} {hex_path}"
    subprocess.run(cmd_hex, shell=True, check=True)
    
    # 2. Compile RTL
    sim_exe = "sat_sim"
    trace_flag = "-D TRACE_MODE" if debug else ""
    cmd_compile = (
        f"iverilog -g2012 {trace_flag} -D NUM_ROWS={num_rows} -D NUM_VARS={num_vars} "
        f"-D LIT_WIDTH={lit_width} -D INIT_FILE='\"rtl/problem.hex\"' -o {sim_exe} "
        "rtl/sat_pkg.sv rtl/comparator.sv rtl/clause_evaluator.sv rtl/unit_detector.sv "
        "rtl/heuristic_engine.sv rtl/propagation_queue.sv rtl/assignment_manager.sv "
        "rtl/static_memory.sv rtl/dynamic_memory.sv rtl/sat_node.sv rtl/tb_sat_node.sv"
    )
    subprocess.run(cmd_compile, shell=True, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    # 3. Run RTL
    cmd_run = f"vvp {sim_exe}"
    result = subprocess.run(cmd_run, shell=True, capture_output=True, text=True)
    
    # Parse Output
    output = result.stdout
    rtl_res = "UNKNOWN"
    rtl_cycles = 0
    rtl_assign = {}
    
    for line in output.splitlines():
        if line.startswith("RESULT:"):
            rtl_res = line.split()[1]
        if line.startswith("CYCLES:"):
            rtl_cycles = int(line.split()[1])
        if line.startswith("ASSIGNMENTS:"):
            bits = line.split()[1]
            for i, bit in enumerate(bits):
                var = i + 1
                rtl_assign[var] = (bit == '1')
                
    return rtl_res, rtl_assign, rtl_cycles, output

def verify_all():
    tests_dir = "tests"
    if not os.path.exists(tests_dir):
        print("Tests directory not found.")
        return

    test_files = sorted([f for f in os.listdir(tests_dir) if f.endswith(".cnf")])
    
    print(f"{'Test File':<25} | {'Py Res':<6} | {'RTL Res':<6} | {'Match':<5} | {'Py Cyc':<6} | {'RTL Cyc':<6}")
    print("-" * 80)
    
    for t in test_files:
        path = os.path.join(tests_dir, t)
        n_vars, clauses = parse_dimacs(path)
        n_rows = len(clauses)
        
        # Python Run
        py_res, py_assign, py_cyc = run_python_model(n_vars, clauses)
        
        # RTL Run
        import math
        req_width = math.ceil(math.log2(2 * n_vars + 2))
        lit_width = max(6, req_width)
        
        rtl_res, rtl_assign, rtl_cyc, rtl_out = run_rtl_model(path, n_vars, n_rows, lit_width, debug=True)
        
        # Compare
        match = (py_res == rtl_res)
        if match and py_res == "SAT":
            for v, val in py_assign.items():
                if v in rtl_assign and rtl_assign[v] != val:
                    match = False
                    break
        
        match_str = "PASS" if match else "FAIL"
        
        print(f"{t:<25} | {py_res:<6} | {rtl_res:<6} | {match_str:<5} | {py_cyc:<6} | {rtl_cyc:<6}")
        if not match:
            print(f"  > Python Assign: {py_assign}")
            print(f"  > RTL Assign:    {rtl_assign}")
            print("  > RTL Full Log:")
            for line in rtl_out.splitlines():
                if "TRACE" in line or "Conflict" in line or "DEBUG" in line:
                    print(f"    {line}")
            print("-" * 40)

    # Cleanup
    if os.path.exists("sat_sim"): os.remove("sat_sim")
    if os.path.exists("rtl/problem.hex"): os.remove("rtl/problem.hex")

if __name__ == "__main__":
    verify_all()
