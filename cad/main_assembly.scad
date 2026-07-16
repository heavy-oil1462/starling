use <tail.scad>
use <wing_rib.scad>
use <wing_adapter.scad>
use <nose.scad>
use <fuselage.scad>

$fn=100;

translate([0, 0, 50]) fuselage();

for (i = [50, 150, 250, 350, 420]) {
    rotate([0, -90, 0]) 
        translate([251, 0, i]) 
            wing_rib_with_cutouts();
}

for (i = [-50, -150, -250, -350, -420]) {
    rotate([0, -90, 0]) 
        translate([251, 0, i]) 
            wing_rib_with_cutouts();
}

translate([0, 0, 300]) 
    wing_adapter();

rotate([0, 0, 180]) 
    translate([0, 0, 565]) 
        cone_housing();

tail_assembly();