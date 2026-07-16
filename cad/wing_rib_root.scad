// ROOT RIB — print ONE per wing panel. Same as the standard rib plus the
// through-window that slides over the wing-adapter tab. Geometry lives in
// wing_rib.scad; this file only exists so regen_all.py exports its STL.

use <wing_rib.scad>

$fn = 120;
wing_rib_root();
