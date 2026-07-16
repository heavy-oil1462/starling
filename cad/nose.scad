// ==============================================================================
//   NOSE CONE — sleeve slides over the front of the fuselage tube; rounded
//   cone with an FPV camera opening bored through the tip.
// ==============================================================================

include <design_params.scad>

$fn = 100;

// --- Cone dimensions (part-local) ---
cone_base_outer_diameter = 60;  // where the cone meets the tube
cone_height_above_sleeve = 80;  // conical section only
cone_tip_radius          = 18;  // rounded tip

// --- Camera opening ---
camera_hole_diameter      = 30;
camera_hole_angle_degrees = 10; // tilt toward the belly (-Y), 0 = straight ahead

// --- Derived ---
tube_outer_radius      = (tube_od + sleeve_clearance) / 2;
cone_base_outer_radius = cone_base_outer_diameter / 2;
rear_fillet_radius     = cone_base_outer_radius - tube_outer_radius;
total_cone_z_height    = nose_sleeve_length + cone_height_above_sleeve;
tip_sphere_center_z    = total_cone_z_height - cone_tip_radius;

module cone_housing() {
    epsilon = 0.5;

    difference() {
        // --- 1. Outer solid ---
        union() {
            // Conical body, hulled between the base and the tip sphere
            hull() {
                translate([0, 0, nose_sleeve_length])
                    cylinder(h = 0.1, r = cone_base_outer_radius);
                translate([0, 0, tip_sphere_center_z])
                    sphere(r = cone_tip_radius);
            }
            // Straight sleeve section
            translate([0, 0, rear_fillet_radius])
                cylinder(nose_sleeve_length - rear_fillet_radius, r = cone_base_outer_radius);
        }

        // --- 2. Cutouts ---
        union() {
            // Bore for the fuselage tube
            translate([0, 0, -epsilon])
                cylinder(nose_sleeve_length + 2 * epsilon, r = tube_outer_radius);

            // Hollow cone interior
            hull() {
                translate([0, 0, nose_sleeve_length])
                    cylinder(h = 0.1, r = cone_base_outer_radius - sleeve_wall);
                translate([0, 0, tip_sphere_center_z])
                    sphere(r = cone_tip_radius - sleeve_wall);
            }

            // Camera opening: bored outward FROM the tip-sphere center along
            // the flight axis, tilted down — anchored to the tip so it stays
            // put if the cone is reshaped. (The old version projected a
            // cone-section formula past its valid range and only landed here
            // by accident.)
            translate([0, 0, tip_sphere_center_z])
                rotate([camera_hole_angle_degrees, 0, 0])
                    cylinder(h = cone_tip_radius + sleeve_wall + 5,
                             r = camera_hole_diameter / 2, $fn = 40);
        }
    }
}

cone_housing();
