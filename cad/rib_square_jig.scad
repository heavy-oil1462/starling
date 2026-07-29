// RIB SQUARE JIG — assembly tooling, not part of the airframe. Slides
// along both spar rods next to a rib; its flat face holds the rib
// perpendicular to the rods while the CA sets. Two spar holes give it the
// angular registration a single rib lacks (a thin rib can tilt about the
// line through its own spar holes).
//
// Use: thread the jig onto the rods behind the rib being glued, press the
// rib flush against the jig face, glue, slide the jig to the next station.
// The holes are a slide fit — looser than the calibrated press-in
// spar_hole_d, snug enough that the face stays square.
//
// Print flat on the large face, holes horizontal (they bridge fine at
// this diameter).

include <design_params.scad>

jig_slide_fit = 0.2;             // added to spar_hole_d for the slide fit
jig_thickness = 16;              // along the rods; sets the squareness
jig_margin    = 8;               // material beyond each hole
jig_height    = 14;

$fn = 96;

difference() {
    translate([-spar_spacing / 2 - jig_margin, -jig_height / 2, 0])
        cube([spar_spacing + 2 * jig_margin, jig_height, jig_thickness]);
    for (dx = [-spar_spacing / 2, spar_spacing / 2])
        translate([dx, 0, -1])
            cylinder(h = jig_thickness + 2, d = spar_hole_d + jig_slide_fit);
}
