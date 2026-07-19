---
name: openscad-review
description: Render and review the OpenSCAD models in cad/ headlessly (via nix, no GUI needed). Use after any .scad change, or when asked to verify/review the CAD. Checks compile warnings, manifold geometry, visual correctness, and Starling's interface rules.
---

# OpenSCAD Review

Review OpenSCAD changes by actually rendering them — never approve a .scad edit from source reading alone.

## Rendering (headless, via nix)

Use the helper — it resolves OpenSCAD + Mesa from nixpkgs (never download binaries manually) and renders without any display:

```bash
scripts/render_scad.py cad/<file>.scad <out.png|out.stl> [extra openscad args]
```

Notes (do not rediscover):
- The sandbox's `LD_LIBRARY_PATH=/lib` crashes nix binaries; the script overrides it. Do the same if running openscad manually via `nix shell`.
- PNG rendering uses Mesa software GL via `EGL_PLATFORM=surfaceless` — no X/xvfb needed.
- `nixpkgs#openscad-unstable` (registry unstable) has no hydra cache and its
  source build fails at link (lld: .debug_gdb_scripts not null terminated),
  costing an hour before dying. `render_scad.py` therefore pins `NIXPKGS` to
  a release branch (nixos-26.05), which ships the identical snapshot
  prebuilt. Probe for a cached build with `--max-jobs 0` (fails fast instead
  of source-building) before changing the pin.

## Review procedure

1. **Run `python3 scripts/check_params.py` first.** Every part interfaces with the same paper tube; a `[FAIL]` means parts physically won't fit. This gates everything else.

2. **Render every changed .scad to PNG** (into the scratchpad dir) and **look at it** with the Read tool. Capture stderr — any `WARNING:`/`ERROR:` is a finding; zero warnings is the baseline.

3. **Export changed printable parts to STL** and check the stderr geometry summary: a printable part must be **exactly 1 volume**. Two volumes usually means coincident faces in a `difference()` (extend cutters by an epsilon beyond both ends).

4. If a file becomes library-only (modules, no top-level call), wrap it — the `use <>` path MUST be absolute (it resolves relative to the wrapper file):
   ```bash
   echo 'use </workspace/cad/wing_rib.scad>; wing_rib_with_cutouts();' > "$SCRATCH/wrap.scad"
   scripts/render_scad.py "$SCRATCH/wrap.scad" "$SCRATCH/wing_rib.png"
   ```

## Starling interface rules to verify

- **`cad/design_params.scad` is the single source of truth** for every dimension two parts share (tube OD, clearances, spar chain, tab/slot, servo/motor footprints, stations). Parts `include` it; `check_params.py` FAILS if any file re-declares one of its names. Never fix a mismatch locally — change the shared value.
- **Wing spar chain**: rib spar holes = adapter rod sockets = carbon rods (`spar_hole_d`, `spar_spacing`, `spar_y_offset`); the root-rib window derives from `wing_tab_thickness + fit_tol`, so alignment holds by construction. Verify by rendering the assembly, not by reading numbers.
- Sleeve bores are `tube_od + sleeve_clearance`. Fit is validated with `cad/calibration/tube_fit_ring.scad` — adjust `sleeve_clearance` in design_params, print the ring, then trust the sleeves.
- **Controls**: servos mount internally, only the pushrod slot meets the airflow. Fin TE groove = surface LE groove (`hinge_groove_w/d`), fins shortened by `ctrl_chord + 2`, slot length gated by `scripts/throw_check.py` — run it after touching any horn/travel/hinge parameter.
- Spar rods must never reach a sleeve bore (they'd press on the paper tube) — sockets keep a 1 mm floor.
- The wing mount must stay movable along the tube (CG adjustment) — no feature may assume a fixed wing station.
- Payload adapters clamp the round tube; new payload parts should reuse the sleeve interface, not invent a new mount.

## Report

Summarize per file: render OK/warnings, volume count, visual findings, rule violations. Include rendered PNG paths so the user can look.
