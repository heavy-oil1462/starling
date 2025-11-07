tube_diameter           = 52.92;
wall_thickness          = 3;
overlap_margin          = 1;
adapter_length          = 40;
wing_tab_thickness      = 11;
wing_tab_le_radius      = wing_tab_thickness / 2;
adapter_depth           = wall_thickness;
wing_tab_span           = 15;
hole_diameter           = 6.2;
hole_spacing            = 20;

module wing_adapter() {
    tube_radius = tube_diameter / 2;
    sleeve_outer_radius = tube_radius + adapter_depth;
    tab_start_x = sleeve_outer_radius - overlap_margin;
    hole_radius = hole_diameter / 2;
    
    // The X coordinate of the very tip of the tab
    tab_tip_x = sleeve_outer_radius + wing_tab_span;
    
    // Vertical positions
    z_center = adapter_length / 2;
    z_offset = hole_spacing / 2;
    
    difference() {
        // 1. SOLID BODY
        union() {
            // Main Sleeve
            difference() {
                cylinder(h = adapter_length, r = sleeve_outer_radius, $fn=50);
                translate([0, 0, -0.1])
                cylinder(h = adapter_length + 0.2, r = tube_radius, $fn=50);
            }

            // Right Tab
            translate([tab_start_x, -wing_tab_le_radius, 0])
            cube([wing_tab_span + overlap_margin, wing_tab_thickness, adapter_length]);
            
            // Left Tab
            mirror([1, 0, 0])
            translate([tab_start_x, -wing_tab_le_radius, 0])
            cube([wing_tab_span + overlap_margin, wing_tab_thickness, adapter_length]);
        }

        // 2. HOLES (Rod Sockets)
        for (z_pos = [z_center - z_offset, z_center + z_offset]) {
            
            // Right Side Holes
            // We translate to the tip, then rotate to point Inwards (-X)
            translate([tab_tip_x + 0.1, 0, z_pos]) // +0.1 ensures clean surface cut
            rotate([0, -90, 0])
            cylinder(h = 10.1, r = hole_radius, $fn=50);

            // Left Side Holes
            mirror([1, 0, 0])
            translate([tab_tip_x + 0.1, 0, z_pos])
            rotate([0, -90, 0])
            cylinder(h = 10.1, r = hole_radius, $fn=50);
        }
    }
}

$fn=100;
wing_adapter();