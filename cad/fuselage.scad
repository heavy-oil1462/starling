// Visual model of the bought paper tube — NOT a printed part (regen_all.py
// deliberately exports no STL for it). Exists so main_assembly.scad can
// show the parts in context.

include <design_params.scad>

module fuselage() {
    difference() {
        cylinder(h = tube_length, r = tube_od / 2);
        // extend the cutter past both ends — coincident faces make the
        // boolean result non-manifold
        translate([0, 0, -0.1])
            cylinder(h = tube_length + 0.2, r = tube_od / 2 - tube_wall);
    }
}

$fn = 100;
fuselage();
