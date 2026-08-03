#!/usr/bin/env python3
"""Tile a template SVG onto A4 pages as a print-ready PDF.

The SVGs under templates/ are true-scale (mm units) but wider than a home
printer: this script slices one into portrait A4 pages that tile along the
span, with an overlap and printed alignment crosses at every seam. Print
at 100% (actual size), lay the pages so the crosses coincide, tape, and
the result is the 1:1 template. The layout also fits US letter.

The PDF is committed next to the SVG and byte-checked by regen_all
--check, so it is written deterministically: no timestamps, no
compression, fixed number formatting. stdlib only.

Usage:
    scripts/tile_template.py templates/wing_skin.svg templates/wing_skin_a4.pdf
"""

import re
import sys
from math import ceil
from pathlib import Path

MM2PT = 72 / 25.4
PAGE_W, PAGE_H = 210.0, 297.0   # A4, mm
MARGIN = 8.0                    # keeps clear of home-printer dead zones
OVERLAP = 15.0                  # doubled strip at each seam, mm
FOOT = 12.0                     # footer baseline height, mm


def _num(v):
    s = f"{v:.3f}".rstrip("0").rstrip(".")
    return s if s else "0"


def parse_svg(text):
    """All subpaths from all <path d=...> elements, model mm, y up."""
    paths = []
    for d in re.findall(r'\bd="([^"]*)"', text):
        subs, cur = [], []
        for cmd, x, y in re.findall(
                r"([MLZz])|(-?[\d.eE+]+),(-?[\d.eE+]+)", d):
            if cmd in ("Z", "z"):
                if cur:
                    subs.append(cur)
                cur = []
            elif cmd == "M":
                if cur:
                    subs.append(cur)
                cur = []
            elif x:
                cur.append((float(x), -float(y)))
        if cur:
            subs.append(cur)
        if subs:
            paths.append(subs)
    return paths


def _stream(body):
    data = body.encode("ascii")
    return b"<< /Length %d >>\nstream\n%s\nendstream" % (len(data), data)


def _pdf(objects):
    """Assemble numbered objects (bytes) into a deterministic PDF."""
    out = bytearray(b"%PDF-1.4\n")
    offsets = []
    for i, obj in enumerate(objects, start=1):
        offsets.append(len(out))
        out += b"%d 0 obj\n" % i + obj + b"\nendobj\n"
    xref = len(out)
    out += b"xref\n0 %d\n0000000000 65535 f \n" % (len(objects) + 1)
    for off in offsets:
        out += b"%010d 00000 n \n" % off
    out += (b"trailer\n<< /Size %d /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF\n"
            % (len(objects) + 1, xref))
    return bytes(out)


def tile_a4(svg_path, pdf_path):
    paths = parse_svg(Path(svg_path).read_text())
    pts = [p for path in paths for sub in path for p in sub]
    min_x = min(p[0] for p in pts)
    max_x = max(p[0] for p in pts)
    min_y = min(p[1] for p in pts)
    max_y = max(p[1] for p in pts)
    width = max_x - min_x
    height = max_y - min_y

    usable = PAGE_W - 2 * MARGIN
    advance = usable - OVERLAP
    n_pages = max(1, ceil((width - usable) / advance) + 1)
    y_off = FOOT + 10 + (PAGE_H - FOOT - 10 - MARGIN - height) / 2
    seams = [min_x + i * advance + OVERLAP / 2 for i in range(1, n_pages)]

    page_objs = []
    for i in range(n_pages):
        x_start = min_x + i * advance

        def X(x):
            return _num((x - x_start + MARGIN) * MM2PT)

        def Y(y):
            return _num((y - min_y + y_off) * MM2PT)

        b = ["q", "0.2 w",
             f"{X(x_start)} {Y(min_y)} {_num(usable * MM2PT)} "
             f"{_num(height * MM2PT)} re W n"]
        for path in paths:
            for sub in path:
                b.append(f"{X(sub[0][0])} {Y(sub[0][1])} m")
                for x, y in sub[1:]:
                    b.append(f"{X(x)} {Y(y)} l")
                b.append("h")
            b.append("f*")
        # seam alignment crosses, drawn identically on both sides of a seam
        for sx in seams:
            for sy in (min_y + 12, (min_y + max_y) / 2, max_y - 12):
                b += [f"{X(sx - 4)} {Y(sy)} m", f"{X(sx + 4)} {Y(sy)} l",
                      f"{X(sx)} {Y(sy - 4)} m", f"{X(sx)} {Y(sy + 4)} l", "S"]
        b.append("Q")
        label = (f"Starling template  page {i + 1}/{n_pages}  -  print at "
                 f"100% (actual size), match the crosses, tape, then check "
                 f"the scale bar")
        b += ["BT", "/F1 8 Tf",
              f"{_num(MARGIN * MM2PT)} {_num(FOOT * MM2PT)} Td",
              f"({label}) Tj", "ET"]
        page_objs.append("\n".join(b))

    objects = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [%s] /Count %d >>" % (
            b" ".join(b"%d 0 R" % (4 + 2 * i) for i in range(n_pages)),
            n_pages),
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
    ]
    for i, body in enumerate(page_objs):
        objects.append(
            b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 %s %s] "
            b"/Resources << /Font << /F1 3 0 R >> >> /Contents %d 0 R >>"
            % (_num(PAGE_W * MM2PT).encode(), _num(PAGE_H * MM2PT).encode(),
               5 + 2 * i))
        objects.append(_stream(body))

    Path(pdf_path).write_bytes(_pdf(objects))
    return n_pages


def main(argv):
    if len(argv) != 3:
        print(__doc__)
        return 2
    n = tile_a4(argv[1], argv[2])
    print(f"tiled {argv[1]} -> {argv[2]} ({n} A4 pages)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
