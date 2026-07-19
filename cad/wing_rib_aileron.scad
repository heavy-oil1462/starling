// AILERON-SPAN RIB — standard rib with the TE cropped at the hinge line so
// the aileron nests inside the wing planform. Print one per rib station
// that falls inside the aileron span (see cad/main_assembly.scad). Geometry
// lives in wing_rib.scad; this file only exists so regen_all.py exports its
// STL.

use <wing_rib.scad>

$fn = 120;
wing_rib_aileron();
