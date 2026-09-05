#!/usr/bin/env python3
"""Genere les icones de lanceur des projets Connect IQ (PNG RGBA, stdlib seule).

Usage: python3 garmin/tools/make_icons.py
Les icones font 40x40, la taille attendue par la famille round-260x260
(fenix 7 / 7S / 7X et variantes Pro).
"""
import math
import os
import struct
import zlib

SIZE = 40
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)


def write_png(path, pixels, size=SIZE):
    raw = b"".join(b"\x00" + bytes(px for pixel in row for px in pixel) for row in pixels)
    def chunk(tag, data):
        payload = tag + data
        return struct.pack(">I", len(data)) + payload + struct.pack(">I", zlib.crc32(payload))
    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(raw, 9))
           + chunk(b"IEND", b""))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as handle:
        handle.write(png)
    print("ecrit", os.path.relpath(path, ROOT))


def blank():
    return [[(0, 0, 0, 0) for _ in range(SIZE)] for _ in range(SIZE)]


def blend(pixels, x, y, color, alpha):
    """Melange une couleur sur un pixel, alpha entre 0.0 et 1.0."""
    if not (0 <= x < SIZE and 0 <= y < SIZE) or alpha <= 0:
        return
    old = pixels[y][x]
    a = min(1.0, alpha)
    new_a = a + old[3] / 255.0 * (1 - a)
    if new_a <= 0:
        return
    out = []
    for i in range(3):
        src = color[i] * a
        dst = old[i] * (old[3] / 255.0) * (1 - a)
        out.append(int(round((src + dst) / new_a)))
    pixels[y][x] = (out[0], out[1], out[2], int(round(new_a * 255)))


def disc(pixels, cx, cy, radius, color):
    for y in range(SIZE):
        for x in range(SIZE):
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            blend(pixels, x, y, color, max(0.0, min(1.0, radius - d)))


def ring(pixels, cx, cy, radius, width, color):
    inner = radius - width
    for y in range(SIZE):
        for x in range(SIZE):
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            cover = min(radius - d, d - inner, 1.0)
            blend(pixels, x, y, color, max(0.0, cover))


def segment(pixels, cx, cy, angle_deg, length, width, color):
    a = math.radians(angle_deg)
    x1, y1 = cx + math.cos(a) * length, cy - math.sin(a) * length
    for y in range(SIZE):
        for x in range(SIZE):
            px, py = x + 0.5, y + 0.5
            dx, dy = x1 - cx, y1 - cy
            t = ((px - cx) * dx + (py - cy) * dy) / (dx * dx + dy * dy)
            t = max(0.0, min(1.0, t))
            d = math.hypot(px - (cx + dx * t), py - (cy + dy * t))
            blend(pixels, x, y, color, max(0.0, min(1.0, width - d)))


def watchface_icon():
    px = blank()
    c = SIZE / 2.0
    disc(px, c, c, 18.5, (0x10, 0x10, 0x10))
    ring(px, c, c, 18.5, 2.5, (0x00, 0xAA, 0xFF))
    segment(px, c, c, 90, 10.5, 1.6, (0xFF, 0xFF, 0xFF))   # aiguille des minutes
    segment(px, c, c, 20, 7.0, 1.9, (0xFF, 0xFF, 0xFF))    # aiguille des heures
    disc(px, c, c, 1.8, (0x00, 0xAA, 0xFF))
    return px


def timer_icon():
    px = blank()
    c = SIZE / 2.0
    disc(px, c, c + 1.5, 16.5, (0x10, 0x10, 0x10))
    ring(px, c, c + 1.5, 16.5, 2.5, (0xFF, 0x55, 0x00))
    segment(px, c, c + 1.5, 90, 9.5, 1.7, (0xFF, 0xFF, 0xFF))
    segment(px, c, c + 1.5, 0, 7.5, 1.7, (0xFF, 0xFF, 0xFF))
    # couronne du chronometre
    for y in range(3, 8):
        for x in range(17, 23):
            blend(px, x, y, (0xFF, 0x55, 0x00), 1.0)
    return px


def field_icon():
    px = blank()
    c = SIZE / 2.0
    disc(px, c, c, 18.5, (0x10, 0x10, 0x10))
    ring(px, c, c, 18.5, 2.5, (0xFF, 0x00, 0x00))
    # trace d'electrocardiogramme
    trace = [(8, 22), (13, 22), (15, 15), (18, 28), (21, 12), (24, 22), (31, 22)]
    for i in range(len(trace) - 1):
        x0, y0 = trace[i]
        x1, y1 = trace[i + 1]
        steps = int(max(abs(x1 - x0), abs(y1 - y0)) * 4) + 1
        for s in range(steps + 1):
            t = s / float(steps)
            fx, fy = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
            for dy in range(-1, 2):
                for dx in range(-1, 2):
                    blend(px, int(fx) + dx, int(fy) + dy, (0xFF, 0xFF, 0xFF),
                          max(0.0, 1.2 - math.hypot(int(fx) + dx + 0.5 - fx,
                                                    int(fy) + dy + 0.5 - fy)))
    return px


if __name__ == "__main__":
    write_png(os.path.join(ROOT, "aurora-watchface/resources/drawables/launcher_icon.png"),
              watchface_icon())
    write_png(os.path.join(ROOT, "interval-timer/resources/drawables/launcher_icon.png"),
              timer_icon())
    write_png(os.path.join(ROOT, "hr-zone-field/resources/drawables/launcher_icon.png"),
              field_icon())
