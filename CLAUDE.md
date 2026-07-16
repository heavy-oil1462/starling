# Starling

Open-source, cheap, quick-to-build RC plane: a paper-tube fuselage (50 mm-class postal tube) with 3D-printed structural parts and off-the-shelf electronics. Designed for payload carrying, possibly single-use missions — cost and assembly speed beat longevity. ArduPilot software config will live here later; the current focus is structural CAD.

## Core design ideas (do not design against these)

- **The fuselage is a paper tube.** Every printed part is a sleeve (slides over the tube) or a plug (slides inside). The tube is consumable; the printed parts and electronics are the reusable kit.
- **Payload modularity**: payloads mount via adapters that clamp the round tube, so they can be added or moved anywhere along the fuselage. New payload parts must reuse the tube-sleeve interface.
- **Movable wing**: the wing adapter slides along the tube to re-trim CG for whatever payload is fitted. Nothing may assume a fixed wing station.
- Wings are built from 3D-printed ribs on 6 mm carbon-rod spars, skinned with foam board.

## Layout

- `cad/design_params.scad` — **single source of truth** for every dimension two parts share. Parts `include` it; `check_params.py` fails the build if any file shadows one of its names. Change shared values there and only there.
- `cad/` — one .scad per printable part + `main_assembly.scad` (visual fit check, renders to `main_assembly.png`; all placement derives from design_params, e.g. `wing_station`)
- `cad/calibration/` — small test prints for dialing in fits (tube ring, motor pattern, servo pocket)
- `cad/archive/` — dead versions, never rendered or reviewed
- `stl/` — committed build products, print-ready; regenerate, never hand-edit
- `scripts/` — Python tools (see below)
- `docs/` — design notes and reviews

## Tools & workflow

Everything runs headless through nix — **never download or manually install binaries** (`nix shell` / `nix build` only). OpenSCAD comes from `nixpkgs#openscad-unstable`.

- `python3 scripts/regen_all.py` — the single entry point for derived artifacts: gates (params, throw) → all STLs → `main_assembly.png`. Run after ANY .scad change (see the `regen-outputs` skill). `--stl-only` exports just the printable STLs.
- `python3 scripts/check_params.py` — cross-file interface-dimension check; `[FAIL]` means parts won't fit the same tube. Gate every commit on it.
- `python3 scripts/throw_check.py` — control-surface throw, pushrod-slot length, and pusher-prop clearance from the shared params (via `scripts/design_params.py`, the Python-side parser of `design_params.scad`).
- `python3 scripts/render_scad.py <file.scad> <out.png|stl> [openscad args]` — one-off headless renders (see the `openscad-review` skill).

Conventions:
- Anything done more than once becomes a skill (`.claude/skills/`) or a Python script in `scripts/` — no ad-hoc command lines or throwaway code.
- Review CAD by rendering and looking at the PNG, never from source alone.
- Interface dimensions (tube OD, spar diameter/spacing, tab/slot thickness) must agree across files — `check_params.py` knows the alias pairs.
- Keep top-level `name = value;` parameters parseable (plain numbers) so the tooling can read them.

## Key off-the-shelf parts

- Fuselage: ~53 mm OD paper/postal tube (calibrate with `cad/calibration/tube_fit_ring.scad` before trusting any sleeve fit)
- Wing spars: 6 mm carbon rods (6.2 mm printed holes)
- Servos: 9 g class (SG90 footprint), all mounted INTERNALLY — tail servos on pads inside the sleeve, aileron servos clipped to the spars inside the wing; wire pushrods exit through small slots (drag rule: nothing but the slot meets the airflow). Throw/slot/clearance numbers: `scripts/throw_check.py`, rationale in `docs/control-system.md`.
- Pushrods: 1.2 mm piano wire; control surfaces hinge on a tape/PP strip glued into matching grooves (never a printed living hinge)
- Motor: 16×19 mm screw pattern (22xx class), rear-mounted (pusher)
