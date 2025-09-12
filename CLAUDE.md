
### Project overview and goals
I am writing code for a new research project. The project is a new hardware-level implementation of a SAT solver. I have already made a cycle accurate simulator using rust to prove that the accelerator will be faster than previous implementations. This project is to write an initial RTL implementation of the design in SystemVerilog, that will later go onto an FPGA.

The MVP (which I want you to make) is as follows:

The architecture is a tile-based SAT solver, with many nodes for solving a 3-SAT problem. For now I want you to create one node. Each node has a key details:

1. A clause memory, which stores clauses. Each term is either True, False or Unknown (2 bits). Each clause has 3 terms. For example (A v ~B v C) with assignments A=True, B=False, C=Unknown would be stored as [(0,1,0), (1,0,1), (2,2,0)] which is in the form [(u8 variable identifier, u2 value assignment, u1 negation), ...]. For now, make the clause memory able to store 16 clauses.

2. Make a paramaterized input interface for receiving clause assignments from neighboring nodes. The node receives a stream of in-order variable assignments, with only variable assignments (the order in which data is received implies the variable which is being assigned). One clause's assignments should be received per clock cycle. For example if the problem was (A v ~B v C) ^ (~A v B v D), and assignments were A=True, B=False, C=True, D=False, the input stream would be cycle 1: [True, False, True], cycle 2: [True, False, False].

3. When the data is received, the node should update the clauses in its clause memory with the new data.

4. Each cycle, there should also be a parameterized clause evaluator (for now make it one clause per cycle). All this does is check if the clause is satisfied (at least one term is True), or unsatisfied (all terms are False), or still unknown (at least one term is Unknown and no terms are True). The evaluator should have a memory to store the results of the last 16 (make this parameterized) evaluations (satisfied, unsatisfied, unknown).

When you are done, please provide a testbench to show that the design works as expected for one 16-clause node.

Also, write a clear markdown file that desicribes this project and design (this will be edited by me later to add more to the project).

### Development guidelines and conventions

Modularize the code well. Every component that seems like its own block should be its own module. 

Also, make sure to parametrize the modules well, so that they can be reused in different contexts and design decisions to change parameters is easy.

Comment every module with a description of what it does, and comment any non-obvious lines of code.

### Architecture decisions

Write the code in SystemVerilog.

### Any specific instructions for how you want me to work on this project
Be truthful about what the user suggests in their implementation. If things are confusing/unclear or you see issues in the plan, please prompt the user to answer these questions and think about these things. 

Look up documentation link and index it before implementing any code / tackling a bug if it's relevant.

Only generate the code that is required to do exactly what I ask accurately and efficiently, and nothing more. 

Code concisely and make it readable and easily maintainable by a human.

If you are unsure about something, ask the user for clarification before proceeding.