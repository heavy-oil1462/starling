// ==============================================================================
//   WING RIB — printed NACA rib for the foam-skinned, carbon-spar wing.
//
//   The foam-board skin WRAPS over the ribs: a 5 mm skin cannot be inlaid
//   into a ~15 mm thick section, so there are deliberately no skin slots —
//   the rib profile is the wing's inner mold line.
//
//   wing_rib_with_cutouts() — standard rib: two spar holes + a cable hole
//   wing_rib_servo()        — servo rib: adds an open-bottom bay aft of the
//                             rear spar that carries the aileron servo. It
//                             REPLACES the nearest standard rib in the row
//                             (print 1 per panel, see cad/wing_rib_servo.scad)
//   wing_rib_aileron()      — standard rib with the TE cropped at the hinge
//                             line, for stations inside the aileron span
//                             (see cad/wing_rib_aileron.scad)
//   wing_rib_tip()          — outermost rib: thicker, BLIND spar sockets
//                             (rods end inside it), rounded outboard cap
//                             (see cad/wing_rib_tip.scad)
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

// Rib-local X runs from the TE (x=0) to the LE (x=rib_chord)
spar_x_offset = rib_chord * (1 - spar_x_pos);
cable_hole_x_offset = rib_chord * (1 - cable_hole_x_pos);

// ==============================================================================
//   RIB MODULES
// ==============================================================================

// Positioned 2D section shared by every rib variant: TE at x=0, LE at
// x=rib_chord, camber up (+y).
module rib_profile() {
    translate([rib_chord, 0])
        mirror([1, 0])
            airfoil_poly(c = rib_chord, naca = naca_code);
}

// te_crop > 0 removes the trailing edge forward to that x — used by the
// aileron-span ribs so the surface nests inside the planform.
module wing_rib_with_cutouts(t = rib_thickness, te_crop = 0) {
    difference() {
        linear_extrude(height = t, center = true) rib_profile();

        for (dx = [0, spar_spacing])
            translate([spar_x_offset + dx, spar_y_offset, 0])
                cylinder(h = t * 2 + 0.2, d = spar_hole_d, center = true);

        translate([cable_hole_x_offset, cable_hole_y_offset, 0])
            cylinder(h = t * 2 + 0.2, d = cable_hole_diameter, center = true);

        if (te_crop > 0)
            translate([-1, -rib_chord / 2, -t])
                cube([te_crop + 1, rib_chord, t * 2]);
    }
}

// Aileron-span rib: TE cropped at the hinge line plus a gap. The gap clears
// the aileron LE's swing under the taped top hinge (4 mm root thickness
// swings 4*sin(throw) forward; 2 mm covers past +-25 deg). The cable hole
// (40 from TE) and the servo bay (33..56 from TE) both survive the crop.
aileron_te_gap = 2;

module wing_rib_aileron() {
    wing_rib_with_cutouts(te_crop = ctrl_chord + aileron_te_gap);
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

// Tip rib: replaces the outermost standard rib on each panel. Thicker than
// the row ribs, with BLIND spar sockets (depth tip_spar_socket from the
// inboard z=0 face) — the carbon rods are cut to end inside them, so no rod
// ever pokes out of the tip. Outboard of a full-profile band (where the
// foam skin edge lands; sand the foam edge into the cap) the section pulls
// in through offset slices to a rounded cap that closes the tip shape.
// Print inboard face down: the sockets stand vertical and the cap needs no
// support. No cable hole — nothing lives outboard of this rib.
tip_rib_flat   = 3;   // full-profile band at the inboard face
tip_round      = 5;   // depth of the rounded cap beyond that
tip_shrink     = 4;   // how far the profile pulls in at the outermost face
tip_cap_slices = 16;

module wing_rib_tip() {
    assert(tip_rib_flat + tip_round >= tip_spar_socket + 1.5,
           "spar socket would break through the tip cap");
    difference() {
        union() {
            linear_extrude(height = tip_rib_flat) rib_profile();
            for (i = [0 : tip_cap_slices - 1])
                translate([0, 0, tip_rib_flat + tip_round * i / tip_cap_slices])
                    linear_extrude(height = tip_round / tip_cap_slices + 0.02)
                        offset(r = -tip_shrink * (1 - cos(90 * i / tip_cap_slices)))
                            rib_profile();
        }

        for (dx = [0, spar_spacing])
            translate([spar_x_offset + dx, spar_y_offset, -0.1])
                cylinder(h = tip_spar_socket + 0.1, d = spar_hole_d);
    }
}

wing_rib_with_cutouts();
