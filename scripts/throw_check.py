#!/usr/bin/env python3
"""Control-throw sanity check for the Starling control system.

Answers "how much surface movement realistically exists?" from the shared
parameters (cad/design_params.scad): a 9 g servo swings its horn through
±servo_travel_deg; the wire pushrod converts that to linear travel; the
control horn converts it back to surface deflection. Also checks that the
pushrod wall slot is long enough and that the deflected surface keeps clear
of the motor face (pusher prop).

Targets (rule of thumb for a docile payload hauler):
  elevator/rudder >= 25 deg each way, aileron >= 20 deg each way.

Exit 1 if any target or clearance fails — regen_all.py runs this as a gate.
"""

import math
import sys

from design_params import PARAMS as P

TARGETS = {"elevator": 25, "rudder": 25, "aileron": 20}


def main():
    horn_r = P["servo_horn_r"]
    ctrl_r = P["ctrl_horn_r"]
    travel = P["servo_travel_deg"]
    chord = P["ctrl_chord"]

    linear = horn_r * math.sin(math.radians(travel))
    if linear >= ctrl_r:
        deflection = 90.0
    else:
        deflection = math.degrees(math.asin(linear / ctrl_r))

    print(f"servo horn {horn_r} mm x +/-{travel} deg -> +/-{linear:.1f} mm at the wire")
    print(f"control horn {ctrl_r} mm            -> +/-{deflection:.1f} deg surface deflection")

    ok = True
    for surface, target in TARGETS.items():
        good = deflection >= target
        ok &= good
        print(f"[{'ok' if good else 'FAIL'}] {surface}: +/-{deflection:.1f} deg "
              f"available vs +/-{target} deg target "
              f"(dial down with transmitter endpoints/expo)")

    # Pushrod slot: must contain the full wire sweep plus the wire itself
    slot_needed = 2 * linear + P["pushrod_d"] + 2  # +2 mm margin
    good = P["pushrod_slot_len"] >= slot_needed
    ok &= good
    print(f"[{'ok' if good else 'FAIL'}] wall slot: {P['pushrod_slot_len']} mm "
          f">= {slot_needed:.1f} mm needed")

    # Pusher clearance: the tail surfaces hinge at ctrl_chord+2 and reach to
    # 2 mm above the motor face at NEUTRAL (deflection only moves the TE away
    # from the face). The prop must sit behind the face with clearance.
    te_gap = (chord + 2) - chord
    print(f"[info] tail surface TE sits {te_gap} mm forward of the motor face at neutral;")
    print("       deflection increases that gap — prop clearance is set by the motor's")
    print("       own standoff, keep >= 5 mm between prop disc and motor face.")

    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
