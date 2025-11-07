// ==============================================================================
//   CONFIGURABLE VARIABLES
// ==============================================================================

// --- Global Resolution ---
$fn = 100; // Smooth curves

// --- Main Fuselage Dimensions ---
tube_diameter       = 52.94;           // Inner diameter (fits over the 50mm tube)
wall_thickness      = 3;               // Thickness of the sleeve wall
fuselage_total_length = 90;            // Total length (Positive Z direction)

// --- Derived Fuselage Values ---
tube_radius         = tube_diameter / 2;
outer_radius        = tube_radius + wall_thickness;
sleeve_fillet_radius = wall_thickness; // Radius of the front lip
motor_mount_solid_length = 4;          // Solid section at rear (starts at Z=0)

// --- Internal Rim Dimensions (NEW) ---
rim_z_position      = 50;              // Distance from Z=0 to the bottom of the rim
rim_height          = 4;               // Height of the rim (in Z)
rim_thickness       = 2;               // Thickness of the rim (radial)

// --- Fin Dimensions ---
fin_thickness       = 4;
fin_servo_gap       = 0;               // Gap for control surfaces
fin_inset           = 1;               // Depth fins penetrate into body
hinge_slit_thickness = 1.5;
hinge_slit_depth    = 2;

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

// --- Motor Mount ---
motor_shaft_hole_dia = 10;
motor_wire_hole_dia  = 10;
motor_mount_spacing  = 30;
motor_mount_hole_dia = 4;
motor_mount_screw_hole_depth = motor_mount_solid_length + 0.2;

// --- Servo & Cutout Configuration ---
servo_body_dims_plate   = [23, 12.2]; // [Length Z, Width Tangential]
servo_flange_dims_plate = [32, 12.2];

servo_body_length   = servo_body_dims_plate[0];
servo_body_width    = servo_body_dims_plate[1];
servo_flange_length = servo_flange_dims_plate[0];
servo_flange_width  = servo_flange_dims_plate[1];

tol                 = 0.2;             // Printing tolerance
epsilon             = 1;               // Cut overlap
pushrod_offset      = 6;               // Offset from fin centerline
blister_pad_thickness = 2;             // External protrusion for servo mount
servo_flange_pocket_depth = 2;         // Depth of pocket in wall

// Distance from the Motor Mount Face (Z=0) to the START of the servo bay
servo_dist_from_mount = 0; 
servo_bay_z_start   = motor_mount_solid_length + servo_dist_from_mount;

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
        
        // 1. Right Fin (Rotated 0, offset "down" in Y)
        servo_cutout_pocket(rotation_angle = 0, offset_y = -(pushrod_offset + servo_flange_width));
        
        // 2. Left Fin (Rotated 180, offset "down" relative to fin)
        servo_cutout_pocket(rotation_angle = 180, offset_y = pushrod_offset);

        // 3. Top Fin (Rotated 90, offset "left" relative to fin)
        servo_cutout_pocket(rotation_angle = 90, offset_y = -(pushrod_offset + servo_flange_width));
    }
}

// ==============================================================================
//   COMPONENT MODULES
// ==============================================================================

module fuselage_sleeve() {
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
 
            servo_mount_boss(rotation_angle = 0, offset_y = -(pushrod_offset + servo_flange_width));
            servo_mount_boss(rotation_angle = 180, offset_y = pushrod_offset);
            servo_mount_boss(rotation_angle = 90, offset_y = -(pushrod_offset+servo_flange_width));
        }
        
        // --- Cutouts ---
        union() {
            // Main bore (Starts after solid section, goes to end)
            translate([0, 0, motor_mount_solid_length])
            cylinder( (fuselage_total_length - motor_mount_solid_length) + 0.1, r = tube_radius);
            
            // Motor Shaft (Starts below 0, goes through solid)
            translate([0, 0, -0.1])
            cylinder(motor_mount_solid_length + 0.2, d=motor_shaft_hole_dia);
            
            // Wire Hole
            translate([-10, 10, -0.1])
            cylinder(motor_mount_solid_length + 0.2, d=motor_wire_hole_dia);
            
            // Motor Mount Screw Pattern
            translate([ 0, 19/2, -0.1 ]) cylinder(motor_mount_screw_hole_depth, d=motor_mount_hole_dia);
            translate([ 0, -19/2, -0.1 ]) cylinder(motor_mount_screw_hole_depth, d=motor_mount_hole_dia);
            translate([ 16/2, 0, -0.1 ]) cylinder(motor_mount_screw_hole_depth, d=motor_mount_hole_dia);
            translate([ -16/2, 0, -0.1 ]) cylinder(motor_mount_screw_hole_depth, d=motor_mount_hole_dia);
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
    
    // Hinge Slit Cutter X-position (remains the same)
    x_pos = -(root - fin_servo_gap) - hinge_slit_depth;
    
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
                -hinge_slit_thickness / 2 
            ])
            cube([
                hinge_slit_depth + epsilon + 1, // X-depth
                slit_length + epsilon, // Y-length
                hinge_slit_thickness // Z-thickness
            ]);

            // 2. Top Slit Cutter (from Y=slit_length + cap up to Y=span)
            translate([
                x_pos, 
                slit_y_start_top, // Start Y after the 10mm cap
                -hinge_slit_thickness / 2 
            ])
            cube([
                hinge_slit_depth + epsilon + 1, // X-depth
                slit_length + epsilon, // Y-length
                hinge_slit_thickness // Z-thickness
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
//   SERVO MOUNT MODULES
// ==============================================================================

module servo_mount_boss(rotation_angle = 0, offset_y = 0) {
    frame_width = 4; 
    frame_thickness = 3;
    
    flange_width_tol = servo_flange_width + tol;
    y_start = offset_y;
    y_end = offset_y + flange_width_tol;
    max_tangential_offset = max(abs(y_start), abs(y_end));
    
    min_inner_radius_at_edge = sqrt(max(0, pow(tube_radius, 2) - pow(max_tangential_offset, 2)));
    cutter_start_radius = min_inner_radius_at_edge - epsilon; 

    flange_length_tol = servo_flange_length + tol;
    // Position relative to Z=0
    cutout_z_pos_flange = servo_bay_z_start;
    
    y_pos_pocket = offset_y;

    radial_start_pos = cutter_start_radius - frame_thickness;
    radial_end_pos = outer_radius + blister_pad_thickness;
    radial_depth = radial_end_pos - radial_start_pos;
    
    y_start_pos = y_pos_pocket - frame_width;
    y_width = flange_width_tol + (2 * frame_width);
    
    z_start_pos = cutout_z_pos_flange - frame_width;
    z_length = flange_length_tol + (2 * frame_width);
    
    rotate([0, 0, rotation_angle]) {
        translate([radial_start_pos, y_start_pos, z_start_pos])
        cube([radial_depth, y_width, z_length]);
    }
}

module servo_cutout_pocket(rotation_angle = 0, offset_y = 0) {
    flange_width_tol = servo_flange_width + tol;
    body_width_tol = servo_body_width + tol;
    
    y_start = offset_y;
    y_end = offset_y + flange_width_tol;
    max_tangential_offset = max(abs(y_start), abs(y_end));
    
    min_inner_radius_at_edge = sqrt(max(0, pow(tube_radius, 2) - pow(max_tangential_offset, 2)));
    
    cutter_start_radius = min_inner_radius_at_edge - epsilon;
    cutter_end_radius = outer_radius + blister_pad_thickness + epsilon;
    cutter_radial_depth = cutter_end_radius - cutter_start_radius;

    flange_cutter_radial_depth = (tube_radius + servo_flange_pocket_depth) - cutter_start_radius;

    flange_length_tol = servo_flange_length + tol;
    body_length_tol = servo_body_length + tol;
    
    // Position relative to Z=0
    cutout_z_pos_flange = servo_bay_z_start;
    cutout_z_pos_body = cutout_z_pos_flange + (flange_length_tol - body_length_tol) / 2;
    
    y_pos_pocket = offset_y;
    y_pos_body = offset_y + (flange_width_tol - body_width_tol) / 2;

    rotate([0, 0, rotation_angle]) {
        union() {
            // 1. Flange Pocket (Shallow)
            translate([cutter_start_radius, y_pos_pocket, cutout_z_pos_flange])
            cube([flange_cutter_radial_depth, flange_width_tol, flange_length_tol]);
            
            // 2. Body Hole (Deep)
            translate([cutter_start_radius, y_pos_body, cutout_z_pos_body])
            cube([cutter_radial_depth, body_width_tol, body_length_tol]);
        }
    }
}