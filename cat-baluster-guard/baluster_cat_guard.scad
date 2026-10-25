// Baluster Cat Guard
// ------------------
// Snap-on clips that hold a vertical rod (wood dowel or acrylic rod) in the
// middle of each gap between balusters, so the gap is too narrow for a cat.
//
//   top view of one clip (loft side is at the bottom of this sketch):
//
//        open air / room below
//      ===========================   <- web (behind everything)
//     (  B  )      ( r )      (  B  )
//      \_ _/        \ /        \_ _/
//        ^           ^           ^   openings: push onto balusters and
//            loft side (you)          press the rod in from where you stand
//
// Each clip prints flat with no supports. Use PETG if you can (it flexes
// without cracking); PLA works with a slightly wider snap opening.
//
// All dimensions in mm. MEASURE YOUR RAILING - the defaults are guesses.

/* [What to render] */
// clip = printable part, fit_test = thin slice to check the fit, assembly = preview with railing
part = "clip"; // [clip, fit_test, assembly]

/* [Your railing - measure these] */
// Center-to-center distance between two neighbouring balusters
baluster_pitch = 120;
// Shape of the baluster where this clip will sit (square blocks at bottom/top, round in the turned middle)
baluster_shape = "square"; // [square, round]
// Width of the square block, or diameter of the round part, where the clip will sit
baluster_size = 32;

/* [Rod] */
// Diameter of the rod/dowel you will use (12.7 = 1/2 inch, 9.5 = 3/8 inch)
rod_d = 12.7;
// Rods per gap: 1 leaves ~40 mm openings (adult cats), 2 leaves ~20-25 mm (nothing gets through)
rods_per_gap = 2; // [1, 2, 3]

/* [Clip] */
// How many gaps one clip spans (2 needs a bigger print bed, but stays rigid and avoids clips stacking on the same baluster)
gaps_per_clip = 1; // [1, 2, 3]
// Height of the clip (print height)
clip_h = 15;
// Wall thickness of the snap rings
wall = 2.6;
// Thickness of the web connecting everything
web_t = 4;
// Extra space around the baluster/rod (0 = tight, increase if it won't go on)
clearance = 0.3;
// Snap opening as a fraction of the round size (smaller = grips harder, harder to push on)
round_opening = 0.80;
// How far the lips of a square grip reach in over the corner
square_lip = 2.2;

/* [Assembly preview only] */
// Height from the top of the bottom (shoe) rail to the underside of the handrail
rail_gap_h = 760;
// Height of the square block at the bottom of each baluster
base_block_h = 110;
// Diameter of the slim turned part of the baluster
turned_d = 24;

/* [Hidden] */
$fn = 72;
eps = 0.01;

// ---------------------------------------------------------------- helpers

// rounds both convex and concave corners of a 2D shape
module soften(r = 0.7) {
    offset(r = r) offset(r = -2 * r) offset(r = r) children();
}

function rod_xs(p, n, gaps) = [
    for (g = [0 : gaps - 1], i = [1 : n])
        -p * gaps / 2 + g * p + p * i / (n + 1)
];

function baluster_xs(p, gaps) = [for (g = [0 : gaps]) -p * gaps / 2 + g * p];

// ---------------------------------------------------------------- 2D grips

// solid outline of a grip
module grip_body(shape, s) {
    if (shape == "round")
        circle(d = s + 2 * clearance + 2 * wall);
    else
        square(s + 2 * clearance + 2 * wall, center = true);
}

// hole + snap opening of a grip (opening faces -Y, the loft side)
module grip_cut(shape, s) {
    c = s + 2 * clearance;
    if (shape == "round") {
        circle(d = c);
        open_w = s * round_opening;
        translate([-open_w / 2, -c]) square([open_w, c]);
    } else {
        square(c, center = true);
        open_w = c - 2 * square_lip;
        translate([-open_w / 2, -c]) square([open_w, c]);
    }
}

// lead-in chamfers on the snap opening so it is easy to push on
module grip_leadin(shape, s) {
    c = s + 2 * clearance;
    open_w = shape == "round" ? s * round_opening : c - 2 * square_lip;
    outer = shape == "round" ? c / 2 + wall : c / 2 + wall;
    for (m = [0, 1]) mirror([m, 0])
        polygon([
            [open_w / 2 - eps, -outer - eps],
            [open_w / 2 + wall * 0.9, -outer - eps],
            [open_w / 2 - eps, -outer + wall * 0.9]
        ]);
}

// ---------------------------------------------------------------- clip

module clip_2d() {
    p = baluster_pitch;
    bxs = baluster_xs(p, gaps_per_clip);
    rxs = rod_xs(p, rods_per_gap, gaps_per_clip);
    rod_shape = "round";

    // the web runs behind the rods (open-air side) so it never blocks a snap opening
    web_y0 = rod_d / 2 + clearance;

    soften() difference() {
        union() {
            for (x = bxs) translate([x, 0]) grip_body(baluster_shape, baluster_size);
            for (x = rxs) translate([x, 0]) grip_body(rod_shape, rod_d);
            translate([bxs[0], web_y0]) square([bxs[len(bxs) - 1] - bxs[0], web_t]);
        }
        for (x = bxs) translate([x, 0]) {
            grip_cut(baluster_shape, baluster_size);
            grip_leadin(baluster_shape, baluster_size);
        }
        for (x = rxs) translate([x, 0]) {
            grip_cut(rod_shape, rod_d);
            grip_leadin(rod_shape, rod_d);
        }
    }
}

module clip(h = clip_h) {
    linear_extrude(h) clip_2d();
}

// ---------------------------------------------------------------- preview

module baluster() {
    color("white") {
        translate([-baluster_size / 2, -baluster_size / 2, 0])
            cube([baluster_size, baluster_size, base_block_h]);
        translate([0, 0, base_block_h])
            cylinder(d = turned_d, h = rail_gap_h - 2 * base_block_h);
        translate([-baluster_size / 2, -baluster_size / 2, rail_gap_h - base_block_h])
            cube([baluster_size, baluster_size, base_block_h]);
    }
}

module assembly() {
    p = baluster_pitch;
    n_gaps = 3;
    span = p * n_gaps;
    // shoe rail and handrail
    color("BurlyWood") {
        translate([-span / 2 - 40, -25, -20]) cube([span + 80, 50, 20]);
        translate([-span / 2 - 40, -35, rail_gap_h]) cube([span + 80, 70, 45]);
    }
    for (x = baluster_xs(p, n_gaps)) translate([x, 0, 0]) baluster();
    // rods resting on the shoe rail
    for (x = rod_xs(p, rods_per_gap, n_gaps))
        color("LightSkyBlue", 0.8) translate([x, 0, 0]) cylinder(d = rod_d, h = rail_gap_h - 5);
    // clips: one gap each, staggered heights so neighbours never share a spot
    for (g = [0 : n_gaps - 1]) {
        x = -span / 2 + p / 2 + g * p;
        dz = (g % 2) * (clip_h + 5);
        translate([x, 0, 20 + dz]) color("Orange") clip();
        translate([x, 0, rail_gap_h - base_block_h + 20 + dz]) color("Orange") clip();
    }
}

// ---------------------------------------------------------------- output

if (part == "clip") clip();
else if (part == "fit_test") clip(h = 4);
else if (part == "assembly") assembly();
