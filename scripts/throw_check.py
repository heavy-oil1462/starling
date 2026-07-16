#!/usr/bin/env python3
"""Control-throw sanity check for the Starling control system.

Answers "how much surface movement realistically exists?" from the shared
parameters (cad/design_params.scad).

Linkage model (see docs/control-system.md):
- The wire attaches at the TIP of the full-length servo arm. A 9 g arm can
  sweep ~180 deg total, but the linkage is only near-linear while the arm
  stays within ~+/-45 deg of perpendicular-to-the-wire — that usable window
  is servo_travel_deg.
- Tail: the servo sits high in the sleeve and the wire rakes down/outboard
  at tail_slot_angle off the fuselage axis. The surface horn's eye travels
  along the fuselage axis, so only cos(tail_slot_angle) of the wire motion
  becomes horn motion.
- Wing: the aileron sits directly behind its servo, linked by a short wire
  above the wing — rake ~0, full transfer.

Targets (docile payload hauler): elevator/rudder >= 25 deg, aileron >= 20 deg
each way. Exit 1 on any failure — regen_all.py runs this as a gate.
"""

import math
import sys

from design_params import PARAMS as P


def surface_throw(linear, transfer, horn_r):
    eff = linear * transfer
    if eff >= horn_r:
        return 90.0
    return math.degrees(math.asin(eff / horn_r))


def main():
    horn_r = P["servo_horn_r"]
    ctrl_r = P["ctrl_horn_r"]
    travel = P["servo_travel_deg"]
    rake = P["tail_slot_angle"]

    linear = horn_r * math.sin(math.radians(travel))
    print(f"arm tip: {horn_r} mm x +/-{travel} deg (of ~180 total) -> +/-{linear:.1f} mm at the wire")

    cases = {
        "elevator": (math.cos(math.radians(rake)), 25),
        "rudder":   (math.cos(math.radians(rake)), 25),
        "aileron":  (1.0, 20),
    }
    ok = True
    for surface, (transfer, target) in cases.items():
        deflection = surface_throw(linear, transfer, ctrl_r)
        good = deflection >= target
        ok &= good
        note = f"rake {rake} deg -> x{transfer:.2f}" if transfer < 1 else "direct link"
        print(f"[{'ok' if good else 'FAIL'}] {surface}: +/-{deflection:.1f} deg available "
              f"({note}) vs +/-{target} deg target")

    # Angled slot channel: must contain the wire's along-axis sweep + wire + margin
    slot_needed = 2 * linear + P["pushrod_d"] + 2
    good = P["pushrod_slot_len"] >= slot_needed
    ok &= good
    print(f"[{'ok' if good else 'FAIL'}] slot channel: {P['pushrod_slot_len']} mm "
          f">= {slot_needed:.1f} mm needed")

    print("[info] never program the arm past ~+/-60 deg: near +/-90 the arm goes")
    print("       parallel to the wire and the linkage binds instead of moving.")
    print("[info] tail surface TE sits 2 mm forward of the motor face at neutral;")
    print("       deflection increases that gap — keep >= 5 mm motor face to prop disc.")

    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
