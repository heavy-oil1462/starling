# Direction

Set by the owner, heavy-oil1462. The supervisor reads this at the start of
every session. Change it through a pull request, or ask on the board issue.

## Goal

Starling is an open-source RC plane that is cheap and quick to build: a
paper postal-tube fuselage, 3D-printed sleeves and plugs, and off-the-shelf
electronics. It carries payloads inside the tube and can be treated as
single-use. Next it should reach a flyable first airframe: every part
printable, calibrated to a real tube, with build docs. After that comes an
ArduPilot configuration that lives in this repository.

## Guiding principles

- The fuselage is one uncut paper tube. Every printed part is a sleeve
  (over the tube) or a plug (in the bore). Nothing cuts or bolts through the tube.
- Payloads go inside the tube as plugs on the bore interface, never outside.
- Nothing assumes a fixed wing station. The wing slides to trim CG.
- Cost and assembly speed beat longevity. Pick the cheaper or faster build
  unless it fails a gate.
- `cad/design_params.scad` is the only home of any dimension two parts
  share. `check_params.py` enforces this.
- Derived files (`stl/`, `templates/`, `main_assembly.png`) come only from
  `scripts/regen_all.py` and are committed with the .scad change that
  caused them. Never edit them by hand.
- Parts print support-free in their stated orientation.
- Servos mount internally and only pushrod slots meet the airflow. Hinges
  are taped strips in grooves, never printed living hinges.
- Tooling is headless and reproducible: nix for binaries, stdlib-only
  Python, no manual installs.
- Anything done twice becomes a script in `scripts/` or a skill in
  `.claude/skills/`.

## Architecture

- `cad/design_params.scad`: shared dimensions. Every part includes it.
  `scripts/design_params.py` parses its plain-number literals for Python.
- `cad/lib/`: shared modules, not printable. `wing_adapter_common.scad` is
  the wing interface shared by the trim rig and the glue-on flight adapter.
- `cad/*.scad`: one printable part per file. Parts depend on
  `design_params.scad` and `cad/lib/` only, never on each other.
  `main_assembly.scad` is the exception: it places every part for the
  fit-check render.
- `cad/calibration/`: numbered-variant gauges whose winner is typed into
  `design_params.scad`.
- `scripts/`: gates (`check_params.py`, `throw_check.py`, `wing_check.py`)
  and builders (`regen_all.py`, `render_scad.py`, `tile_template.py`).
  `regen_all.py` is the only entry point that writes artifacts.
  `--check` is the commit gate that CI runs (`.github/workflows/verify.yml`).
- `stl/`, `templates/`, `main_assembly.png`: committed build products.
- `docs/`: design notes (`design-review.md`, `control-system.md`,
  `wing-build.md`, `wing-stations.md`). Decisions go in `docs/adr` (none yet).
- `cad/archive/`: dead versions, never built or reviewed.

## Priorities, in order

1. Close the open follow-ups in `docs/design-review.md`: choose the
   motor/prop combo and gate the prop clearance on it.
2. A complete build guide for the whole airframe (fuselage, tail, nose,
   electronics), like `docs/wing-build.md` does for the wing, with a full BOM.
3. A payload adapter reference part plus a CG/wing-station procedure for a
   given payload mass and position.
4. ArduPilot configuration for the airframe in the repository.

## Not now

- External payload mounts, a cut or multi-piece fuselage, dihedral or
  washout in the wing.
- Durability features that cost print time or assembly speed.

## How to work

- After any .scad change run `python3 scripts/regen_all.py` and commit the
  artifacts with it. `python3 scripts/regen_all.py --check` must pass
  before a pull request (CI runs the same).
- Review CAD by rendering it and looking at the PNG, not from source.
- New shared dimensions go into `design_params.scad` as plain-number literals.
- When a change alters a documented number or procedure, update its doc
  in `docs/` or README in the same pull request.

## Ask the owner first

- Changing the core design ideas above (tube, payload-inside, movable wing).
- Choosing specific bought hardware that sets cost (motor, prop, flight
  controller, battery).
- Removing or replacing a calibration gauge or a gate script.
