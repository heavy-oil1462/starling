# Design review — 2026-07-16

Reviewed by rendering every part headlessly (`scripts/regen_all.py`) and inspecting the assembly render. **Update (same day): all findings below are fixed or explicitly documented** — each item now carries a status. The enabling change is `cad/design_params.scad`: a single shared parameter file every part includes, enforced by `scripts/check_params.py`, which fails if any file re-declares a shared name — so interface mismatches can no longer exist silently.

## Fit-critical (parts would not have gone together as drawn)

1. **The tube diameter was defined five times with four different values** (52.9–52.95 across fuselage, nose, tail, wing adapter, fit ring).
   **Fixed:** one `tube_od` (52.95 — verify against your actual tube with the fit ring) plus `sleeve_clearance` in `design_params.scad`; every sleeve bore derives from them. Shadowing a shared name now fails `check_params.py`.

2. **Wing adapter tab (11 mm) ≠ rib adapter slot (15 mm).**
   **Fixed:** both sides now derive from the shared `wing_tab_thickness` (11); the root-rib window is `wing_tab_thickness + fit_tol` by construction.

3. **The rib's adapter/foam slots were declared but never cut.**
   **Fixed (adapter):** new `wing_rib_root()` (exported as `stl/wing_rib_root.stl`, one per panel) cuts a through-window centered on the spar holes that slides over the adapter tab, so rib holes and adapter sockets align by construction.
   **Removed (foam):** the foam-skin slots were geometrically impossible — a 5 mm skin cannot be inlaid into a ~15 mm-thick section — so the dead parameters are gone and the design intent is documented in `wing_rib.scad`: the skin *wraps* the ribs; the rib profile is the inner mold line.

4. **The tail's internal rim (tube stop) was declared but never modeled**, letting the tube slide into the servo bodies.
   **Fixed:** the rim is now modeled (top edge at shared `tail_tube_stop = 54`, above the servo bay at z≈4–36) and `main_assembly.scad` seats the tube on the same shared value. Verified in a cutaway render.

## Structural concerns

5. **Wing spar engagement was 10 mm of blind socket in a printed tab.**
   **Improved:** sockets now run through the tab *and* the sleeve wall (~19 mm engagement, rod bears on the tube itself), and `wing_adapter.scad` documents that rods must be bonded in for flight — sockets are alignment, not structure. A continuous over/under-tube spar remains the upgrade path if flight testing shows the joint working loose.

6. **The wing adapter had no clamp** (CG-trim slide was friction-only at the highest-load joint).
   **Fixed:** belly slit + M3 lug pair (two screws) so the adapter locks anywhere along the tube. Nose and tail sleeves stay friction/tape fits — they carry far smaller loads and tape suits the expendable philosophy.

7. **"Living hinge" fins in PLA would crack within dozens of cycles.**
   **Documented as intent:** the TE slit is a *groove for a taped/glued-in hinge* (foam or hinge strip), not a printed living hinge — stated in `tail.scad` where the slit parameters live.

8. **Pusher prop vs control surfaces**: the prop disc sits immediately behind the fin trailing edges.
   **Documented as a build rule** in `tail.scad`'s motor-mount section: use a prop standoff at least as long as the control-surface chord, or keep the prop radius clear of the surfaces at full deflection. (Not resolvable in CAD until a motor/prop combo is chosen.)

## Geometry / code health

9. **Assembly rib row didn't line up with the adapter** (magic numbers 251/300, no spars modeled).
   **Fixed:** `main_assembly.scad` rewritten — everything derives from `design_params.scad` (`wing_station`, `tail_tube_stop`, spar chain), spar rods are modeled, the root rib sits on the tab, and the whole wing group moves with one number. The render is now an actual fit check.
10. **Nose camera hole placed by a cone-section formula extrapolated past its valid range.**
    **Fixed:** the opening is bored outward from the tip-sphere center along the flight axis, tilted `camera_hole_angle_degrees` toward the belly — anchored to the tip so it survives reshaping the cone.
11. **`fuselage.scad` coincident faces** (inner cutter same height as outer).
    **Fixed:** cutter extended past both ends; the file is also now marked as a visual model of the bought tube (no STL is exported for it).
12. **`$airfoil_fn`/`$close_airfoils` special-variable warnings** (top-level `$var` assignments are invisible to `use<>` consumers).
    **Fixed:** plain variables, closed-TE constant baked in; assembly renders with zero warnings.
13. **Comment drift** ("symmetric" on the cambered 2415, unmeasured paper wall).
    **Fixed/consolidated:** NACA comment corrected; `tube_wall` lives once in `design_params.scad` with a note to measure the real tube.

## Good bones (kept)

- The sleeve/plug-on-a-tube architecture, the calibration-print habit, the single-print tail with wall-pocketed servos, and NACA 2415 at 100 mm chord — all solid choices, now all fed from the shared parameter file.

## Remaining follow-ups

- Measure the real tube (OD and wall) and set `tube_od`/`tube_wall`; print `tube_fit_ring` to dial in `sleeve_clearance`.
- Pick the motor/prop combo and verify prop-vs-elevator clearance (finding 8).
- If flight tests show the bonded spar joints loosening, design the continuous-spar variant of the adapter (finding 5's upgrade path).
