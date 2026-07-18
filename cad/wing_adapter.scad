// ==============================================================================
//   WING ADAPTER (TRIM RIG) — the clamping variant. This is TOOLING, not an
//   airframe part: it lives in the kit box and is used to FIND the wing
//   station for a payload. The M3 belly clamp locks it anywhere along the
//   tube, so CG trim is slide → fly → slide again, no glue.
//
//   Once a payload's station is known, record it in docs/wing-stations.md;
//   replica airframes fly the hardware-free wing_adapter_glue.scad instead.
//
//   Geometry (sleeve, tabs, spar sockets) is shared with the glue variant
//   via cad/lib/wing_adapter_common.scad — the wing cannot tell them apart.
// ==============================================================================

include <design_params.scad>
include <lib/wing_adapter_common.scad>

// --- Clamp (part-local) ---
clamp_slit_width = 2;   // belly slit the M3 screws pull shut
clamp_lug_width  = 6;   // each lug, along X
clamp_lug_height = 9;   // radial lug protrusion beyond the sleeve
clamp_screw_d    = 3.2; // M3 clearance holes

module wing_adapter() {
    screw_y = -(wa_outer_r() + clamp_lug_height / 2);

    difference() {
        union() {
            wa_solid();

            // Clamp lugs on the belly (wa_cuts()'s bore trims their inside)
            for (m = [0, 1]) mirror([m, 0, 0])
                translate([clamp_slit_width / 2, -(wa_outer_r() + clamp_lug_height), 0])
                    cube([clamp_lug_width, wa_outer_r() + clamp_lug_height, adapter_length]);
        }

        wa_cuts();

        // Belly slit between the lugs — severs the wall so the clamp can close
        translate([-clamp_slit_width / 2, -(wa_outer_r() + clamp_lug_height + 0.1), -0.1])
            cube([clamp_slit_width,
                  wa_outer_r() + clamp_lug_height - wa_tube_r() + 1.1,
                  adapter_length + 0.2]);

        // Clamp screws through both lugs
        for (z_pos = wa_spar_z())
            translate([-(clamp_slit_width / 2 + clamp_lug_width + 0.1), screw_y, z_pos])
                rotate([0, 90, 0])
                    cylinder(h = clamp_slit_width + 2 * clamp_lug_width + 0.2, d = clamp_screw_d);
    }
}

$fn = 100;
wing_adapter();
