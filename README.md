# Starling

![Current assembly](main_assembly.png)

**Starling** is an open-source, cheap, quick-to-assemble RC plane built around a paper tube. The fuselage is a ~53 mm postal tube; everything structural that isn't the tube is 3D printed or off the shelf. It is deliberately **not** built to last — it's built to be so cheap and fast to assemble that it can be treated as single-use for whatever job it's needed for (painting the tube adds some weather resistance if you want more than one flight).

## Project goals

1. **Cheap and expendable** — paper-tube fuselage, printed joints, hobby-grade electronics. Losing the airframe should not hurt.
2. **Payload modularity** — payloads mount on adapters that clamp the round tube, so they can be added, swapped, or slid anywhere along the fuselage.
3. **Movable wing** — the wing mount slides along the tube to re-trim CG for whatever payload is fitted.
4. **Quick assembly** — parts slide over/into the tube; the goal is field-assembly speed, not workshop craftsmanship.
5. **ArduPilot brain** — flight controller config will live in this repo alongside the CAD (planned).

## Airframe

| Part | File | Notes |
|---|---|---|
| Fuselage | (bought, not printed) | 50 mm-class paper/postal tube, ~53 mm OD |
| Nose cone | `cad/nose.scad` | Sleeve-mounted, angled FPV camera opening |
| Wing adapter | `cad/wing_adapter.scad` | Slides on the tube, M3 belly clamp; through-sockets for the wing spars |
| Wing ribs | `cad/wing_rib.scad`, `cad/wing_rib_root.scad` | NACA airfoil ribs on 6 mm carbon spars, foam-board skin; the root rib slides over the adapter tab |
| Tail | `cad/tail.scad` | One print: sleeve + fins with living hinges, 3 servo pockets, rear motor mount (pusher) |
| Calibration prints | `cad/calibration/` | Tube fit ring, motor screw pattern, servo pocket — print these first |

Print-ready STLs for every part are committed under `stl/`.

## Working on the CAD

Tooling is Python + OpenSCAD, fully headless, fetched via nix (no manual installs):

```bash
python3 scripts/regen_all.py      # param check + rebuild every STL + assembly render
python3 scripts/check_params.py   # do the parts still fit the same tube?
python3 scripts/render_scad.py cad/nose.scad nose.png   # one-off render
```

`scripts/regen_all.py` is the single entry point for derived artifacts — the STLs and `main_assembly.png` are build products and regenerate with the CAD that changed them. Every dimension two parts share (tube OD, clearances, spar chain, servo/motor footprints, stations) lives in **`cad/design_params.scad`**; parts include it, and `check_params.py` fails the build if any file shadows a shared name — so the parts can never silently disagree about the tube they share.

## Status

Early prototype. Structural parts exist, print, and fit together on paper (see `docs/design-review.md` for the reviewed-and-fixed findings and the open follow-ups: measure your actual tube, pick the motor/prop combo). Wing skin build notes and the ArduPilot configuration are next.
