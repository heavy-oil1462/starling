// SERVO RIB — print ONE per wing panel. Standard rib plus the open-bottom
// servo bay aft of the rear spar; the aileron servo's flange seats on this
// rib's outboard face. Geometry lives in wing_rib.scad; this file only
// exists so regen_all.py exports its STL.

use <wing_rib.scad>

$fn = 120;
wing_rib_servo();
