// SERVO MOUNT TEST — flat plate with the 9g servo pocket from
// design_params, to verify the servo footprint and fit_tol before
// printing the whole tail.

include <../design_params.scad>

plate_dims      = [50, 30];
plate_thickness = 5;
flange_thickness = 3;
screw_spacing   = 28;
screw_dia       = 3;
use_screws      = false;

$fn = 100;

servo_mount_plate();

module servo_mount_plate() {
    difference() {
        // 1. The main plate
        cube([plate_dims[0], plate_dims[1], plate_thickness], center = true);

        // 2. Flush pocket for the flange
        translate([0, 0, (plate_thickness / 2) - (flange_thickness / 2)])
            cube([servo_flange[0] + fit_tol,
                  servo_flange[1] + fit_tol,
                  flange_thickness + fit_tol], center = true);

        // 3. Through-hole for the servo body
        cube([servo_body[0] + fit_tol,
              servo_body[1] + fit_tol,
              plate_thickness + 2], center = true);

        if (use_screws)
            for (x_pos = [-screw_spacing / 2, screw_spacing / 2])
                translate([x_pos, 0, 0])
                    cylinder(h = plate_thickness + 2, d = screw_dia, center = true);
    }
}
