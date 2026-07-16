// HORIZONTAL TAIL FIN — print TWO (left and right are the same symmetric
// part), FLAT on the bed: no supports, and the layer lines run along the
// span, which is the strong direction. The root tab glues into the tail
// sleeve's fin socket; the TE groove takes the elevator hinge strip.
// Geometry lives in tail.scad.

use <tail.scad>

$fn = 60;
fin_horizontal_part();
