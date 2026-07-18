// TUBE FIT RING — measures the tube's OUTSIDE diameter, which every
// sleeve (nose, wing adapter, tail) has to slide over.
//
// One print gives three rings, each bored for a different tube_od and
// engraved with that number. Slide all three onto the tube, keep the one
// that grips without forcing, then put ITS number into tube_od in
// cad/design_params.scad — every sleeve is exported from that value, so
// the whole kit is calibrated by typing in one measurement.
//
// If the best fit is one of the outer rings the real tube is outside the
// range: move tube_od to that number and reprint to bracket it again.
//
// Batch-to-batch variation is expected — recalibrate with each new tube.

include <../design_params.scad>
include <../lib/labels.scad>

variant_count = 3;
variant_step  = 0.4;   // tube_od difference between neighbouring rings
ring_height   = 10;
label_size    = 4;
label_depth   = 0.8;
ring_gap      = 6;     // clear space between rings on the bed

$fn = 128;

// Rings bracket the current tube_od symmetrically.
function variant_od(i) = tube_od + (i - (variant_count - 1) / 2) * variant_step;

module fit_ring(od) {
    // Bore matches what a real sleeve would use, so the ring tests the
    // actual production fit rather than a bare nominal diameter.
    bore_r  = (od + sleeve_clearance) / 2;
    outer_r = bore_r + sleeve_wall;
    difference() {
        cylinder(h = ring_height, r = outer_r);
        translate([0, 0, -1])
            cylinder(h = ring_height + 2, r = bore_r);
        // Engraved outside: on a sleeve the bore is the fit surface, so
        // cutting into the outer wall costs nothing.
        translate([0, 0, ring_height / 2])
            curved_text(str(od), outer_r, label_size, label_depth);
    }
}

pitch = tube_od + variant_count * variant_step + 2 * sleeve_wall + ring_gap;

for (i = [0 : variant_count - 1])
    translate([(i - (variant_count - 1) / 2) * pitch, 0, 0])
        fit_ring(variant_od(i));
