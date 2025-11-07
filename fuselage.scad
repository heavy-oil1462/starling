tube_diameter           = 52.95;
wall_thickness          = 3;
length                  = 540;

// Calculate the necessary radii
outer_radius = tube_diameter / 2;
inner_radius = outer_radius - wall_thickness;

module fuselage() {
    // The difference module subtracts the second shape (inner cylinder) 
    // from the first shape (outer cylinder).
    difference() {
        // Outer Cylinder (Solid part)
        cylinder(h = length, r = outer_radius);

        // Inner Cylinder (The hollow part to be subtracted)
        cylinder(h = length, r = inner_radius);
    }
}

// --- Render the Module ---
$fn=100; // Increased segments for a smoother render
fuselage();