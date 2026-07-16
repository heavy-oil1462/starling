// --- Variables ---
tube_diameter = 50;
tube_radius = tube_diameter / 2;
adapter_length = 15;     // How far it plugs into the paper tube (USER REQ 2)
wall_thickness = 6;      // Wall thickness of the plug
tube_wall_thickness = 2; // NEW: Thickness of the paper fuselage tube
fin_thickness = 5;       // Thickness of all fins
fin_servo_gap = 0;       // Gap at the back of the fin for control surfaces
fin_inset = 1;           // NEW: How far fins are inset into the body for a good join

// Motor Mount
// motor_mount_plate_thickness will be set after fins are defined
motor_shaft_hole_dia = 15;       // Center hole for motor shaft/wires
motor_mount_spacing = 43;        // 'X' pattern spacing for motor screws (common for 50mm class)
motor_mount_hole_dia = 3;        // Motor screw hole diameter
motor_mount_screw_hole_depth = 10; // How deep to make the screw holes from the back

// Vertical Fin (Rudder)
vertical_fin_height = 80;
vertical_fin_root_chord = 90; // Length at the base
vertical_fin_tip_chord = 30;  // Length at the top
vertical_fin_leading_sweep = 20; // How far back the tip's leading edge is (positive = swept back)

// Horizontal Fins (Elevators)
horizontal_fin_span = 120; // Span from fuselage center to tip
horizontal_fin_root_chord = 90;
horizontal_fin_tip_chord = 30;
horizontal_fin_leading_sweep = 5;

// Set external body length based on the longest fin (USER REQ 1)
motor_mount_plate_thickness = max(vertical_fin_root_chord, horizontal_fin_root_chord);


// --- Module Definitions ---

// Module for the main hollow tube and motor mount
module fuselage_plug() {
    difference() {
        // --- 1. Main solid plug and motor mount plate ---
        union() {
            // Main plug cylinder (goes forward into the tube)
            // MODIFIED: Radius is reduced to fit *inside* the paper tube
            cylinder(adapter_length, r=tube_radius - tube_wall_thickness);
            
            // Motor mount plate / Fin Body (sits at the back, z=0)
            // This remains at full radius to be flush with tube OD
            translate([0, 0, -motor_mount_plate_thickness])
            cylinder(motor_mount_plate_thickness, r=tube_radius);
        }
        
        // --- 2. Cutouts ---
        union() {
            // --- NEW: Hollow cutout for the adapter plug (z >= 0) ---
            // This part plugs into the tube.
            cylinder(adapter_length + 0.1, r = (tube_radius - tube_wall_thickness) - wall_thickness); 
            
            // --- NEW: Hollow cutout for the fin body (z < 0) ---
            // This part is flush with the tube OD.
            translate([0, 0, -motor_mount_plate_thickness - 0.1]) 
            cylinder(motor_mount_plate_thickness + 0.2, r = tube_radius - wall_thickness);
            
            // Motor shaft hole (goes all the way through for wires)
            translate([0, 0, -motor_mount_plate_thickness - 0.1])
            cylinder(adapter_length + motor_mount_plate_thickness + 0.2, d=motor_shaft_hole_dia);
            
            // Motor mount screw holes (in a 45-degree 'X' pattern)
            for (angle = [45, 135, 225, 315]) {
                translate([
                    cos(angle) * (motor_mount_spacing / 2),
                    sin(angle) * (motor_mount_spacing / 2),
                    -motor_mount_plate_thickness - 0.1 // Cut from the back plate
                ])
                // Cut only to a shallow depth
                cylinder(motor_mount_screw_hole_depth, d=motor_mount_hole_dia);
            }
        }
    }
}

// --- NEW: FIN MODULES WITH ROUNDED LEADING EDGE ---

// This sub-module creates the 2D "airfoil" profile in the XZ plane
// It will be hulled along the Y-axis (span)
module fin_airfoil_profile(chord, thickness) {
    radius = thickness / 2;
    // Profile in XZ plane
    // LE at x=0, TE at x=-chord
    // Centered on z=0
    
    // Main body: cube
    // from x=-chord to x=-radius
    translate([-chord, 0, -radius])
    cube([chord - radius, 0.1, thickness]); // 0.1 in Y for hulling
    
    // Rounded LE: cylinder
    // center at x=-radius, so front is at x=0
    translate([-radius, 0, 0])
    cylinder(h=0.1, r=radius, $fn=20);
}

// This module replaces the user's "fin" module
// It builds the fin planform in the XY plane, with thickness along Z.
// It uses hull() to create a rounded leading edge.
module fin(root_chord, tip_chord, span, leading_edge_sweep, thickness) {
    // NEW LOGIC (2025-11-02):
    // We want a straight trailing edge, as in the user's original polygon.
    // This means TE_Root_X = -root_chord
    // and TE_Tip_X = -root_chord
    //
    // The LE_Tip_X is then calculated from the TE_Tip_X and tip_chord:
    // LE_Tip_X = TE_Tip_X + tip_chord = -root_chord + tip_chord
    //
    // This model *ignores* the leading_edge_sweep variable, because
    // it's geometrically impossible to specify root_chord, tip_chord,
    // leading_edge_sweep, AND a straight trailing edge simultaneously.
    
    // The LE_Tip_X coordinate is the new translation offset.
    leading_edge_tip_x = -root_chord + tip_chord;

    hull() {
        // Root profile
        // at y=0 (span)
        // LE at x=0, TE at x=-root_chord
        fin_airfoil_profile(root_chord, thickness);
        
        // Tip profile
        // at y=span
        // LE at x = -root_chord + tip_chord
        // TE at x = (-root_chord + tip_chord) - tip_chord = -root_chord
        translate([leading_edge_tip_x, span, 0])
        fin_airfoil_profile(tip_chord, thickness);
    }
}


// --- Assemble the Tail Section ---
module tail_assembly() {
    union() {
        // 1. Fuselage Plug & Motor Mount
        fuselage_plug();
        
        // 2. Vertical Fin
        // Rotated 90 deg around Y-axis to stand up (span on Y, chord on Z)
        // We translate it to z=0 so it starts at the end of the tube
        // MODIFIED: Inset by `fin_inset`
        translate([0, tube_radius - fin_inset, 0]) // Position on top, inset slightly
        rotate([0, 270, 0])
        fin(vertical_fin_root_chord - fin_servo_gap, // Shorten fin to leave gap
            vertical_fin_tip_chord, 
            vertical_fin_height, 
            vertical_fin_leading_sweep, 
            fin_thickness);
        
        // 3. Horizontal Fins
        // Rotated to lay flat (span on X, chord on Z)
        
        // Right Fin (positive X)
        // MODIFIED: Inset by `fin_inset`
        translate([tube_radius - fin_inset, 0, 0]) // Position on right side, inset slightly
        rotate([0, 270, -90]) // Rotate chord to Z, then span to X
        fin(horizontal_fin_root_chord - fin_servo_gap, // Shorten fin to leave gap
            horizontal_fin_tip_chord, 
            horizontal_fin_span, 
            horizontal_fin_leading_sweep, 
            fin_thickness);
            
        // Left Fin (negative X)
        // We just mirror the right fin
        mirror([1, 0, 0]) {
            // MODIFIED: Inset by `fin_inset`
            translate([tube_radius - fin_inset, 0, 0]) // Position on right side, inset slightly
            rotate([0, 270, -90]) // Rotate chord to Z, then span to X
            fin(horizontal_fin_root_chord - fin_servo_gap, // Shorten fin to leave gap
                horizontal_fin_tip_chord, 
                horizontal_fin_span, 
                horizontal_fin_leading_sweep, 
                fin_thickness);
        }
    }
}

// --- Render the Module ---
$fn=50; // Increase segments for a smoother render
tail_assembly();

