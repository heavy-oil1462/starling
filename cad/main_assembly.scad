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
include <design_params.scad>

$fn = 60;

// Spanwise rib stations. The first sits just OUTBOARD of the adapter tab tip
// (~44.5) — ribs never overlap the adapter. The servo rib is placed
// separately at wing_servo_station.
rib_stations = [47, 120, 200, 280, 360, 440];
wing_servo_station = 310;
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
// Tail controls: one block per surface. Servos press into their internal
// pockets, Z-STAGGERED — elevators high (arms up-outboard, wires raking
// down-aft), rudder low (arm down-outboard, wire raking up-forward). Every
// wire attaches at the ARM TIP, perpendicular to the wire at neutral.
// Pocket floor sits at r=21.4, so the servo side face is at 21.4 and the
// shaft pivot at r=15.3.
// ------------------------------------------------------------------------------
tail_control(0,  88, tail_servo_z, 233,  [23.3, -(ctrl_horn_r + 0.3), tail_servo_z + 12]);
mirror([1, 0, 0])
    tail_control(0, 88, tail_servo_z, 233, [23.3, -(ctrl_horn_r + 0.3), tail_servo_z + 12]);
tail_control(90, 60, tail_rudder_z, -38, [21.5, -(ctrl_horn_r + 0.3), tail_rudder_z - 1.9]);

module tail_control(angle, span, z0, horn_angle, arm_tip) {
    horn_eye = [sleeve_r + 11, -ctrl_horn_r, hinge_z - 2];

    rotate([0, 0, angle]) {
        // servo in its pocket, shaft end down (aft), arm toward the slot
        translate([9.2, 12.7, z0 + servo_body[0]])
            mirror([0, 0, 1])
                mirror([0, 1, 0])
                    servo_9g(horn_angle = horn_angle);
        // wire: arm tip -> angled slot -> control horn
        pushrod(arm_tip, horn_eye);
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
    for (s = rib_stations)
        color("Gold")
            translate([s, -spar_y_offset, wing_station - rib_chord / 2])
                rotate([0, -90, 0])
                    wing_rib_with_cutouts();

    // servo rib: carries the aileron servo in its open-bottom bay aft of the
    // rear spar; the servo's flange seats on the rib's outboard face, the
    // arm pokes through the upper skin, and the aileron sits directly
    // behind. Rib cable holes carry the servo lead inboard.
    color("Gold")
        translate([wing_servo_station, -spar_y_offset, wing_station - rib_chord / 2])
            rotate([0, -90, 0])
                wing_rib_servo();
    translate([wing_servo_station - 12.5, -8.4, wing_station + 6])
        rotate([180, 0, 90])
            servo_9g(horn_angle = -90);   // arm straight up, ⊥ to the wire

    // aileron at the outboard TE, horn up, short link from the servo arm
    // tip above the wing (horn_pos matches the servo arm plane)
    aileron_hinge_z = wing_station - rib_chord / 2 + ctrl_chord;
    // the servo arm plane sits 9.2 outboard of the rib station (flange seat
    // + boss + horn plate); the aileron horn and wire live on that plane
    color("Gold")
        translate([300, 0, aileron_hinge_z])
            rotate([0, -90, -90])
                control_surface(span = 120, horn_pos = wing_servo_station + 9.2 - 300, horn_up = true);
    pushrod([wing_servo_station + 9.2, 7.7, wing_station - 11],
            [wing_servo_station + 9.2, ctrl_horn_r, aileron_hinge_z - 2]);
}
