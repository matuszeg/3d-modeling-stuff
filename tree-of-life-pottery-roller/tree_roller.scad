// Tree pottery roller
//
// A texture roller for clay. Roll it once across a slab and it presses in a
// bare, branching tree with spreading roots, on a background of little swirls
// (the swirls can be turned off). The tree runs along the roller's length, so
// one turn of the roller prints one tree.
//
// The tree and swirls stand up from the roller as rounded ridges, so they come
// out as grooves in the clay, which is where the glaze pools dark. The design
// is mirrored on the roller so the tree in the clay reads the way it does in
// the "imprint" preview.
//
// The tree is drawn by the file from a seed: change tree_seed for a different
// tree of the same style. Every value below is a Customizer setting
// (Window > Customizer in OpenSCAD).
//
// Prints standing on end with no supports. Slide a dowel through the bore as
// a handle.

/* [What to show] */
show = "roller";  // [roller:Roller to print, imprint:What the clay will look like (flat), tree:Tree only (flat)]

/* [Roller] */
roller_diameter = 45;          // at the base of the pattern; the ridges add relief_height on top
roller_length = 100;           // along the axis
bore_diameter = 8.6;           // handle hole: 8.6 fits an 8 mm or 5/16" dowel. 0 = no hole
end_margin = 4;                // plain band at each end
end_chamfer = 1;               // chamfer on the roller's end edges

/* [Tree] */
tree_seed = 42;                // change for a different tree
tree_height = 86;              // root tips to crown top, along the roller
tree_width = 64;               // widest part of the crown, around the roller
trunk_width = 6;               // at the base of the trunk
trunk_share = 0.45;            // how much of the height is bare trunk before it splits
main_limbs = 5;                // limbs leaving the top of the trunk
branch_levels = 5;             // how many times branches split: more = finer twigs
root_count = 7;
smallest_line = 1.1;           // narrowest twig, mm. Under ~1 mm won't print or press cleanly
wiggle = 14;                   // how crooked the branches are, degrees

/* [Swirl background] */
swirls = true;
swirl_size = 13;               // spacing between swirls
swirl_line = 1.0;              // swirl line width
swirl_gap = 1.2;               // clear space kept around the tree

/* [Relief] */
relief_height = 1.6;           // how deep the tree presses into the clay
swirl_height = 0.9;            // how deep the swirls press
mirror_for_imprint = true;     // mirror on the roller so the imprint reads the right way

/* [Quality] */
slices = 72;                   // flat strips around the roller (at 72 each is within 0.03 mm of round); more = slower
$fn = 16;

// ---------------------------------------------------------------- derived
R = roller_diameter / 2;
C = PI * roller_diameter;                 // one turn = this much clay
pattern_len = roller_length - 2 * end_margin;

assert(tree_height <= pattern_len,
       str("tree_height ", tree_height, " is longer than the pattern band (",
           pattern_len, " mm). Make the roller longer or the tree shorter."));
assert(tree_width < C - 6,
       str("tree_width ", tree_width, " won't fit around a ", roller_diameter,
           " mm roller (", round(C), " mm around). Use a fatter roller."));
assert(bore_diameter < roller_diameter - 12, "bore_diameter leaves too thin a wall");

// ---------------------------------------------------------------- tree
// Everything is built as a list of tapered segments [[x1,y1], r1, [x2,y2], r2]
// in tree units (trunk base at the origin, growing up +y), then scaled to fit.

function rnd(s, n = 6) = rands(0, 1, n, s);
function dir(a) = [cos(a), sin(a)];
rmin = smallest_line / 2;

// one limb: two slightly bent segments, then it splits
function limb(p, a, len, r, lvl, s, up = 0.1) =
    let(q = rnd(s),
        a1 = a + (q[0] - 0.5) * wiggle,
        a2 = a1 + (q[1] - 0.5) * wiggle,
        r2 = max(rmin, r * 0.62),
        rm = (r + r2) / 2,
        m = p + dir(a1) * len * 0.5,
        e = m + dir(a2) * len * 0.5,
        me = [[p, r, m, rm], [m, rm, e, r2]],
        kids = (lvl <= 0 || len < 1.5) ? 0 : (q[2] < 0.1 ? 3 : 2),
        spread = 26 + q[3] * 18,
        // a twig sometimes sprouts from the middle of the limb as well
        side = (lvl >= 2 && q[4] < 0.3)
            ? limb(m, a1 + (q[5] < 0.5 ? -1 : 1) * (40 + q[4] * 30), len * 0.45,
                   max(rmin, rm * 0.55), lvl - 2, (s * 13 + 5) % 1000003, up)
            : [])
    concat(me, side,
           [for (k = [0:kids - 1]) if (kids > 0)
               let(raw = a2 + (kids == 3 ? (k - 1) * spread : (k - 0.5) * spread * 1.4)
                          + (rnd(s * 3 + k)[0] - 0.5) * 18)
               // pull each child a little toward vertical so the crown stays rounded
               each limb(e, raw + (90 - raw) * up, len * (0.68 + rnd(s * 7 + k)[1] * 0.12),
                         max(rmin, r2 * 0.85), lvl - 1, (s * 31 + k * 17 + 11) % 1000003, up)]);

// roots: grow sideways and down, flatter and shorter
function root(p, a, len, r, lvl, s) =
    let(q = rnd(s),
        a1 = a + (q[0] - 0.5) * wiggle,
        a2 = a1 + (q[1] - 0.5) * wiggle + (a1 < -90 ? -6 : 6),
        r2 = max(rmin, r * 0.55),
        m = p + dir(a1) * len * 0.5,
        e = m + dir(a2) * len * 0.5)
    concat([[p, r, m, (r + r2) / 2], [m, (r + r2) / 2, e, r2]],
           lvl <= 0 ? [] :
           [for (k = [0:1]) each root(e, a2 + (k - 0.5) * (30 + q[2] * 20), len * 0.6,
                                       max(rmin, r2 * 0.8), lvl - 1, (s * 19 + k * 7 + 3) % 1000003)]);

// the whole tree in raw units (trunk 100 tall-ish), before scaling
function raw_tree(s) =
    let(tw = trunk_width / 2,
        th = 100 * trunk_share,
        top = [0, th],
        lq = rnd(s + 1, 20),
        limbs = [for (i = [0:main_limbs - 1])
                    let(f = main_limbs == 1 ? 0.5 : i / (main_limbs - 1),
                        a = 140 - f * 100 + (lq[i] - 0.5) * 12,
                        // outer limbs leave a little lower on the trunk
                        y0 = th - abs(f - 0.5) * 2 * th * 0.18,
                        len = 26 + lq[i + 7] * 6 - abs(f - 0.5) * 6)
                    each limb([0, y0], a, len, tw * (0.62 - abs(f - 0.5) * 0.25),
                              branch_levels, (s * 101 + i * 37) % 1000003)],
        roots = [for (i = [0:root_count - 1])
                    let(f = root_count == 1 ? 0.5 : i / (root_count - 1),
                        // most roots run out sideways along the ground, a few go down
                        g = 2 * f - 1,
                        a = -90 - sign(g) * 82 * pow(abs(g), 0.6) + (lq[(i + 3) % 20] - 0.5) * 10,
                        len = 17 + (1 - abs(f - 0.5) * 2) * -7 + lq[(i + 11) % 20] * 5)
                    each root([0, 3], a, len, tw * 0.5, 1, (s * 53 + i * 29) % 1000003)],
        trunk = [[[0, 0], tw, [0, th * 0.5], tw * 0.82],
                 [[0, th * 0.5], tw * 0.82, top, tw * 0.68]])
    concat(trunk, limbs, roots);

TREE = raw_tree(tree_seed);
xs = [for (g = TREE) each [g[0].x - g[1], g[2].x - g[3]]];
xs2 = [for (g = TREE) each [g[0].x + g[1], g[2].x + g[3]]];
ys = [for (g = TREE) each [g[0].y - g[1], g[2].y - g[3]]];
ys2 = [for (g = TREE) each [g[0].y + g[1], g[2].y + g[3]]];
bb = [[min(xs), min(ys)], [max(xs2), max(ys2)]];
// stretch to the asked-for size, but keep line widths as drawn
sx = tree_width / (bb[1].x - bb[0].x);
sy = tree_height / (bb[1].y - bb[0].y);
cx = (bb[0].x + bb[1].x) / 2;

module tree2d() {
    // trunk flare where it meets the roots
    tw = trunk_width / 2;
    hull() {
        translate([(0 - cx) * sx, (4 - bb[0].y) * sy]) circle(tw * 1.25);
        translate([(0 - cx) * sx, (16 - bb[0].y) * sy]) circle(tw * 0.9);
    }
    for (g = TREE)
        hull() {
            translate([(g[0].x - cx) * sx, (g[0].y - bb[0].y) * sy]) circle(g[1], $fn = g[1] < 1 ? 8 : 14);
            translate([(g[2].x - cx) * sx, (g[2].y - bb[0].y) * sy]) circle(g[3], $fn = g[3] < 1 ? 8 : 14);
        }
}

// ---------------------------------------------------------------- swirls
// A little curl: a spiral of about one and a half turns with a tail.
function curl_pts(sz, hand) =
    [for (t = [0:20:560]) let(rr = sz * 0.36 * (1 - t / 560) + sz * 0.04)
         [hand * rr * cos(t), rr * sin(t)]];

// A line of width w along pts, as one polygon (much lighter than hulls),
// with round ends.
function _n(a, b) = let(d = b - a, l = norm(d)) [-d.y, d.x] / l;
function _norm_at(pts, i) =
    i == 0 ? _n(pts[0], pts[1])
  : i == len(pts) - 1 ? _n(pts[i - 1], pts[i])
  : let(v = _n(pts[i - 1], pts[i]) + _n(pts[i], pts[i + 1])) v / norm(v);
module polyline(pts, w) {
    n = len(pts);
    polygon(concat([for (i = [0:n - 1]) pts[i] + _norm_at(pts, i) * w / 2],
                   [for (i = [n - 1:-1:0]) pts[i] - _norm_at(pts, i) * w / 2]));
    for (e = [pts[0], pts[n - 1]]) translate(e) circle(w / 2, $fn = 12);
}

// tree segments in the placed (flat pattern) frame, to keep swirls off it
function placed(pt) = [(pt.x - cx) * sx + C / 2, (pt.y - bb[0].y) * sy + (pattern_len - tree_height) / 2];
TREE_PLACED = [for (g = TREE) [placed(g[0]), g[1], placed(g[2]), g[3]]];
function seg_dist(p, a, b) =
    let(d = b - a, t = max(0, min(1, ((p - a) * d) / max(1e-9, d * d)))) norm(p - (a + d * t));
// does a circle at c of radius r touch the tree?
function hits_tree(c, r) =
    len([for (g = TREE_PLACED) if (seg_dist(c, g[0], g[2]) < r + max(g[1], g[3])) 1]) > 0;

function swirl_fits(c, sz) =
    let(r = sz * 0.4 + swirl_line / 2)
    c.y - r >= 0 && c.y + r <= pattern_len && !hits_tree(c, r + swirl_gap);
function fit_swirl(c, sz) =
    // not below 60%: smaller curls' coils run together in the clay
    swirl_fits(c, sz) ? sz : swirl_fits(c, sz * 0.75) ? sz * 0.75 : swirl_fits(c, sz * 0.6) ? sz * 0.6 : 0;

module swirl_field() {
    cols = max(1, round(C / swirl_size));
    cw = C / cols;                               // exact fit so the seam lines up
    rows = max(1, round(pattern_len / swirl_size));
    rh = pattern_len / rows;
    for (i = [0:cols - 1], j = [0:rows - 1]) {
        q = rnd(tree_seed * 1000 + i * 97 + j * 13, 4);
        x = (i + (j % 2) * 0.5 + (q[0] - 0.5) * 0.25) * cw;
        y = (j + 0.5 + (q[1] - 0.5) * 0.25) * rh;
        // a swirl that would touch the tree or run off the band shrinks until
        // it fits, or is left out, so nothing is left as cut-off dashes
        sz = fit_swirl([x, y], swirl_size * (0.85 + q[3] * 0.2));
        if (sz > 0)
        for (wrap = [-C, 0, C])                  // copies across the seam
            translate([x + wrap, y]) rotate(q[2] * 360)
                polyline(curl_pts(sz, q[3] < 0.5 ? 1 : -1), swirl_line);
    }
}

// The full flat pattern: x = distance around the roller (0..C),
// y = along the roller (0..pattern_len). The tree is centred on the far side
// of the seam.
module tree_placed() {
    translate([C / 2, (pattern_len - tree_height) / 2]) tree2d();
}

module swirls_placed() {
    intersection() {
        square([C, pattern_len]);
        difference() {
            swirl_field();
            offset(delta = swirl_gap) tree_placed();
        }
    }
}

module maybe_mirror() {
    if (mirror_for_imprint) translate([C, 0]) mirror([1, 0]) children();
    else children();
}

// ---------------------------------------------------------------- wrapping
// Wrap a flat 2D pattern around the roller: cut it into thin strips and stand
// each one out radially as a wedge, so neighbouring strips meet face to face.
module wrap(h) {
    w = C / slices;
    Rf = R * cos(180 / slices) - 0.05;   // just inside the body's flat faces
    for (i = [0:slices - 1])
        rotate([0, 0, i * 360 / slices + (360 / slices) / 2])
            translate([Rf, 0, end_margin])
                rotate([90, 0, 90])
                    linear_extrude(R + h - Rf, scale = [(R + h) / Rf, 1])
                        scale([Rf / R, 1])   // arc length on the clay -> width of this flat
                            translate([-(i + 0.5) * w, 0])
                                intersection() {
                                    children();
                                    translate([i * w, -1]) square([w, pattern_len + 2]);
                                }
}

// Ridges with a drafted top: two stacked steps, the upper one narrower, so
// the clay lets go and the grooves have soft shoulders. The finest twigs only
// reach the first step, which makes them press shallower, like a real carved
// line.
module ridge(h) {
    wrap(h * 0.6) children();
    wrap(h) offset(delta = -0.3) children();
}

module roller() {
    difference() {
        union() {
            // body with chamfered ends
            color("#e3d3b0") rotate_extrude($fn = slices)
                polygon([[bore_diameter > 0 ? bore_diameter / 2 : 0, 0],
                         [R - end_chamfer, 0], [R, end_chamfer],
                         [R, roller_length - end_chamfer], [R - end_chamfer, roller_length],
                         [bore_diameter > 0 ? bore_diameter / 2 : 0, roller_length]]);
            color("#6b4a2b") ridge(relief_height) maybe_mirror() tree_placed();
            if (swirls) color("#9a7a52") ridge(swirl_height) maybe_mirror() swirls_placed();
        }
        if (bore_diameter > 0)
            translate([0, 0, -1]) cylinder(d = bore_diameter, h = roller_length + 2, $fn = 48);
    }
}

// What the slab looks like after one roll: grooves where the ridges were.
module imprint() {
    color("#5f9e5a") translate([-6, -6, -1]) cube([C + 12, pattern_len + 12, 1]);
    color("#14301a") linear_extrude(0.2) { tree_placed(); if (swirls) swirls_placed(); }
}

echo(str("One turn of the roller = ", round(C * 10) / 10, " mm of clay; pattern ",
         pattern_len, " mm wide. Tree ", tree_width, " x ", tree_height, " mm."));

if (show == "roller") roller();
else if (show == "imprint") imprint();
else if (show == "tree") tree2d();
