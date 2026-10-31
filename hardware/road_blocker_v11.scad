// =====================================================================
//  Toy-car Road Blocker - enclosure, barrier arm, arm rest and clamps
//  VERSION 11  (2026-10-17)
//
//  v1  first design: box, lid, arm, rest; screws for servo, rails for sensor
//  v2  part colours; screwless clamps in floor slots, locked by lid ribs
//  v3  45-degree wedges under wall pads - prints without supports
//  v4  US-025A sensor sizes; cans flush with the outer wall face;
//      clamps moved back; servo shelf from below + flange-ear stops
//  v5  US-025A can spacing: 6.9 mm gap between cans (HC-SR04: 9.9 mm)
//  v6  sensor pads: centre pad removed (crystal), 4 corner pads, each its own colour
//  v7  two support walls under the sensor board - it cannot be pushed down
//  v8  real main-PCB size: 90 x 89 mm, M2 holes 3.6 mm from the edges
//  v9  panel USB-C socket (on wires, not on the PCB): hole 3 mm longer, raised;
//      front M2 hole pair 3.5 mm further apart; PCB 5 mm further from the back wall
//  v10 FIX: front M2 pair moved 3.5 mm FORWARD (toward sensor/servo), not sideways;
//      hole check: console printout, PCB ghost in the assembly, printable 1:1 template
//  v11 PCB standoffs: M2 heat-set insert holes, 3 mm taller (9 mm), coloured in pairs;
//      console prints the M2 -> servo/sensor clamp distances
//
//  For the ESP32 DOIT DevKit V1 PCB (train-controller board, 2022-07-06)
//  Front face : US-025A ultrasonic (U7) + MG90S servo (S1) with barrier arm
//  Back face  : power switch (CN3) + USB charging port (U3)
//  Lid        : red + green 5 mm LEDs (to CN9 / CN8)
//
//  Axes: X = along the front face (left -> right seen from the front)
//        Y = front -> back (front face at Y = 0), Z = up
//  Export each part separately by setting `part`.
// =====================================================================

version = "v11";
part = "all";   // "all" | "box" | "lid" | "arm" | "rest" | "sensor_clamp" | "servo_clamp" | "assembly" | "pcb_template"
assembly_angle = 0;      // assembly preview only: 0 = blocked, 90 = open

// ------------------------- top-level calls --------------------------
echo(str("Road blocker ", version));
if (part == "box"          || part == "all") color(c_box) box();
if (part == "lid"          || part == "all") color(c_lid) translate([outer_x + 10, 0, 0]) lid_print();
if (part == "arm"          || part == "all") color(c_arm) translate([stub_len + 5, -hub_d/2 - 12, 0]) arm();
if (part == "rest"         || part == "all") color(c_rest) translate([150, -75, 0]) arm_rest();
if (part == "sensor_clamp" || part == "all") color(c_sclamp) translate([us_w/2, -100, 0]) sensor_clamp_print();
if (part == "servo_clamp"  || part == "all") color(c_vclamp) translate([60 + scl_w/2, -100, 0]) servo_clamp_print();
if (part == "assembly") assembly();
if (part == "pcb_template") color("White") pcb_template();

// ============================ PARAMETERS ============================
$fn = 48;
eps = 0.01;

/* ---------- part colours (preview) ---------- */
c_box    = "SteelBlue";
c_lid    = "Gold";
c_arm    = "Crimson";
c_rest   = "DarkOrange";
c_sclamp = "LimeGreen";
c_vclamp = "MediumPurple";

/* ---------- shell ---------- */
wall     = 2.5;
floor_t  = 2.5;
lid_t    = 2.5;
r_corner = 3;

/* ---------- main PCB  (measured) ---------- */
pcb_l          = 90;    // length, along the front face (X)
pcb_w          = 89;    // width, front-to-back (Y)
pcb_t          = 1.6;
pcb_hole_inset = 3.6;   // M2 hole centres from the PCB edges
standoff_h     = 9;     // was 6 - PCB 3 mm higher
standoff_d     = 7;     // wall around the insert
insert_d       = 3.2;   // M2 heat-set insert hole (M2 x 3 x 3.2 OD inserts; check yours)
insert_depth   = 4;     // insert length + ~1 mm
screw_clear_d  = 2.4;   // below the insert: room for the screw tip
c_standoff_front = "Chartreuse";   // front pair (sensor / servo side)
c_standoff_back  = "DarkViolet";   // back pair (switch / USB side)
side_clear     = 4;     // gap PCB <-> side walls
front_zone     = 34;    // space in front of the PCB for sensor, servo and clamps
back_gap       = 6;     // PCB edge <-> back wall (room for the USB socket + switch bodies)

inner_x = pcb_l + 2*side_clear;
inner_y = front_zone + pcb_w + back_gap;
inner_z = 50;

outer_x = inner_x + 2*wall;
outer_y = inner_y + 2*wall;
outer_z = floor_t + inner_z;

pcb_x0 = wall + side_clear;
pcb_y0 = wall + front_zone;
pcb_z0 = floor_t + standoff_h;          // underside of PCB
// M2 holes. Side-to-side (X): 3.6 mm from each side edge -> 82.8 mm apart.
// Front-to-back (Y): back pair 3.6 mm from the back edge; the front pair is
// pcb_hole_extra_y further FORWARD (toward sensor + servo) than 3.6 mm from
// the front edge.  ** Check: with 89 mm width this leaves the front holes
// only 0.1 mm from the front edge - verify with part="pcb_template". **
pcb_hole_extra_y = 3.5;
pcb_hole_dx = pcb_l - 2*pcb_hole_inset;                       // 82.8 mm
pcb_hole_dy = pcb_w - 2*pcb_hole_inset + pcb_hole_extra_y;    // 85.3 mm
pcb_hole_y_back  = pcb_w - pcb_hole_inset;                    // 85.4 from PCB front edge
pcb_hole_y_front = pcb_hole_y_back - pcb_hole_dy;             //  0.1 from PCB front edge
pcb_holes = [ for (y = [pcb_hole_y_front, pcb_hole_y_back])
              for (x = [pcb_hole_inset, pcb_l - pcb_hole_inset]) [x, y] ];
echo(str("PCB M2 holes (from PCB front-left corner, mm): ", pcb_holes));
echo(str("Hole spacing  side-to-side: ", pcb_hole_dx, "   front-to-back: ", pcb_hole_dy));

/* ---------- clamps (shared) ---------- */
lid_gap   = 0.3;    // clamp top <-> lid underside
slot_h    = 5;      // height of the floor slot bosses
slot_fit  = 0.2;    // clearance per side in the slot
slot_wall = 2;      // boss wall around the slot
rib_h     = 3;      // lid rib that locks the clamp tops
rib_t     = 2;
clamp_H   = outer_z - floor_t - lid_gap;   // clamp height (floor -> lid)

/* ---------- US-025A ultrasonic (front, left)  (MEASURE YOUR MODULE) ---------- */
us_w        = 45;     // board width  (X)
us_h        = 20;     // board height (Z)
us_t        = 1.2;    // board thickness
us_can_d    = 16;     // transducer can diameter
us_can_gap  = 6.9;    // edge-to-edge gap between the two cans (measured; HC-SR04 = 9.9)
us_pitch    = us_can_d + us_can_gap;   // centre spacing = 22.9 mm
us_can_h    = 12;     // can height, board front face -> can face
us_hole_d   = us_can_d + 0.4;   // snug - stops the module sliding down
us_recess   = 0;      // can face behind the outer wall face (0 = flush)
us_pad      = 3;      // locating pad height (wall pads) and size (clamp pads)
us_pad_w    = 2.5;    // wall pad width at the board edge - keeps the wedges clear of the cans
pad_colors  = ["Red", "Yellow", "Magenta", "Cyan"];   // bottom-left, bottom-right, top-left, top-right
us_sup_w    = 5;      // support walls under the board: width (at each board end)
c_us_sup    = "Orange";   // support-wall colour (preview)
us_cx       = wall + side_clear + 4 + us_w/2;
us_cz       = 36;     // board bottom at 26 mm: room for the header + Dupont plugs below

us_y_front  = us_recess + us_can_h;      // board front face (cans reach back to the outer face)
us_y_back   = us_y_front + us_t;         // board back face
us_standoff = us_y_front - wall;         // pad depth: inner wall face -> board front

ucl_pad = 2.5;        // clamp pads: clear the back-side components / solder joints
ucl_t   = 3.5;        // clamp plate thickness
ucl_w   = us_w;       // clamp width
ucl_leg = 7;          // leg width (legs go into the floor slots)
ucl_y   = us_y_back + ucl_pad;           // clamp plate front face

/* ---------- MG90S servo (front, right)  (MEASURE YOUR SERVO) ---------- */
srv_body_x       = 22.8;
srv_body_z       = 12.4;
srv_clear        = 0.4;
srv_flange_x     = 32.5;
srv_flange_t     = 2.5;
srv_below_flange = 20;    // flange (wall side) -> servo bottom face  ** measure **
srv_above_flange = 6;     // flange -> gear-top of the body (preview only)
srv_pad_t        = 4;     // front-wall thickness around the servo (flange seat)
srv_cx           = outer_x - wall - 9 - srv_flange_x/2;
srv_cz           = 34;    // = arm pivot height above the table
srv_shaft_dx     = 5.5;   // shaft offset from body centre; fit servo with shaft toward +X
srv_protrude     = 8;     // horn face in front of the box face (preview / rest placement)
srv_cable_side   = -1;    // -1: cable exits at the -X end (away from shaft), +1: +X end

srv_y_bottom = srv_pad_t + srv_below_flange;    // servo bottom face
srv_z_under  = srv_cz - (srv_body_z + srv_clear)/2;   // underside of the servo

// shelf (support from below)
shf_rib  = 2;         // rib thickness
shf_top  = 2;         // shelf plate thickness
shf_w    = srv_body_x - 2;   // narrower than the body: cable at the end stays free
// flange-ear stops (keep the servo centred sideways)
ear_stop_w = 2.5;
ear_stop_h = 4;       // height of the stop (from the bottom of the ear)

scl_pocket = 1.5;     // pocket in the clamp that cradles the servo bottom
scl_t      = 5;       // clamp plate thickness (incl. pocket)
scl_w      = srv_body_x + srv_clear + 6;
scl_y      = srv_y_bottom - scl_pocket;         // clamp plate front face

// ---- clearance report: front M2 standoffs <-> clamps (printed in the console) ----
function rect_dist(px, py, x0, x1, y0, y1) =
    let(dx = max(x0 - px, 0, px - x1), dy = max(y0 - py, 0, py - y1)) sqrt(dx*dx + dy*dy);
_mfl = [pcb_x0 + pcb_holes[0][0], pcb_y0 + pcb_holes[0][1]];   // front-left M2 centre
_mfr = [pcb_x0 + pcb_holes[1][0], pcb_y0 + pcb_holes[1][1]];   // front-right M2 centre
_d_srv  = rect_dist(_mfr[0], _mfr[1], srv_cx - scl_w/2, srv_cx + scl_w/2, scl_y, scl_y + scl_t);
_d_srvb = rect_dist(_mfr[0], _mfr[1], srv_cx - scl_w/2 - slot_fit - slot_wall, srv_cx + scl_w/2 + slot_fit + slot_wall,
                    scl_y - slot_fit - slot_wall, scl_y + scl_t + slot_fit + slot_wall);
_d_us   = rect_dist(_mfl[0], _mfl[1], us_cx - ucl_w/2, us_cx + ucl_w/2, ucl_y, ucl_y + ucl_t);
echo(str("Front-right M2 centre -> servo clamp: ", _d_srv, " mm  (-> its floor-slot boss: ", _d_srvb, " mm)"));
echo(str("Front-left  M2 centre -> sensor clamp: ", _d_us, " mm"));

/* ---------- back panel ---------- */
sw_w       = 13;  sw_h = 19;   // mini rocker (KCD1-style) cutout
sw_round_d = 0;                // > 0 -> round hole of this diameter instead
sw_cx      = outer_x - 28;
sw_cz      = floor_t + 32;
// panel-mount USB-C socket on a PH2.0 lead (not soldered to the PCB)
usb_w      = 15;  usb_h = 7;   // opening: long edge 15 (was 12), short edge 7
usb_cx     = wall + 25;        // centre, from the left outer face (seen from the FRONT)
usb_cz     = floor_t + 20;     // centre height - well above the PCB (PCB top at ~10 mm)

/* ---------- lid fixing ---------- */
post        = 7;
post_h      = 12;
m3_pilot    = 2.5;
m3_clear    = 3.4;
m3_head_d   = 6.4;
screw_depth = 10;
lip_h = 3;  lip_t = 1.6;  lip_clear = 0.3;

/* ---------- LEDs on the lid ---------- */
led_d       = 5.1;          // 5 mm LED pushed up from below, rim stops it
led_pitch   = 18;
led_cx      = outer_x/2;
led_cy      = wall + front_zone + 12;
labels      = true;
label_size  = 5;
label_depth = 0.6;

/* ---------- barrier arm ---------- */
arm_len      = 150;
arm_h        = 10;
arm_t        = 4.5;
hub_d        = 18;
hub_t        = 7;
stub_len     = 18;
horn_len     = 14.5;   // spline centre -> tip-circle centre of single-arm horn (measure)
horn_hub_d   = 7.5;
horn_tip_d   = 4.5;
horn_t       = 1.8;
horn_fit     = 0.25;
horn_screw_d = 2.4;
horn_head_d  = 5;
horn_head_h  = 2;

/* ---------- arm rest (far side of the road) ---------- */
rest_base    = [40, 30, 3];
rest_col     = 8;
rest_prong_h = 8;
rest_gap     = arm_t + 1.5;

// ============================== HELPERS =============================
module rbox(s, r) {
    hull() for (x = [r, s[0] - r], y = [r, s[1] - r])
        translate([x, y, 0]) cylinder(r = r, h = s[2]);
}

// [x, y, isRight, isBack] of each inner-corner post
function post_xy() = [ for (sx = [0, 1]) for (sy = [0, 1])
    [ sx == 0 ? wall : outer_x - wall - post,
      sy == 0 ? wall : outer_y - wall - post, sx, sy ] ];

// block sticking out of a wall face (at y = y0, toward +Y) with a 45-degree
// wedge underneath so it prints without supports
module wall_block(x0, y0, z0, sx, d, sz) {
    hull() {
        translate([x0, y0 - eps, z0]) cube([sx, d + eps, sz]);
        translate([x0, y0 - eps, z0 - d]) cube([sx, eps, eps]);
    }
}

// floor boss with a slot: slot footprint [x0, y0, size_x, size_y] (nominal, no clearance)
module slot_boss(x0, y0, sx, sy) {
    difference() {
        translate([x0 - slot_fit - slot_wall, y0 - slot_fit - slot_wall, floor_t - eps])
            cube([sx + 2*(slot_fit + slot_wall), sy + 2*(slot_fit + slot_wall), slot_h + eps]);
        translate([x0 - slot_fit, y0 - slot_fit, floor_t])
            cube([sx + 2*slot_fit, sy + 2*slot_fit, slot_h + 1]);
    }
}

// ================================ BOX ===============================
module box() {
    difference() {
        union() {
            difference() {
                rbox([outer_x, outer_y, outer_z], r_corner);
                translate([wall, wall, floor_t]) cube([inner_x, inner_y, inner_z + 1]);
            }
            pcb_standoffs();
            corner_posts();
            servo_pad();
            servo_ear_stops();
            servo_shelf();
            sensor_pads();
            sensor_supports();
            clamp_slots();
        }
        sensor_holes();
        servo_cutout();
        back_cutouts();
        for (p = post_xy())
            translate([p[0] + post/2, p[1] + post/2, outer_z - screw_depth])
                cylinder(d = m3_pilot, h = screw_depth + 1);
        for (h = pcb_holes) translate([pcb_x0 + h[0], pcb_y0 + h[1], 0]) {
            translate([0, 0, pcb_z0 - insert_depth]) cylinder(d = insert_d, h = insert_depth + 1);
            translate([0, 0, floor_t]) cylinder(d = screw_clear_d, h = standoff_h);
        }
    }
}

// pcb_holes order: front-left, front-right, back-left, back-right
module pcb_standoffs() {
    for (i = [0:3])
        color(i < 2 ? c_standoff_front : c_standoff_back)
            translate([pcb_x0 + pcb_holes[i][0], pcb_y0 + pcb_holes[i][1], floor_t - eps])
                cylinder(d = standoff_d, h = standoff_h + eps);
}

// lid-screw posts hang from the top with a 45-degree gusset (no supports)
module corner_posts() {
    for (p = post_xy()) translate([p[0], p[1], 0]) hull() {
        translate([0, 0, outer_z - post_h]) cube([post, post, post_h]);
        translate([p[2]*(post - 0.2), p[3]*(post - 0.2), outer_z - post_h - post*1.45])
            cube([0.2, 0.2, 0.2]);
    }
}

// ---- US-025A: can holes, 4 locating pads, 2 support walls ----
module sensor_holes() {
    for (s = [-1, 1])
        translate([us_cx + s*us_pitch/2, -1, us_cz]) rotate([-90, 0, 0])
            cylinder(d = us_hole_d, h = us_y_front + 1);   // also trims pads clear of the cans
}

// 4 pads, one at each board corner (centre pad removed - crystal).
// Each pad is us_pad_w wide at the very edge of the board, so its wedge
// runs down outside the cans. The board front face rests on them, which
// sets the can faces flush with the outer wall.
// Colours (preview): pad_colors = [bottom-left, bottom-right, top-left, top-right]
module sensor_pads() {
    zb = us_cz - us_h/2;
    for (i = [0:3]) {
        sx = (i % 2 == 0) ? -1 : 1;              // left / right (seen from the front)
        top = i >= 2;
        color(pad_colors[i])
            wall_block(us_cx + sx*(us_w/2 - us_pad_w/2) - us_pad_w/2, wall,
                       top ? zb + us_h - us_pad : zb,
                       us_pad_w, us_standoff, us_pad);
    }
}

// two walls from the floor up to the board's bottom edge, one under each
// end of the board (the header + Dupont plugs hang down in the middle, between
// them). They run from the front wall back to the board's back face - not
// further, so the clamp pads can still slide down past them.
module sensor_supports() {
    zb = us_cz - us_h/2;
    color(c_us_sup) for (s = [-1, 1])
        translate([us_cx + s*(us_w/2 - us_sup_w/2) - us_sup_w/2, wall - eps, floor_t - eps])
            cube([us_sup_w, us_y_back - wall + eps, zb - floor_t + eps]);
}

// ---- MG90S: flange seats on a thickened pad, body pokes through ----
module servo_pad() {
    wall_block(srv_cx - srv_flange_x/2 - 3, wall, srv_z_under - 5,
               srv_flange_x + 6, srv_pad_t - wall, srv_body_z + 10);
}

module servo_cutout() {
    translate([srv_cx - (srv_body_x + srv_clear)/2, -1, srv_z_under])
        cube([srv_body_x + srv_clear, srv_pad_t + 2, srv_body_z + srv_clear]);
}

// stops just outside the flange ear tips - centre the servo sideways
module servo_ear_stops() {
    ex = srv_flange_x/2 + 0.3;
    for (s = [-1, 1])
        wall_block(s < 0 ? srv_cx - ex - ear_stop_w : srv_cx + ex, srv_pad_t,
                   srv_z_under, ear_stop_w, srv_flange_t, ear_stop_h);
}

// shelf under the servo: two ribs from the floor + a top plate;
// the servo slides in over it and cannot be pushed down
module servo_shelf() {
    y0 = srv_pad_t - eps;
    y1 = srv_y_bottom - 4.5;            // stops short of the clamp slot boss
    zt = srv_z_under;
    for (s = [-1, 1])
        translate([srv_cx + s*(shf_w/2 - shf_rib/2) - shf_rib/2, y0, floor_t - eps])
            cube([shf_rib, y1 - y0, zt - floor_t + eps]);
    translate([srv_cx - shf_w/2, y0, zt - shf_top]) cube([shf_w, y1 - y0, shf_top]);
}

// ---- floor slots for the two clamps ----
module clamp_slots() {
    for (s = [-1, 1])     // sensor clamp: one slot per leg
        slot_boss(s < 0 ? us_cx - ucl_w/2 : us_cx + ucl_w/2 - ucl_leg, ucl_y, ucl_leg, ucl_t);
    slot_boss(srv_cx - scl_w/2, scl_y, scl_w, scl_t);   // servo clamp
}

// ---- back: power switch + USB charging port ----
module back_cutouts() {
    yb  = outer_y - wall - 1;
    if (sw_round_d > 0)
        translate([sw_cx, yb, sw_cz]) rotate([-90, 0, 0]) cylinder(d = sw_round_d, h = wall + 2);
    else
        translate([sw_cx - sw_w/2, yb, sw_cz - sw_h/2]) cube([sw_w, wall + 2, sw_h]);

    hull() for (s = [-1, 1])
        translate([usb_cx + s*(usb_w - usb_h)/2, yb, usb_cz]) rotate([-90, 0, 0])
            cylinder(d = usb_h, h = wall + 2);
}

// ============================== CLAMPS ==============================
// Modelled installed: front (pressing) face at y = 0, plate toward +Y,
// z = 0 at the floor surface (bottom of the slot).

// US-025A clamp: two legs in floor slots, bridge on top, 4 corner pads
// pressing the board corners; open window below the board for the wires.
module sensor_clamp() {
    zb  = us_cz - us_h/2 - floor_t;        // board bottom edge (local z)
    difference() {
        translate([-ucl_w/2, 0, 0]) cube([ucl_w, ucl_t, clamp_H]);
        translate([-ucl_w/2 + ucl_leg, -1, -1]) cube([ucl_w - 2*ucl_leg, ucl_t + 2, zb - 2 + 1]);
    }
    for (sx = [-1, 1], sz = [-1, 1])
        translate([sx*(ucl_w/2 - us_pad/2) - us_pad/2, -ucl_pad - eps,
                   zb + us_h/2 + sz*(us_h/2 - us_pad/2) - us_pad/2])
            cube([us_pad, ucl_pad + 2*eps, us_pad]);
}

// MG90S clamp: plate with a shallow pocket that cradles the servo bottom,
// pocket open on the cable side.
module servo_clamp() {
    bx = srv_body_x + srv_clear;
    bz = srv_body_z + srv_clear;
    zc = srv_cz - floor_t;
    difference() {
        translate([-scl_w/2, 0, 0]) cube([scl_w, scl_t, clamp_H]);
        translate([srv_cable_side < 0 ? -scl_w/2 - 1 : -bx/2, -1, zc - bz/2])
            cube([bx/2 + scl_w/2 + 1, scl_pocket + 1, bz]);
    }
}

// print orientations: back face on the bed, pads / pocket facing up
module sensor_clamp_print() { translate([0, 0, ucl_t]) rotate([-90, 0, 0]) sensor_clamp(); }
module servo_clamp_print()  { translate([0, 0, scl_t]) rotate([-90, 0, 0]) servo_clamp(); }

// ================================ LID ===============================
// modelled in its installed orientation (plate z = 0..lid_t, lip below)
module lid() {
    difference() {
        union() {
            rbox([outer_x, outer_y, lid_t], r_corner);
            translate([0, 0, -lip_h]) difference() {
                translate([wall + lip_clear, wall + lip_clear, 0])
                    cube([inner_x - 2*lip_clear, inner_y - 2*lip_clear, lip_h + eps]);
                translate([wall + lip_clear + lip_t, wall + lip_clear + lip_t, -1])
                    cube([inner_x - 2*(lip_clear + lip_t), inner_y - 2*(lip_clear + lip_t), lip_h + 2]);
            }
            // ribs behind the clamp tops - stop them leaning back
            translate([us_cx - ucl_w/2, ucl_y + ucl_t + 0.3, -rib_h])
                cube([ucl_w, rib_t, rib_h + eps]);
            translate([srv_cx - scl_w/2, scl_y + scl_t + 0.3, -rib_h])
                cube([scl_w, rib_t, rib_h + eps]);
        }
        // notch the lip around the screw posts
        for (p = post_xy())
            translate([p[0] - 1, p[1] - 1, -lip_h - 1]) cube([post + 2.5, post + 2.5, lip_h + 1]);
        // countersunk M3 holes
        for (p = post_xy()) translate([p[0] + post/2, p[1] + post/2, 0]) {
            translate([0, 0, -1]) cylinder(d = m3_clear, h = lid_t + 2);
            translate([0, 0, lid_t - 1.6]) cylinder(d1 = m3_clear, d2 = m3_head_d, h = 1.6 + eps);
        }
        // LEDs: red (left), green (right)
        for (s = [-1, 1])
            translate([led_cx + s*led_pitch/2, led_cy, -lip_h - 1]) cylinder(d = led_d, h = lid_t + lip_h + 2);
        if (labels) {
            translate([led_cx - led_pitch/2, led_cy - 8, lid_t - label_depth])
                linear_extrude(label_depth + 1)
                    text("STOP", size = label_size, halign = "center", valign = "center",
                         font = "Liberation Sans:style=Bold");
            translate([led_cx + led_pitch/2, led_cy - 8, lid_t - label_depth])
                linear_extrude(label_depth + 1)
                    text("GO", size = label_size, halign = "center", valign = "center",
                         font = "Liberation Sans:style=Bold");
        }
    }
}

// print orientation: top face on the bed, lip and ribs up
module lid_print() {
    translate([0, outer_y, lid_t]) rotate([180, 0, 0]) lid();
}

// ============================ BARRIER ARM ===========================
// print flat; z = 0 face (with the horn pocket) faces the servo
module arm() {
    difference() {
        union() {
            cylinder(d = hub_d, h = hub_t);
            hull() {
                translate([0, -arm_h/2, 0]) cube([eps, arm_h, arm_t]);
                translate([arm_len - arm_h/2, 0, 0]) cylinder(d = arm_h, h = arm_t);
            }
            hull() {   // short counter-stub
                translate([-stub_len + arm_h/2, 0, 0]) cylinder(d = arm_h, h = arm_t);
                translate([0, -arm_h/2, 0]) cube([eps, arm_h, arm_t]);
            }
        }
        // single-arm horn pocket, aligned with the arm
        translate([0, 0, -eps]) linear_extrude(horn_t + 0.2)
            offset(delta = horn_fit) hull() {
                circle(d = horn_hub_d);
                translate([horn_len, 0]) circle(d = horn_tip_d);
            }
        // centre screw into the spline + counterbore
        translate([0, 0, -1]) cylinder(d = horn_screw_d, h = hub_t + 2);
        translate([0, 0, hub_t - horn_head_h]) cylinder(d = horn_head_d, h = horn_head_h + 1);
    }
}

// ============================ ARM REST ==============================
// fork the lowered arm drops into, placed on the far side of the road
module arm_rest() {
    cw  = rest_gap + 6;
    top = srv_cz - arm_h/2;            // underside of the lowered arm
    translate([-rest_base[0]/2, -rest_base[1]/2, 0]) cube(rest_base);
    translate([-rest_col/2, -cw/2, 0]) cube([rest_col, cw, top]);
    for (s = [-1, 1])
        translate([-rest_col/2, s < 0 ? -cw/2 : rest_gap/2, 0])
            cube([rest_col, (cw - rest_gap)/2, top + rest_prong_h]);
}

// ========================= PCB CHECK TEMPLATE =======================
// 1:1 thin plate: PCB outline with the M2 hole positions. Print it (2 layers),
// lay the real PCB on it and see if the holes line up. Front edge is marked
// with an arrow pointing toward the sensor/servo side.
module pcb_template() {
    t = 0.6;
    difference() {
        cube([pcb_l, pcb_w, t]);
        for (h = pcb_holes) translate([h[0], h[1], -1]) cylinder(d = 2.2, h = t + 2);
        translate([pcb_l/2, pcb_w/2, t - 0.3]) linear_extrude(1)
            text(str(version, "  ", pcb_hole_dx, " x ", pcb_hole_dy), size = 5,
                 halign = "center", valign = "center");
        translate([pcb_l/2, 8, t - 0.3]) linear_extrude(1)
            text("FRONT - sensor/servo side", size = 4, halign = "center", valign = "center");
    }
}

// PCB stand-in on its standoffs (assembly preview)
module ghost_pcb() {
    color("ForestGreen", 0.7) translate([pcb_x0, pcb_y0, pcb_z0]) difference() {
        cube([pcb_l, pcb_w, pcb_t]);
        for (h = pcb_holes) translate([h[0], h[1], -1]) cylinder(d = 2.2, h = pcb_t + 2);
    }
}

// ============================= ASSEMBLY =============================
module assembly() {
    color(c_box) box();
    color(c_lid, 0.5) translate([0, 0, outer_z]) lid();
    color(c_sclamp) translate([us_cx, ucl_y, floor_t]) sensor_clamp();
    color(c_vclamp) translate([srv_cx, scl_y, floor_t]) servo_clamp();
    ghost_sensor();
    ghost_servo();
    ghost_pcb();
    color(c_arm) translate([srv_cx + srv_shaft_dx, -srv_protrude, srv_cz])
        rotate([0, -assembly_angle, 0]) rotate([90, 0, 0]) arm();
    color(c_rest) translate([srv_cx + srv_shaft_dx + arm_len - 12, -srv_protrude - arm_t/2, 0])
        arm_rest();
}

// simple stand-ins for checking fit (not printed)
module ghost_sensor() {
    color("DarkGreen") translate([us_cx - us_w/2, us_y_front, us_cz - us_h/2]) cube([us_w, us_t, us_h]);
    color("Silver") for (s = [-1, 1])
        translate([us_cx + s*us_pitch/2, us_y_front + eps, us_cz]) rotate([90, 0, 0])
            cylinder(d = us_can_d, h = us_can_h);
}

module ghost_servo() {
    color("RoyalBlue") {
        translate([srv_cx - srv_body_x/2, srv_pad_t, srv_cz - srv_body_z/2])
            cube([srv_body_x, srv_below_flange, srv_body_z]);
        translate([srv_cx - srv_flange_x/2, srv_pad_t, srv_cz - srv_body_z/2])
            cube([srv_flange_x, srv_flange_t, srv_body_z]);
        translate([srv_cx - srv_body_x/2, srv_pad_t - srv_above_flange, srv_cz - srv_body_z/2])
            cube([srv_body_x, srv_above_flange, srv_body_z]);
    }
    color("White") translate([srv_cx + srv_shaft_dx, srv_pad_t - srv_above_flange, srv_cz])
        rotate([90, 0, 0]) cylinder(d = 4.8, h = srv_protrude - (srv_above_flange - srv_pad_t));
}
