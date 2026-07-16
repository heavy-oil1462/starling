// TUBE FIT RING — 10-minute print to verify tube_od / sleeve_clearance
// before trusting any real sleeve. If the fit is wrong, adjust
// sleeve_clearance (or the measured tube_od) in cad/design_params.scad,
// reprint, repeat — never tune an individual part.

include <../design_params.scad>

test_length = 10;

tube_radius  = (tube_od + sleeve_clearance) / 2;
outer_radius = tube_radius + sleeve_wall;

$fn = 100;

difference() {
    cylinder(h = test_length, r = outer_radius, center = true);
    cylinder(h = test_length + 2, r = tube_radius, center = true);
}
