# Control system — servos, linkages, throw

Design decided 2026-07-16. Numbers below are computed by `scripts/throw_check.py`
from `cad/design_params.scad` (re-run it after changing any horn/travel/slot
parameter — `regen_all.py` runs it as a gate).

## Layout: servos INSIDE, only a slot in the airstream

All five servos are 9 g (SG90-class) and all mount *internally*, with a wire
pushrod exiting through a small slot to the control horn:

- **Tail (elevator ×2, rudder ×1)** — each servo lies on its side on a printed
  locating pad against the inner sleeve wall (glued/taped, installed through
  the open front before the tube goes in; the internal rim keeps the tube off
  the servo bay). The shaft points tangentially, so the horn swings in the
  radial/axial plane and drives the wire radially out through a
  2.5 × 18 mm wall slot to the surface horn. The outer surface carries
  nothing but that slot — the previous design had a flange pocket, blister
  pad, and exposed horn+rod on the outside of a Ø59 mm body; this removes
  all of it.
- **Wing (aileron ×2)** — a printed cradle (`cad/wing_servo_mount.scad`)
  snap-clips onto both carbon spars close to the fuselage (heavy bits stay
  near the CG, and servo lead stays short). The servo hides inside the wing
  under the foam skin; the long wire runs outboard to the aileron, threading
  the ribs' 6 mm cable holes, and exits through a small slot in the skin at
  the aileron horn. Only the last ~20 mm of wire and the horn see airflow.

## Control surfaces

`cad/control_surface.scad` — one printed part, three sizes (span is a module
parameter): elevator 88, rudder 60, aileron 120 mm; chord 22 mm, tapering
4 → 1.2 mm. The tail fins are shortened by `ctrl_chord + 2` so the surfaces
fill the gap without ever crossing the motor-face plane.

**Hinge**: the fin TE and the surface LE both carry a 1.6 × 2.5 mm groove;
a flexible strip (fiber tape folded, or 0.5 mm PP sheet) glues into both.
Printed living hinges crack within dozens of cycles — the strip doesn't, and
it suits the expendable-airframe idea (surfaces survive, tube doesn't).

## How much throw actually exists

With `servo_horn_r = 10`, `servo_travel_deg = 40`, `ctrl_horn_r = 8`:

| step | value |
|---|---|
| servo horn ±40° × 10 mm | **±6.4 mm** linear at the wire |
| ÷ 8 mm control horn | **±53°** mechanical surface deflection |
| targets | elevator/rudder ±25°, aileron ±20° |
| wall slot needed | 2 × 6.4 + 1.2 wire + 2 margin = 15.1 → **18 mm** in the wall |

So the mechanics give roughly **twice the needed throw** — that's intentional:
run ~50–60 % endpoints/rates in the transmitter (or ArduPilot SERVOx trims),
which also softens 9 g-servo centering slop. If a surface ever needs more
authority, move the wire inward on the servo horn, not outward on the control
horn (keeps slot length inside 18 mm).

**Prop clearance (pusher):** at neutral the tail surfaces' TE sits 2 mm
forward of the motor face; deflection only rotates the TE *away* from it.
Clearance to the prop disc is therefore set by the motor's own shaft length —
keep ≥5 mm between the motor face and the prop disc, which any 22xx with a
normal prop adapter provides.

## Open items

- The rib cable hole doubles as the aileron-wire guide; if the wire buzzes,
  add a printed guide clip on a spar mid-span.
- Wire ends: Z-bend at the servo horn, and a Z-bend or micro linkage stopper
  at the control horn (nothing printed needed).
- Rudder + both elevators use identical geometry; differential/mixing is a
  software (ArduPilot) concern, not a mechanical one.
