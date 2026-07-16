// ==============================================================================
//   WING RIB — printed NACA rib for the foam-skinned, carbon-spar wing.
//
//   The foam-board skin WRAPS over the ribs: a 5 mm skin cannot be inlaid
//   into a ~15 mm thick section, so there are deliberately no skin slots —
//   the rib profile is the wing's inner mold line.
//
//   wing_rib_with_cutouts() — standard rib: two spar holes + a cable hole
//   wing_rib_servo()        — servo rib: adds an open-bottom bay aft of the
//                             rear spar that carries the aileron servo
//                             (print 1 per panel, see cad/wing_rib_servo.scad)
//
//   All ribs sit OUTBOARD of the adapter tab (innermost station > tab tip) —
//   ribs never overlap the adapter.
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

module wing_rib_with_cutouts(t = rib_thickness) {
    spar_x_offset = rib_chord * (1 - spar_x_pos);
    cable_hole_x_offset = rib_chord * (1 - cable_hole_x_pos);

    difference() {
        translate([rib_chord, 0, 0])
            rotate([0, 180, 0])
                linear_extrude(height = t, center = true)
                    airfoil_poly(c = rib_chord, naca = naca_code);

        for (dx = [0, spar_spacing])
            translate([spar_x_offset + dx, spar_y_offset, 0])
                cylinder(h = t * 2 + 0.2, d = spar_hole_d, center = true);

        translate([cable_hole_x_offset, cable_hole_y_offset, 0])
            cylinder(h = t * 2 + 0.2, d = cable_hole_diameter, center = true);
    }
}

// Servo rib: carries the aileron servo. An open-bottom bay aft of the rear
// spar takes the servo body (inserted from below, lying flat: shaft along
// the span, arm swinging in the chord-vertical plane, up through the top
// skin); the servo's flange seats on the rib's OUTBOARD face, overlapping
// the bay ends — tack it with CA or strapping tape.
// The aft bay of a 15%/100 mm section is thinner than a 9 g servo, so the
// bay opens through the bottom and the servo sits ~3 mm proud of the LOWER
// skin — fair it with tape, or drop to a 5 g servo which fits flush. The
// strip above the bay thins to ~1.5 mm; the glued-on top skin backs it up.
// The bay's forward edge keeps ~1 mm of material to the rear spar hole.
// The servo rib prints thicker than the standard ribs — it reacts the whole
// servo/linkage load until the skin is on, so it needs the extra stiffness.
servo_rib_thickness = 4;

module wing_rib_servo() {
    bay_l    = servo_body[0] + fit_tol;
    bay_h    = servo_body[1] + fit_tol;
    bay_x_hi = rib_chord * 0.56;   // bay spans 44%..67.4% chord, aft of the rear spar
    bay_y0   = -6.9;               // keeps a printable strip under the top surface

    difference() {
        wing_rib_with_cutouts(servo_rib_thickness);
        translate([bay_x_hi - bay_l, bay_y0, -servo_rib_thickness])
            cube([bay_l, bay_h, servo_rib_thickness * 2]);
    }
}

wing_rib_with_cutouts();
