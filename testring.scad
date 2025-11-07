// --- Test Ring Variables ---
// Copied from your main file to ensure accuracy
tube_diameter = 52.9; // The inner diameter
wall_thickness = 4;    // The wall thickness
test_length = 10;      // The length of the test piece

// --- Calculations ---
tube_radius = tube_diameter / 2;
outer_radius = tube_radius + wall_thickness;

$fn=100; // For a smooth circle

// --- Create the Test Ring ---
// We'll create a solid outer ring and subtract the inner hole.
difference() {
    // 1. Outer solid cylinder
    cylinder(h = test_length, r = outer_radius, center = true);
    
    // 2. Inner cutout
    // We make the cutout slightly taller to ensure a clean boolean operation
    cylinder(h = test_length + 2, r = tube_radius, center = true);
}