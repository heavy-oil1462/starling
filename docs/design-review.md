# Design review — 2026-07-16

Reviewed by rendering every part headlessly (`scripts/regen_all.py`) and inspecting the assembly render. Findings ordered by how much they matter. Nothing here is fixed yet — this is the worklist.

## Fit-critical (parts will not go together as drawn)

1. **The tube diameter is defined five times with four different values** — 52.9 / 52.92 / 52.94 / 52.95 across `fuselage.scad`, `nose.scad`, `tail.scad`, `wing_adapter.scad`, `calibration/tube_fit_ring.scad`. These look like fit-test iterations that never got consolidated. Sleeves printed from different files will fit the tube differently. **Fix:** one `cad/design_params.scad` (the PrintTrek pattern) holding `tube_od` plus explicit `sleeve_clearance` / `plug_clearance`; every part includes it; `tube_fit_ring.scad` becomes the calibration print for the clearance values. `scripts/check_params.py` already fails on this and will pass once consolidated.

2. **Wing adapter tab (11 mm) ≠ rib adapter slot (15 mm)** — `wing_tab_thickness = 11` in `wing_adapter.scad` vs `adapter_slot_thickness = 15` in `wing_rib.scad`, whose own comment says "must match wing_tab_thickness".

3. **The rib slots don't actually exist** — `foam_slot_thickness`, `adapter_slot_thickness`, `adapter_slot_depth` are declared in `wing_rib.scad` but `wing_rib_with_cutouts()` never cuts them. As printed, ribs have spar holes and a cable hole only: no root rib can engage the adapter tab, and there's no registration for the foam skin.

4. **The tail's internal rim is missing** — `rim_z_position/height/thickness` (tail.scad:20-22) are declared but never modeled. That rim is what stops the paper tube from sliding over the servo bay: the bore runs z=4→90 and the servo bodies protrude into the bore at z≈4–36, so without the rim the tube can be pushed into the servos (or the servos block insertion). Add the rim (or state the tube stop some other way).

## Structural concerns

5. **Wing spar joint is 10 mm of engagement in a printed tab.** The adapter's rod sockets are 10 mm deep for a 6 mm rod, and each wing panel cantilevers off them. Root bending moment for a payload-carrying wing will be far beyond what a 10 mm socket in printed plastic (worse if printed with layer lines across the tab) holds. Options: run the spars continuous over/under the tube (through both tabs), deepen the tabs to full adapter length with through-holes, or bond the rods in and treat wings as non-removable per airframe (fits the single-use idea).

6. **The wing adapter has no clamp.** It slides on the tube (that's the CG-adjustment feature) but nothing fixes it once positioned — friction only, and it's also the highest-load joint on the aircraft (all lift enters the fuselage here). A simple screw-clamp slit boss, or even documented "tape it", is needed; same question applies to nose and tail sleeves.

7. **Living hinges in PLA fins will fail early** (`tail.scad` hinge slits, 1.5 mm slit leaving thin plastic at the TE). PLA work-hardens and cracks within a few dozen cycles; PETG is a bit better. Given the airframe is expendable but the *tail is printed and reusable*, consider the foam-board approach: cut the surface free and tape-hinge it. The slit design is fine as a knife guide if that's the intent — document it.

8. **Pusher prop vs control surfaces/ground**: motor mounts on the rear face at z=0 and the fin trailing edges end at the same station, so the prop disc sits immediately behind the control surfaces. Check the intended prop diameter against the horizontal fin span (110 mm per side) and elevator throw — an 8" prop reaches r≈102 mm, inside the fin span, so elevator deflection into the disc is plausible depending on hinge geometry. Worth a quick clearance check in the assembly.

## Geometry / code health

9. **Assembly doesn't line up**: in `main_assembly.scad` the rib rows sit at x-offset 251 / spanwise stations ±50…420 while the wing adapter sits at z=300 with sockets at z≈305–325 — the render shows ribs floating detached from the adapter, and no spar rods or skin are modeled. Parameterize the wing station once (`wing_station = 300`) and place adapter + ribs + (future) spar rods from it, so the assembly actually demonstrates fit.
10. **`nose.scad` camera hole extrapolates past the cone** — `get_cone_radius_at_z()` is a linear cone-section formula valid for z between the sleeve top (20) and the sphere tangency (~82), but `camera_hole_z_position = 100` is the very tip. The hole currently lands there only by accident of the extrapolation. If a tip-mounted FPV opening is the intent, place it relative to the tip sphere; if a mid-cone window is the intent, move z into the valid range.
11. **`fuselage.scad` has coincident faces** — the inner cylinder of the `difference()` has exactly the same height as the outer, which produces z-fighting faces (the old CGAL backend reported 2 volumes for it). Extend the cutter: `translate([0,0,-0.1]) cylinder(h = length + 0.2, ...)`.
12. **`wing_rib.scad` special-variable warnings** — `$airfoil_fn` / `$close_airfoils` are set at file top level, but top-level assignments don't execute for `use <>` consumers, so every assembly render logs "Ignoring unknown variable" and the airfoil silently falls back to defaults. Pass them as module parameters or make them plain variables inside the functions.
13. **Comment drift**: `naca_code = 2415` is commented "(Symmetric)" — 2415 is cambered (which is the right choice for a lifter; the comment is what's wrong). `wall_thickness = 3` in `fuselage.scad` models the *paper* wall; the archived tail_v1 used 2 mm — worth measuring the real tube and recording it once in the shared params.

## Good bones (keep these)

- The sleeve/plug-on-a-tube architecture is genuinely well suited to the cheap/modular/expendable goal, and the calibration prints (`tube_fit_ring`, `motor_mount_test`, `servo_mount_test`) are exactly the right habit.
- Rib spar holes (6.2 mm at 20 mm spacing) and the adapter sockets already agree — the wing spar chain is consistent.
- The tail as a single print — sleeve + fins + servo pockets + motor mount — is a strong part-count win; the wall-pocketed servos with blister bosses are a nice detail.
- NACA 2415 ribs at 100 mm chord with foam skin is a sane, buildable wing for this class.

## Suggested order of work

1. `design_params.scad` consolidation (fixes #1, #2, #13; makes #5/#6 parameter changes trivial).
2. Cut the missing rib slots and the tail rim (#3, #4).
3. Decide the spar-joint scheme (#5) and add the adapter clamp (#6).
4. Re-parameterize `main_assembly.scad` around a single wing station (#9) so the render becomes the fit check.
5. Cosmetic/code health passes (#10–#12) opportunistically.
