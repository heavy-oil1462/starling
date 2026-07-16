// ==============================================================================
//   CONTROL SURFACE — printed flap for elevator, rudder, or aileron.
//
//   Local frame: hinge line = Y axis (span along +Y), chord extends -X (aft),
//   thickness centered on Z. The LE face carries a hinge groove matching the
//   groove in the fin trailing edges (and the wing TE): a flexible strip
//   (fiber tape / 0.5 mm PP) glues into both grooves and is the hinge —
//   printed living hinges crack, this doesn't.
//
//   The control horn is integrated near the root; the pushrod hooks into its
//   hole at ctrl_horn_r from the hinge line. Print flat, horn up, with a dab
//   of support under the horn (or slice horn-side down and accept the seam).
//
//   Default render = elevator (span 88). Other sizes are module parameters —
//   the assembly instantiates rudder (60) and aileron (120) variants.
// ==============================================================================

include <design_params.scad>

$fn = 60;

module control_surface(span = 88, horn_pos = 12, with_horn = true) {
    te_thickness = 1.2;

    difference() {
        union() {
            // Tapered flap: full thickness at the hinge, thin TE
            rotate([90, 0, 0])   // build profile in X-Z, extrude along span
                translate([0, 0, -span])
                    linear_extrude(height = span)
                        polygon([
                            [0,            ctrl_thickness / 2],
                            [0,           -ctrl_thickness / 2],
                            [-ctrl_chord, -te_thickness / 2],
                            [-ctrl_chord,  te_thickness / 2],
                        ]);

            // Control horn: a blade in the X-Z plane, pushrod hole at
            // ctrl_horn_r below the hinge line
            if (with_horn)
                translate([0, horn_pos, 0])
                    horn();
        }

        // Hinge groove along the LE face (mirror of the fin TE groove)
        translate([-hinge_groove_d, -0.1, -hinge_groove_w / 2])
            cube([hinge_groove_d + 0.1, span + 0.2, hinge_groove_w]);
    }
}

module horn() {
    hole_d = pushrod_d + 0.4;
    difference() {
        hull() {
            translate([-8, -1, -ctrl_thickness / 2])
                cube([8, 2, 0.1]);
            translate([-2, 0, -(ctrl_horn_r + 2)])
                rotate([90, 0, 0])
                    cylinder(h = 2, d = 4, center = true);
        }
        translate([-2, 0, -ctrl_horn_r])
            rotate([90, 0, 0])
                cylinder(h = 3, d = hole_d, center = true);
    }
}

control_surface();
