python3 rtl/cnf_to_hex.py tests/test_unsat_simple.cnf rtl/problem.hex
iverilog -g2012 -D NUM_ROWS=2 -D NUM_VARS=1 -D LIT_WIDTH=6 -D INIT_FILE='"rtl/problem.hex"' -D TRACE_MODE -o sat_sim_debug rtl/sat_pkg.sv rtl/comparator.sv rtl/clause_evaluator.sv rtl/unit_detector.sv rtl/heuristic_engine.sv rtl/propagation_queue.sv rtl/assignment_manager.sv rtl/static_memory.sv rtl/dynamic_memory.sv rtl/sat_node.sv rtl/tb_sat_node.sv
vvp sat_sim_debug
