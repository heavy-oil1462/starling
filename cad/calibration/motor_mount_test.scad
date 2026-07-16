// MOTOR MOUNT TEST — flat plate with the motor screw pattern and shaft
// hole from design_params, to verify against the real motor before
// printing the whole tail.

include <../design_params.scad>

plate_width     = 40;
plate_height    = 40;
plate_thickness = 2;

$fn = 50;

difference() {
    cube([plate_width, plate_height, plate_thickness], center = true);

    // Center shaft hole
    cylinder(h = plate_thickness + 2, d = motor_shaft_hole_d, center = true);

    // Screw pattern — the same "+" layout the tail's motor face uses
    for (p = [[0,  motor_pattern_y / 2],
              [0, -motor_pattern_y / 2],
              [ motor_pattern_x / 2, 0],
              [-motor_pattern_x / 2, 0]])
        translate([p[0], p[1], 0])
            cylinder(h = plate_thickness + 2, d = motor_screw_hole_d, center = true);
}
