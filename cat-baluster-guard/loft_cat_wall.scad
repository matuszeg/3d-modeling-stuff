// Loft Cat Wall
// -------------
// A low wall on the loft side of the balusters, built like a fence:
//   - a slim I-beam POST on every other baluster
//   - each post section has a CLAMP BLOCK with a V-notch in its back; a
//     printed U-BOLT goes around the back of the baluster, through the block,
//     and two NUTS pull it tight from the loft side
//   - the nuts sit in round pockets and get covered by CAPS, so the face is flush
//   - PANELS span two gaps; their edges sit in the slots between the post's
//     front and back flanges
//   - the wall is 3 levels of 203 mm; post sections stack with a short stub
//     that drops into a recess in the clamp block below
//
// Putting up one level: stand the panels in place, slide the post sections
// down over the panel edges, put the U-bolts on and tighten, press in the caps.
//
// Coordinates (top view): x along the railing, y toward the living room,
// so the loft is -y. Baluster center at the origin.
//
// Everything prints with no supports. PETG recommended. All sizes in mm.

/* [What to render] */
part = "assembly"; // [assembly, post_0, post_1, post_2, ubolt_0, ubolt_1, ubolt_2, panel_0, panel_1, panel_2, nut, cap, wrench, test_kit, test_post, test_ubolt, test_panel, preview]
// for the assembly view: how far along the install to show (1-4), and how many levels
step = 4;
show_levels = 3;
show_baluster_h = 803;

/* [Railing - measured] */
baluster_pitch = 126.8;  // center to center
square_block_w = 31.9;   // square block at the bottom of each baluster
baluster_max_d = 26;     // thickest round part the U-bolt has to go around
// baluster thickness where each level's clamp sits (estimated from the taper; measure to confirm)
clamp_d = [25, 22, 19];

/* [Wall] */
level_h = 203;
levels = 3;

/* [Post] */
post_back_y = -17.5;     // back of the clamp block (clears the square block)
block_d = 22;            // clamp block depth
block_h = 30;
block_w = 64;
flange_w = 44;           // front flange: what you see from the loft
back_flange_w = 30;
flange_t = 2.2;
web_t = 3;
panel_slot = 5.4;        // gap between the flanges for the panel edge
v_depth = 9.5;           // V notch in the back of the block
test_post_h = 70;
stub_h = 3;              // stub on the bottom of a post section that drops into the block below

/* [U-bolt and nuts] */
rod_d = 10;              // thread major diameter
pitch = 2.5;
thread_depth = 1.2;
thread_clr = 0.35;       // radial clearance in the nut
test_arm_len = 32;       // test kit U-bolt
arm_end_y = -33.5;       // where the arm ends should land: past the nut, short of the cap
nut_af = 14;             // across flats
nut_h = 8;
pocket_d = 22;           // round pocket so a socket wrench fits around the nut
pocket_depth = 16;

/* [Panel] */
panel_t = 5;
panel_skin = 0.8;
panel_rim = 4;
panel_edge = 15;         // full-thickness strip along the sides that sits in the post slots
panel_rib = 3;
// rows of panels lock together: a V-ridge along each top edge fits a V-groove
// along the bottom edge of the panel above (45-degree sides print without support)
ridge_h = 1.5;
ridge_z = [1, 4];        // where the ridge's base sits across the thickness
groove_clr = 0.2;
panel_gap = 0.3;         // between rows

/* [Hidden] */
$fn = 64;
eps = 0.01;

ubolt_inner = baluster_max_d + 1;
arm_x = ubolt_inner / 2 + rod_d / 2;
post_front_y = post_back_y - block_d;
v_apex_y = post_back_y - v_depth;
nut_ac = nut_af / cos(30);
panel_front_y = post_front_y + flange_t + 0.2;
panel_w = 2 * baluster_pitch - web_t - 0.6;
panel_h = level_h - panel_gap;

// where the baluster sits for a given diameter, and the U-bolt arm length that
// lands the arm ends at arm_end_y
function baluster_cy(d) = v_apex_y + d / 2 * sqrt(2);
function ubolt_back_y(d) = baluster_cy(d) + d / 2 * sqrt(2);
function arm_len_for(d) = ubolt_back_y(d) - ubolt_inner / 2 - arm_end_y;

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
module teardrop(d, h, cap_at = 1e3)
    linear_extrude(h) intersection() {
        hull() { circle(d = d); translate([0, d / 2 / sin(45) - 0.01]) rotate(45) square(0.01, center = true); }
        translate([-d, -d]) square([2 * d, d + cap_at]);
    }

module ibeam2d() {
    translate([-flange_w / 2, post_front_y]) square([flange_w, flange_t]);
    translate([-back_flange_w / 2, post_front_y + flange_t + panel_slot]) square([back_flange_w, flange_t]);
    translate([-web_t / 2, post_front_y]) square([web_t, 2 * flange_t + panel_slot]);
}
module block2d() difference() {
    translate([-block_w / 2, post_front_y]) square([block_w, block_d]);
    polygon([[-v_depth - 2, post_back_y + eps], [0, v_apex_y], [v_depth + 2, post_back_y + eps]]);
}

// post section with its clamp block at the top; stub = stub on the bottom,
// recess = socket in the top of the block for the next section's stub
module post_section(h, stub = false, recess = false) difference() {
    union() {
        linear_extrude(h) ibeam2d();
        translate([0, 0, h - block_h]) linear_extrude(block_h) block2d();
        if (stub) translate([0, 0, -stub_h]) linear_extrude(stub_h + eps) offset(delta = -0.25) ibeam2d();
    }
    if (recess) translate([0, 0, h - stub_h - 0.5]) linear_extrude(stub_h + 1) offset(delta = 0.15) ibeam2d();
    // rotate([-90,0,0]) turns the teardrop's point toward -z: up when printed block-down
    for (s = [-1, 1]) translate([s * arm_x, post_front_y - eps, h - block_h / 2]) rotate([-90, 0, 0]) {
        teardrop(pocket_d, pocket_depth, block_h / 2 - 1.5);
        teardrop(rod_d + 0.8, block_d + 1, block_h / 2 - 1.5);
    }
}

// the post section for a level, as it stands in the wall
module post_level(l) post_section(level_h - 0.6, stub = l > 0, recess = l < levels - 1);

// a post section turned over so the clamp block sits on the bed
module post_section_print(h) translate([0, 0, h]) rotate([180, 0, 0]) post_section(h);
module post_level_print(l) translate([0, 0, level_h - 0.6]) rotate([180, 0, 0]) post_level(l);

// U-bolt, printed standing on its arm ends: the inside of the bend is a
// 90-degree V, so it needs no support
module ubolt(arm_len) {
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
            cylinder(d = pocket_d - 0.4, h = 4);
            for (a = [0 : 60 : 359]) rotate(a) translate([pocket_d / 2 - 0.2, 0, 1.6]) cylinder(d = 1.2, h = 2.4, $fn = 12);
        }
        translate([0, 0, 1.6]) cylinder(d = pocket_d - 3.2, h = 4);
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

// panel spanning two gaps, lying as it prints: loft face down on the bed.
// The sides are full thickness where they sit in the post slots, and the top
// corners are notched to clear the clamp blocks.
// notch_l / notch_r: which top corners get a notch (the end panels at the
// wall and the wooden post only need one, on the post side)
module panel(ridge = true, groove = true, notch_l = true, notch_r = true) {
    w = panel_w; h = panel_h;
    nw = block_w / 2 - web_t / 2 - 0.3 + 0.5;
    nh = block_h + 1;
    module outline() difference() {
        square([w, h]);
        if (notch_l) translate([-1, h - nh]) square([nw + 1, nh + 1]);
        if (notch_r) translate([w - nw, h - nh]) square([nw + 1, nh + 1]);
    }
    zm = (ridge_z[0] + ridge_z[1]) / 2;
    difference() {
        union() {
            intersection() {
                linear_extrude(panel_t) outline();
                union() {
                    cube([w, h, panel_skin]);
                    linear_extrude(panel_t) difference() { outline(); offset(delta = -panel_rim) outline(); }
                    for (x = [0, w - panel_edge]) translate([x, 0, 0]) cube([panel_edge, h, panel_t]);
                    for (f = [1/3, 2/3]) translate([0, h * f - 2, 0]) cube([w, 4, panel_rib]);
                    translate([w / 2 - 2, 0, 0]) cube([4, h, panel_rib]);
                }
            }
            // ridge along the top edge, between the corner notches
            rl = notch_l ? nw : 0;
            rr = notch_r ? nw : 0;
            if (ridge) translate([rl, 0, 0]) rotate([90, 0, 90]) linear_extrude(w - rl - rr)
                polygon([[h - eps, ridge_z[0]], [h + ridge_h, zm], [h - eps, ridge_z[1]]]);
        }
        // groove along the bottom edge
        if (groove) translate([-1, 0, 0]) rotate([90, 0, 90]) linear_extrude(w + 2)
            polygon([[-eps, ridge_z[0] - groove_clr], [ridge_h + groove_clr, zm], [-eps, ridge_z[1] + groove_clr]]);
    }
}

// the panel for each row: bottom row has only a ridge, top row only a groove
module panel_level(l) panel(ridge = l < levels - 1, groove = l > 0);
// end panels: "left" is the wall end (post on its right), "right" the wooden-post end
module panel_end(l, side) panel(ridge = l < levels - 1, groove = l > 0, notch_l = side == "right", notch_r = side == "left");

// the panel standing in the wall: left edge at x0, bottom at z0
module panel_in_wall(l = 1) translate([0, panel_front_y, 0]) rotate([90, 0, 0]) mirror([0, 0, 1]) panel_level(l);

// an edge strip of a panel to try in the post's slot
module test_panel(w = 40, h = 50) cube([w, h, panel_t]);

module test_kit() {
    post_section_print(test_post_h);
    translate([0, 55, 0]) ubolt(test_arm_len);
    for (i = [0, 1]) translate([-60 + i * 22, 80, 0]) nut();
    for (i = [0, 1]) translate([60, 40 - i * 26, 0]) cap();
    translate([0, -75, 0]) wrench();
    translate([50, -60, 0]) test_panel();
}

// ---------------------------------------------------------------- assembly

module baluster_model(h = 803) color("white") {
    sq = square_block_w;
    translate([-sq / 2, -sq / 2, 0]) cube([sq, sq, 89.6]);
    translate([0, 0, 89.6]) cylinder(d1 = sq * 0.9, d2 = 22, h = 12);
    translate([0, 0, 101.6]) cylinder(d = 28, h = 6);
    // taper from 26 just above the bead to 15.9 at the handrail
    translate([0, 0, 107.6]) cylinder(d1 = 26, d2 = 15.9, h = h - 107.6);
}

// One section: posts on balusters at x = 0 and x = 2 * pitch, a panel
// between them, a bare baluster in the middle. step 1: panels stand in
// place; 2: post sections slid down over the panel edges; 3: U-bolts and
// nuts tightened; 4: caps in.
module clamp_hardware(l, show_caps) {
    d = clamp_d[l];
    zc = (l + 1) * level_h - 0.6 - block_h / 2;
    L = arm_len_for(d);
    color("Orange") translate([0, ubolt_back_y(d) - ubolt_inner / 2 - L, zc]) rotate([-90, 0, 0]) ubolt(L);
    for (s = [-1, 1]) color("Gold") translate([s * arm_x, post_front_y + pocket_depth, zc]) rotate([90, 0, 0]) nut();
    if (show_caps) for (s = [-1, 1]) color("Gold") translate([s * arm_x, post_front_y, zc]) rotate([-90, 0, 0]) cap();
}

module section_assembly(step = 4, nlev = 3, lift = 120) {
    color("BurlyWood") translate([-80, -60, -20]) cube([2 * baluster_pitch + 160, 80, 20]);
    for (i = [0 : 2]) translate([i * baluster_pitch, 0, 0]) baluster_model(show_baluster_h);
    for (l = [0 : nlev - 1]) {
        top = l == nlev - 1;
        st = top ? step : 4;
        z0 = l * level_h;
        color("LightSteelBlue") translate([web_t / 2 + 0.3, 0, z0 + panel_gap / 2]) panel_in_wall(l);
        if (st >= 2) for (x = [0, 2 * baluster_pitch]) translate([x, 0, z0]) color("SteelBlue") post_level(l);
        if (st == 1) for (x = [0, 2 * baluster_pitch]) translate([x, 0, z0 + lift]) color("SteelBlue", 0.35) post_level(l);
        if (st >= 3) for (x = [0, 2 * baluster_pitch]) translate([x, 0, 0]) clamp_hardware(l, st >= 4);
    }
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
    color("Orange") translate([0, back - ubolt_inner / 2 - test_arm_len, zc]) rotate([-90, 0, 0]) ubolt(test_arm_len);
    for (s = [-1, 1]) color("Gold") translate([s * arm_x, post_front_y + pocket_depth, zc]) rotate([90, 0, 0]) nut();
    color("LightSteelBlue") translate([web_t / 2 + 0.3, post_front_y + flange_t + 0.2, 0]) cube([60, panel_t, h - block_h - 1]);
}

// ---------------------------------------------------------------- output

if (part == "assembly") section_assembly(step, show_levels);
else if (part == "post_0") post_level_print(0);
else if (part == "post_1") post_level_print(1);
else if (part == "post_2") post_level_print(2);
else if (part == "ubolt_0") ubolt(arm_len_for(clamp_d[0]));
else if (part == "ubolt_1") ubolt(arm_len_for(clamp_d[1]));
else if (part == "ubolt_2") ubolt(arm_len_for(clamp_d[2]));
else if (part == "panel_0") panel_level(0);
else if (part == "panel_1") panel_level(1);
else if (part == "panel_2") panel_level(2);
else if (part == "panel_end_left_0") panel_end(0, "left");
else if (part == "panel_end_left_1") panel_end(1, "left");
else if (part == "panel_end_left_2") panel_end(2, "left");
else if (part == "panel_end_right_0") panel_end(0, "right");
else if (part == "panel_end_right_1") panel_end(1, "right");
else if (part == "panel_end_right_2") panel_end(2, "right");
else if (part == "test_ubolt") ubolt(test_arm_len);
else if (part == "test_kit") test_kit();
else if (part == "test_post") post_section_print(test_post_h);
else if (part == "nut") nut();
else if (part == "cap") cap();
else if (part == "wrench") wrench();
else if (part == "test_panel") test_panel();
else if (part == "preview") preview();
