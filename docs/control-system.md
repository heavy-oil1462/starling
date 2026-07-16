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

- **Tail (elevator ×2, rudder ×1)** — each servo lies on its side on a printed
  locating pad against the inner sleeve wall (glued/taped, installed through
  the open front before the tube goes in; the pads end below the internal
  rim, so the tube never touches them). The servos mount HIGH in the sleeve
  (`tail_servo_z`), shaft tangential, and the wire rakes down and outboard
  at `tail_slot_angle` (42°) through an **angled wall slot** to the surface
  horn — the slot channel is aligned with the wire so it exits at the
  correct angle toward the control surface. The outer surface carries
  nothing but that slot — the previous design had a flange pocket, blister
  pad, and exposed horn+rod on the outside of a Ø59 mm body; this removes
  all of it.
- **Wing (aileron ×2)** — a printed cradle (`cad/wing_servo_mount.scad`)
  snap-clips onto both carbon spars, positioned so the aileron sits
  **directly behind the servo**. The servo hides inside the wing under the
  foam skin; only its arm pokes through a small slot in the **upper** skin
  (the low-pressure side — the high-pressure lower surface stays clean),
  and a short wire links it to the aileron's up-turned horn just above the
  wing. The rib cable holes carry the servo lead inboard to the fuselage.

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

A 9 g servo arm can sweep ~180° total, but only ~±45° of it is usable: past
that the arm approaches parallel with the wire and the linkage goes nonlinear
and finally binds (never program past ~±60°). With the wire on the arm tip
(`servo_horn_r = 10`), `servo_travel_deg = 45`, and a 1:1 control horn
(`ctrl_horn_r = 10`):

| step | value |
|---|---|
| arm tip ±45° × 10 mm | **±7.1 mm** at the wire |
| tail: wire raked 42° off the horn's travel direction | × 0.74 → **±31.7°** elevator/rudder |
| wing: direct link, no rake | **±45°** aileron |
| targets | elevator/rudder ±25°, aileron ±20° |
| slot channel needed | 2 × 7.1 + 1.2 wire + 2 margin = 17.3 → **18 mm**, angled with the wire |

The rake factor is the price of keeping the tail servos inside the tube —
cos(42°) of the wire motion becomes horn motion — and the margins still
clear the targets. Trim the excess with transmitter endpoints/expo (or
ArduPilot SERVOx limits), which also softens 9 g centering slop. If a
surface ever needs more authority, enlarge the *control* horn only as a
last resort (it grows the exposed horn); first reduce the rake by moving
the servo higher (`tail_servo_z`).

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
