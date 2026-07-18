// ==============================================================================
//   WING ADAPTER (FLIGHT, GLUE-ON) — the airframe variant. Identical wing
//   interface to the trim rig (shared via cad/lib/wing_adapter_common.scad)
//   but no clamp: no lugs, no slit, no M3 hardware — lighter and cheaper,
//   which is what a possibly single-use airframe wants.
//
//   Build sequence (docs/wing-stations.md): find the station with the
//   clamping trim rig, mark the fresh tube, slide THIS part to the mark,
//   tack it with hot-glue fillets at both rims. Fillets only, never glue
//   in the bore — rim tacks cut free cleanly, so a bad trim guess (or a
//   spent tube) gives the adapter back.
//
//   Each rim carries a shallow chamfer around the bore edge: a keyed seat
//   that lets the fillet grip printed plastic AND tube instead of sitting
//   on a sharp corner.
// ==============================================================================

include <design_params.scad>
include <lib/wing_adapter_common.scad>

glue_chamfer = 1.8;   // rim relief, radial and axial (< sleeve_wall)

module wing_adapter_glue() {
    difference() {
        wa_solid();
        wa_cuts();

        // Glue-relief chamfers, both rims. 45° cones stay printable when
        // the part prints upright, and stop well short of the outer wall.
        for (m = [0, 1])
            translate([0, 0, m ? adapter_length : 0]) mirror([0, 0, m])
                translate([0, 0, -0.1])
                    cylinder(h = glue_chamfer + 0.1,
                             r1 = wa_tube_r() + glue_chamfer + 0.1,
                             r2 = wa_tube_r());
    }
}

$fn = 100;
wing_adapter_glue();
