#!/usr/bin/env python3
"""Cross-file parameter consistency check for the Starling CAD files.

Every printed part interfaces with the paper fuselage tube, so dimensions
like the tube diameter MUST agree across files. This script parses the
top-level `name = value;` assignments of every .scad under cad/ (archive
excluded) and reports any parameter that is defined in more than one file
with different values.

Exit code 1 if any INTERFACE-critical parameter disagrees, 0 otherwise
(other mismatches are printed as informational — chord vs chord etc. may
legitimately differ per part).

Usage:
    scripts/check_params.py
"""

import re
import sys
from collections import defaultdict
from pathlib import Path

CAD = Path(__file__).resolve().parent.parent / "cad"

# Parameters that describe a physical interface between parts: any
# disagreement here means parts will not fit together.
INTERFACE = {
    "tube_diameter",
    "tube_outer_diameter",
    "carbon_spar_diameter",
    "hole_diameter",       # wing adapter rod sockets = rib spar holes
    "spar_spacing",
    "hole_spacing",        # adapter socket spacing = rib spar spacing
    "wing_tab_thickness",
    "adapter_slot_thickness",
}

# Names that mean the same interface dimension in different files.
ALIASES = {
    "tube_outer_diameter": "tube_diameter",
    "hole_diameter": "carbon_spar_diameter",
    "hole_spacing": "spar_spacing",
    "adapter_slot_thickness": "wing_tab_thickness",
}

ASSIGN = re.compile(r"(?m)^\s*(\w+)\s*=\s*([-\d.][^;]*?)\s*;")


def scad_files():
    return [p for p in sorted(CAD.rglob("*.scad")) if "archive" not in p.parts]


def collect():
    values = defaultdict(dict)  # canonical name -> {file: value}
    for path in scad_files():
        for m in ASSIGN.finditer(path.read_text()):
            name, raw = m.group(1), m.group(2)
            try:
                val = float(raw)
            except ValueError:
                continue  # derived expression, skip
            canon = ALIASES.get(name, name)
            rel = str(path.relative_to(CAD.parent))
            # keep first top-level literal per file
            values[canon].setdefault(rel, (name, val))
    return values


def main():
    values = collect()
    failures = 0
    for canon in sorted(values):
        per_file = values[canon]
        distinct = {v for (_, v) in per_file.values()}
        if len(per_file) > 1 and len(distinct) > 1:
            critical = canon in INTERFACE
            tag = "FAIL" if critical else "info"
            print(f"[{tag}] {canon} disagrees:")
            for rel, (name, val) in sorted(per_file.items()):
                alias = f" (as {name})" if name != canon else ""
                print(f"        {val:<8g} {rel}{alias}")
            failures += critical
    if failures:
        print(f"\n{failures} interface parameter(s) disagree — parts will not fit together.")
        return 1
    print("all interface parameters consistent")
    return 0


if __name__ == "__main__":
    sys.exit(main())
