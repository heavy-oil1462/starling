// ==============================================================================
//   VISUAL FIT CHECK — renders to main_assembly.png via scripts/regen_all.py.
//   All placement derives from design_params.scad: sliding the wing for CG
//   trim is a one-number change (wing_station), and the rib row, adapter
//   sockets, and spar rods line up by construction.
// ==============================================================================

use <tail.scad>
use <wing_rib.scad>
use <wing_adapter.scad>
use <nose.scad>
use <fuselage.scad>
include <design_params.scad>

$fn = 60;

rib_stations = [40, 120, 200, 280, 360, 440]; // spanwise; first = root rib on the tab
spar_length  = 460;

// Paper tube, bottomed out on the tail sleeve's internal rim
color("BurlyWood")
    translate([0, 0, tail_tube_stop])
        fuselage();

// Tail (sleeve + fins + servo pockets + motor mount) at the origin
color("Tomato")
    tail_assembly();

// Nose cone over the top of the tube
color("Tomato")
    translate([0, 0, tail_tube_stop + tube_length - nose_sleeve_length])
        cone_housing();

// Wing adapter, clamped at the wing station
color("SteelBlue")
    translate([0, 0, wing_station])
        wing_adapter();

// Wing panels: spar rods + ribs. Rib local X (chord, flipped so the LE is at
// x=100) maps to global Z via rotate([0,-90,0]); shifting the rib down by
// spar_y_offset puts its spar holes on the adapter's socket axis (global y=0).
for (side = [1, -1]) {
    color("DimGray")
        for (dz = [adapter_length / 2 - spar_spacing / 2,
                   adapter_length / 2 + spar_spacing / 2])
            translate([side * (tube_od / 2 - 1), 0, wing_station + dz])
                rotate([0, side * 90, 0])
                    cylinder(h = spar_length, d = spar_rod_d);

    for (i = [0 : len(rib_stations) - 1])
        color("Gold")
            translate([side * rib_stations[i], -spar_y_offset, wing_station - rib_chord / 2])
                rotate([0, -90, 0])
                    if (i == 0) wing_rib_root();
                    else        wing_rib_with_cutouts();
}
