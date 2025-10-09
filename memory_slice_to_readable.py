import textwrap

def format_hex_array(hex_string: str) -> str:
    """
    Takes a raw hexadecimal string, processes it as pairs of 1-byte (u8) values,
    and formats the output as a structured array initialization string.

    Args:
        hex_string: The input hexadecimal string.

    Returns:
        A string formatted as '{ [u8, u1], [u8, u1], ... }'.
    """
    # 1. Clean and validate the input string
    # Remove any whitespace and convert to uppercase for consistency
    cleaned_hex = hex_string.strip().upper()

    # The format [u8, u1] implies a 2-byte (4-hex-character) structure.
    # We must ensure the input length is even and divisible by 4.
    if len(cleaned_hex) % 2 != 0:
        # A proper hex string representing bytes must have an even length.
        print(f"Warning: Input hex string has an odd length ({len(cleaned_hex)}). Truncating the last character.")
        cleaned_hex = cleaned_hex[:-1]

    # Handle incomplete last element if the length is not divisible by 4
    remainder = len(cleaned_hex) % 4
    if remainder != 0:
        print(f"Warning: Input length ({len(cleaned_hex)}) is not divisible by 4. The last {remainder} hex characters will be ignored.")
        cleaned_hex = cleaned_hex[:-remainder]

    # 2. Process the string in 4-character chunks (1-byte u8 and 1-byte u1)
    formatted_pairs = []
    
    # Iterate through the string, stepping by 4 characters
    for i in range(0, len(cleaned_hex), 4):
        # Slice the 4-character chunk
        chunk = cleaned_hex[i:i+4]
        
        # Split the chunk into two 2-character bytes
        byte_1_hex = chunk[0:2]
        byte_2_hex = chunk[2:4]

        try:
            # Convert hex bytes to unsigned integers (u8, u1)
            u8_val = int(byte_1_hex, 16)
            u1_val = int(byte_2_hex, 16)

            # Format the pair as requested: [u8, u1]
            pair_string = f"[{u8_val}, {u1_val}]"
            formatted_pairs.append(pair_string)
        except ValueError as e:
            # Should not happen if the input is validated, but good practice
            print(f"Error processing chunk '{chunk}': {e}")
            continue

    # 3. Join the pairs and wrap in curly braces
    # Using textwrap.wrap for pretty printing by wrapping lines (optional, but cleaner)
    wrapped_pairs = textwrap.wrap(", ".join(formatted_pairs), width=80)
    
    # Indent all lines after the first one
    if len(wrapped_pairs) > 1:
        result_content = ",\n    " + ",\n    ".join(wrapped_pairs[1:])
        result_content = wrapped_pairs[0] + result_content
    else:
        result_content = wrapped_pairs[0] if wrapped_pairs else ""

    return "{\n    " + result_content + "\n}"


# --- Main Execution ---

# Your input hex number
INPUT_HEX = "000080800010100002020000404000080800010100002020000404000080800010100002020000404000080800010100002020000404"

# Call the function and print the result
output = format_hex_array(INPUT_HEX)

print("--- Formatted Output ---")
print(output)
print("------------------------")

# Example of how the data is processed:
# "0000" -> Byte 1: "00" (0), Byte 2: "00" (0) -> [0, 0]
# "8080" -> Byte 1: "80" (128), Byte 2: "80" (128) -> [128, 128]
# ... and so on.
