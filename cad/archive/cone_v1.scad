// --- Variables ---
tube_diameter = 50;
adapter_height = 15;

cone_height = 60;
cone_radius1 = tube_diameter / 2; // Base radius, derived from diameter
cone_radius2 = 10;                // Top radius
thickness = 3;                    // Desired wall thickness

// --- Module Definition ---
module cone() {
    // Use difference() to subtract the inner shape from the outer shape
    difference() {
        
        // --- 1. The Outer (Solid) Shape ---
        // We join the straight adapter with the new rounded cone part
        union() {
            // Adapter cylinder (this part remains straight)
            cylinder(adapter_height, r=cone_radius1);
            
            // Create a rounded cone by "hulling" the top of the
            // adapter with the sphere at the tip.
            hull() {
                // Base of the hull: a thin cylinder at the top of the adapter
                translate([0, 0, adapter_height])
                cylinder(0.1, r=cone_radius1); // Use a tiny height
                
                // Top of the hull: the outer sphere
                translate([0, 0, adapter_height + cone_height - cone_radius2])
                sphere(r = cone_radius2);
            }
        }
        
        // --- 2. The Inner (Cutout) Shape ---
        // This shape is 'thickness' smaller in radius
        epsilon = 0.5; // A small value to prevent z-fighting
        
        union() {
            // Inner adapter cylinder (straight cutout)
            translate([0, 0, -epsilon])
            cylinder(adapter_height + (2*epsilon), r=cone_radius1 - thickness);
            
            // Inner rounded cone cutout (using hull)
            hull() {
                // Base of the inner hull
                translate([0, 0, adapter_height])
                cylinder(0.1, r=cone_radius1 - thickness);
                
                // Top of the inner hull: the inner sphere
                translate([0, 0, adapter_height + cone_height - cone_radius2])
                sphere(r = cone_radius2 - thickness);
            }
        }
    }
}

// --- Render the Module ---
cone();

