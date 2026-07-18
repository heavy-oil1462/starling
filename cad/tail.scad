// ==============================================================================
//   TAIL — printable as separate support-free parts:
//
//   tail_sleeve()  (this file's STL) — prints UPRIGHT on the motor face, no
//   supports: the internal rim has a 45° chamfer underneath, the servo
//   pockets stand as columns on the motor plate with 45°-sloped pocket
//   ceilings, and the fin sockets are vertical grooves in chamfered bosses.
//
//   tail_fin_horizontal.scad (print 2) / tail_fin_vertical.scad (print 1) —
//   the fins print FLAT on the bed (their strongest orientation: layer
//   lines along the span) with a root tab that glues into the sleeve's
//   fin sockets. One-piece printing was rejected: the fins' straight
//   horizontal trailing edges are full-span overhangs in any upright
//   orientation, and upright fins would snap along layer seams anyway.
//
//   tail_assembly() shows everything together (used by main_assembly.scad).
// ==============================================================================

include <design_params.scad>

// --- Global Resolution ---
$fn = 100; // Smooth curves

// --- Main Fuselage Dimensions ---
fuselage_total_length = 90;            // Total length (Positive Z direction)

// --- Derived Fuselage Values ---
tube_radius         = (tube_od + sleeve_clearance) / 2;
outer_radius        = tube_radius + sleeve_wall;
sleeve_fillet_radius = sleeve_wall;    // Radius of the front lip
motor_mount_solid_length = 4;          // Solid section at rear (starts at Z=0)

// --- Internal Rim (tube stop) ---
// Keeps the paper tube off the servo bay. The rim top (= tail_tube_stop) is
// where the tube bottoms out; main_assembly.scad places the tube from the
// same value. A 45° chamfer under the rim makes it print support-free.
rim_height          = 4;               // Height of the rim (in Z)
rim_thickness       = 2;               // Radial protrusion into the bore
rim_z_position      = tail_tube_stop - rim_height;

// --- Fin Dimensions ---
fin_thickness       = 4;
fin_servo_gap       = ctrl_chord + 2;  // fins end here; control surfaces fill the gap
// TE hinge groove: matches the LE groove of control_surface.scad — a
// flexible strip (fiber tape / 0.5 mm PP) glues into both grooves and IS
// the hinge. Groove size comes from design_params (hinge_groove_w/d).

// --- Fin sockets (fins are separate flat-printed parts) ---
fin_boss_h    = 2.5;                       // socket boss proud of the sleeve
fin_groove_r  = tube_radius + 1;           // groove floor: 1 mm of wall remains
fin_tab_d     = outer_radius + fin_boss_h - fin_groove_r;  // = 4.5 engagement
fin_root_r    = fin_groove_r + fin_tab_d;  // where the aerodynamic root sits

// Vertical Fin (Rudder)
vertical_fin_height = 80;
vertical_fin_root   = fuselage_total_length; // Matches body length
vertical_fin_tip    = 15;
vertical_fin_sweep  = 20;

// Horizontal Fins (Elevators)
horizontal_fin_span = 110;
horizontal_fin_root = fuselage_total_length; // Matches body length
horizontal_fin_tip  = 30;
horizontal_fin_sweep = 5;

// --- Motor Mount (pattern comes from design_params) ---
// NOTE: control surfaces extend aft of the motor face — mount the prop on a
// standoff at least as long as the control-surface chord, or keep the prop
// radius under the fin-root cutout span, so full deflection clears the disc.
motor_wire_hole_dia  = 10;
motor_mount_screw_hole_depth = motor_mount_solid_length + 0.2;

// --- Servo Mounting (INTERNAL, push-fit, Z-STAGGERED) ---
// The servos press into snug pockets, lying on their sides so the output
// shaft points tangentially and the full-length arm swings in the radial/
// axial plane. Three 22 mm bodies cannot share one height in the bore, so
// the ELEVATOR servos sit HIGH (opposite sides; bodies reach past the rim
// into the hollow tube interior, held by a narrow tower that clears the
// tube bore) and the RUDDER servo sits LOW. Each pocket is a COLUMN
// standing on the motor plate — no overhanging undersides — and its
// ceiling slopes at 45°, so the whole sleeve prints support-free. Wires
// attach at the ARM TIPS and exit through ANGLED wall slots raked toward
// the surface horns. Throw and rake numbers: scripts/throw_check.py.

servo_body_length   = servo_body[0];
tol                 = fit_tol;         // Printing tolerance (shared)
epsilon             = 1;               // Cut overlap
pushrod_offset      = ctrl_horn_r;     // pushrod plane, offset from fin centerline

// ==============================================================================
//   MAIN RENDER — the printable sleeve (fins are separate parts)
// ==============================================================================

tail_sleeve();

// ==============================================================================
//   ASSEMBLY MODULES
// ==============================================================================

// Visual: sleeve with all three fins seated in their sockets
module tail_assembly() {
    tail_sleeve();

    // Vertical fin (top)
    translate([0, fin_root_r, fuselage_total_length])
        rotate([0, -90, 0])
            fin_vertical_part();

    // Right + left horizontal fins (same part, mirrored)
    translate([fin_root_r, 0, fuselage_total_length])
        rotate([0, -90, -90])
            fin_horizontal_part();
    mirror([1, 0, 0])
        translate([fin_root_r, 0, fuselage_total_length])
            rotate([0, -90, -90])
                fin_horizontal_part();
}

// The printable sleeve part
module tail_sleeve() {
    difference() {
        union() {
            fuselage_sleeve();
            fin_boss(0);
            fin_boss(90);
            fin_boss(180);
        }

        // Fin socket grooves (open at the top and radially outward)
        fin_groove(0);
        fin_groove(90);
        fin_groove(180);

        // Pushrod slots through the wall, one per control surface. Both
        // elevator linkages live on the BELLY side; the left one is a true
        // MIRROR of the right. Rudder linkage on the right side, raked the
        // other way because its servo sits LOW.
        pushrod_slot(rotation_angle = 0, offset_y = -pushrod_offset);
        mirror([1, 0, 0])
            pushrod_slot(rotation_angle = 0, offset_y = -pushrod_offset);
        pushrod_slot(rotation_angle = 90, offset_y = -pushrod_offset,
                     z_center = tail_rudder_z + 2.4,
                     tilt = -(90 - tail_rudder_slot_angle));
    }
}

// ==============================================================================
//   COMPONENT MODULES
// ==============================================================================

module fuselage_sleeve() {
    // Internal rim (tube stop) with a 45° chamfer underneath so it prints
    // without support — added after the main difference so the bore cut
    // doesn't erase it
    translate([0, 0, rim_z_position])
        difference() {
            cylinder(rim_height, r = tube_radius + 0.5); // buried into the wall
            translate([0, 0, -0.1])
                cylinder(rim_height + 0.2, r = tube_radius - rim_thickness);
        }
    translate([0, 0, rim_z_position - rim_thickness])
        difference() {
            cylinder(rim_thickness, r = tube_radius + 0.5);
            translate([0, 0, -0.1])
                cylinder(rim_thickness + 0.2,
                         r1 = tube_radius, r2 = tube_radius - rim_thickness);
        }

    // Internal push-fit servo pockets (columns standing on the motor
    // plate), one per control surface, matching the slots. The left
    // elevator pocket is the mirror of the right one; the rudder pocket
    // sits LOW so the three servo bodies never share a height.
    servo_pad(rotation_angle = 0, z0 = tail_servo_z);
    mirror([1, 0, 0]) servo_pad(rotation_angle = 0, z0 = tail_servo_z);
    servo_pad(rotation_angle = 90, z0 = tail_rudder_z);

    difference() {
        // --- Solids ---
        union() {
            // Main cylinder (Starts at 0, goes to Length - Fillet)
            cylinder(fuselage_total_length - sleeve_fillet_radius, r = outer_radius);

            // Front Fillet (Torus at the end)
            translate([0, 0, fuselage_total_length - sleeve_fillet_radius])
            rotate_extrude(convexity = 10)
                translate([outer_radius - sleeve_fillet_radius, 0, 0])
                circle(r = sleeve_fillet_radius, $fn=30);

        }

        // --- Cutouts ---
        union() {
            // Main bore (Starts after solid section, goes to end)
            translate([0, 0, motor_mount_solid_length])
            cylinder( (fuselage_total_length - motor_mount_solid_length) + 0.1, r = tube_radius);

            // Motor Shaft (Starts below 0, goes through solid)
            translate([0, 0, -0.1])
            cylinder(motor_mount_solid_length + 0.2, d=motor_shaft_hole_d);

            // Wire Hole
            translate([-10, 10, -0.1])
            cylinder(motor_mount_solid_length + 0.2, d=motor_wire_hole_dia);

            // Motor Mount Screw Pattern (matches calibration/motor_mount_test.scad)
            translate([ 0, motor_pattern_y/2, -0.1 ]) cylinder(motor_mount_screw_hole_depth, d=motor_screw_hole_d);
            translate([ 0, -motor_pattern_y/2, -0.1 ]) cylinder(motor_mount_screw_hole_depth, d=motor_screw_hole_d);
            translate([ motor_pattern_x/2, 0, -0.1 ]) cylinder(motor_mount_screw_hole_depth, d=motor_screw_hole_d);
            translate([ -motor_pattern_x/2, 0, -0.1 ]) cylinder(motor_mount_screw_hole_depth, d=motor_screw_hole_d);
        }
    }
}

// ==============================================================================
//   FIN SOCKETS (on the sleeve) AND FIN PARTS (printed flat, separately)
// ==============================================================================

// External socket boss: a bar along the fin station with a 45° ramp at its
// lower end (hull of the bar and a thin wall-hugging plate below it)
module fin_boss(angle) {
    boss_w = 8;
    rotate([0, 0, angle])
        hull() {
            translate([outer_radius - 0.5, -boss_w / 2, fin_servo_gap])
                cube([fin_boss_h + 0.5, boss_w, fuselage_total_length - fin_servo_gap]);
            translate([outer_radius - 0.5, -boss_w / 2, fin_servo_gap - fin_boss_h])
                cube([0.5, boss_w, fuselage_total_length - fin_servo_gap + fin_boss_h]);
        }
}

// Socket groove: vertical channel through the boss and 1 mm into the wall,
// open at the top and radially outward — the fin tab drops in and glues
module fin_groove(angle) {
    rotate([0, 0, angle])
        translate([fin_groove_r, -(fin_thickness + fit_tol) / 2, fin_servo_gap])
            cube([outer_radius + fin_boss_h - fin_groove_r + 1,
                  fin_thickness + fit_tol,
                  fuselage_total_length - fin_servo_gap + 0.1]);
}

// A fin with its root tab, in the fin's local (flat, print-ready) frame:
// chord along -X, span +Y, thickness Z. The tab extends the root to -Y.
module fin_part(root, tip, span, sweep) {
    construct_fin_with_hinge(root, tip, span, sweep);
    translate([-(root - fin_servo_gap), -fin_tab_d, -fin_thickness / 2])
        cube([root - fin_servo_gap, fin_tab_d + 0.1, fin_thickness]);
}

module fin_horizontal_part() {
    fin_part(horizontal_fin_root, horizontal_fin_tip,
             horizontal_fin_span, horizontal_fin_sweep);
}

module fin_vertical_part() {
    fin_part(vertical_fin_root, vertical_fin_tip,
             vertical_fin_height, vertical_fin_sweep);
}

module construct_fin_with_hinge(root, tip, span, sweep) {
    // --- Hinge groove layout ---
    hinge_cap_length = 10;

    // Two slits with a solid cap in the middle (and at both ends)
    slit_length = (span - hinge_cap_length*3) / 2;
    slit_y_start_bottom = hinge_cap_length;
    slit_y_start_top    = slit_length + hinge_cap_length*2;

    // Hinge groove cutter X-position (at the shortened TE)
    x_pos = -(root - fin_servo_gap) - hinge_groove_d;

    difference() {
        // Base Fin Shape
        fin(
            root - fin_servo_gap,
            tip,
            span,
            sweep,
            fin_thickness
        );

        union() {
            // 1. Bottom Slit Cutter (from Y=0 up to Y=slit_length)
            translate([
                x_pos,
                slit_y_start_bottom - epsilon,
                -hinge_groove_w / 2
            ])
            cube([
                hinge_groove_d + epsilon + 1,
                slit_length + epsilon,
                hinge_groove_w
            ]);

            // 2. Top Slit Cutter (from Y=slit_length + cap up to Y=span)
            translate([
                x_pos,
                slit_y_start_top,
                -hinge_groove_w / 2
            ])
            cube([
                hinge_groove_d + epsilon + 1,
                slit_length + epsilon,
                hinge_groove_w
            ]);
        }
    }
}

module fin(root_chord, tip_chord, span, leading_edge_sweep, thickness) {
    // Calculate tip offset to maintain straight trailing edge
    // Note: Fin is built in local X/Z plane before hulling
    leading_edge_tip_x = -root_chord + tip_chord;

    hull() {
        // Root profile
        fin_airfoil_profile(root_chord, thickness);

        // Tip profile
        translate([leading_edge_tip_x, span, 0])
        fin_airfoil_profile(tip_chord, thickness);
    }
}

module fin_airfoil_profile(chord, thickness) {
    radius = thickness / 2;
    // Main body
    // LE at X=0, TE at X=-chord
    translate([-chord, 0, -radius])
    cube([chord - radius, 0.1, thickness]);

    // Rounded LE
    translate([-radius, 0, 0])
    cylinder(h=0.1, r=radius, $fn=20);
}

// ==============================================================================
//   INTERNAL SERVO MOUNT MODULES
// ==============================================================================

// PUSH-FIT pocket COLUMN: stands on the motor plate (no overhanging
// underside) and rises past the pocket so a top wall retains the servo.
// The servo (side-lying, shaft tangential) presses radially into the
// pocket; the walls grip the outer 6 mm of the body on both Z ends and the
// side away from the shaft, the shaft/arm side stays open so the arm can
// swing, and the pocket CEILING slopes at 45° (hull of the void and a
// taller slab at its inner face) so it prints support-free. Above the tube
// stop the column narrows to a tower that clears the tube's inner bore
// (elevator pockets only reach up there). A drop of CA is optional; the
// installed tube boxes the servos in radially. z0 = servo body bottom.
module servo_pad(rotation_angle = 0, z0 = tail_servo_z) {
    grip = 6;      // radial depth of the pocket walls
    wall = 2.5;
    snug = 0.15;   // press-fit allowance (tighter than fit_tol)

    p_l    = servo_body_length + snug;         // pocket along Z
    p_w    = servo_height + snug;              // pocket tangential
    y0     = -pushrod_offset - 0.5;            // shaft/arm end (open side)
    pad_y1 = y0 + p_w + wall;
    pad_z0 = motor_mount_solid_length - 0.5;   // stands on the motor plate
    pad_top = min(z0 + p_l + grip + 1, 62);
    // Pocket floor sits just inboard of the wall at the pad's widest edge
    floor_x = sqrt(pow(tube_radius, 2) - pow(max(abs(y0), abs(pad_y1)), 2)) - 1;

    rotate([0, 0, rotation_angle])
        difference() {
            // Column: hugs the wall (buried 0.5) below the tube stop, and
            // narrows to a free-standing tower clearing the tube above it
            intersection() {
                translate([floor_x - grip, y0, pad_z0])
                    cube([tube_radius, pad_y1 - y0, pad_top - pad_z0]);
                union() {
                    cylinder(tail_tube_stop, r = tube_radius + 0.5);
                    cylinder(64, r = tube_id / 2 - 1);
                }
            }
            // The pocket: open radially inward and toward the shaft side;
            // its ceiling slopes up at 45° toward the inner face
            hull() {
                translate([floor_x - grip - 0.1, y0 - 5, z0])
                    cube([grip + 0.1, p_w + 5, p_l]);
                translate([floor_x - grip - 0.1, y0 - 5, z0])
                    cube([0.1, p_w + 5, p_l + grip]);
            }
        }
}

// ANGLED slot for the wire pushrod: a channel through the pocket column and
// the wall, aligned with the rod's raked path from the arm tip to the
// control horn. z_center = where the rod crosses the wall; tilt = signed
// rotation of the channel off the fuselage axis (+ = rod runs outboard-AFT
// like the elevators, - = outboard-FORWARD like the low rudder servo's rod).
module pushrod_slot(rotation_angle = 0, offset_y = 0,
                    z_center = tail_servo_z + 6.6, tilt = 90 - tail_slot_angle) {
    rotate([0, 0, rotation_angle])
        translate([tube_radius + 1.5, offset_y, z_center])
            rotate([0, tilt, 0])
                cube([pushrod_slot_len, pushrod_slot_w, 9], center = true);
}
