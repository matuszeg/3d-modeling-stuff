// Floor tower for a UniFi G3 Instant / G4 Instant: lifts the camera to about 15 cm,
// with a heavy, wide base so a puppy can't knock it over, and a snap-in channel that
// holds the USB cable so it can't twist the camera off its aim.
//
// Two parts:
//   part = "tower": base + column + top pad, one piece. Prints base-down, NO supports.
//   part = "lid":   flat plate screwed under the base to close the ballast wells.
//
// The camera keeps its own stand (that's what tilts). Screw the stand's foot to the top
// pad with small wood / self-tapping screws through its mounting holes. The pad is
// thick and flat so screws bite anywhere, and there's a recess for a steel washer in
// case your stand's foot is magnetic.

part   = "tower";   // "tower", "lid", or "assembly" (preview only)
camera = "G4";      // "G4" or "G3": only changes the height

// ---- Measure these ----
cable_d = 4.0;      // USB cable diameter. Measure it! The channel snaps over this size.
// Height of the top pad above the floor. The camera on its stand puts the lens roughly
// 60-70 mm above the pad, so these land the lens around 15 cm up.
pad_top_g4 = 82;
pad_top_g3 = 90;
// Optional locating pocket for the stand's foot (0 = flat pad). Measure the foot.
foot_d     = 0;     // round foot diameter
foot_depth = 2;
// Optional recess for a steel washer, in case the stand's foot is magnetic (0 = none)
washer_d   = 25.8;  // fits a 1" fender washer
washer_t   = 1.8;

// ---- Shape ----
base_d    = 140;    // wide, so it's hard to tip
base_h    = 18;     // straight rim height
base_slope = 30;    // degrees; the base rises from the rim to the column at this angle
col_d     = 34;
pad_d     = 62;
pad_t     = 8;
// ballast = false gives a solid bottom: no wells, no lid needed, and four shallow
// pockets for stick-on rubber feet right on the tower's underside.
ballast   = true;
// Ballast wells, open underneath, closed by the lid. Fill with steel BBs, sand,
// coins (pennies stack in them), or fishing weights.
well_d    = 25;     // a US quarter is 24.3 mm
well_h    = 11;     // straight part; each well also has a 45-degree pointed roof
well_n    = 9;      // wells spaced every 36 degrees, skipping the cable side
well_r    = 55;     // ring radius of the well centers
// Lid
lid_t     = 2.4;
screw_pilot = 2.5;  // for #4 / M3 self-tapping screws
screw_clear = 3.4;
screw_head  = 6.5;
screw_r     = 30;   // screws sit in the solid middle, clear of the wells
// Cable channel: a keyhole groove; the cable presses past a narrow throat into a bore
cable_clear = 0.4;
throat_frac = 0.75; // throat width as a fraction of the cable diameter

$fn = 96;
eps = 0.01;
base_r  = base_d/2;
col_r   = col_d/2;
pad_r   = pad_d/2;
cone_h  = (base_r - col_r) * tan(base_slope);
flare_h = pad_r - col_r;                       // 45-degree flare under the pad
pad_top = camera == "G3" ? pad_top_g3 : pad_top_g4;
col_top = pad_top - pad_t - flare_h;           // where the flare starts
bore    = cable_d + cable_clear;
throat  = cable_d * throat_frac;
inset   = bore/2 + 0.6;                        // bore center below the surface

assert(col_top > base_h + cone_h, "pad_top too low for this base; lower base_h or base_slope");

// Base surface height at radius r (on the sloped part)
function base_z(r) = base_h + (base_r - r) * tan(base_slope);

// Keyhole groove along a straight run A->B (points in the YZ plane, x = 0), cut
// in from a surface whose outward normal is n.
module channel_seg(A, B, n) {
    hull() for (P = [A, B]) translate(P - n*inset) sphere(d = bore, $fn = 32);
    hull() for (P = [A, B]) for (s = [0, inset + 3])
        translate(P - n*inset + n*s) cube([throat, 0.2, 0.2], center = true);
}

module cable_channel() {
    // Path runs down the back (-Y) of the tower, from the top of the pad to the rim.
    nB = [0, -sin(base_slope), cos(base_slope)];
    nC = [0, -1, 0];
    nF = [0, -1/sqrt(2), -1/sqrt(2)];
    // path points on the surfaces
    P_rim  = [0, -base_r - 1, base_h - 1];
    P_rim2 = [0, -base_r + 1, base_z(base_r - 1)];
    P_foot = [0, -col_r - 4, base_z(col_r + 4)];
    P_c0   = [0, -col_r, base_z(col_r) + 4];
    P_c1   = [0, -col_r, col_top];
    P_pad0 = [0, -pad_r, col_top + flare_h];
    P_pad1 = [0, -pad_r, pad_top + 1];
    channel_seg(P_rim, P_rim2, [0, -1, 0]);           // off the rim edge
    channel_seg(P_rim2, P_foot, nB);                  // down the base slope
    channel_seg(P_foot, P_c0, [0, -0.7, 0.7]);        // bend into the column
    channel_seg(P_c0, P_c1, nC);                      // up the column
    channel_seg(P_c1, P_pad0, nF);                    // out along the flare
    channel_seg(P_pad0, P_pad1, nC);                  // up the pad edge
    // relief notch at the pad's top edge so the cable turns toward the camera
    translate([0, -pad_r, pad_top]) rotate([0, 90, 0])
        cylinder(r = 3, h = bore + 2, center = true);
}

function well_angle(i) = -90 + 36*(i + 1);   // 9 of 10 slots, skipping -90 (cable side)

module wells() {
    for (i = [0 : well_n - 1]) rotate(well_angle(i)) translate([well_r, 0, -eps]) {
        cylinder(d = well_d, h = well_h + eps);
        translate([0, 0, well_h]) cylinder(d1 = well_d, d2 = 0, h = well_d/2);
    }
}

module screw_points() {
    for (a = [90, 210, 330]) rotate(a) translate([screw_r, 0, 0]) children();
}

module tower() {
    difference() {
        union() {
            cylinder(r = base_r, h = base_h);
            translate([0, 0, base_h - eps]) cylinder(r1 = base_r, r2 = col_r, h = cone_h);
            cylinder(r = col_r, h = col_top + eps);
            translate([0, 0, col_top]) cylinder(r1 = col_r, r2 = pad_r, h = flare_h + eps);
            translate([0, 0, col_top + flare_h]) cylinder(r = pad_r, h = pad_t);
        }
        if (ballast) {
            wells();
            screw_points() translate([0, 0, -eps]) cylinder(d = screw_pilot, h = 12);
        } else {
            feet_pockets();
        }
        cable_channel();
        // small chamfer on the rim so it doesn't elephant-foot
        translate([0, 0, -eps]) difference() {
            cylinder(r = base_r + 1, h = 0.6);
            cylinder(r1 = base_r - 0.6, r2 = base_r, h = 0.6);
        }
        if (foot_d > 0)
            translate([0, 0, pad_top - foot_depth]) cylinder(d = foot_d + 0.4, h = foot_depth + eps);
        if (washer_d > 0)
            translate([0, 0, pad_top - (foot_d > 0 ? foot_depth : 0) - washer_t])
                cylinder(d = washer_d, h = washer_t + eps);
    }
}

// four shallow pockets for stick-on rubber feet
module feet_pockets() {
    for (a = [45, 135, 225, 315]) rotate(a) translate([base_r - 14, 0, -eps])
        cylinder(d = 13, h = 0.6);
}

module lid() {
    difference() {
        cylinder(r = base_r - 0.3, h = lid_t);
        screw_points() {
            translate([0, 0, -eps]) cylinder(d = screw_clear, h = lid_t + 1);
            // countersink on the floor side (the bed side when printed)
            translate([0, 0, -eps]) cylinder(d1 = screw_head, d2 = screw_clear, h = (screw_head - screw_clear)/2);
        }
        feet_pockets();
    }
}

if (part == "tower") tower();
else if (part == "lid") lid();
else {
    color("SteelBlue") tower();
    color("Orange") translate([0, 0, -lid_t - 8]) lid();
}
