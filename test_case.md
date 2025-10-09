

# Test a 16 clause 3-SAT problem

### Problem:

(x1 | ~x2 | x3) &
(~x1 | x4 | ~x5) &
(x2 | ~x3 | x5) &
(x1 | x2 | ~x4) &
(~x2 | x3 | ~x5) &
(x3 | x4 | x5) &
(~x1 | ~x3 | x4) &
(x1 | ~x2 | ~x5) &
(x2 | x3 | ~x4) &
(~x1 | x3 | x5) &
(x2 | ~x4 | x5) &
(~x1 | ~x2 | ~x3) &
(x1 | x4 | x5) &
(~x2 | ~x3 | x4) &
(x1 | x3 | ~x5) &
(~x3 | ~x4 | ~x5)

### Initial assignments:

x1 = 1 (False), 
x2 = 0 (True),
x3 = 0 (True),
x4 = 0 (True),

assign_var_val = 1 (False) -- we are assigning False to the next variable we look up

vars_assignment_number = 4 -- we have already assigned var 4

clauses_in is defined where the assignment of each var is written in
and if any var is unassigned (even if ~var), it is written as 0