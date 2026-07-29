// ============================================================
// STARLING SHARED DESIGN PARAMETERS — single source of truth for
// every dimension two parts must agree on.
//
// Consumers:
//   - every part in cad/ does        include <design_params.scad>
//   - parts in cad/calibration/ do   include <../design_params.scad>
//   - scripts/check_params.py FAILS the build if any of these names
//     is re-declared anywhere else — change values HERE only.
//
// Keep this file to simple `name = value;` lines so the tooling can
// parse it. One-off experiments: `openscad -D name=value` beats the
// include, no need to edit this file.
// ============================================================

// --- The paper tube (bought part, consumable) ---
// BOTH diameters are measured, not derived from a nominal wall thickness:
// paper wall varies batch to batch, so the OD does not predict the bore.
// Print the two calibration gauges with every new batch of tube, and type
// the number engraved on the best-fitting variant in here.
tube_od     = 52.95;   // sleeves slide OVER this — cad/calibration/tube_fit_ring.scad
tube_id     = 46.95;   // plugs slide INTO this  — cad/calibration/tube_bore_gauge.scad
tube_length = 540;

// --- Printed-part fits ---
sleeve_clearance = 0;   // added to every sleeve bore diameter; tune via the fit ring
plug_clearance   = 0;   // subtracted from every plug OD; tune via the bore gauge
fit_tol          = 0.2; // clearance for printed slots/pockets
sleeve_wall      = 3;   // wall thickness of printed sleeves

// --- Wing spar chain (rib holes = adapter sockets = carbon rods) ---
spar_rod_d    = 6;     // carbon rod diameter
spar_hole_d   = 6.2;   // printed hole for that rod
spar_spacing  = 20;    // chordwise distance between the two spars
spar_y_offset = 1.5;   // spar line sits this far above the rib chord line
spar_x_pos    = 0.4;   // rear spar chord fraction (front spar sits
                       // spar_spacing further forward, at 20% on a 100 chord)
spar_socket_lift = 1;  // adapter socket floor sits this far above the sleeve
                       // bore — rods must never reach the paper tube or they
                       // jam against it and block the CG slide

// --- Wing geometry ---
rib_chord     = 100;
naca_code     = 2415;  // cambered lifting section
rib_thickness = 2;
servo_rib_thickness = 4; // the servo rib prints thicker — it reacts the whole
                         // servo/linkage load until the skin is glued on
tip_rib_flat  = 3;     // full-profile band at the tip rib's inboard face;
                       // the foam skin's outboard edge lands on it
tip_spar_socket = 6;   // blind spar-socket depth in the tip rib; the spar
                       // rods are cut so they END inside these sockets, so
                       // the assembly's spar length derives from this too
aileron_te_gap  = 2;   // extra TE crop beyond the hinge line so the aileron
                       // LE can swing under the taped top hinge (see
                       // cad/wing_rib.scad for the geometry rationale)

// --- Wing adapter <-> root rib interface ---
wing_tab_thickness = 11; // adapter tab (socket carrier; ribs sit outboard of it)
wing_tab_span      = 15; // how far the tab reaches out from the sleeve
adapter_length     = 40; // sleeve length = tab chord extent

// --- Wing span layout (per panel, X from the fuselage centerline) ---
// Span is a first-class tunable: resize the wing per mission and rod stock
// by editing these literals, then satisfy scripts/wing_check.py, which
// enforces the relationships between them (spar fit window, station order,
// arm-slot clearance) and prints the spar cavity so rods can be cut to
// match whatever stock is on hand.
rib_stations         = [47, 120, 200]; // full-chord standard ribs
wing_servo_station   = 280;  // servo rib REPLACES the row rib here
aileron_rib_stations = [360];// TE-cropped ribs inside the aileron span
aileron_root_station = 283;  // = wing_servo_station + servo_rib_thickness/2
                             //   + 1 mm gap (wing_check.py enforces this)
aileron_span         = 120;
tip_station          = 440;  // tip rib inboard face — THE span knob
spar_rod_len         = 417;  // carbon rod length per spar per side (cut from
                             // stock; one 500 mm kite rod covers this with a
                             // single cut) — wing_check.py verifies the fit

// --- Stations along the tube (assembly; wing slides for CG trim) ---
wing_station       = 300; // wing adapter position, measured from the motor face
tail_tube_stop     = 54;  // tube bottoms out here inside the tail sleeve (rim top)
nose_sleeve_length = 20;  // how far the nose cone slides over the tube

// --- Servos (9 g / SG90 class) ---
servo_body   = [23, 12.2]; // [length, width]
servo_flange = [32, 12.2];
servo_height = 22;         // body height incl. shaft boss, without horn

// --- Control system (internal servos, wire pushrods through wall slots) ---
ctrl_chord       = 22;   // control-surface chord (elevator / rudder / aileron)
ctrl_thickness   = 4;    // control-surface root thickness = fin thickness
hinge_groove_w   = 1.6;  // groove for the hinge strip/tape, both fin TE and surface LE
hinge_groove_d   = 2.5;
pushrod_d        = 1.2;  // piano-wire pushrod, attached at the TIP of both arms
pushrod_slot_w   = 2.5;  // wall slot the pushrod moves in
pushrod_slot_len = 18;   // slot channel length along the rod (see throw_check.py)
servo_horn_r     = 10;   // full arm length — the wire connects at the far end
servo_travel_deg = 45;   // used one-sided travel; the arm can do ~±90 (180 total)
                         // but the linkage stays near-linear only within ±45
ctrl_horn_r      = 10;   // control-surface horn = servo horn -> 1:1 linkage
aileron_arm_plane = 9.2; // the aileron servo's arm plane sits this far
                         // outboard of the servo-rib station (flange seat +
                         // shaft boss + horn plate)
aileron_arm_x_te  = 39;  // arm-tip chord position, measured from the TE —
                         // sets where the skin's arm slot goes (gated by
                         // wing_check.py against the spar and aileron notch)

// Tail linkage geometry. Three 22 mm-wide servos cannot share one height
// inside the Ø53 bore (corner collisions), so they are STAGGERED in Z:
// the two elevator servos sit HIGH (opposite sides, they coexist), the
// rudder servo sits LOW. Each wire attaches at the arm tip and exits
// through an angled wall slot raked toward its surface horn.
tail_servo_z           = 33; // bottom (shaft end) of the ELEVATOR servo bodies
tail_slot_angle        = 42; // elevator rod angle off the fuselage axis
tail_rudder_z          = 9;  // bottom (shaft end) of the RUDDER servo body
tail_rudder_slot_angle = 56; // rudder rod angle off the fuselage axis

// --- Motor (22xx class, rear pusher) ---
motor_shaft_hole_d = 10;
motor_screw_hole_d = 4;
motor_pattern_x    = 16;  // screw pattern
motor_pattern_y    = 19;
