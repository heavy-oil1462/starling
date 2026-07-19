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
use <wing_adapter_glue.scad>
use <nose.scad>
use <fuselage.scad>
use <servo_9g.scad>
use <control_surface.scad>
include <design_params.scad>

$fn = 60;

// Spanwise rib row. The first station sits just OUTBOARD of the adapter tab
// tip (~44.5) — ribs never overlap the adapter. One row, no doubling-up:
// the servo rib REPLACES the standard rib at its station, stations inside
// the aileron span take the TE-cropped rib, and the outermost station is
// the tip rib (blind sockets — the spars are cut to end inside it).
rib_stations         = [47, 120, 200];  // full-chord standard ribs
aileron_rib_stations = [360];           // TE-cropped ribs under the aileron
wing_servo_station   = 280;             // servo rib, in place of a row rib
tip_station          = 440;             // tip rib INBOARD face
aileron_span         = 120;
spar_x_start = (tube_od + sleeve_clearance) / 2 + 1;
spar_length  = tip_station + tip_spar_socket - spar_x_start;

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

// Wing adapter at the wing station — the glue-on flight variant is shown
// (this is what a finished airframe flies); the clamping trim rig is
// identical plus the belly lugs
color("SteelBlue") translate([0, 0, wing_station]) wing_adapter_glue();

// ------------------------------------------------------------------------------
// Tail controls: one block per surface. Servos press into their internal
// pockets, Z-STAGGERED — elevators high (arms up-outboard, wires raking
// down-aft), rudder low (arm down-outboard, wire raking up-forward). Every
// wire attaches at the ARM TIP, perpendicular to the wire at neutral.
// Pocket floor sits at r=21.4, so the servo side face is at 21.4 and the
// shaft pivot at r=15.3.
// ------------------------------------------------------------------------------
// (fin roots now sit on the socket bosses, 2.5 outboard of the sleeve)
fin_root = sleeve_r + 2.5;

tail_control(0,  88, tail_servo_z, 229,  [22.7, -(ctrl_horn_r + 0.3), tail_servo_z + 12.4]);
mirror([1, 0, 0])
    tail_control(0, 88, tail_servo_z, 229, [22.7, -(ctrl_horn_r + 0.3), tail_servo_z + 12.4]);
tail_control(90, 60, tail_rudder_z, -34, [20.8, -(ctrl_horn_r + 0.3), tail_rudder_z - 2.3]);

module tail_control(angle, span, z0, horn_angle, arm_tip) {
    horn_eye = [fin_root + 12, -ctrl_horn_r, hinge_z - 2];

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
            translate([fin_root + 10, 0, hinge_z])
                rotate([0, -90, -90])
                    control_surface(span = span, horn_pos = 2);
    }
}

// ------------------------------------------------------------------------------
// Wing: spars + ribs + aileron servo (inboard, clipped to the spars, hidden
// under the skin) driving the outboard aileron through a long wire.
// ------------------------------------------------------------------------------
for (side = [1, -1]) mirror([side < 0 ? 1 : 0, 0, 0]) {
    // spars: two carbon rods, seated on the adapter's socket floors, cut so
    // they end inside the tip rib's blind sockets
    color("DimGray")
        for (dz = [adapter_length / 2 - spar_spacing / 2,
                   adapter_length / 2 + spar_spacing / 2])
            translate([spar_x_start, 0, wing_station + dz])
                rotate([0, 90, 0])
                    cylinder(h = spar_length, d = spar_rod_d);

    // ribs (rib local X maps to global Z via rotate([0,-90,0]); shifting down
    // by spar_y_offset puts the spar holes on the adapter socket axis)
    for (s = rib_stations)
        color("Gold")
            translate([s, -spar_y_offset, wing_station - rib_chord / 2])
                rotate([0, -90, 0])
                    wing_rib_with_cutouts();

    for (s = aileron_rib_stations)
        color("Gold")
            translate([s, -spar_y_offset, wing_station - rib_chord / 2])
                rotate([0, -90, 0])
                    wing_rib_aileron();

    // tip rib: inboard face at tip_station, rounded cap growing outboard
    // (mirror flips its +z extrusion to global +x)
    color("Gold")
        translate([tip_station, -spar_y_offset, wing_station - rib_chord / 2])
            rotate([0, -90, 0])
                mirror([0, 0, 1])
                    wing_rib_tip();

    // servo rib: carries the aileron servo in its open-bottom bay aft of the
    // rear spar; the servo's flange seats on the rib's outboard face, the
    // arm pokes through the upper skin, and the aileron root starts just
    // outboard of it. Rib cable holes carry the servo lead inboard.
    color("Gold")
        translate([wing_servo_station, -spar_y_offset, wing_station - rib_chord / 2])
            rotate([0, -90, 0])
                wing_rib_servo();
    translate([wing_servo_station - 12.5, -8.4, wing_station + 6])
        rotate([180, 0, 90])
            servo_9g(horn_angle = -90);   // arm straight up, ⊥ to the wire

    // aileron nested into the TE, root 1 mm outboard of the servo rib face
    // (rib is 4 thick, centered on its station), horn up, short link from
    // the servo arm tip above the wing. Taped to the top skin — see
    // docs/control-system.md.
    aileron_root    = wing_servo_station + 3;
    aileron_hinge_z = wing_station - rib_chord / 2 + ctrl_chord;
    // the servo arm plane sits 9.2 outboard of the rib station (flange seat
    // + boss + horn plate); the aileron horn and wire live on that plane
    color("Gold")
        translate([aileron_root, 0, aileron_hinge_z])
            rotate([0, -90, -90])
                control_surface(span = aileron_span,
                                horn_pos = wing_servo_station + 9.2 - aileron_root,
                                horn_up = true);
    pushrod([wing_servo_station + 9.2, 7.7, wing_station - 11],
            [wing_servo_station + 9.2, ctrl_horn_r, aileron_hinge_z - 2]);
}
