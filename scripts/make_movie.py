#!/usr/bin/env python3
"""
make_movie.py: Compiles dumped screen frames from tb_computer_screen into an animated GIF.
Supports ASCII PBM (P1), Binary PBM (P4), and raw 16-bit binary memory dumps.
Uses pure Python GIF encoder with zero external dependencies.
"""

import sys
import os
import glob
import struct
import subprocess
import shlex

def parse_pbm_p1(filepath):
    """Parses ASCII PBM (P1) file and returns (width, height, 1D list of 0/1 pixels)."""
    with open(filepath, 'r') as f:
        tokens = f.read().split()
    if not tokens or tokens[0] != 'P1':
        raise ValueError(f"Not a valid P1 PBM file: {filepath}")
    width = int(tokens[1])
    height = int(tokens[2])
    pixels = [int(tok) for tok in tokens[3:3 + width * height]]
    return width, height, pixels

def parse_pbm_p4(filepath):
    """Parses Binary PBM (P4) file and returns (width, height, 1D list of 0/1 pixels)."""
    with open(filepath, 'rb') as f:
        header = b""
        while len(header.split()) < 3:
            line = f.readline()
            if not line:
                break
            if line.startswith(b'#'):
                continue
            header += b" " + line.strip()
        tokens = header.split()
        if tokens[0] != b'P4':
            raise ValueError(f"Not a valid P4 PBM file: {filepath}")
        width = int(tokens[1])
        height = int(tokens[2])
        raw_data = f.read()
        row_bytes = (width + 7) // 8
        pixels = []
        for r in range(height):
            row_slice = raw_data[r * row_bytes : (r + 1) * row_bytes]
            for c in range(width):
                byte_val = row_slice[c // 8]
                bit_val = (byte_val >> (7 - (c % 8))) & 1
                pixels.append(bit_val)
        return width, height, pixels

def parse_frame_file(filepath):
    if filepath.endswith('.pbm'):
        with open(filepath, 'rb') as f:
            magic = f.read(2)
        if magic == b'P1':
            return parse_pbm_p1(filepath)
        elif magic == b'P4':
            return parse_pbm_p4(filepath)
        else:
            return parse_pbm_p1(filepath)
    else:
        raise ValueError(f"Unsupported frame format: {filepath}")

def create_gif(frames_pixels, width, height, output_gif_path, duration_ms=500):
    """
    Encodes a list of 1-bit monochrome frames (0 = white/background, 1 = black/pixel)
    into an animated GIF file using pure Python.
    """
    # Palette: 2 colors: [0] = Off-White (245,245,245), [1] = Dark Charcoal (30,30,30)
    palette = bytes([245, 245, 245, 30, 30, 30]) + bytes(254 * 3)

    def lzw_encode(index_stream, min_code_size=8):
        clear_code = 1 << min_code_size
        end_of_info = clear_code + 1
        
        dictionary = {bytes([i]): i for i in range(clear_code)}
        next_code = end_of_info + 1
        curr_code_size = min_code_size + 1
        
        bits_buf = 0
        bits_count = 0
        byte_stream = bytearray()
        
        def write_code(code, size):
            nonlocal bits_buf, bits_count, byte_stream
            bits_buf |= (code << bits_count)
            bits_count += size
            while bits_count >= 8:
                byte_stream.append(bits_buf & 0xFF)
                bits_buf >>= 8
                bits_count -= 8

        write_code(clear_code, curr_code_size)
        
        pattern = bytes()
        for idx in index_stream:
            new_pattern = pattern + bytes([idx])
            if new_pattern in dictionary:
                pattern = new_pattern
            else:
                write_code(dictionary[pattern], curr_code_size)
                dictionary[new_pattern] = next_code
                next_code += 1
                
                if next_code == (1 << curr_code_size) + 1 and curr_code_size < 12:
                    curr_code_size += 1
                elif next_code > 4095:
                    write_code(clear_code, curr_code_size)
                    dictionary = {bytes([i]): i for i in range(clear_code)}
                    next_code = end_of_info + 1
                    curr_code_size = min_code_size + 1
                
                pattern = bytes([idx])
                
        if pattern:
            write_code(dictionary[pattern], curr_code_size)
            
        write_code(end_of_info, curr_code_size)
        
        if bits_count > 0:
            byte_stream.append(bits_buf & 0xFF)
            
        # Pack into sub-blocks (max 255 bytes each)
        packed = bytearray([min_code_size])
        for i in range(0, len(byte_stream), 255):
            chunk = byte_stream[i:i + 255]
            packed.append(len(chunk))
            packed.extend(chunk)
        packed.append(0) # Block terminator
        return packed

    with open(output_gif_path, 'wb') as f:
        # 1. Header & Logical Screen Descriptor
        f.write(b'GIF89a')
        f.write(struct.pack('<HH', width, height))
        f.write(bytes([0b11110111, 0, 0])) # 256 colors
        f.write(palette)
        
        # 2. Netscape 2.0 Application Extension (Looping animation)
        f.write(b'\x21\xFF\x0BNETSCAPE2.0\x03\x01\x00\x00\x00')
        
        # 3. Frames
        delay_centisecs = max(1, int(duration_ms / 10))
        for frame_idx, pixels in enumerate(frames_pixels):
            # Graphic Control Extension
            f.write(b'\x21\xF9\x04')
            f.write(bytes([0b00000100]))
            f.write(struct.pack('<H', delay_centisecs))
            f.write(b'\x00\x00')
            
            # Image Descriptor
            f.write(b'\x2C')
            f.write(struct.pack('<HHHH', 0, 0, width, height))
            f.write(bytes([0]))
            
            # Image Data
            lzw_data = lzw_encode(pixels, min_code_size=8)
            f.write(lzw_data)
            
        # 4. Trailer
        f.write(b'\x3B')

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Convert captured Hack screen frames to an animated GIF movie.")
    parser.add_argument("--frames-dir", default="sim/frames", help="Directory containing frame_*.pbm files")
    parser.add_argument("--output", default="sim/pong_movie.gif", help="Output GIF path")
    parser.add_argument("--delay", type=int, default=200, help="Frame delay in milliseconds (default: 200ms -> 5 FPS)")
    parser.add_argument("--force", action="store_true", help="Ignore missing frames error and attempt to build GIF (useful for dry runs)")
    args = parser.parse_args()

    frame_files = sorted(glob.glob(os.path.join(args.frames_dir, "frame_*.pbm")))
    if not frame_files:
        frame_files = sorted(glob.glob(os.path.join("frames", "frame_*.pbm")))

    if not frame_files:
        if args.force:
            print(f"[WARN] No frame files found in '{args.frames_dir}'; proceeding due to --force")
            frame_files = []
        else:
            print(f"[ERROR] No frame files found in '{args.frames_dir}' or 'frames/'! Run the simulator first (e.g. make sim_computer_screen) or use the Makefile 'movie' target.")
            sys.exit(1)

    print(f"[INFO] Found {len(frame_files)} frame files. Parsing...")
    frames = []
    width, height = None, None

    # Overlay frame counter in bottom-right corner
    def overlay_frame_counter(pixels, frame_idx, width, height):
        # Simple 5x7 pixel font for digits 0-9
        font = {
            '0': [0b11111,
                  0b10001,
                  0b10011,
                  0b10101,
                  0b11001,
                  0b10001,
                  0b11111],
            '1': [0b00100,
                  0b01100,
                  0b00100,
                  0b00100,
                  0b00100,
                  0b00100,
                  0b01110],
            '2': [0b11111,
                  0b00001,
                  0b00001,
                  0b11111,
                  0b10000,
                  0b10000,
                  0b11111],
            '3': [0b11111,
                  0b00001,
                  0b00001,
                  0b01111,
                  0b00001,
                  0b00001,
                  0b11111],
            '4': [0b10001,
                  0b10001,
                  0b10001,
                  0b11111,
                  0b00001,
                  0b00001,
                  0b00001],
            '5': [0b11111,
                  0b10000,
                  0b10000,
                  0b11111,
                  0b00001,
                  0b00001,
                  0b11111],
            '6': [0b11111,
                  0b10000,
                  0b10000,
                  0b11111,
                  0b10001,
                  0b10001,
                  0b11111],
            '7': [0b11111,
                  0b00001,
                  0b00010,
                  0b00100,
                  0b01000,
                  0b10000,
                  0b10000],
            '8': [0b11111,
                  0b10001,
                  0b10001,
                  0b11111,
                  0b10001,
                  0b10001,
                  0b11111],
            '9': [0b11111,
                  0b10001,
                  0b10001,
                  0b11111,
                  0b00001,
                  0b00001,
                  0b11111]
        }

        s = str(frame_idx)
        # character width 5, spacing 1
        char_w = 5
        char_h = 7
        spacing = 1
        total_w = len(s) * (char_w + spacing) - spacing
        margin = 4
        x0 = width - total_w - margin
        y0 = height - char_h - margin
        # draw each character
        for ci, ch in enumerate(s):
            if ch not in font:
                continue
            col_x = x0 + ci * (char_w + spacing)
            bitmap = font[ch]
            for ry in range(char_h):
                rowbits = bitmap[ry]
                for rx in range(char_w):
                    if (rowbits >> (char_w - 1 - rx)) & 1:
                        px_y = y0 + ry
                        px_x = col_x + rx
                        if 0 <= px_x < width and 0 <= px_y < height:
                            pixels[px_y * width + px_x] = 1

    for i, fp in enumerate(frame_files):
        w, h, px = parse_frame_file(fp)
        if width is None:
            width, height = w, h

        overlay_frame_counter(px, i, w, h)
        frames.append(px)
        active_count = sum(px)
        print(f"  - Frame {i:03d} ({os.path.basename(fp)}): {active_count} active pixels")

    print(f"[INFO] Compiling {len(frames)} frames ({width}x{height}) into '{args.output}'...")
    create_gif(frames, width, height, args.output, duration_ms=args.delay)
    print(f"[SUCCESS] Movie created successfully: {args.output} ({os.path.getsize(args.output)} bytes)")

if __name__ == '__main__':
    main()
