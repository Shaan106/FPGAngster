import numpy as np
from typing import Tuple, List, Optional, Dict

class StaticMemory:
    """
    Component: Row Pointer & Static Memory
    
    Stores a static representation of the entire problem (Array of Literal IDs).
    N Clauses per row, M rows.
    Literal encoding: 2*var for positive, 2*var + 1 for negative. 0 is padding.
    """
    def __init__(self, literal_matrix: np.ndarray):
        self.memory = literal_matrix
        self.num_rows, self.num_cols = literal_matrix.shape
        self.row_pointer = 0

    def fetch_row(self, row_idx: int) -> np.ndarray:
        if 0 <= row_idx < self.num_rows:
            return self.memory[row_idx]
        return np.zeros(self.num_cols, dtype=int)

    def advance_pointer(self):
        self.row_pointer += 1
        
    def reset_pointer(self):
        self.row_pointer = 0

class ClauseEvaluator:
    """
    Component: Clause Evaluator
    
    Checks if a clause (row) is False (Conflict).
    A clause is False if ALL its active literals are 1 (False).
    """
    def evaluate(self, static_row: np.ndarray, dynamic_row: np.ndarray) -> bool:
        # Literal 0 is padding and is never False.
        # We only care about slots where static_row != 0.
        active_mask = (static_row != 0)
        if not np.any(active_mask):
            return False # Empty row is not a conflict
        
        # A conflict occurs if all active literals are 1.
        # (dynamic_row[mask] == 1) for all mask
        is_conflict = np.all(dynamic_row[active_mask] == 1)
        return is_conflict

class HeuristicEngine:
    """
    Component: Heuristic Engine
    
    Predicts which variable assignment to make next.
    """
    def __init__(self, num_vars: int):
        self.num_vars = num_vars
        self.forced_next = None

    def set_next_decision(self, var_id: int):
        self.forced_next = var_id

    def predict(self, assigned_vars: Dict[int, bool]) -> Optional[int]:
        if self.forced_next is not None:
            d = self.forced_next
            self.forced_next = None
            return d
        
        # Simple heuristic: pick the first unassigned variable
        for v in range(1, self.num_vars + 1):
            if v not in assigned_vars:
                return v
        return None

class Comparator:
    """
    Component: Comparator
    
    Generates a bitmask where problem_literal == target_literal.
    """
    def compare(self, static_row: np.ndarray, target_literal: int) -> np.ndarray:
        matches = (static_row == target_literal)
        return matches.astype(int)

class BitwiseUpdate:
    """
    Component: Bitwise OR Update
    
    Updates the dynamic state of literals.
    """
    def update(self, current_dynamic_row: np.ndarray, update_mask: np.ndarray) -> np.ndarray:
        return np.bitwise_or(current_dynamic_row, update_mask)

class UnitDetector:
    """
    Component: Unit Detector
    
    Detects if a clause is Unit (all but one literals are False).
    Returns the literal that MUST be True.
    """
    def detect(self, static_row: np.ndarray, dynamic_row: np.ndarray) -> Optional[int]:
        active_mask = (static_row != 0)
        # dynamic_row[j] == 1 means literal static_row[j] is False.
        # A clause is Unit if exactly one active literal is 0 (True/Symbolic).
        zero_indices = np.where((dynamic_row == 0) & active_mask)[0]
        if len(zero_indices) == 1:
            # One literal remains that could be True.
            return static_row[zero_indices[0]]
        return None

class SatNode:
    """
    Top-Level Module: Computation Node
    Fully functional SAT solver node with cycle-accurate simulation.
    """
    def __init__(self, literal_matrix: np.ndarray, num_vars: int):
        self.static_memory = StaticMemory(literal_matrix)
        self.num_rows, self.num_cols = literal_matrix.shape
        self.dynamic_memory = np.zeros_like(literal_matrix, dtype=int)
        
        self.num_vars = num_vars
        self.assignment_table = {} # var_id -> value (True/False)
        self.decision_stack = []    # list of (var_id, value, is_forced)
        
        self.state = 'IDLE' # IDLE, DECIDE, PROPAGATE, BACKTRACK, SAT, UNSAT
        self.propagation_queue = [] # List of literals that are now FALSE
        self.current_prop_literal = None
        
        self.clause_evaluator = ClauseEvaluator()
        self.heuristic_engine = HeuristicEngine(num_vars)
        self.comparator = Comparator()
        self.bitwise_updater = BitwiseUpdate()
        self.unit_detector = UnitDetector()
        
        self.cycle_count = 0
        self.max_cycles = 5000 # Increased for more complex problems

    def negate_literal(self, literal: int) -> int:
        if literal == 0: return 0
        return literal ^ 1

    def get_var_and_val(self, literal: int) -> Tuple[int, bool]:
        var = literal // 2
        val = (literal % 2 == 1) # if literal is 2*v+1, it means negation of v, so v is False?
        # Wait, let's be consistent:
        # Literal 2*v is x_v. If 2*v is False, then x_v is False.
        # Literal 2*v+1 is ~x_v. If 2*v+1 is False, then ~x_v is False -> x_v is True.
        if literal % 2 == 0:
            return var, False # x_v is False
        else:
            return var, True  # x_v is True

    def step(self):
        """
        Executes one cycle of the SAT node state machine.
        """
        self.cycle_count += 1
        
        if self.state == 'IDLE':
            self.state = 'DECIDE'
            return {"state": self.state}

        elif self.state == 'DECIDE':
            var = self.heuristic_engine.predict(self.assignment_table)
            if var is None:
                self.state = 'SAT'
            else:
                # Decision: Set variable to False (literal 2*var becomes False)
                val = False
                self.assignment_table[var] = val
                self.decision_stack.append((var, val, False))
                self.propagation_queue.append(2 * var)
                self.state = 'PROPAGATE'
                self.static_memory.reset_pointer()
            return {"state": self.state, "decision_var": var}

        elif self.state == 'PROPAGATE':
            if not self.current_prop_literal:
                if not self.propagation_queue:
                    self.state = 'DECIDE'
                    return {"state": self.state}
                self.current_prop_literal = self.propagation_queue.pop(0)
                self.static_memory.reset_pointer()

            # Process one row per cycle
            row_idx = self.static_memory.row_pointer
            static_row = self.static_memory.fetch_row(row_idx)
            dynamic_row = self.dynamic_memory[row_idx]
            
            # 1. Update dynamic memory with current propagation
            mask = self.comparator.compare(static_row, self.current_prop_literal)
            new_dynamic_row = self.bitwise_updater.update(dynamic_row, mask)
            self.dynamic_memory[row_idx] = new_dynamic_row
            
            # 2. Check for conflict
            if self.clause_evaluator.evaluate(static_row, new_dynamic_row):
                self.state = 'BACKTRACK'
                self.current_prop_literal = None
                return {"state": self.state, "conflict_row": row_idx}
            
            # 3. BCP: Unit Clause Detection
            forced_true_literal = self.unit_detector.detect(static_row, new_dynamic_row)
            if forced_true_literal:
                forced_var, forced_val = self.get_var_and_val(self.negate_literal(forced_true_literal))
                # Wait, if forced_true_literal must be True, then its negation must be False.
                # get_var_and_val(literal) returns the (var, value) assignment that makes 'literal' False.
                # So if literal L is False, get_var_and_val(L) is what we want.
                # The literal that is now False is negate_literal(forced_true_literal).
                false_literal = self.negate_literal(forced_true_literal)
                var, val = self.get_var_and_val(false_literal)
                
                if var in self.assignment_table:
                    if self.assignment_table[var] != val:
                        # Conflict! Forced assignment contradicts existing one.
                        self.state = 'BACKTRACK'
                        self.current_prop_literal = None
                        return {"state": self.state, "bcp_conflict_var": var}
                else:
                    self.assignment_table[var] = val
                    self.decision_stack.append((var, val, True)) # forced
                    self.propagation_queue.append(false_literal)
            
            # Advance pointer
            self.static_memory.advance_pointer()
            if self.static_memory.row_pointer >= self.num_rows:
                # Finished propagating this literal
                self.current_prop_literal = None
            
            return {"state": 'PROPAGATE', "row": row_idx, "lit": self.current_prop_literal}

        elif self.state == 'BACKTRACK':
            if not self.decision_stack:
                self.state = 'UNSAT'
                return {"state": self.state}
            
            var, val, is_forced = self.decision_stack.pop()
            del self.assignment_table[var]
            
            if not is_forced:
                # Try the other value (True)
                # If variable x is True, literal 2*x + 1 is False.
                new_val = True
                self.assignment_table[var] = new_val
                self.decision_stack.append((var, new_val, True)) # Now it's forced
                
                # Re-propagate EVERYTHING from the stack
                # In this simple simulation, we clear dynamic memory and re-propagate
                self.dynamic_memory.fill(0)
                self.propagation_queue = []
                for v, v_val, _ in self.decision_stack:
                    lit_is_false = (2 * v) if v_val == False else (2 * v + 1)
                    self.propagation_queue.append(lit_is_false)
                
                self.state = 'PROPAGATE'
                self.current_prop_literal = None
                self.static_memory.reset_pointer()
            else:
                # Already tried both values for this decision, keep backtracking
                # Re-run backtrack in next cycle or recursively?
                # For cycle-accuracy, let's just stay in BACKTRACK and pop again next cycle
                pass 
            
            return {"state": self.state}

        return {"state": self.state}

    def solve(self):
        """Helper to run the simulation until it finishes."""
        while self.state not in ['SAT', 'UNSAT'] and self.cycle_count < self.max_cycles:
            self.step()
        return self.state, self.assignment_table

if __name__ == "__main__":
    # Test with a simple SAT problem
    # (x1 or x2) and (not x1 or x3) and (not x2 or not x3)
    # Literals:
    # x1: 2, not x1: 3
    # x2: 4, not x2: 5
    # x3: 6, not x3: 7
    # Padding: 0
    
    # Clauses:
    # [2, 4, 0]
    # [3, 6, 0]
    # [5, 7, 0]
    
    problem = np.array([
        [2, 4, 0],
        [3, 6, 0],
        [5, 7, 0]
    ])
    
    node = SatNode(problem, num_vars=3)
    result, assignments = node.solve()
    print(f"Result: {result}")
    print(f"Assignments: {assignments}")
    print(f"Cycles: {node.cycle_count}")