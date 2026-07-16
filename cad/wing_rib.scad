// ==============================================================================
//   WING RIB — printed NACA rib for the foam-skinned, carbon-spar wing.
//
//   The foam-board skin WRAPS over the ribs: a 5 mm skin cannot be inlaid
//   into a ~15 mm thick section, so there are deliberately no skin slots —
//   the rib profile is the wing's inner mold line.
//
//   wing_rib_with_cutouts() — standard rib: two spar holes + a cable hole
//   wing_rib_root()         — root rib: adds the through-window that slides
//                             over the wing-adapter tab (print 1 per panel,
//                             see cad/wing_rib_root.scad)
// ==============================================================================

include <design_params.scad>

$fn = 120;

// ==============================================================================
//   NACA AIRFOIL FUNCTIONS
//   Plain variables only — no $-specials: top-level $var assignments are
//   invisible to use<> consumers and fall back silently. That bug shipped
//   once; don't reintroduce it.
// ==============================================================================

airfoil_fn = 120; // points along the chord

// Half-thickness of a symmetric NACA section; 0.1036 closes the TE cleanly
function foil_y(x, c, t) =
    (5 * t * c) * ( 0.2969 * sqrt(x / c) - 0.1260 * (x / c)
                  - 0.3516 * pow(x / c, 2) + 0.2843 * pow(x / c, 3)
                  - 0.1036 * pow(x / c, 4) );

// Camber line
function camber(x, c, m, p) = ( x <= (p * c) ?
    ( ( (c * m) / pow(p, 2) )       * ( ( 2 * p * (x / c) ) - pow(x / c, 2) ) ) :
    ( ( (c * m) / pow(1 - p, 2) )   * ( (1 - (2 * p)) + ( 2 * p * (x / c) ) - pow(x / c, 2) ) ) );

// Angle of the camber line
function theta(x, c, m, p) = ( x <= (p * c) ?
    atan( ( m / pow(p, 2) )     * (p - (x / c)) ) :
    atan( ( m / pow(1 - p, 2) ) * (p - (x / c)) ) );

// Upper/lower surface coordinates
function camber_y(x, c, t, m, p, upper=true) = ( upper ?
    ( camber(x, c, m, p) + (foil_y(x, c, t) * cos(theta(x, c, m, p))) ) :
    ( camber(x, c, m, p) - (foil_y(x, c, t) * cos(theta(x, c, m, p))) ) );

function camber_x(x, c, t, m, p, upper=true) = ( upper ?
    ( x - (foil_y(x, c, t) * sin(theta(x, c, m, p))) ) :
    ( x + (foil_y(x, c, t) * sin(theta(x, c, m, p))) ) );

module airfoil_poly(c = 100, naca = 0015) {
    res = c / airfoil_fn;
    t = (naca % 100) / 100;              // thickness/chord
    m = floor(naca / 1000) / 100;        // max camber
    p = (floor(naca / 100) % 10) / 10;   // position of max camber

    points_u = ( m == 0 || p == 0 ) ?
        [for (i = [0:res:c]) [i, foil_y(i, c, t)]] :
        [for (i = [0:res:c]) [camber_x(i, c, t, m, p), camber_y(i, c, t, m, p)]];

    points_l = ( m == 0 || p == 0 ) ?
        [for (i = [c:-res:0]) [i, -foil_y(i, c, t)]] :
        [for (i = [c:-res:0]) [camber_x(i, c, t, m, p, upper=false), camber_y(i, c, t, m, p, upper=false)]];

    polygon(concat(points_u, points_l));
}

// ==============================================================================
//   RIB-LOCAL CONFIGURATION (part-internal, not an interface)
// ==============================================================================

spar_x_pos = 0.4;             // rear spar at 40% chord (front one lands at 20%)
cable_hole_diameter = 6;
cable_hole_x_pos = 0.6;       // fraction of chord
cable_hole_y_offset = 1.5;

// ==============================================================================
//   RIB MODULES
// ==============================================================================

module wing_rib_with_cutouts() {
    spar_x_offset = rib_chord * (1 - spar_x_pos);
    cable_hole_x_offset = rib_chord * (1 - cable_hole_x_pos);

    difference() {
        translate([rib_chord, 0, 0])
            rotate([0, 180, 0])
                linear_extrude(height = rib_thickness, center = true)
                    airfoil_poly(c = rib_chord, naca = naca_code);

        for (dx = [0, spar_spacing])
            translate([spar_x_offset + dx, spar_y_offset, 0])
                cylinder(h = rib_thickness * 2 + 0.2, d = spar_hole_d, center = true);

        translate([cable_hole_x_offset, cable_hole_y_offset, 0])
            cylinder(h = rib_thickness * 2 + 0.2, d = cable_hole_diameter, center = true);
    }
}

// Root rib: a through-window, centered on the spar holes, that slides over
// the wing-adapter tab — so the rod sockets and rib spar holes line up by
// construction. The window may nick the upper surface near its forward edge:
// the tab stands slightly proud of the thin front of the profile there, and
// the rib is glued to the tab anyway.
module wing_rib_root() {
    window_l = adapter_length + fit_tol;
    window_h = wing_tab_thickness + fit_tol;
    window_center_x = rib_chord * (1 - spar_x_pos) + spar_spacing / 2;

    difference() {
        wing_rib_with_cutouts();
        translate([window_center_x - window_l / 2, spar_y_offset - window_h / 2, -rib_thickness])
            cube([window_l, window_h, rib_thickness * 2]);
    }
}

wing_rib_with_cutouts();
