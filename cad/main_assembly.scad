// ==============================================================================
//   VISUAL FIT CHECK — renders to main_assembly.png via scripts/regen_all.py.
//   All placement derives from design_params.scad: sliding the wing for CG
//   trim is a one-number change (wing_station), and the rib row, adapter
//   sockets, and spar rods line up by construction.
//
//   Includes the control system: placeholder 9 g servos (bought part) INSIDE
//   the tail sleeve and inside the wing, wire pushrods out through the wall/
//   skin slots, and the printed control surfaces (elevators, rudder,
//   ailerons). Throw numbers: scripts/throw_check.py.
// ==============================================================================

use <tail.scad>
use <wing_rib.scad>
use <wing_adapter.scad>
use <nose.scad>
use <fuselage.scad>
use <servo_9g.scad>
use <control_surface.scad>
use <wing_servo_mount.scad>
include <design_params.scad>

$fn = 60;

rib_stations = [40, 120, 200, 280, 360, 440]; // spanwise; first = root rib on the tab
spar_length  = 460;

sleeve_r  = (tube_od + sleeve_clearance) / 2 + sleeve_wall;
hinge_z   = ctrl_chord + 2;      // = fin_servo_gap in tail.scad
pushrod_z = hinge_z - 2;

// Paper tube, bottomed out on the tail sleeve's internal rim
color("BurlyWood") translate([0, 0, tail_tube_stop]) fuselage();

// Tail (sleeve + fins + internal servo pads + motor mount) at the origin
color("Tomato") tail_assembly();

// Nose cone over the top of the tube
color("Tomato")
    translate([0, 0, tail_tube_stop + tube_length - nose_sleeve_length])
        cone_housing();

// Wing adapter, clamped at the wing station
color("SteelBlue") translate([0, 0, wing_station]) wing_adapter();

// ------------------------------------------------------------------------------
// Tail controls: one block per surface, rotated to its fin. Servo lies on its
// internal pad (horn on the pushrod plane), the wire runs radially out
// through the wall slot to the horn of the printed control surface.
// ------------------------------------------------------------------------------
tail_control(0,   88);   // right elevator
tail_control(180, 88);   // left elevator
tail_control(90,  60);   // rudder

module tail_control(angle, span) {
    rotate([0, 0, angle]) {
        // servo on its pad, shaft on the pushrod plane
        translate([8.6, 12.7, 5])
            mirror([0, 1, 0])
                servo_9g(horn_angle = 90);
        // wire: servo horn -> through the slot -> control horn
        pushrod([12, -(ctrl_horn_r + 2), pushrod_z],
                [sleeve_r + 12, -ctrl_horn_r, pushrod_z]);
        // printed control surface, hinged in the fin TE groove
        color("Gold")
            translate([sleeve_r - 1 + 10, 0, hinge_z])
                rotate([0, -90, -90])
                    control_surface(span = span, horn_pos = 2);
    }
}

// ------------------------------------------------------------------------------
// Wing: spars + ribs + aileron servo (inboard, clipped to the spars, hidden
// under the skin) driving the outboard aileron through a long wire.
// ------------------------------------------------------------------------------
for (side = [1, -1]) mirror([side < 0 ? 1 : 0, 0, 0]) {
    // spars: two carbon rods, seated on the adapter's socket floors
    color("DimGray")
        for (dz = [adapter_length / 2 - spar_spacing / 2,
                   adapter_length / 2 + spar_spacing / 2])
            translate([(tube_od + sleeve_clearance) / 2 + 1, 0, wing_station + dz])
                rotate([0, 90, 0])
                    cylinder(h = spar_length, d = spar_rod_d);

    // ribs (rib local X maps to global Z via rotate([0,-90,0]); shifting down
    // by spar_y_offset puts the spar holes on the adapter socket axis)
    for (i = [0 : len(rib_stations) - 1])
        color("Gold")
            translate([rib_stations[i], -spar_y_offset, wing_station - rib_chord / 2])
                rotate([0, -90, 0])
                    if (i == 0) wing_rib_root();
                    else        wing_rib_with_cutouts();

    // aileron servo mount clipped onto both spars, close to the tube
    translate([70, -7.5, wing_station + adapter_length / 2 - spar_spacing / 2])
        rotate([0, -90, -90]) {
            color("SteelBlue") wing_servo_mount();
            translate([-4, -11, 2.5])
                rotate([0, -90, 0])
                    servo_9g();
        }

    // aileron at the outboard TE + the long wire from the servo. The wire
    // threads the ribs' cable holes (60% chord, on the chord line) and only
    // drops to the horn after the last rib it crosses.
    color("Gold")
        translate([300, 0, wing_station - rib_chord / 2 + ctrl_chord])
            rotate([0, -90, -90])
                control_surface(span = 120, horn_pos = 2);
    cable_z = wing_station + rib_chord / 2 - 0.6 * rib_chord;  // cable-hole line
    pushrod([77, 0, cable_z - 1], [285, 0, cable_z]);
    pushrod([285, 0, cable_z],
            [302, -ctrl_horn_r, wing_station - rib_chord / 2 + ctrl_chord - 2]);
}
