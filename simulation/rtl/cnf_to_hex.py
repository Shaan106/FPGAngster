import sys
import os

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

def write_hex(clauses, num_vars, filename, cols=4, lit_width=6):
    with open(filename, 'w') as f:
        for clause in clauses:
            row_val = 0
            for i in range(cols):
                lit_val = 0
                if i < len(clause):
                    raw_lit = clause[i]
                    if raw_lit > 0:
                        lit_val = 2 * raw_lit
                    else:
                        lit_val = 2 * abs(raw_lit) + 1
                row_val |= (lit_val << (i * lit_width))
            
            # Format as hex (24 bits = 6 hex digits)
            f.write(f"{row_val:06X}\n")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 cnf_to_hex.py <input.cnf> <output.hex>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    n_vars, cls = parse_dimacs(input_file)
    write_hex(cls, n_vars, output_file)
    print(f"Converted {input_file} ({n_vars} vars, {len(cls)} clauses) to {output_file}")
