// Shared geometry for the two wing adapters — the clamping trim rig
// (wing_adapter.scad) and the glue-on flight part (wing_adapter_glue.scad).
// Sleeve, wing tabs, and spar sockets live here ONCE so the wing-root
// interface cannot drift between the variants: a wing trimmed on the rig
// must drop unchanged onto the flight adapter.
//
// Not a printable part (lives in cad/lib/, which regen_all.py does not
// scan). Consumers include <design_params.scad> first, then this file.

wa_overlap = 1;   // tab root buried into the sleeve wall for a clean union

function wa_tube_r()    = (tube_od + sleeve_clearance) / 2;
function wa_outer_r()   = wa_tube_r() + sleeve_wall;
function wa_tab_tip_x() = wa_outer_r() + wing_tab_span;
function wa_spar_z()    = [adapter_length / 2 - spar_spacing / 2,
                           adapter_length / 2 + spar_spacing / 2];

// Sleeve + wing tabs, SOLID (no bore). Variants union their extras onto
// this before subtracting wa_cuts(), so anything they add is trimmed by
// the same bore.
module wa_solid() {
    cylinder(h = adapter_length, r = wa_outer_r());
    for (m = [0, 1]) mirror([m, 0, 0])
        translate([wa_outer_r() - wa_overlap, -wing_tab_thickness / 2, 0])
            cube([wing_tab_span + wa_overlap, wing_tab_thickness, adapter_length]);
}

// Tube bore + rod sockets. The sockets run from the tab tip to a 1 mm
// floor above the bore (~17 mm engagement); the rods must never reach the
// bore or they jam against the paper tube and block the CG slide. Bond
// the rods in with CA/epoxy for flight — the sockets alone are alignment,
// not structure.
module wa_cuts() {
    translate([0, 0, -0.1])
        cylinder(h = adapter_length + 0.2, r = wa_tube_r());

    socket_depth = (wa_tab_tip_x() + 0.1) - (wa_tube_r() + 1);
    for (z = wa_spar_z())
        for (m = [0, 1]) mirror([m, 0, 0])
            translate([wa_tab_tip_x() + 0.1, 0, z])
                rotate([0, -90, 0])
                    cylinder(h = socket_depth, d = spar_hole_d);
}
