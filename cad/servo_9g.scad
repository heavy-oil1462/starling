// PLACEHOLDER MODELS of bought parts — a 9 g (SG90-class) servo and a
// piano-wire pushrod. Visual stand-ins for assembly/fit checks only;
// regen_all.py exports no STL for this file.
//
// servo_9g() local frame: body length along Z, width along Y, mounted face
// down at x=0 growing +X (radial when placed against the tube wall from
// inside); output shaft axis along Y ("side-lying" mount) so the horn
// swings in the X-Z plane — pushrod travel along Z.

include <design_params.scad>

module servo_9g(horn_angle = 0) {
    body_l = servo_body[0];
    body_w = servo_body[1];

    color("DarkSlateGray") {
        // Body (lying on its side: height along Y)
        translate([0, 0, 0])
            cube([16, servo_height - 5, body_l]);
        // Mounting flange (sticks out along Z at the shaft end)
        translate([4, 0, -(servo_flange[0] - body_l) / 2])
            cube([2.5, servo_height - 5, servo_flange[0]]);
        // Shaft boss + shaft (axis along Y)
        translate([8, servo_height - 5, body_l - 6])
            rotate([-90, 0, 0])
                cylinder(h = 5, d = 11, $fn = 24);
    }
    // Horn (swings in the X-Z plane)
    color("White")
        translate([8, servo_height + 0.5, body_l - 6])
            rotate([90, 0, 0])
                rotate([0, 0, horn_angle])
                    hull() {
                        cylinder(h = 1.6, d = 6, $fn = 16);
                        translate([0, servo_horn_r, 0])
                            cylinder(h = 1.6, d = 3, $fn = 16);
                    }
}

// Straight pushrod between two points (visual)
module pushrod(from, to) {
    color("Silver")
        hull() {
            translate(from) sphere(d = pushrod_d, $fn = 12);
            translate(to)   sphere(d = pushrod_d, $fn = 12);
        }
}

servo_9g();
