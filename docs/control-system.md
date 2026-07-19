# Control system — servos, linkages, throw

Design decided 2026-07-16. Numbers below are computed by `scripts/throw_check.py`
from `cad/design_params.scad` (re-run it after changing any horn/travel/slot
parameter — `regen_all.py` runs it as a gate).

## Layout: servos INSIDE, only a slot in the airstream

All five servos are 9 g (SG90-class) and all mount *internally*, with a wire
pushrod exiting through a small slot to the control horn:

The wire always attaches at the **tip of the full-length servo arm**, and at
neutral the arm sits **perpendicular to the wire** — that is where the
linkage is most linear and transmits the most motion.

- **Tail (elevator ×2, rudder ×1)** — each servo lies on its side, shaft
  tangential, and **presses into a snug printed pocket** (walls grip the
  outer 6 mm of the body on both ends and the side away from the shaft; a
  drop of CA is optional and the tube, once installed, boxes the servos in
  radially). Three 22 mm bodies cannot share one height in the Ø53 bore, so
  they are **Z-staggered**: the two elevator servos sit HIGH (`tail_servo_z`,
  opposite sides — their bodies coexist, reaching past the rim into the
  hollow tube interior on a narrowed tower), the rudder servo sits LOW
  (`tail_rudder_z`, arm swinging just above the motor plate). The pockets
  stand as **columns on the motor plate** with 45°-sloped ceilings, so the
  sleeve prints upright with zero supports. Each wire rakes outboard through
  an **angled wall slot** aligned with its run — elevators down-aft at 42°,
  rudder up-forward at 56°. The outer surface carries nothing but those
  slots and the three fin-socket bosses.
- **Wing (aileron ×2)** — the servo mounts to a dedicated **servo rib**
  (`cad/wing_rib_servo.scad`): an open-bottom bay aft of the rear spar takes
  the body, and the servo's flange seats on the rib's outboard face (CA/
  strapping tape; the rib itself is bonded to spars and skin, so the servo
  reacts against real structure — an earlier spar-clip cradle was dropped
  because printed clips on smooth carbon rod rotate, creep, and pry open
  under wire loads). The servo rib is not an extra station: it **replaces
  the standard rib** at its place in the row. The aileron root starts just
  outboard of it; the arm pokes through a small slot in the **upper** skin
  (low-pressure side) and a short wire links to the aileron's up-turned horn
  just above the wing. A 9 g servo stands ~3 mm proud of the LOWER skin at
  the bay (the aft bay of a 15 %/100 mm section is thinner than the servo) —
  fair it with tape, or use a 5 g servo which fits flush. Rib cable holes
  carry the lead inboard.

## Control surfaces

`cad/control_surface.scad` — one printed part, three sizes (span is a module
parameter): elevator 88, rudder 60, aileron 120 mm; chord 22 mm, tapering
4 → 1.2 mm. The tail fins are shortened by `ctrl_chord + 2` so the surfaces
fill the gap without ever crossing the motor-face plane.

**Tail hinge**: the fin TE and the surface LE both carry a 1.6 × 2.5 mm
groove; a flexible strip (fiber tape folded, or 0.5 mm PP sheet) glues into
both. Printed living hinges crack within dozens of cycles — the strip
doesn't, and it suits the expendable-airframe idea (surfaces survive, tube
doesn't).

**Aileron mounting**: the aileron nests *inside* the wing planform — rib
stations under its span use the TE-cropped rib (`cad/wing_rib_aileron.scad`,
cut at the hinge line + 2 mm), so the surface fills a notch in the TE rather
than hanging behind it. There is no printed wing TE to carry a matching
groove, so the aileron hinges on **plain tape along the top surface**: the
top skin ends at the crop line, tape spans from skin onto the aileron's top
face (the aileron top sits a few mm below the skin surface — the tape
bridges the step; add a second strip on top after checking throw). The 2 mm
crop gap clears the 4 mm LE face swinging under the tape pivot to past
±25°, comfortably over the ±20° target. The aileron's printed LE groove
(shared part with the tail) is simply unused.

## How much throw actually exists

A 9 g servo arm can sweep ~180° total, but only ~±45° of it is usable: past
that the arm approaches parallel with the wire and the linkage goes nonlinear
and finally binds (never program past ~±60°). With the wire on the arm tip
(`servo_horn_r = 10`), `servo_travel_deg = 45`, and a 1:1 control horn
(`ctrl_horn_r = 10`):

| step | value |
|---|---|
| arm tip ±45° × 10 mm | **±7.1 mm** at the wire |
| elevators (high servos): wire raked 42° | × 0.74 → **±31.7°** |
| rudder (low servo): wire raked 56° | × 0.56 → **±23.3°** |
| wing: direct link, no rake | **±45°** aileron |
| targets | elevator ±25°, rudder ±20°, aileron ±20° |
| slot channel needed | 2 × 7.1 + 1.2 wire + 2 margin = 17.3 → **18 mm**, angled with the wire |

The rake factor is the price of keeping the servos inside the tube —
cos(rake) of the wire motion becomes horn motion. The rudder pays the most
because its low, staggered position stretches the radial run, which is fine:
with ailerons fitted the rudder only coordinates turns (hence its ±20°
target). Trim the excess with transmitter endpoints/expo (or ArduPilot
SERVOx limits), which also softens 9 g centering slop. The rudder arm dips
to z≈5 at full ±45° — 1 mm above the motor plate — so never program it past
±40°.

**Prop clearance (pusher):** at neutral the tail surfaces' TE sits 2 mm
forward of the motor face; deflection only rotates the TE *away* from it.
Clearance to the prop disc is therefore set by the motor's own shaft length —
keep ≥5 mm between the motor face and the prop disc, which any 22xx with a
normal prop adapter provides.

## Open items

- The aileron servo's arm slot in the upper foam skin (~4 × 20 mm) is cut at
  build time — mark it from the mount position before skinning.
- Wire ends: Z-bend at the servo arm tip, and a Z-bend or micro linkage
  stopper at the control horn (nothing printed needed).
- Rudder + both elevators use identical geometry; differential/mixing is a
  software (ArduPilot) concern, not a mechanical one.
