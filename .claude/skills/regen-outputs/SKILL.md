---
name: regen-outputs
description: Regenerate ALL derived artifacts for Starling in one command (parameter check, every printable STL, main_assembly.png). Use after ANY change to cad/*.scad — never hand-run individual openscad commands.
---

# Regenerate derived outputs

One command rebuilds everything that is committed but derived:

```bash
python3 scripts/regen_all.py            # everything
python3 scripts/regen_all.py nose tail  # just these parts
```

Pipeline:
1. `scripts/check_params.py` — cross-file interface dimensions must agree (FAIL gates the commit)
2. every part in `cad/` + `cad/calibration/` → `stl/<name>.stl`
3. `cad/main_assembly.scad` → `main_assembly.png` (the README image)

## Rules

- Do NOT compose ad-hoc render command lines; if a new artifact appears, add it to `regen_all.py` so the pipeline stays the single entry point.
- The committed STLs and `main_assembly.png` are build products — regenerate them in the same change that alters their sources, never edit around them.
- After running, read the output: every part must be `[ok]` (no warnings, geometry status `NoError`). A bad status usually means coincident faces in a `difference()` — extend the cutter past both surfaces, don't ship the STL.
- Files in `cad/archive/` are dead versions and are deliberately not rendered.
- Finish by eyeballing `main_assembly.png` (Read tool) — parts floating apart or interpenetrating are findings even when everything compiles.
