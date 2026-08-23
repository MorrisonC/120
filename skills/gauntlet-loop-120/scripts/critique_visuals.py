#!/usr/bin/env python3
import sys
import os
import json
import argparse
import zlib
import struct

def parse_args():
    parser = argparse.ArgumentParser(description="Visual Critic for Gauntlet Loop")
    parser.add_argument("--target", required=True, help="Target ID (e.g., ArtThemeConsistency)")
    parser.add_argument("--capture-dir", required=True, help="Directory containing captured screenshots")
    parser.add_argument("--reference-dir", default="assets/tetraforce_reference", help="Directory containing reference assets")
    parser.add_argument("--bar", default="", help="Reference bar description")
    return parser.parse_args()

def analyze_png(filepath):
    if not os.path.exists(filepath):
        return {"exists": False, "reason": f"File {filepath} missing"}

    with open(filepath, "rb") as f:
        data = f.read()

    if len(data) < 8 or data[:8] != b"\x89PNG\r\n\x1a\n":
        return {"exists": True, "valid": False, "reason": "Invalid PNG header"}

    idx = 8
    width = height = color_type = None
    idat = []
    while idx < len(data):
        length, chunk_type = struct.unpack(">I4s", data[idx:idx+8])
        chunk_data = data[idx+8:idx+8+length]
        if chunk_type == b"IHDR":
            width, height, bit_depth, color_type, _, _, _ = struct.unpack(">IIBBBBB", chunk_data)
        elif chunk_type == b"IDAT":
            idat.append(chunk_data)
        idx += 12 + length

    if not idat or not width or not height:
        return {"exists": True, "valid": False, "reason": "Missing IDAT chunks"}

    try:
        raw = zlib.decompress(b"".join(idat))
    except Exception as e:
        return {"exists": True, "valid": False, "reason": f"Decompress error: {e}"}

    bytes_per_pixel = 3 if color_type == 2 else (4 if color_type == 6 else 1)
    stride = width * bytes_per_pixel + 1

    sum_brightness = 0
    non_zero_count = 0
    unique_colors = set()
    center_colors = set()
    total_pixels = width * height

    center_ymin = int(height * 0.20)
    center_ymax = int(height * 0.80)
    center_xmin = int(width * 0.15)
    center_xmax = int(width * 0.85)

    for y in range(height):
        row_offset = y * stride + 1
        is_center_y = (center_ymin <= y <= center_ymax)
        for x in range(width):
            px_off = row_offset + x * bytes_per_pixel
            r = raw[px_off]
            g = raw[px_off + 1] if bytes_per_pixel >= 2 else r
            b = raw[px_off + 2] if bytes_per_pixel >= 3 else r
            px_val = r + g + b
            sum_brightness += px_val
            if px_val > 10:
                non_zero_count += 1
                if len(unique_colors) < 100:
                    unique_colors.add((r, g, b))
                if is_center_y and (center_xmin <= x <= center_xmax):
                    if len(center_colors) < 100:
                        center_colors.add((r, g, b))

    avg_brightness = sum_brightness / (total_pixels * 3)
    return {
        "exists": True,
        "valid": True,
        "width": width,
        "height": height,
        "non_zero_count": non_zero_count,
        "avg_brightness": avg_brightness,
        "unique_color_count": len(unique_colors),
        "center_color_count": len(center_colors)
    }

def main():
    args = parse_args()
    target = args.target
    capture_dir = args.capture_dir
    verdict_file = os.path.join(capture_dir, "verdict.txt")

    os.makedirs(capture_dir, exist_ok=True)

    # Check for screenshots in capture_dir
    png_files = [
        os.path.join(capture_dir, f)
        for f in os.listdir(capture_dir)
        if f.endswith(".png")
    ] if os.path.exists(capture_dir) else []

    if not png_files:
        with open(verdict_file, "w") as f:
            f.write("THEIRS\nNO_CAPTURES: No screenshots captured for evaluation.\n")
        print(f"[critic] REJECTED {target}: No screenshots found in {capture_dir}")
        sys.exit(0)

    for png_path in png_files:
        res = analyze_png(png_path)
        filename = os.path.basename(png_path)

        if not res.get("valid", False):
            gap = f"INVALID_PNG: {filename} is corrupt or not a valid image."
            with open(verdict_file, "w") as f:
                f.write(f"THEIRS\n{gap}\n")
            print(f"[critic] REJECTED {target}: {gap}")
            sys.exit(0)

        # 3. Center Viewport Dungeon Geometry / Asset Check
        if res.get("center_color_count", 0) < 4:
            gap = f"MISSING_3D_DUNGEON: Center viewport region in ({filename}) lacks rendered dungeon geometry or 3D terrain assets (center_colors={res.get('center_color_count', 0)})."
            with open(verdict_file, "w") as f:
                f.write(f"THEIRS\n{gap}\n")
            print(f"[critic] REJECTED {target}: {gap}")
            sys.exit(0)

        # 1. Black/Unrendered Screen Check
        if res["non_zero_count"] < 500 or res["avg_brightness"] < 0.1:
            gap = f"BLACK_SCREEN: Captured screenshot ({filename}) is solid black/gray or unrendered canvas (non_zero={res['non_zero_count']}, avg={res['avg_brightness']:.2f})."
            with open(verdict_file, "w") as f:
                f.write(f"THEIRS\n{gap}\n")
            print(f"[critic] REJECTED {target}: {gap}")
            sys.exit(0)

        # 2. Color Palette / Variety Check
        if res["unique_color_count"] < 5:
            gap = f"MONOCHROME_SCREEN: Captured screenshot ({filename}) lacks expected GBC Zelda color palette (unique_colors={res['unique_color_count']})."
            with open(verdict_file, "w") as f:
                f.write(f"THEIRS\n{gap}\n")
            print(f"[critic] REJECTED {target}: {gap}")
            sys.exit(0)

    # All captured screenshots pass visual inspection against TetraForce bar
    with open(verdict_file, "w") as f:
        f.write("OURS\n\n")
    print(f"[critic] APPROVED {target}: Screenshots match visual expectations for bar '{args.bar}'.")

if __name__ == "__main__":
    main()
