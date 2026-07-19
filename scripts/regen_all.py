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
    scripts/regen_all.py --stl-only    # export the printable STLs, skip the
                                       # assembly PNG (the "give me everything
                                       # to print" mode)
    scripts/regen_all.py --check       # read-only gate (the verify skill and
                                       # CI): render everything to a temp dir
                                       # and byte-compare against the committed
                                       # artifacts; [STALE] means a source
                                       # changed without regenerating. Renders
                                       # are byte-deterministic (same pinned
                                       # OpenSCAD), so equality is exact.
"""

import re
import subprocess
import sys
import tempfile
from pathlib import Path

from render_scad import render

ROOT = Path(__file__).resolve().parent.parent
PARTS_DIRS = [ROOT / "cad", ROOT / "cad" / "calibration"]
# Not printable parts: the assembly renders to PNG, design_params is data,
# and fuselage (paper tube) / servo_9g (bought servo) are visual models only.
NON_PARTS = {"main_assembly", "design_params", "fuselage", "servo_9g"}


def parts():
    for d in PARTS_DIRS:
        for p in sorted(d.glob("*.scad")):
            if p.stem not in NON_PARTS:
                yield p


def run_one(scad: Path, out: Path, expect: Path = None) -> bool:
    """Render scad -> out; with expect set (check mode), also byte-compare
    the fresh render against the committed artifact."""
    proc = render(str(scad), str(out))
    warnings = sorted({l.strip() for l in proc.stderr.splitlines() if "WARNING" in l or "ERROR" in l})
    # Manifold backend reports geometry health as "Status: NoError"
    geom = re.search(r"Status:\s+(\w+)", proc.stderr)
    geom_ok = geom is None or geom.group(1) == "NoError"
    render_ok = proc.returncode == 0 and not warnings and geom_ok
    stale = expect is not None and render_ok and (
        not expect.exists() or expect.read_bytes() != out.read_bytes())
    ok = render_ok and not stale
    shown = expect if expect is not None else out
    tag = "ok" if ok else ("STALE" if stale else "FAIL")
    print(f"[{tag}] {scad.relative_to(ROOT)} -> {shown.relative_to(ROOT)}")
    for w in warnings:
        print(f"        {w}")
    if not geom_ok:
        print(f"        geometry status: {geom.group(1)} — part is not cleanly manifold")
    if stale:
        print("        committed artifact does not match its sources —"
              " run scripts/regen_all.py and commit the result")
    return ok


def main(argv):
    stl_only = "--stl-only" in argv
    check = "--check" in argv
    only = {a for a in argv[1:] if not a.startswith("--")}

    ok = True
    for gate in ("check_params.py", "throw_check.py"):
        ok &= subprocess.run([sys.executable, str(ROOT / "scripts" / gate)]).returncode == 0

    (ROOT / "stl").mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory() as td:
        def target(committed):
            return (Path(td) / committed.name, committed) if check else (committed, None)

        for scad in parts():
            if only and scad.stem not in only:
                continue
            ok &= run_one(scad, *target(ROOT / "stl" / f"{scad.stem}.stl"))

        if not stl_only and (not only or "main_assembly" in only):
            ok &= run_one(ROOT / "cad" / "main_assembly.scad",
                          *target(ROOT / "main_assembly.png"))

    if check and not only:
        expected = {f"{p.stem}.stl" for p in parts()}
        for f in sorted((ROOT / "stl").glob("*.stl")):
            if f.name not in expected:
                print(f"[STALE] {f.relative_to(ROOT)} has no source part — delete it")
                ok = False

    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
