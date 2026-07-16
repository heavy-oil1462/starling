#!/usr/bin/env python3
"""Regenerate ALL derived artifacts for Starling in one command.

Run after ANY change to cad/*.scad — never hand-compose openscad command
lines (see the regen-outputs skill).

Pipeline:
  1. scripts/check_params.py          — interface dimensions must agree
  2. every part in cad/ + cad/calibration/  -> stl/<name>.stl
  3. cad/main_assembly.scad           -> main_assembly.png (README image)

STLs are committed build products (print-ready). A part whose STL gains a
second volume or errors out is a finding, not something to ignore.

Usage:
    scripts/regen_all.py [part ...]    # no args = everything
"""

import re
import subprocess
import sys
from pathlib import Path

from render_scad import render

ROOT = Path(__file__).resolve().parent.parent
PARTS_DIRS = [ROOT / "cad", ROOT / "cad" / "calibration"]
# Not printable parts: the assembly renders to PNG, design_params is data,
# and the fuselage is the bought paper tube (visual model only).
NON_PARTS = {"main_assembly", "design_params", "fuselage"}


def parts():
    for d in PARTS_DIRS:
        for p in sorted(d.glob("*.scad")):
            if p.stem not in NON_PARTS:
                yield p


def run_one(scad: Path, out: Path) -> bool:
    proc = render(str(scad), str(out))
    warnings = sorted({l.strip() for l in proc.stderr.splitlines() if "WARNING" in l or "ERROR" in l})
    # Manifold backend reports geometry health as "Status: NoError"
    geom = re.search(r"Status:\s+(\w+)", proc.stderr)
    geom_ok = geom is None or geom.group(1) == "NoError"
    ok = proc.returncode == 0 and not warnings and geom_ok
    print(f"[{'ok' if ok else 'FAIL'}] {scad.relative_to(ROOT)} -> {out.relative_to(ROOT)}")
    for w in warnings:
        print(f"        {w}")
    if not geom_ok:
        print(f"        geometry status: {geom.group(1)} — part is not cleanly manifold")
    return ok


def main(argv):
    check = subprocess.run([sys.executable, str(ROOT / "scripts" / "check_params.py")])
    ok = check.returncode == 0

    only = set(argv[1:])
    (ROOT / "stl").mkdir(exist_ok=True)
    for scad in parts():
        if only and scad.stem not in only:
            continue
        ok &= run_one(scad, ROOT / "stl" / f"{scad.stem}.stl")

    if not only or "main_assembly" in only:
        ok &= run_one(ROOT / "cad" / "main_assembly.scad", ROOT / "main_assembly.png")

    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
