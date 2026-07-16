// ==============================================================================
//   NACA AIRFOIL LIBRARY FUNCTIONS
// ==============================================================================

$airfoil_fn = 120;
$close_airfoils = true; // Ensures TE closes cleanly

// Function to calculate the half-thickness (y) for a symmetric NACA airfoil
function foil_y(x, c, t) = 
    (5*t*c)*( ( 0.2969 * sqrt(x/c) ) - ( 0.1260*(x/c) ) - ( 0.3516*pow((x/c),2) ) + ( 0.2843*pow((x/c),3) ) - ( ( $close_airfoils ? 0.1036 : 0.1015)*pow((x/c),4) ) ); //NACA symetrical airfoil formula

// Function to calculate the camber line (not strictly needed for 00XX but included for completeness)
function camber(x,c,m,p) = ( x <= (p * c) ? 
    ( ( (c * m)/pow( p, 2 ) ) * ( ( 2 * p * (x / c) ) - pow( (x / c) , 2) ) ) :
    ( ( (c * m)/pow((1 - p),2) ) * ( (1-(2 * p) ) + ( 2 * p * (x / c) ) - pow( (x / c) , 2)))
    );

// Angle of the camber line (for calculating surface points)
function theta(x,c,m,p) = ( x <= (p * c) ? 
    atan( ((m)/pow(p,2)) * (p - (x / c)) ) :
    atan( ((m)/pow((1 - p),2) ) * (p - (x / c)) ) 
    );

// Upper/Lower surface Y coordinates
function camber_y(x,c,t,m,p, upper=true) = ( upper == true ?
    ( camber(x,c,m,p) + (foil_y(x,c,t) * cos( theta(x,c,m,p) ) ) ) :
    ( camber(x,c,m,p) - (foil_y(x,c,t) * cos( theta(x,c,m,p) ) ) )
    );

// Upper/Lower surface X coordinates
function camber_x(x,c,t,m,p, upper=true) = ( upper == true ?
    ( x - (foil_y(x,c,t) * sin( theta(x,c,m,p) ) ) ) :
    ( x + (foil_y(x,c,t) * sin( theta(x,c,m,p) ) ) )
    );


module airfoil_poly (c = 100, naca = 0015, raw=false) {
    // Global variable setup (required by the imported library)
    $close_airfoils = ($close_airfoils != undef) ? $close_airfoils : false;
    $airfoil_fn = ($airfoil_fn != undef) ? $airfoil_fn : 100;
    res = c/$airfoil_fn; //resolution of foil poly 
    
    // establish thickness/length ratio
    t = (raw == false) ? ((naca%100)/100) : raw[2]; 
    // maximum camber:chord
    m = (raw == false) ?((floor((((naca-(naca%100))/1000))) /100) ):raw[0];
    //distance of maximum camber from the airfoil leading edge in tenths of the chord
    p = (raw == false) ?((((naca-(naca%100))/100)%10) / 10): raw[1];

    
    // points have to be generated with or without camber, depending. 
    points_u = ( m == 0 || p == 0) ?
        [for (i = [0:res:c]) let (x = i, y = foil_y(i,c,t) ) [x,y]] :
        [for (i = [0:res:c]) let (x = camber_x(i,c,t,m,p), y = camber_y(i,c,t,m,p) ) [x,y]] ;
    
    points_l = ( m == 0 || p == 0) ?
        [for (i = [c:-1*res:0]) let (x = i, y = foil_y(i,c,t) * -1 ) [x,y]] :
        [for (i = [c:-1*res:0]) let (x = camber_x(i,c,t,m,p,upper=false), y = camber_y(i,c,t,m,p, upper=false) ) [x,y]] ;   
 
    polygon(concat(points_u,points_l)); //draw poly
}

// ==============================================================================
//   CONFIGURATION VARIABLES
// ==============================================================================

// --- Global Resolution ---
$fn = 120; // Smooth curves

servo_adapter = false;

// --- Rib Dimensions ---
rib_chord = 100;                 // Length of the rib from Leading Edge (LE) to Trailing Edge (TE)
naca_code = 2415;               // The specific NACA profile to use (Symmetric)
rib_thickness_z = 2;            // Thickness of the physical rib part (Z-axis)

// --- Structural Slots & Spars ---
spar_spacing = 20;
carbon_spar_diameter = 6.2;  
cable_hole_diameter = 6;
spar_x_pos = 0.4;               // X-position of the spar hole as a fraction of chord (0=LE, 1=TE)
spar_y_offset = 1.5;             // Vertical offset of the spar hole from the centerline (negative = below center)
cable_hole_x_pos = 0.6;               // X-position of the spar hole as a fraction of chord (0=LE, 1=TE)
cable_hole_y_offset = 1.5;             // Vertical offset of the spar hole from the centerline (negative = below center)
foam_slot_thickness = 5;        // Thickness of the slot for the foam board skin (runs along top/bottom)
adapter_slot_thickness = 15;    // Thickness of the slot for the adapter plate (must match wing_tab_thickness)
adapter_slot_depth = 5;         // Depth the adapter slot extends into the rib

// --- Derived Constants ---
rib_half_thickness_z = rib_thickness_z / 2;


// ==============================================================================
//   MAIN RIB MODULE
// ==============================================================================

module wing_rib_with_cutouts() {
    difference() {
        translate([rib_chord, 0, 0])
        rotate([0, 180, 0]) {
            linear_extrude(height = rib_thickness_z, center = true) {
                airfoil_poly(c = rib_chord, naca = naca_code);
            }
        }
        
        union() {
            spar_x_offset = rib_chord * (1 - spar_x_pos);
            cable_hole_x_offset = rib_chord * (1 - cable_hole_x_pos);
            
            translate([spar_x_offset, spar_y_offset, 0])
            cylinder(h=rib_thickness_z * 2 + 0.2, d=carbon_spar_diameter, center=true);
            
            translate([spar_x_offset+spar_spacing, spar_y_offset, 0])
            cylinder(h=rib_thickness_z * 2 + 0.2, d=carbon_spar_diameter, center=true);
            
            translate([cable_hole_x_offset, cable_hole_y_offset, 0])
            cylinder(h=rib_thickness_z * 2 + 0.2, d=cable_hole_diameter, center=true);
        }
    }
}

// --- Render the Module ---
wing_rib_with_cutouts();
