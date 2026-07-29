// ==============================================================================
//   WING SKIN CUT TEMPLATE — 2D, exports to templates/wing_skin.svg (mm units,
//   print or plot 1:1; regen_all.py owns the export, never render this to STL).
//
//   The foam-board skin is one piece per panel, wrapped around the ribs from
//   the lower TE over the LE back to the upper TE. This template is that skin
//   developed flat, drawn as thin outlines and marks:
//     X = span station (same numbers as design_params.scad, root edge at the
//         first rib, outboard edge on the tip rib's flat band)
//     Y = developed distance around the airfoil, 0 at the LOWER surface TE,
//         the LE fold line at the lower arc length, the UPPER surface TE at
//         the full perimeter
//   One template serves both panels: flip the foam over for the mirror side.
//
//   The developed lengths trace the rib profile (the wing's inner mold line)
//   via the NACA functions from wing_rib.scad — the same math that shapes the
//   ribs, so template and ribs cannot drift apart. The 5 mm foam's outer face
//   is longer around the LE than the inner face this measures: leave the
//   UPPER TE edge oversize when rough-cutting and trim to fit after the test
//   wrap (see docs/wing-build.md). Cut the servo-arm slot and the aileron
//   notches BEFORE skinning.
//
//   Marks (all thin lines, cut nothing except where labeled CUT):
//     - dashed line across the span         = LE fold / score line
//     - solid lines along the span          = spar lines (glue reference)
//     - dashed lines across the chord       = rib stations (glue lines)
//     - small rectangle near the aileron    = servo-arm slot, CUT OUT
//     - crossed boxes at both TE edges      = aileron TE notch, CUT OFF
//     - 100 mm bar near the root            = print-scale check
// ==============================================================================

include <design_params.scad>
use <wing_rib.scad>

lw = 0.4;   // drawn line width
fn = 120;   // sampling points along each surface for the arc lengths

// --- NACA decode (same as airfoil_poly in wing_rib.scad) ---------------------
naca_t = (naca_code % 100) / 100;
naca_m = floor(naca_code / 1000) / 100;
naca_p = (floor(naca_code / 100) % 10) / 10;

// Surface polylines from the LE (index 0) to the TE (index fn)
upper_pts = [for (i = [0:fn]) let (x = rib_chord * i / fn)
    [camber_x(x, rib_chord, naca_t, naca_m, naca_p, true),
     camber_y(x, rib_chord, naca_t, naca_m, naca_p, true)]];
lower_pts = [for (i = [0:fn]) let (x = rib_chord * i / fn)
    [camber_x(x, rib_chord, naca_t, naca_m, naca_p, false),
     camber_y(x, rib_chord, naca_t, naca_m, naca_p, false)]];

function arc_to(pts, k) = k <= 0 ? 0 : arc_to(pts, k - 1) + norm(pts[k] - pts[k - 1]);

s_lower = arc_to(lower_pts, fn);   // TE -> LE along the bottom
s_upper = arc_to(upper_pts, fn);   // LE -> TE along the top
s_total = s_lower + s_upper;

// Developed Y of a point x_te mm forward of the TE, on either surface
function y_low(x_te) = s_lower - arc_to(lower_pts, round((rib_chord - x_te) / rib_chord * fn));
function y_up(x_te)  = s_lower + arc_to(upper_pts, round((rib_chord - x_te) / rib_chord * fn));

// --- Template frame and feature positions ------------------------------------
x_root = rib_stations[0] - rib_thickness / 2;  // skin root edge = first rib face
x_tip  = tip_station + tip_rib_flat;           // skin edge lands on the tip band

stations   = concat(rib_stations, [wing_servo_station], aileron_rib_stations,
                    [tip_station]);
spar_te    = rib_chord * (1 - spar_x_pos);     // rear spar, mm from the TE
notch_te   = ctrl_chord + aileron_te_gap;      // aileron TE notch depth (chord)
slot_x     = wing_servo_station + aileron_arm_plane;
slot_half  = servo_horn_r * sin(servo_travel_deg) + pushrod_d / 2 + 1;
ail_end    = aileron_root_station + aileron_span;

// --- Drawing helpers ----------------------------------------------------------
module hline(xa, xb, y) { translate([min(xa, xb), y - lw / 2]) square([abs(xb - xa), lw]); }
module vline(x, ya, yb) { translate([x - lw / 2, min(ya, yb)]) square([lw, abs(yb - ya)]); }
module hdash(xa, xb, y, dash = 8, gap = 5) {
    x0 = min(xa, xb);
    for (x = [x0 : dash + gap : max(xa, xb) - 1])
        hline(x, min(x + dash, max(xa, xb)), y);
}
module vdash(x, ya, yb, dash = 8, gap = 5) {
    y0 = min(ya, yb);
    for (y = [y0 : dash + gap : max(ya, yb) - 1])
        vline(x, y, min(y + dash, max(ya, yb)));
}
module frame(xa, ya, xb, yb) {
    difference() {
        translate([xa, ya]) square([xb - xa, yb - ya]);
        translate([xa + lw, ya + lw]) square([xb - xa - 2 * lw, yb - ya - 2 * lw]);
    }
}
module seg(a, b) { hull() { translate(a) circle(d = lw, $fn = 16); translate(b) circle(d = lw, $fn = 16); } }
module label(x, y, s, size = 4) { translate([x, y]) text(s, size = size); }

// --- The template -------------------------------------------------------------

// sheet outline
frame(x_root, 0, x_tip, s_total);

// LE fold / score line
hdash(x_root, x_tip, s_lower);

// spar lines (rear + front; upper surface, where the glue reference matters)
hline(x_root, x_tip, y_up(spar_te));
hline(x_root, x_tip, y_up(spar_te + spar_spacing));

// rib stations: dashed glue lines across the full developed chord
for (s = stations) vdash(s, 0, s_total);

// servo-arm slot: CUT OUT before skinning (gated by scripts/wing_check.py)
frame(slot_x - 2, y_up(aileron_arm_x_te + slot_half),
      slot_x + 2, y_up(aileron_arm_x_te - slot_half));

// aileron TE notch: the skin ends at the hinge crop line over the aileron
// span, on BOTH surfaces — crossed boxes mark the corner regions to cut off
for (y = [[0, y_low(notch_te)], [y_up(notch_te), s_total]]) {
    frame(aileron_root_station, y[0], ail_end, y[1]);
    seg([aileron_root_station, y[0]], [ail_end, y[1]]);
    seg([aileron_root_station, y[1]], [ail_end, y[0]]);
}

// print-scale check bar: exactly 100 mm between the end ticks
scale_y = 25;
hline(x_root + 20, x_root + 120, scale_y);
vline(x_root + 20, scale_y - 3, scale_y + 3);
vline(x_root + 120, scale_y - 3, scale_y + 3);

// labels
label(x_root + 20, scale_y + 6, "100 mm - check before cutting");
label(x_root + 20, s_lower - 12, str("STARLING wing skin  ", x_tip - x_root,
      " x ", round(s_total), "  chord ", rib_chord, "  naca ", naca_code));
label(x_root + 20, s_lower - 20,
      "one template for both panels - flip the foam for the mirror side", 3.2);
label(x_root + 20, s_lower + 8, "fold line - score, LE");
label(x_root + 20, y_up(spar_te) + 2, "rear spar", 3.2);
label(x_root + 20, y_up(spar_te + spar_spacing) + 2, "front spar", 3.2);
label(slot_x - 45, y_up(aileron_arm_x_te) - 2, "servo arm slot - cut", 3.2);
label(aileron_root_station + 8, y_up(notch_te) + 4, "aileron - cut off", 3.2);
label(x_root + 20, s_total - 10,
      "upper TE - rough-cut oversize, trim after test wrap", 3.2);
