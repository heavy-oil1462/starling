# Wing build

How to turn the printed parts, two carbon rods, and a sheet of foam board
into one wing panel. Every number below comes from `cad/design_params.scad`
and is gated by `scripts/wing_check.py` — if you change the span layout,
regenerate everything (`scripts/regen_all.py`) and this doc's tables follow
from the params, not the other way round. The cutting truth for the skin is
`templates/wing_skin.svg`, never the prose here.

## Design decisions

- **Flat wing.** No dihedral, washout, or incidence — deliberately. Ailerons
  plus ArduPilot stabilization cover roll behaviour for a docile payload
  hauler, and flat ribs on straight uncut spars are what makes the wing
  cheap and quick. Do not add angled joints.
- **Span is a mission/stock tunable.** The default layout (tip station 440,
  417 mm rods) is sized so one 500 mm carbon rod yields one spar with a
  single cut. To resize: edit the span literals in `design_params.scad`
  (`tip_station` is the span knob; move the stations with it), set
  `spar_rod_len` to what your rod stock allows, and run
  `python3 scripts/wing_check.py` — it prints the available spar cavity and
  fails until the layout is consistent. Then `python3 scripts/regen_all.py`.
- **The skin template is exact at the rib surface.** The developed lengths
  trace the inner mold line, so the outer face of 5 mm foam runs slightly
  long around the LE. Rough-cut the blank oversize on the upper-TE side and
  trim after a dry wrap.

## Bill of materials (one airframe, both panels)

| Item | Qty | Spec | Typical source |
| --- | --- | --- | --- |
| Carbon rod | 4 | 6 mm dia, cut to `spar_rod_len` (417 mm; one 500 mm kite/hobby rod each, one cut) | kite shops, hobby carbon stock |
| Foam board | 1 sheet | 5 mm paper-faced, at least 500 x 700 mm (each skin blank is ~397 x 206 mm plus trim margin, see the template) | dollar store / stationery |
| `stl/wing_rib.stl` | 6 | 3 per panel (`rib_stations`) | print |
| `stl/wing_rib_servo.stl` | 2 | 1 per panel | print |
| `stl/wing_rib_aileron.stl` | 2 | 1 per panel (`aileron_rib_stations`) | print |
| `stl/wing_rib_tip.stl` | 2 | 1 per panel | print |
| `stl/control_surface.stl` | 2 | aileron, `aileron_span` = 120 mm | print |
| `stl/wing_adapter_glue.stl` | 1 | flight adapter (the clamping trim rig is tooling, printed once) | print |
| Servo | 2 | 9 g SG90 class + extension leads reaching the fuselage | hobby electronics |
| Piano wire | ~0.5 m | 1.2 mm, pushrods | hobby / hardware |
| Tape | 1 roll | fiber or packing tape: aileron hinge + servo fairing | anywhere |
| CA glue (or epoxy) | 1 | ribs to rods, rods into sockets, skin seams | anywhere |

Tooling, printed once per printer/filament, reused across airframes:
`stl/spar_fit_gauge.stl` (calibrates `spar_hole_d`), `stl/rib_square_jig.stl`
(squares ribs while gluing), 2x `stl/skin_cradle.stl` (holds the panel
level), and `stl/wing_adapter.stl` (the clamping CG trim rig).

Print `templates/wing_skin_a4.pdf` on plain A4 (or letter) at 100% /
actual size — never "fit to page". It is three portrait pages tiled along
the span: lay them so the printed alignment crosses coincide, tape, and
confirm the 100 mm scale bar with a ruler before cutting anything.
`templates/wing_skin.svg` is the same template as a single sheet, for A3
printers or cutting plotters.

## Station table (defaults; `design_params.scad` is the source)

| Station (mm from centerline) | Part |
| --- | --- |
| 47, 120, 200 | `wing_rib` (full chord) |
| 280 | `wing_rib_servo` (replaces a row rib) |
| 283..403 | aileron (root at `aileron_root_station`, span 120) |
| 360 | `wing_rib_aileron` (TE-cropped, under the aileron) |
| 440 | `wing_rib_tip` (inboard face; rods end inside its blind sockets) |

## Build sequence (per panel)

1. Calibrate first: print `stl/spar_fit_gauge.stl`, push a rod through the
   three holes, and type the number of the best fit (slides fully, no
   wobble) into `spar_hole_d` in `cad/design_params.scad`. Regenerate and
   only then print the rib set.
2. Print the ribs; a rod should slide through without force.
3. Thread all ribs onto both rods in station order (tip rib last, blind
   sockets outboard). Set each rib at its station, measuring from the rod's
   inboard end plus the adapter engagement (the inboard ~15 mm of rod stays
   bare for the adapter sockets — `wing_check.py` prints the exact
   engagement numbers).
4. Seat the rod ends in the tip rib's blind sockets. Square each rib with
   `stl/rib_square_jig.stl`: slide the jig against the rib, press the rib
   flush against its face, CA the rib to both rods, move to the next
   station.
5. Mount the aileron servo in the servo rib's open-bottom bay: flange seats
   on the outboard face, arm up. Route the lead inboard through the rib
   cable holes. Tack the flange with CA or strapping tape
   (docs/control-system.md has the linkage details).
6. Cut the skin blank from the printed template: transfer the fold line,
   spar lines, and station marks; cut the servo-arm slot and the aileron
   corner cut-offs BEFORE skinning. Flip the foam for the mirror panel.
7. Rest the frame in two `stl/skin_cradle.stl` saddles. Score the fold
   line, crack the foam over a table edge, and glue the lower surface to
   the rib TEs first; then wrap over the LE and glue the upper surface,
   spar lines over the spars. Trim the upper TE to the lower TE edge. Sand
   the outboard edge flush into the tip rib's cap. The skinned panel sits
   snug in the cradles for the remaining steps.
8. Hinge the aileron with tape along the top surface per
   docs/control-system.md; Z-bend the pushrod between servo arm and horn.
   Verify throws move freely over the range `scripts/throw_check.py`
   reports.
9. At final assembly, bond the bare rod ends into the wing adapter sockets
   (CA/epoxy — the sockets alone are alignment, not structure) and trim CG
   per docs/wing-stations.md.
