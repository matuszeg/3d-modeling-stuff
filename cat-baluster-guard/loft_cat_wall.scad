// Loft Cat Wall
// -------------
// A low wall on the loft side of the balusters, built like a fence:
//   - a POST in front of every baluster, held on by a U-shaped COLLAR that
//     wraps the back of the baluster and slides down into dovetail slots in
//     the post, then gets locked tight with a tapered WEDGE
//   - PANELS that drop down between the posts; their side tongues ride in
//     grooves in the posts
//
// Coordinates (top view): x along the railing, y toward the living room,
// so the loft is -y. The back face of a post is at y = post_back_y.
//
// Everything prints with no supports. PETG recommended. All sizes in mm.

/* [What to render] */
part = "test_kit"; // [test_kit, test_post, collar, wedge, test_panel, preview]

/* [Railing - measured] */
baluster_pitch = 126.8;  // center to center
block_w = 31.9;          // square block at the bottom of each baluster
baluster_min_d = 15.9;   // thinnest part of the round section
baluster_max_d = 28;     // fattest part the collar must slide past (the bead above the block)

/* [Post] */
post_w = 44;
post_d = 18;
// back face of the post, measured from the baluster center (clears the square block)
post_back_y = -17.5;
test_post_h = 60;

/* [Panel joint] */
panel_t = 5;             // panel thickness at its edges
panel_reveal = 2.5;      // how far the panel face sits behind the post face
tongue_t = 2;            // tongue thickness (flush with the panel's loft face)
tongue_len = 5.5;
groove_clr = 0.2;        // per side

/* [Collar] */
collar_h = 15;
arm_t = 3.5;             // collar arm thickness
key_flare = 0.8;         // how much the dovetail key widens on each side
key_depth = 4.5;         // how deep the key sits in the post
slot_clr = 0.25;         // clearance around the key
slot_floor = 10;         // slot stops this far above the bottom of a post section
back_t = 4;              // thickness of the collar behind the baluster

/* [Wedge] */
wedge_w = 12;
wedge_len = 120;
wedge_thin = 2.5;
wedge_thick = 17;

/* [Hidden] */
$fn = 96;
eps = 0.01;

collar_inner = baluster_max_d + 1;                   // clear width between the arms
arm_x = collar_inner / 2 + arm_t / 2;                // arm centerline
post_front_y = post_back_y - post_d;
panel_front_y = post_front_y + panel_reveal;
groove_y0 = panel_front_y - groove_clr;
groove_w = tongue_t + 2 * groove_clr;
groove_depth = tongue_len + 0.5;
// apex of the V inside the collar: a baluster of max diameter leaves the
// thinnest wedge gap, the thinnest baluster the thickest
v_apex_y = post_back_y + wedge_thin + 0.5 + (baluster_max_d / 2 - 0.5) * (1 + sqrt(2));

// ---------------------------------------------------------------- 2D profiles

// dovetail key at the end of a collar arm, pointing into the post (-y)
module key2d(grow = 0)
    polygon([
        [-arm_t / 2 - grow, eps],
        [ arm_t / 2 + grow, eps],
        [ arm_t / 2 + key_flare + grow, -key_depth - grow],
        [-arm_t / 2 - key_flare - grow, -key_depth - grow]
    ]);

module post2d() difference() {
    translate([-post_w / 2, post_front_y]) square([post_w, post_d]);
    for (m = [0, 1]) mirror([m, 0]) {
        // panel groove
        translate([post_w / 2 - groove_depth, groove_y0]) square([groove_depth + 1, groove_w]);
    }
    // shallow guide channel for the wedge
    translate([-wedge_w / 2 - 0.5, post_back_y - 1]) square([wedge_w + 1, 1 + eps]);
}

module slots2d() for (m = [0, 1]) mirror([m, 0]) translate([arm_x, post_back_y]) key2d(slot_clr);

module collar2d() {
    yi = v_apex_y - collar_inner / 2;     // where the V meets the arms
    difference() {
        union() {
            for (m = [0, 1]) mirror([m, 0]) {
                translate([arm_x - arm_t / 2, post_back_y]) square([arm_t, yi - post_back_y + eps]);
                translate([arm_x, post_back_y]) key2d();
            }
            // rounded back
            hull() {
                translate([-arm_x - arm_t / 2, yi - 1]) square([2 * arm_x + arm_t, 1]);
                translate([0, yi]) intersection() {
                    circle(r = arm_x + arm_t / 2);
                    translate([-50, 0]) square([100, collar_inner / 2 + back_t + 1]);
                }
            }
        }
        // V-shaped inside
        polygon([
            [-collar_inner / 2, yi - 1], [-collar_inner / 2, yi], [0, v_apex_y],
            [collar_inner / 2, yi], [collar_inner / 2, yi - 1]
        ]);
        translate([-collar_inner / 2, post_back_y - 1]) square([collar_inner, yi - post_back_y + 1]);
    }
}

// ---------------------------------------------------------------- parts

module post_section(h) difference() {
    linear_extrude(h) post2d();
    translate([0, 0, slot_floor]) linear_extrude(h) slots2d();
}

module collar() linear_extrude(collar_h) collar2d();

// prints lying on its side
module wedge() {
    linear_extrude(wedge_w) polygon([
        [0, 0], [wedge_thin, 0], [wedge_thick, wedge_len - 8], [wedge_thick, wedge_len], [0, wedge_len]
    ]);
}

// a corner of a panel: just enough to try the tongue in the groove
module test_panel(w = 40, h = 40) {
    cube([w, h, panel_t]);
    translate([-tongue_len, 0, 0]) cube([tongue_len + eps, h, tongue_t]);
}

module test_kit() {
    // laid out on one plate, each part flat and support-free
    translate([0, 95.5, 0]) post_section(test_post_h);
    collar();
    translate([150, -22, 0]) rotate([0, 0, 90]) wedge();
    translate([40, 20, 0]) test_panel();
}

// ---------------------------------------------------------------- preview

module baluster_preview(h = 220) color("white") {
    // a round baluster at its thickest, seated in the collar's V
    r = baluster_max_d / 2 - 1;
    translate([0, v_apex_y - r * sqrt(2), -40]) cylinder(r = r, h = h);
}

module preview() {
    baluster_preview();
    color("SteelBlue") post_section(test_post_h);
    color("Orange") translate([0, 0, slot_floor]) collar();
    // wedge pushed partway down, thick end up
    color("Gold") translate([-wedge_w / 2, post_back_y, -20]) rotate([0, 0, 90]) rotate([90, 0, 0]) wedge();
    color("LightSteelBlue") {
        translate([post_w / 2 + 0.3, panel_front_y, 0]) cube([60, panel_t, test_post_h]);
        translate([post_w / 2 + 0.3 - tongue_len, panel_front_y, 0]) cube([tongue_len + eps, tongue_t, test_post_h]);
    }
}

// ---------------------------------------------------------------- output

if (part == "test_kit") test_kit();
else if (part == "test_post") post_section(test_post_h);
else if (part == "collar") collar();
else if (part == "wedge") wedge();
else if (part == "test_panel") test_panel();
else if (part == "preview") preview();
