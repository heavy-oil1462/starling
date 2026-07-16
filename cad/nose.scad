// ==============================================================================
//   CONFIGURATION VARIABLES
// ==============================================================================

// --- Global Resolution ---
$fn = 100; // Set segments for a good balance of smoothness and rendering speed

// --- Fuselage Base Dimensions ---
tube_outer_diameter = 52.94;           // Outer diameter of the fuselage tube
cone_base_outer_diameter = 60;      // Outer diameter of the cone's base (where it meets the tube)
sleeve_length = 20;                 // How far the cone slides *over* the tube
wall_thickness = 3;                 // Desired wall thickness for the cone

// --- Cone Body Dimensions ---
cone_height_above_sleeve = 80;      // Height of the conical section only
cone_tip_radius = 18;               // Radius of the rounded tip

// --- Camera Hole Configuration ---
camera_hole_diameter = 30;          // Diameter of the camera lens hole
camera_hole_angle_degrees = 10;     // Angle "down" from the Z-axis (0=straight fwd)
camera_hole_z_position = 100;       // Z-position of the camera hole (Measured from Z=0)


// ==============================================================================
//   DERIVED CONSTANTS AND HELPER FUNCTIONS
// ==============================================================================

tube_outer_radius = tube_outer_diameter / 2;
cone_base_outer_radius = cone_base_outer_diameter / 2;

// The fillet radius is the difference between the base radius and the tube radius
rear_fillet_radius = cone_base_outer_radius - tube_outer_radius;

// Total Z height from base to the center of the tip sphere
total_cone_z_height = sleeve_length + cone_height_above_sleeve;

// Z position of the center of the tip sphere
tip_sphere_center_z = total_cone_z_height - cone_tip_radius;


// Function to calculate the outer radius (R) of the cone body at a given Z position.
// This is used for placing the camera hole cutter.
function get_cone_radius_at_z(z_pos) =
    let(
        // Point 1 (Base of cone section):
        z1 = sleeve_length, 
        r1 = cone_base_outer_radius, 
        
        // Point 2 (Point where cone meets tip sphere):
        z2 = tip_sphere_center_z, 
        r2 = cone_tip_radius, 
        
        // Slope (m = dz / dr) of the cone side wall
        cone_slope_m = (z2 - z1) / (r2 - r1)
    )
    // r = ((z - z1) / m) + r1
    ((z_pos - z1) / cone_slope_m) + r1;


// ==============================================================================
//   MAIN MODULE
// ==============================================================================

module cone_housing() {
    // Calculate the required radius for the camera cutter's center point
    // This value is used for translating the cutter radially (along Y axis)
    camera_hole_radial_pos = get_cone_radius_at_z(camera_hole_z_position);
    
    epsilon = 0.5; // Small overlap value

    // Use difference() to subtract the inner shape from the outer shape
    difference() {
        
        // --- 1. The Outer (Solid) Shape ---
        union() {
            
            // A) Conical Body (Hulled between the base and the tip sphere)
            hull() {
                // Base of the cone hull
                translate([0, 0, sleeve_length])
                cylinder(h=0.1, r=cone_base_outer_radius); 
                
                // Top of the hull (Center of the outer sphere)
                translate([0, 0, tip_sphere_center_z])
                sphere(r = cone_tip_radius);
            }
            
            // B) The Straight Sleeve Section (above the fillet)
            translate([0, 0, rear_fillet_radius])
            cylinder(sleeve_length - rear_fillet_radius, r=cone_base_outer_radius);
        }
        
        // --- 2. The Inner (Cutout) Shape ---
        union() {
            // A) Hollow Cutout for the Fuselage Tube (Defining the sleeve ID)
            translate([0, 0, -epsilon])
            cylinder(sleeve_length + (2 * epsilon), r=tube_outer_radius);
            
            // B) Hollow Cone Cutout (Starts above the sleeve ID, defining the wall thickness)
            hull() {
                // Base of the inner hull
                translate([0, 0, sleeve_length])
                cylinder(h=0.1, r=cone_base_outer_radius - wall_thickness);
                
                // Top of the inner hull (Center of the inner sphere)
                translate([0, 0, tip_sphere_center_z])
                sphere(r = cone_tip_radius - wall_thickness);
            }
            
            // C) Camera Hole Cutout
            translate([0, camera_hole_radial_pos, camera_hole_z_position]) {
                rotate([camera_hole_angle_degrees, 0, 0]) {
                    // Cutout needs to be long enough to pass through both walls
                    cylinder(h=50, r=camera_hole_diameter/2, center=true, $fn=20);
                }
            }
        }
    }
}

// --- Render the Module ---
cone_housing();