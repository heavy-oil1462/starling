// ==============================================================================
//   WING SERVO MOUNT — printed cradle that snap-clips onto BOTH wing spar
//   rods, holding a 9 g aileron servo close to the fuselage tube (inboard),
//   INSIDE the wing: the servo hides under the foam skin and only the
//   pushrod exits through a small slot in the skin — far less drag than a
//   surface-mounted servo.
//
//   Local frame: X = chord (spars at x = 0 and spar_spacing, LE toward +X),
//   Y = span, Z = wing thickness. The servo lies on its side between the
//   spars, shaft toward the TE, so the horn swings in the chord plane and
//   the pushrod runs straight aft to the aileron horn. Zip-tie or glue the
//   servo into the fence; snap the clips onto the rods next to a rib and
//   tack with CA.
// ==============================================================================

include <design_params.scad>

$fn = 60;

plate_t   = 2.5;
clip_w    = 6;      // each clip along the span direction
clip_gap  = 1;      // clip mouth narrowing for snap fit
fence_h   = 6;
fence_t   = 2;

plate_x   = spar_spacing + 16;         // covers both spars + margin
plate_y   = servo_body[0] + 2 * fence_t + 2;

module spar_clip() {
    // C-clip that snaps down onto a spar rod lying along Y
    difference() {
        translate([-4, 0, 0]) cube([8, clip_w, 8]);
        translate([0, -0.1, 5])
            rotate([-90, 0, 0])
                cylinder(h = clip_w + 0.2, d = spar_hole_d);
        // mouth
        translate([-(spar_rod_d - clip_gap) / 2, -0.1, 5])
            cube([spar_rod_d - clip_gap, clip_w + 0.2, 4]);
    }
}

module wing_servo_mount() {
    body_l = servo_body[0] + fit_tol;
    body_w = servo_body[1] + fit_tol;

    // Base plate spanning both spars
    translate([-8, -plate_y / 2, 0])
        cube([plate_x, plate_y, plate_t]);

    // Clips: two per rod, at the plate's span-wise edges
    for (x = [0, spar_spacing])
        for (y = [-plate_y / 2, plate_y / 2 - clip_w])
            translate([x, y, plate_t])
                spar_clip();

    // Servo fence between the spars (servo on its side, shaft toward TE=-X)
    translate([-(body_w + fence_t) + 4, -body_l / 2 - fence_t, plate_t])
        difference() {
            cube([body_w + 2 * fence_t, body_l + 2 * fence_t, fence_h]);
            translate([fence_t, fence_t, -0.1])
                cube([body_w, body_l, fence_h + 0.2]);
        }
}

wing_servo_mount();
