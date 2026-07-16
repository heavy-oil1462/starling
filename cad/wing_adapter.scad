// ==============================================================================
//   WING ADAPTER — sleeve that slides on the fuselage tube and carries the
//   wing panels on two carbon-rod spars per side.
//
//   - The rod sockets go THROUGH the tabs and the sleeve wall: the rods bear
//     on the paper tube and get the full tab as engagement (~19 mm). Bond the
//     rods in with CA/epoxy for flight — the sockets alone are alignment, not
//     structure.
//   - Belly clamp: a slit plus an M3 lug pair lets the adapter be locked
//     anywhere along the tube (movable wing = CG trim).
// ==============================================================================

include <design_params.scad>

overlap_margin = 1;     // tab root buried into the sleeve wall for a clean union

// --- Clamp (part-local) ---
clamp_slit_width = 2;   // belly slit the M3 screws pull shut
clamp_lug_width  = 6;   // each lug, along X
clamp_lug_height = 9;   // radial lug protrusion beyond the sleeve
clamp_screw_d    = 3.2; // M3 clearance holes

module wing_adapter() {
    tube_radius = (tube_od + sleeve_clearance) / 2;
    sleeve_outer_radius = tube_radius + sleeve_wall;
    tab_start_x = sleeve_outer_radius - overlap_margin;
    tab_tip_x = sleeve_outer_radius + wing_tab_span;

    z_center = adapter_length / 2;
    z_offset = spar_spacing / 2;

    // Through the tab AND the sleeve wall — the rod stops on the tube itself
    socket_depth = wing_tab_span + overlap_margin + sleeve_wall + 0.2;
    screw_y = -(sleeve_outer_radius + clamp_lug_height / 2);

    difference() {
        // 1. SOLID BODY
        union() {
            cylinder(h = adapter_length, r = sleeve_outer_radius);

            // Wing tabs, left and right
            for (m = [0, 1]) mirror([m, 0, 0])
                translate([tab_start_x, -wing_tab_thickness / 2, 0])
                    cube([wing_tab_span + overlap_margin, wing_tab_thickness, adapter_length]);

            // Clamp lugs on the belly (the bore cut below trims their inside)
            for (m = [0, 1]) mirror([m, 0, 0])
                translate([clamp_slit_width / 2, -(sleeve_outer_radius + clamp_lug_height), 0])
                    cube([clamp_lug_width, sleeve_outer_radius + clamp_lug_height, adapter_length]);
        }

        // 2. CUTOUTS
        // Bore for the tube (cut last so the lugs don't intrude into it)
        translate([0, 0, -0.1])
            cylinder(h = adapter_length + 0.2, r = tube_radius);

        // Belly slit between the lugs — severs the wall so the clamp can close
        translate([-clamp_slit_width / 2, -(sleeve_outer_radius + clamp_lug_height + 0.1), -0.1])
            cube([clamp_slit_width,
                  sleeve_outer_radius + clamp_lug_height - tube_radius + 1.1,
                  adapter_length + 0.2]);

        // Clamp screws through both lugs
        for (z_pos = [z_center - z_offset, z_center + z_offset])
            translate([-(clamp_slit_width / 2 + clamp_lug_width + 0.1), screw_y, z_pos])
                rotate([0, 90, 0])
                    cylinder(h = clamp_slit_width + 2 * clamp_lug_width + 0.2, d = clamp_screw_d);

        // Rod sockets (both sides)
        for (z_pos = [z_center - z_offset, z_center + z_offset])
            for (m = [0, 1]) mirror([m, 0, 0])
                translate([tab_tip_x + 0.1, 0, z_pos])
                    rotate([0, -90, 0])
                        cylinder(h = socket_depth, d = spar_hole_d);
    }
}

$fn = 100;
wing_adapter();
