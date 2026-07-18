# Starling

Open-source, cheap, quick-to-build RC plane: a paper-tube fuselage (50 mm-class postal tube) with 3D-printed structural parts and off-the-shelf electronics. Designed for payload carrying, possibly single-use missions — cost and assembly speed beat longevity. ArduPilot software config will live here later; the current focus is structural CAD.

## Core design ideas (do not design against these)

- **The fuselage is a paper tube.** Every printed part is a sleeve (slides over the tube) or a plug (slides inside). The tube is consumable; the printed parts and electronics are the reusable kit.
- **Payload modularity**: payloads go INSIDE the tube, never on the outside. The tube is a single uncut length (sized per mission); a printed adapter wraps the payload so it slides into the tube bore and can sit anywhere along it. New payload parts are plugs — they must reuse the tube-bore (plug) interface, not the sleeve one. A payload that is already a correct-diameter cylinder needs no adapter.
- **Movable wing**: the wing adapter slides along the tube to re-trim CG for whatever payload is fitted. Nothing may assume a fixed wing station.
- Wings are built from 3D-printed ribs on 6 mm carbon-rod spars, skinned with foam board.

## Layout

- `cad/design_params.scad` — **single source of truth** for every dimension two parts share. Parts `include` it; `check_params.py` fails the build if any file shadows one of its names. Change shared values there and only there.
- `cad/` — one .scad per printable part + `main_assembly.scad` (visual fit check, renders to `main_assembly.png`; all placement derives from design_params, e.g. `wing_station`)
- `cad/calibration/` — small test prints for dialing in fits (tube OD ring, tube bore gauge, motor pattern, servo pocket). Gauges print as 3 numbered variants; the user prints one, picks the best fit, and types that number into `design_params.scad`.
- `cad/lib/` — shared OpenSCAD helper modules, not printable parts (regen_all does not scan it)
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

- Fuselage: ~53 mm OD paper/postal tube. `tube_od` AND `tube_id` are both measured per batch (paper wall varies, so OD does not predict the bore) — calibrate with `tube_fit_ring.scad` before trusting a sleeve and `tube_bore_gauge.scad` before trusting a plug
- Wing spars: 6 mm carbon rods (6.2 mm printed holes)
- Servos: 9 g class (SG90 footprint), all mounted INTERNALLY — tail servos on pads inside the sleeve, aileron servos carried by a servo rib (`wing_rib_servo.scad`); wire pushrods exit through small slots (drag rule: nothing but the slot meets the airflow). Throw/slot/clearance numbers: `scripts/throw_check.py`, rationale in `docs/control-system.md`.
- Pushrods: 1.2 mm piano wire; control surfaces hinge on a tape/PP strip glued into matching grooves (never a printed living hinge)
- Motor: 16×19 mm screw pattern (22xx class), rear-mounted (pusher)
