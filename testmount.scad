// --- Motor Mount Variables ---
// Copied from your rc_tail_assembly_v3.scad file
motor_shaft_hole_dia = 10;
motor_mount_hole_dia = 4;
hole_pattern_x = 16; // The 16mm dimension
hole_pattern_y = 19; // The 19mm dimension

// --- Test Plate Variables ---
plate_width = 40;  // Total width of the test plate
plate_height = 40; // Total height of the test plate
plate_thickness = 2;   // Thickness of the test plate

$fn = 50; // For smooth holes

// --- Create the Test Plate ---
difference() {
    // 1. The main solid plate
    cube([plate_width, plate_height, plate_thickness], center = true);
    
    // 2. The cutouts
    
    // Center shaft hole
    translate([0, 0, 0])
    cylinder(h = plate_thickness + 2, d = motor_shaft_hole_dia, center = true);
    
    // --- 16x19mm "+" (plus) pattern ---
    
    // Hole 1 (Top, +Y)
    translate([ 0, hole_pattern_y / 2, 0 ])
    cylinder(h = plate_thickness + 2, d = motor_mount_hole_dia, center = true);
    
    // Hole 2 (Bottom, -Y)
    translate([ 0, -hole_pattern_y / 2, 0 ])
    cylinder(h = plate_thickness + 2, d = motor_mount_hole_dia, center = true);
    
    // Hole 3 (Right, +X)
    translate([ hole_pattern_x / 2, 0, 0 ])
    cylinder(h = plate_thickness + 2, d = motor_mount_hole_dia, center = true);
    
    // Hole 4 (Left, -X)
    translate([ -hole_pattern_x / 2, 0, 0 ])
    cylinder(h = plate_thickness + 2, d = motor_mount_hole_dia, center = true);
}