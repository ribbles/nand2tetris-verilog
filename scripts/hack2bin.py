#!/usr/bin/env python3
"""
Converts a Nand2Tetris Hack ASCII program (.hack) into a binary file (.bin)
formatted for the Gowin FLASH608K User Flash controller.

Flash word structure (32-bit):
- word[31:16] = Even Hack instruction (PC = 2*i)
- word[15:0]  = Odd Hack instruction  (PC = 2*i + 1)
"""

import sys
import struct

def hack_to_bin(hack_file, bin_file):
    instructions = []
    with open(hack_file, 'r', encoding='utf-8') as f:
        for line in f:
            clean = line.strip()
            if clean and not clean.startswith('//'):
                instructions.append(int(clean, 2))

    # Pad to even number of instructions (each flash word holds 2 instructions)
    if len(instructions) % 2 != 0:
        instructions.append(0)

    with open(bin_file, 'wb') as f:
        for i in range(0, len(instructions), 2):
            inst_even = instructions[i]
            inst_odd = instructions[i + 1]
            # Even instruction goes to upper 16 bits [31:16], odd to lower [15:0]
            word32 = ((inst_even & 0xFFFF) << 16) | (inst_odd & 0xFFFF)
            f.write(struct.pack('<I', word32))

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <input.hack> <output.bin>")
        sys.exit(1)
    hack_to_bin(sys.argv[1], sys.argv[2])
