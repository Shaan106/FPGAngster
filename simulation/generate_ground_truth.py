import numpy as np
import pandas as pd
from sat_node import SatNode

def generate_ground_truth():
    print("Generating Cycle-Accurate Ground Truth for SAT Node RTL Verification")
    print("===================================================================")
    
    # Simple problem: (x1 or x2) and (not x1 or x3) and (not x2 or not x3)
    # Literals: x1:2, ~x1:3, x2:4, ~x2:5, x3:6, ~x3:7
    problem_matrix = np.array([
        [2, 4, 0, 0],
        [3, 6, 0, 0],
        [5, 7, 0, 0]
    ])
    
    num_vars = 3
    node = SatNode(problem_matrix, num_vars)
    
    history = []
    
    print(f"Solving simple SAT problem with {num_vars} variables.\n")
    
    while node.state not in ['SAT', 'UNSAT'] and node.cycle_count < 100:
        prev_state = node.state
        prev_assignments = node.assignment_table.copy()
        
        step_data = node.step()
        
        curr_state = node.state
        curr_assignments = node.assignment_table.copy()
        
        # Format assignments for display
        assign_str = ", ".join([f"x{v}:{'T' if val else 'F'}" for v, val in curr_assignments.items()])
        
        history.append({
            "Cycle": node.cycle_count,
            "State": prev_state,
            "Assignments": assign_str,
            "Next State": curr_state,
            "Info": str(step_data)
        })

    # Output Formatted Table
    df = pd.DataFrame(history)
    pd.set_option('display.max_columns', None)
    pd.set_option('display.width', 1000)
    pd.set_option('display.max_colwidth', 50)

    print(df.to_string(index=False))
    
    print(f"\nFinal Result: {node.state}")
    print(f"Final Assignments: {node.assignment_table}")

if __name__ == "__main__":
    generate_ground_truth()
