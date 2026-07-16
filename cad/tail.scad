// ==============================================================================
//   CONFIGURABLE VARIABLES
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
// Keeps the paper tube off the servo bay (pads end just below the rim).
// The rim top (= tail_tube_stop) is where the tube bottoms out;
// main_assembly.scad places the tube from the same value.
rim_height          = 4;               // Height of the rim (in Z)
rim_thickness       = 2;               // Radial protrusion into the bore
rim_z_position      = tail_tube_stop - rim_height;

// --- Fin Dimensions ---
fin_thickness       = 4;
fin_servo_gap       = ctrl_chord + 2;  // fins end here; control surfaces fill the gap
fin_inset           = 1;               // Depth fins penetrate into body
// TE hinge groove: matches the LE groove of control_surface.scad — a
// flexible strip (fiber tape / 0.5 mm PP) glues into both grooves and IS
// the hinge. NOT a printed living hinge — those crack within dozens of
// cycles. Groove size comes from design_params (hinge_groove_w/d).

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

// --- Servo Mounting (INTERNAL — servos live HIGH inside the sleeve) ---
// The servos sit against the inner wall on shallow locating pads, lying on
// their sides so the output shaft points tangentially and the full-length
// arm swings in the radial/axial plane. They mount high (shaft end at
// tail_servo_z, body up toward the rim) so the wire, attached at the ARM
// TIP, rakes down and outboard at ~tail_slot_angle through an ANGLED wall
// slot to the control-surface horn — the arm is perpendicular to the wire
// at neutral, and nothing but a 2.5 mm slot disturbs the outer surface.
// Install through the open front end before the tube goes in (the tube
// stops at the internal rim; the pads end below it).
// Throw and rake numbers: scripts/throw_check.py.

servo_body_length   = servo_body[0];
tol                 = fit_tol;         // Printing tolerance (shared)
epsilon             = 1;               // Cut overlap
pushrod_offset      = ctrl_horn_r;     // pushrod plane, offset from fin centerline

// ==============================================================================
//   MAIN RENDER
// ==============================================================================

tail_assembly();

// ==============================================================================
//   ASSEMBLY MODULES
// ==============================================================================

module tail_assembly() {
    difference() {
        union() {
            // 1. Main Body Sleeve
            fuselage_sleeve();
            
            // 2. Vertical Fin (Top)
            // Move to Z = Length, Rotate 90 on Y to point TE back to 0
            translate([0, outer_radius - fin_inset, fuselage_total_length])
            rotate([0, -90, 0])
            construct_fin_with_hinge(
                vertical_fin_root, 
                vertical_fin_tip, 
                vertical_fin_height, 
                vertical_fin_sweep
            );
            
            // 3. Right Fin (Horizontal)
            translate([outer_radius - fin_inset, 0, fuselage_total_length])
            rotate([0, -90, -90])
            construct_fin_with_hinge(
                horizontal_fin_root, 
                horizontal_fin_tip, 
                horizontal_fin_span, 
                horizontal_fin_sweep
            );
                  
            // 4. Left Fin (Horizontal - Mirrored)
            mirror([1, 0, 0]) {
                translate([outer_radius - fin_inset, 0, fuselage_total_length])
                rotate([0, -90, -90])
                construct_fin_with_hinge(
                    horizontal_fin_root, 
                    horizontal_fin_tip, 
                    horizontal_fin_span, 
                    horizontal_fin_sweep
                );
            }
        }
        
        // Pushrod slots through the wall, one per control surface. The
        // horizontal-fin rods run on the belly side, the rudder rod on the
        // right side — mirrors where the surface horns hang.
        pushrod_slot(rotation_angle = 0,   offset_y = -pushrod_offset);
        pushrod_slot(rotation_angle = 180, offset_y = pushrod_offset);
        pushrod_slot(rotation_angle = 90,  offset_y = -pushrod_offset);
    }
}

// ==============================================================================
//   COMPONENT MODULES
// ==============================================================================

module fuselage_sleeve() {
    // Internal rim (tube stop) — added after the main difference so the
    // bore cut doesn't erase it
    translate([0, 0, rim_z_position])
        difference() {
            cylinder(rim_height, r = tube_radius + 0.5); // buried into the wall
            translate([0, 0, -0.1])
                cylinder(rim_height + 0.2, r = tube_radius - rim_thickness);
        }

    // Internal servo locating pads (also after the difference — they live
    // inside the bore), one per control surface, same angles as the slots
    servo_pad(rotation_angle = 0);
    servo_pad(rotation_angle = 180);
    servo_pad(rotation_angle = 90);

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


module construct_fin_with_hinge(root, tip, span, sweep) {
    // --- New Hinge Variables ---
    hinge_cap_length = 10;
    
    // Calculate the length of the new, shortened slits.
    // The total length of the span to be cut is roughly 'span'. We split this into two cuts 
    // and reserve the cap length in the middle.
    slit_length = (span - hinge_cap_length*3) / 2;
    
    // Y-start positions for the two slits:
    // 1. Bottom Slit starts at Y=0 (the fin root).
    // 2. Top Slit starts immediately after the 10mm cap.
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
                slit_y_start_bottom - epsilon, // -epsilon ensures the cut starts before the fin material
                -hinge_groove_w / 2 
            ])
            cube([
                hinge_groove_d + epsilon + 1, // X-depth
                slit_length + epsilon, // Y-length
                hinge_groove_w // Z-thickness
            ]);

            // 2. Top Slit Cutter (from Y=slit_length + cap up to Y=span)
            translate([
                x_pos, 
                slit_y_start_top, // Start Y after the 10mm cap
                -hinge_groove_w / 2 
            ])
            cube([
                hinge_groove_d + epsilon + 1, // X-depth
                slit_length + epsilon, // Y-length
                hinge_groove_w // Z-thickness
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

// Shallow pad against the inner wall with a locating recess for the servo's
// side face (servo lies on its side, shaft tangential, glued/taped in). The
// recess is placed so the horn plane lands on the pushrod plane (offset
// -pushrod_offset from the fin centerline in this rotated frame).
module servo_pad(rotation_angle = 0) {
    recess_y0 = -pushrod_offset - 0.5;                    // arm side
    recess_w  = servo_height + tol;
    pad_y0    = recess_y0 - 3;
    pad_y1    = recess_y0 + recess_w + 3;
    pad_z0    = tail_servo_z - 3;
    pad_l     = tail_tube_stop - pad_z0;   // capped below the tube stop
    // Flat mounting face, inboard of the wall at the pad's widest edge
    face_x    = sqrt(pow(tube_radius, 2) - pow(max(abs(pad_y0), abs(pad_y1)), 2)) - 0.5;

    rotate([0, 0, rotation_angle])
        difference() {
            // Solid between the flat face and the bore wall (buried 0.5)
            intersection() {
                translate([face_x, pad_y0, pad_z0])
                    cube([tube_radius, pad_y1 - pad_y0, pad_l]);
                translate([0, 0, pad_z0])
                    cylinder(pad_l, r = tube_radius + 0.5);
            }
            // Locating recess = servo side profile, 1.2 deep
            translate([face_x - 0.1, recess_y0, tail_servo_z])
                cube([1.3, recess_w, servo_body_length + tol]);
        }
}

// ANGLED slot for the wire pushrod: a channel through the pad and the wall,
// aligned with the rod's raked path (tail_slot_angle off the fuselage axis)
// from the arm tip down/outboard to the control horn. Channel length =
// pushrod_slot_len; the extra Z-height gives the wire room to sweep.
module pushrod_slot(rotation_angle = 0, offset_y = 0) {
    rotate([0, 0, rotation_angle])
        translate([tube_radius + 1.5, offset_y, tail_servo_z + 6])
            rotate([0, 90 - tail_slot_angle, 0])
                cube([pushrod_slot_len, pushrod_slot_w, 9], center = true);
}
