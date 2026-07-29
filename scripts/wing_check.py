#!/usr/bin/env python3
"""Wing span-layout sanity check for Starling.

The span layout in cad/design_params.scad is a set of literals (the parser
cannot evaluate expressions), so the relationships between them live here:
resize the wing by editing the literals, then make this gate pass. Exit 1
on any failure — regen_all.py runs this as a gate.

Checks:
- Spar fit: one carbon rod of spar_rod_len per spar per side must drop into
  the cavity between the adapter socket floor and the tip rib's blind
  socket floor with play, while keeping real engagement at BOTH ends. The
  cavity depends on tube_od, which is measured per batch — a new tube batch
  can legitimately trip this check; that means the rods no longer fit and
  spar_rod_len (or tip_station) must be re-sized, not the check loosened.
- Station order: ribs ascend, clear the adapter tab, and sit outside the
  aileron span; aileron ribs sit inside it; the aileron clears the tip.
- Aileron root: aileron_root_station must equal wing_servo_station +
  servo_rib_thickness/2 + 1 (the 1 mm gap the assembly is drawn with).
- Servo arm slot: the skin slot swept by the arm tip (see wing_skin.scad)
  must clear the aileron TE notch and the rear spar line.
"""

import math
import sys

from design_params import PARAMS as P


def check(ok, label, detail):
    print(f"[{'ok' if ok else 'FAIL'}] {label}: {detail}")
    return ok


def main():
    ok = True

    # --- Spar fit window -------------------------------------------------
    spar_x_start = (P["tube_od"] + P["sleeve_clearance"]) / 2 + P["spar_socket_lift"]
    tab_tip_x = (P["tube_od"] + P["sleeve_clearance"]) / 2 + P["sleeve_wall"] + P["wing_tab_span"]
    cavity = P["tip_station"] + P["tip_spar_socket"] - spar_x_start
    rod = P["spar_rod_len"]
    play = cavity - rod
    tip_engage = rod - (P["tip_station"] - spar_x_start)       # rod bottomed inboard
    adapter_engage = tab_tip_x - (P["tip_station"] + P["tip_spar_socket"] - rod)  # bottomed outboard

    print(f"spar cavity: {cavity:.1f} mm (adapter socket floor at {spar_x_start:.1f} "
          f"to tip socket floor; tube_od is measured per batch)")
    ok &= check(play >= 1, "spar rod fit",
                f"{rod} mm rod leaves {play:.1f} mm play (need >= 1)")
    ok &= check(tip_engage >= 2, "tip socket engagement",
                f"{tip_engage:.1f} mm with the rod bottomed inboard (need >= 2)")
    ok &= check(adapter_engage >= 5, "adapter socket engagement",
                f"{adapter_engage:.1f} mm with the rod bottomed outboard (need >= 5)")

    # --- Station layout --------------------------------------------------
    ribs = P["rib_stations"]
    ail_ribs = P["aileron_rib_stations"]
    servo = P["wing_servo_station"]
    ail_root = P["aileron_root_station"]
    ail_end = ail_root + P["aileron_span"]
    tip = P["tip_station"]

    stations = ribs + [servo] + ail_ribs + [tip]
    ok &= check(stations == sorted(stations) and len(set(stations)) == len(stations),
                "station order",
                f"ribs {ribs} < servo {servo} < aileron ribs {ail_ribs} < tip {tip}")
    ok &= check(stations[0] > tab_tip_x + 1, "adapter clearance",
                f"first rib at {stations[0]} vs tab tip at {tab_tip_x:.1f} (need > +1)")

    want_root = servo + P["servo_rib_thickness"] / 2 + 1
    ok &= check(math.isclose(ail_root, want_root), "aileron root",
                f"{ail_root} (must be servo station + rib half + 1 = {want_root:g})")
    ok &= check(all(ail_root < s < ail_end for s in ail_ribs), "aileron ribs",
                f"{ail_ribs} inside the aileron span ({ail_root}..{ail_end})")
    ok &= check(all(not (ail_root <= s <= ail_end) for s in ribs + [servo]),
                "full-chord ribs", f"none inside the aileron span ({ail_root}..{ail_end})")
    ok &= check(ail_end + 1 <= tip, "aileron tip clearance",
                f"aileron ends at {ail_end}, tip rib at {tip} (need >= 1 mm)")

    # --- Servo arm slot in the upper skin --------------------------------
    half = (P["servo_horn_r"] * math.sin(math.radians(P["servo_travel_deg"]))
            + P["pushrod_d"] / 2 + 1)
    slot_lo = P["aileron_arm_x_te"] - half
    slot_hi = P["aileron_arm_x_te"] + half
    notch = P["ctrl_chord"] + P["aileron_te_gap"]
    rear_spar = P["rib_chord"] * (1 - P["spar_x_pos"])

    print(f"arm slot (from TE): {slot_lo:.1f}..{slot_hi:.1f} mm, "
          f"{2 * half:.1f} mm long")
    ok &= check(slot_lo >= notch + 2, "slot vs aileron notch",
                f"slot starts {slot_lo:.1f} vs notch depth {notch} (need >= +2)")
    ok &= check(slot_hi <= rear_spar - 2, "slot vs rear spar",
                f"slot ends {slot_hi:.1f} vs spar line {rear_spar:g} (need <= -2)")

    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
