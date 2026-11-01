// Loft Cat Wall
// -------------
// A low wall on the loft side of the balusters, built like a fence:
//   - a slim I-beam POST on every other baluster
//   - each post section has a CLAMP BLOCK with a V-notch in its back; a
//     printed U-BOLT goes around the back of the baluster, through the block,
//     and two NUTS pull it tight from the loft side
//   - the nuts sit in round pockets and get covered by CAPS, so the face is flush
//   - PANELS slide into the slots between the post's front and back flanges
//
// Coordinates (top view): x along the railing, y toward the living room,
// so the loft is -y. Baluster center at the origin.
//
// Everything prints with no supports. PETG recommended. All sizes in mm.

/* [What to render] */
part = "test_kit"; // [test_kit, test_post, ubolt, nut, cap, wrench, test_panel, preview]

/* [Railing - measured] */
baluster_pitch = 126.8;  // center to center
square_block_w = 31.9;   // square block at the bottom of each baluster
baluster_max_d = 26;     // thickest round part the U-bolt has to go around

/* [Post] */
post_back_y = -17.5;     // back of the clamp block (clears the square block)
block_d = 20;            // clamp block depth
block_h = 30;
block_w = 64;
flange_w = 44;           // front flange: what you see from the loft
back_flange_w = 30;
flange_t = 2.2;
web_t = 3;
panel_slot = 5.4;        // gap between the flanges for the panel edge
v_depth = 9.5;           // V notch in the back of the block
test_post_h = 70;

/* [U-bolt and nuts] */
rod_d = 10;              // thread major diameter
pitch = 2.5;
thread_depth = 1.2;
thread_clr = 0.35;       // radial clearance in the nut
arm_len = 32;            // long enough for the thickest baluster; thinner ones get shorter arms later
nut_af = 14;             // across flats
nut_h = 8;
pocket_d = 22;           // round pocket so a socket wrench fits around the nut
pocket_depth = 10;

/* [Panel] */
panel_t = 5;

/* [Hidden] */
$fn = 64;
eps = 0.01;

ubolt_inner = baluster_max_d + 1;
arm_x = ubolt_inner / 2 + rod_d / 2;
post_front_y = post_back_y - block_d;
v_apex_y = post_back_y - v_depth;
nut_ac = nut_af / cos(30);

// ---------------------------------------------------------------- threads

// cross-section of a single-start thread; extruding it with a twist of one
// turn per pitch gives an exact helical thread
module thread2d(major, depth, grow = 0) {
    r1 = major / 2 + grow;
    r0 = r1 - depth;
    // trapezoid profile along one pitch: root flat, flank, crest flat, flank
    function prof(u) = u < 0.2 ? r0 : u < 0.45 ? r0 + (u - 0.2) / 0.25 * depth
                     : u < 0.7 ? r1 : u < 0.95 ? r1 - (u - 0.7) / 0.25 * depth : r0;
    n = 72;
    polygon([for (i = [0 : n - 1]) let(a = i * 360 / n) prof(i / n) * [cos(a), sin(a)]]);
}
module threaded_rod(len, grow = 0)
    linear_extrude(len, twist = -360 * len / pitch, slices = ceil(len / 0.2), convexity = 4)
        thread2d(rod_d, thread_depth, grow);

// ---------------------------------------------------------------- parts

// hole along +z whose cross-section has a 45-degree point toward +y, so it
// prints without support when +y is up on the printer
module teardrop(d, h)
    linear_extrude(h) hull() { circle(d = d); translate([0, d / 2 / sin(45) - 0.01]) rotate(45) square(0.01, center = true); }

module ibeam2d() {
    translate([-flange_w / 2, post_front_y]) square([flange_w, flange_t]);
    translate([-back_flange_w / 2, post_front_y + flange_t + panel_slot]) square([back_flange_w, flange_t]);
    translate([-web_t / 2, post_front_y]) square([web_t, 2 * flange_t + panel_slot]);
}
module block2d() difference() {
    translate([-block_w / 2, post_front_y]) square([block_w, block_d]);
    polygon([[-v_depth - 2, post_back_y + eps], [0, v_apex_y], [v_depth + 2, post_back_y + eps]]);
}

// post section with its clamp block at the top
module post_section(h) difference() {
    union() {
        linear_extrude(h) ibeam2d();
        translate([0, 0, h - block_h]) linear_extrude(block_h) block2d();
    }
    // rotate([-90,0,0]) turns the teardrop's point toward -z: up when printed block-down
    for (s = [-1, 1]) translate([s * arm_x, post_front_y - eps, h - block_h / 2]) rotate([-90, 0, 0]) {
        teardrop(pocket_d, pocket_depth);
        teardrop(rod_d + 0.8, block_d + 1);
    }
}

// a post section turned over so the clamp block sits on the bed
module post_section_print(h) translate([0, 0, h]) rotate([180, 0, 0]) post_section(h);

// U-bolt, printed standing on its arm ends: the inside of the bend is a
// 90-degree V, so it needs no support
module ubolt() {
    t = rod_d;
    translate([0, 0, arm_len]) {
        rotate([90, 0, 0]) linear_extrude(t, center = true) difference() {
            hull() {
                translate([-arm_x - t / 2, -eps]) square([2 * arm_x + t, eps]);
                intersection() { circle(r = arm_x + t / 2); translate([-50, 0]) square([100, 50]); }
            }
            polygon([[-ubolt_inner / 2, -1], [-ubolt_inner / 2, 0], [0, ubolt_inner / 2],
                     [ubolt_inner / 2, 0], [ubolt_inner / 2, -1]]);
        }
    }
    for (s = [-1, 1]) translate([s * arm_x, 0, 0]) threaded_rod(arm_len + eps);
}

module nut() difference() {
    cylinder(d = nut_ac, h = nut_h, $fn = 6);
    translate([0, 0, -eps]) threaded_rod(nut_h + 2 * eps, thread_clr);
    // lead-in chamfers
    for (z = [0, nut_h]) translate([0, 0, z]) cylinder(d1 = rod_d + 1, d2 = rod_d - 2 * thread_depth, h = 1, center = true);
}

// press-fit cap over a nut pocket
module cap() {
    cylinder(d = pocket_d + 1.5, h = 1.6);
    difference() {
        union() {
            cylinder(d = pocket_d - 0.4, h = 5);
            for (a = [0 : 60 : 359]) rotate(a) translate([pocket_d / 2 - 0.2, 0, 1.6]) cylinder(d = 1.2, h = 3.4, $fn = 12);
        }
        translate([0, 0, 1.6]) cylinder(d = pocket_d - 3.2, h = 5);
    }
}

// socket wrench for the nuts: a hex socket with a T handle
module wrench() {
    difference() {
        cylinder(d = pocket_d - 0.8, h = 30);
        translate([0, 0, 30 - nut_h - 2]) cylinder(d = nut_ac + 0.6, h = nut_h + 3, $fn = 6);
        translate([0, 0, -eps]) cylinder(d = rod_d + 2, h = 30);   // room for the bolt end
    }
    translate([0, 0, 0]) hull() for (s = [-1, 1]) translate([s * 35, 0, 0]) cylinder(d = 12, h = 10);
}

// an edge strip of a panel to try in the post's slot
module test_panel(w = 40, h = 50) cube([w, h, panel_t]);

module test_kit() {
    post_section_print(test_post_h);
    translate([0, 55, 0]) ubolt();
    for (i = [0, 1]) translate([-60 + i * 22, 80, 0]) nut();
    for (i = [0, 1]) translate([60, 40 - i * 26, 0]) cap();
    translate([0, -75, 0]) wrench();
    translate([50, -60, 0]) test_panel();
}

// ---------------------------------------------------------------- preview

module preview() {
    h = test_post_h;
    r = baluster_max_d / 2 - 1;
    cy = v_apex_y + r * sqrt(2);
    back = cy + r * sqrt(2);
    zc = h - block_h / 2;
    color("white") translate([0, cy, -30]) cylinder(r = r, h = h + 80);
    color("SteelBlue") post_section(h);
    color("Orange") translate([0, back - ubolt_inner / 2 - arm_len, zc]) rotate([-90, 0, 0]) ubolt();
    for (s = [-1, 1]) color("Gold") translate([s * arm_x, post_front_y + pocket_depth, zc]) rotate([90, 0, 0]) nut();
    color("LightSteelBlue") translate([web_t / 2 + 0.3, post_front_y + flange_t + 0.2, 0]) cube([60, panel_t, h - block_h - 1]);
}

// ---------------------------------------------------------------- output

if (part == "test_kit") test_kit();
else if (part == "test_post") post_section_print(test_post_h);
else if (part == "ubolt") ubolt();
else if (part == "nut") nut();
else if (part == "cap") cap();
else if (part == "wrench") wrench();
else if (part == "test_panel") test_panel();
else if (part == "preview") preview();
