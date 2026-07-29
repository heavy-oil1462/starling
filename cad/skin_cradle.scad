// SKIN CRADLE — assembly tooling, not part of the airframe. A saddle
// matching the wing's LOWER surface (rib profile offset outward by the
// foam skin) so a panel sits level and does not rock while the top skin
// is glued, the aileron is hinged, or the servo is rigged. Print two and
// space them along the span, one near the root, one near the aileron.
//
// The saddle also fits the bare rib frame before skinning, just slightly
// loose (the skin offset becomes clearance). Short prongs at the TE and
// LE cup the section so the wing cannot slide chordwise.
//
// Print lying on a side face; the profile stands vertical and needs no
// support.

include <design_params.scad>
use <wing_rib.scad>

cradle_width = 30;   // spanwise
cradle_base  = 22;   // material under the lowest point of the section
cradle_lip   = 2;    // how far the TE/LE prongs rise above the chord line
cradle_wall  = 9;    // block beyond the TE and LE points

$fn = 90;

linear_extrude(height = cradle_width)
    difference() {
        translate([-cradle_wall, -cradle_base])
            square([rib_chord + 2 * cradle_wall, cradle_base + cradle_lip]);
        offset(r = skin_thickness + fit_tol)
            rib_profile();
    }
