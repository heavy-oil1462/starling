// TUBE BORE GAUGE — measures the tube's INSIDE diameter, which every plug
// (payload adapter, bulkhead) has to fit inside. Separate print from
// tube_fit_ring because the OD does not predict the bore: the paper wall
// is the part that varies between batches.
//
// One print gives three plugs, each sized for a different tube_id and
// engraved with that number. Push all three into the tube, keep the one
// that slides in snugly without crushing the paper, then put ITS number
// into tube_id in cad/design_params.scad.
//
// If the best fit is one of the outer plugs the real bore is outside the
// range: move tube_id to that number and reprint to bracket it again.
//
// Each plug has a collar at the bottom: it stops the plug from vanishing
// down the tube, and it carries the label clear of the fit surface.

include <../design_params.scad>
include <../lib/labels.scad>

variant_count = 3;
variant_step  = 0.4;   // tube_id difference between neighbouring plugs
plug_height   = 10;    // length of the fit surface
collar_height = 5;
collar_extra  = 4;     // collar radius beyond the plug
plug_wall     = 2.5;
label_size    = 4;
label_depth   = 0.8;
plug_gap      = 6;     // clear space between plugs on the bed

$fn = 128;

// Plugs bracket the current tube_id symmetrically.
function variant_id(i) = tube_id + (i - (variant_count - 1) / 2) * variant_step;

module bore_plug(id) {
    // What a real payload adapter would present to the bore.
    plug_r  = (id - plug_clearance) / 2;
    inner_r = plug_r - plug_wall;
    // Collar on the BOTTOM so the step faces inward going up — printed
    // flange-down there is no outward overhang to bridge.
    difference() {
        union() {
            cylinder(h = collar_height, r = plug_r + collar_extra);
            cylinder(h = collar_height + plug_height, r = plug_r);
        }
        translate([0, 0, -1])
            cylinder(h = collar_height + plug_height + 2, r = inner_r);
        // On the collar, never on the plug: the plug's outer wall IS the
        // dimension being measured and must stay untouched.
        translate([0, 0, collar_height / 2])
            curved_text(str(id), plug_r + collar_extra, label_size, label_depth);
    }
}

pitch = tube_id + variant_count * variant_step + 2 * collar_extra + plug_gap;

for (i = [0 : variant_count - 1])
    translate([(i - (variant_count - 1) / 2) * pitch, 0, 0])
        bore_plug(variant_id(i));
