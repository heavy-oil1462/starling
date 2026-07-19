// TIP RIB — print ONE per wing panel (regen exports one STL; the assembly
// mirrors it). Replaces the outermost standard rib: thicker, blind spar
// sockets the rod ends glue into, rounded outboard cap. Geometry lives in
// wing_rib.scad; this file only exists so regen_all.py exports its STL.

use <wing_rib.scad>

$fn = 120;
wing_rib_tip();
