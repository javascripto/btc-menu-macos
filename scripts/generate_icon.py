#!/usr/bin/env python3
import math
import os
import struct
import zlib
from binascii import crc32


def write_png(path, width, height, rgba_bytes):
    def chunk(tag, data):
        return (
            struct.pack(">I", len(data))
            + tag
            + data
            + struct.pack(">I", crc32(tag + data) & 0xFFFFFFFF)
        )

    raw = bytearray()
    stride = width * 4
    for y in range(height):
        raw.append(0)  # filter type 0
        start = y * stride
        raw.extend(rgba_bytes[start : start + stride])

    png = bytearray()
    png.extend(b"\x89PNG\r\n\x1a\n")
    png.extend(
        chunk(
            b"IHDR",
            struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0),
        )
    )
    png.extend(chunk(b"IDAT", zlib.compress(bytes(raw), level=9)))
    png.extend(chunk(b"IEND", b""))

    with open(path, "wb") as f:
        f.write(png)


def draw_icon(size=1024):
    # Colors
    orange = (247, 147, 26, 255)  # #F7931A
    white = (255, 255, 255, 255)
    transparent = (0, 0, 0, 0)

    img = bytearray(size * size * 4)

    cx = cy = size / 2.0
    radius = size * 0.45
    r2 = radius * radius

    # Draw orange circle
    for y in range(size):
        dy = y - cy
        for x in range(size):
            dx = x - cx
            if dx * dx + dy * dy <= r2:
                idx = (y * size + x) * 4
                img[idx : idx + 4] = bytes(orange)
            else:
                idx = (y * size + x) * 4
                img[idx : idx + 4] = bytes(transparent)

    # Simple block "B"
    # 9x13 bitmap
    bitmap = [
        "01111110",
        "01100011",
        "01100011",
        "01111110",
        "01100011",
        "01100011",
        "01111110",
    ]

    # Scale bitmap to fit
    scale = size // 16
    bw = len(bitmap[0]) * scale
    bh = len(bitmap) * scale
    bx0 = int(cx - bw / 2)
    by0 = int(cy - bh / 2)

    for row, line in enumerate(bitmap):
        for col, ch in enumerate(line):
            if ch == "1":
                for sy in range(scale):
                    for sx in range(scale):
                        x = bx0 + col * scale + sx
                        y = by0 + row * scale + sy
                        if 0 <= x < size and 0 <= y < size:
                            idx = (y * size + x) * 4
                            img[idx : idx + 4] = bytes(white)

    # Add two vertical bars to mimic BTC mark
    bar_w = max(4, size // 80)
    bar_h = int(bh * 1.15)
    bar_y0 = int(cy - bar_h / 2)
    bar_x_offsets = [-int(bw * 0.28), int(bw * 0.28)]
    for offset in bar_x_offsets:
        x0 = int(cx + offset - bar_w / 2)
        for y in range(bar_y0, bar_y0 + bar_h):
            if 0 <= y < size:
                for x in range(x0, x0 + bar_w):
                    if 0 <= x < size:
                        idx = (y * size + x) * 4
                        img[idx : idx + 4] = bytes(white)

    return img


def main():
    out_dir = os.path.join(os.path.dirname(__file__), "..", "assets")
    os.makedirs(out_dir, exist_ok=True)
    png_path = os.path.join(out_dir, "BTCMenu.png")
    icon = draw_icon(1024)
    write_png(png_path, 1024, 1024, icon)
    print(f"Generated {png_path}")


if __name__ == "__main__":
    main()
