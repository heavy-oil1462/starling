// SPAR FIT GAUGE — calibrates spar_hole_d, the printed hole for the 6 mm
// carbon rod. Every rib and both adapter sockets trust this number; print
// the gauge and pick the fit BEFORE printing a full set of ribs.
//
// One print gives three blocks, each with a hole sized for a different
// spar_hole_d and engraved with that number. Push a rod through each: keep
// the one that slides all the way without force but without wobble, then
// put ITS number into spar_hole_d in cad/design_params.scad.
//
// If the best fit is one of the outer blocks the real fit is outside the
// range: move spar_hole_d to that number and reprint to bracket it again.
//
// The blocks are gauge_height thick so the fit is judged over a real
// engagement length (the adapter sockets hold ~15 mm of rod), not over a
// 2 mm rib face. Print holes vertical, as they come.

include <../design_params.scad>

variant_count = 3;
variant_step  = 0.1;   // spar_hole_d difference between neighbouring blocks
gauge_height  = 12;    // fit surface length, close to a socket engagement
block_w       = 20;
label_size    = 4;
label_depth   = 0.6;
block_gap     = 4;

$fn = 96;

function variant_d(i) = spar_hole_d + (i - (variant_count - 1) / 2) * variant_step;

module fit_block(d) {
    difference() {
        translate([-block_w / 2, -block_w / 2])
            cube([block_w, block_w, gauge_height]);
        translate([0, 0, -1])
            cylinder(h = gauge_height + 2, d = d);
        // label on the top face, between the hole and the block edge
        translate([0, -block_w / 2 + 1.5,
                   gauge_height - label_depth])
            linear_extrude(height = label_depth + 1)
                text(str(d), size = label_size, halign = "center",
                     valign = "baseline");
    }
}

for (i = [0 : variant_count - 1])
    translate([(i - (variant_count - 1) / 2) * (block_w + block_gap), 0, 0])
        fit_block(variant_d(i));
