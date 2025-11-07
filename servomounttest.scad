// Module to create a mounting plate for a 9g servo (like SG90)
// This version uses global variables for configuration.

// --- 🔧 Global Parameters for Servo Mount ---
// Change these values to customize your plate.

tol = 0.2;                 // Printing tolerance

// Plate dimensions
plate_dims = [50, 30];
plate_thickness = 5;

// --- Standard 9g (SG90) Servo Dimensions ---
servo_body = [23, 12.2];   // [width, depth]
servo_flange = [32, 12.2]; // [width, depth]
flange_thickness = 3;
screw_spacing = 28;
screw_dia = 3;           // Good for an M2 screw
use_screws = false;

// --- Example Usage ---
// Call the module to create the plate.
// It will use the global variables defined above.
servo_mount_plate();


/**
 * Creates a rectangular plate with a 9g servo cutout.
 * This module reads its configuration from the global
 * variables defined at the top of the file.
 */
module servo_mount_plate() {
    
    // Use difference() to subtract the holes from the main plate
    difference() {
        
        // 1. The main plate
        cube([plate_dims[0], plate_dims[1], plate_thickness], center = true);
        
        // --- Subtractions ---
        
        // 2. The flush indentation (pocket) for the flange
        // We move this cutting cube so its top is aligned with the plate's top
        translate([0, 0, (plate_thickness / 2) - (flange_thickness / 2)]) {
            cube([
                servo_flange[0] + tol, 
                servo_flange[1] + tol, 
                flange_thickness + tol // Cut slightly deeper to ensure flush
            ], center = true);
        }
        
        // 3. The main hole for the servo body
        // This cube is extra tall to ensure it cuts all the way through
        cube([
            servo_body[0] + tol, 
            servo_body[1] + tol, 
            plate_thickness + 2 // +2 ensures a clean cut
        ], center = true);
        
        if (use_screws) {
            // 4. The screw holes
            // We use a for loop to create both holes
            for (x_pos = [-screw_spacing / 2, screw_spacing / 2]) {
                translate([x_pos, 0, 0]) {
                    cylinder(
                        h = plate_thickness + 2, // +2 ensures a clean cut
                        d = screw_dia, 
                        center = true
                    );
                }
            }
        }
    }
}

$fn=100; // Increase segments for a smoother render