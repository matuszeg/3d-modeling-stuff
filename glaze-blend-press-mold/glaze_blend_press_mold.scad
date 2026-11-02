// Glaze blend test - press mold for a RAISED-cone test tile, any number of glazes
//
// The tile is a regular polygon with one glaze at each corner: 3 sides is a
// classic triaxial blend, 4 a quadraxial, 5 a pentagon, and so on. Cones sit
// at every corner, along every edge and in rings towards the centre, and the
// file works out each cone's blend recipe (show = "recipes" shows the card).
//
// Press clay into the tray, scrape it flat across the wall tops, then turn it
// out: the tile comes out with cones standing up from its face. Each cone
// is split into wedges of different surface textures, the same set on every
// cone, so every glaze blend is tried on every texture.
//
// Prints cavity-up with no supports. Every value below is a Customizer
// setting (Window > Customizer in OpenSCAD).

/* [What to show] */
show = "mold";  // [mold:Mold to print, tile:Preview of the clay tile, recipes:Blend recipe card, cone:One cone up close, cut:Cross-section through one cone]

/* [Shape] */
sides = 3;                          // number of glazes: 3 = triangle, 4 = square, 5 = pentagon, 6 = hexagon...
cones_per_edge = 5;                 // cones along each edge, corners included (ignored when fill_mode = cones)
target_width = 240;                 // overall mold width in mm; 0 = size it from cones_per_edge and min_cone_spacing instead
fill_mode = "spacing";  // [spacing:Keep cones_per_edge and spread them out, cones:Fit as many cones as the width allows, size:Keep cones_per_edge and resize the cones to fit]
printer_bed_size = 256;             // your printer's bed (Bambu P2S: 256); the file refuses a mold bigger than this

/* [Cone textures] */
// Pick up to six; slots set to "none" are left out. Wedges go anticlockwise from texture_1.
texture_1 = "stepped";  // [none:None, smooth:Smooth, stepped:Stepped rings, rings:Throwing rings, ribs:Vertical ribs, fluting:Fluting, facets:Facets, crosshatch:Crosshatch, pebbles:Pebble bumps, dimples:Dimples]
texture_2 = "fluting";  // [none:None, smooth:Smooth, stepped:Stepped rings, rings:Throwing rings, ribs:Vertical ribs, fluting:Fluting, facets:Facets, crosshatch:Crosshatch, pebbles:Pebble bumps, dimples:Dimples]
texture_3 = "pebbles";  // [none:None, smooth:Smooth, stepped:Stepped rings, rings:Throwing rings, ribs:Vertical ribs, fluting:Fluting, facets:Facets, crosshatch:Crosshatch, pebbles:Pebble bumps, dimples:Dimples]
texture_4 = "smooth";  // [none:None, smooth:Smooth, stepped:Stepped rings, rings:Throwing rings, ribs:Vertical ribs, fluting:Fluting, facets:Facets, crosshatch:Crosshatch, pebbles:Pebble bumps, dimples:Dimples]
texture_5 = "none";  // [none:None, smooth:Smooth, stepped:Stepped rings, rings:Throwing rings, ribs:Vertical ribs, fluting:Fluting, facets:Facets, crosshatch:Crosshatch, pebbles:Pebble bumps, dimples:Dimples]
texture_6 = "none";  // [none:None, smooth:Smooth, stepped:Stepped rings, rings:Throwing rings, ribs:Vertical ribs, fluting:Fluting, facets:Facets, crosshatch:Crosshatch, pebbles:Pebble bumps, dimples:Dimples]
texture_rotation = 90;              // direction texture_1's wedge faces on the tile (90 = towards corner A)

/* [Layout] */
min_cone_spacing = 31;              // spacing between cone centres; with target_width on, the smallest spacing allowed
edge_margin = 22;                   // cone centre to tray wall, measured perpendicular

/* [Cone shape] */
cone_height = 10;                   // cone height on the finished tile
cone_base_radius = 10.5;            // cone radius where it meets the tile face (the largest size when fill_mode = size)
cone_top_radius = 3.5;              // radius of the flat top before rounding
cone_tip_rounding = 2.0;            // rounding on the cone's top edge

/* [Texture details] */
step_count = 4;                     // stepped rings: number of steps
step_wall_angle = 12;               // stepped rings: degrees off vertical for each step wall
step_edge_rounding = 0.5;           // stepped rings: rounding on each step's outer edge
step_inner_rounding = 0.4;          // stepped rings: rounding where a ledge meets the next wall
ring_spacing = 2.5;                 // throwing rings: spacing
ring_depth = 0.5;                   // throwing rings: depth
rib_spacing = 3;                    // vertical ribs: spacing at the base
rib_width = 1.6;                    // vertical ribs: width (they stand about a third of this tall)
flute_spacing = 3.2;                // fluting: spacing at the base
flute_width = 2.4;                  // fluting: groove width
flute_depth = 0.8;                  // fluting: groove depth
facet_count = 12;                   // facets: flat faces around a whole cone
crosshatch_lines = 16;              // crosshatch: lines each way around a whole cone
crosshatch_depth = 0.5;             // crosshatch: line depth
crosshatch_twist = 55;              // crosshatch: how much the lines spiral, degrees base to top
pebble_radius = 1.0;                // pebble bumps: radius
pebble_spacing = 3.0;               // pebble bumps: spacing
dimple_radius = 1.3;                // dimples: radius
dimple_depth = 0.7;                 // dimples: depth
dimple_spacing = 3.4;               // dimples: spacing

/* [Groove around each cone] */
grooves_around_cones = true;        // a groove around each cone to catch pooling glaze
groove_width = 2.5;                 // width of the groove around each cone base
groove_depth = 2.0;                 // depth of that groove

/* [Tray] */
slab_thickness = 6.5;               // tray depth, which sets the clay slab thickness
wall_thickness = 5;                 // thickness of the tray wall
wall_lean_angle = 10;               // degrees the tray wall leans out (helps release)
corner_radius = 8;                  // rounding on the tray's corners
plastic_under_cones = 2;            // plastic under the cone tips

/* [Release vents] */
release_vents = true;               // a pin-hole vent at every cone tip
vent_diameter = 1.2;                // through-hole at each cone tip; push a pin up to pop a cone

/* [Hanging hole] */
// Which corner gets the hanging hole
hanging_hole_corner = "A";  // [none, A, B, C, D, E, F, G, H]
hanging_hole_diameter = 6;          // finished hole size after firing
clay_shrinkage_percent = 12;        // % your clay shrinks from wet to fired; the mold post is enlarged to suit
clay_around_hanging_hole = 5;       // clay left between the hole and the tile's edges
hanging_post_taper = 3;             // degrees the post tapers so the clay lifts off it

/* [Labels] */
show_corner_letters = true;         // a letter at each corner: A at the top (top-left if flat), then anticlockwise
corner_letters = "ABCDEFGHIJKL";    // letters used for the corners, in order
show_cone_numbers = true;           // number every cone, row by row from the top
letter_size = 7;                    // height of the corner letters
number_size = 4;                    // height of the cone numbers
text_depth = 0.8;                   // how deep the letters are cut into the clay
font = "Liberation Sans:style=Bold";  // font for letters and numbers

/* [Quality] */
$fn = 48;                           // smoothness of curves: higher is smoother but slower

// ---------------------------------------------------------------------------

textures = [for (t = [texture_1, texture_2, texture_3, texture_4, texture_5, texture_6]) if (t != "none") t];
n_tex = len(textures);

// Regular polygon, flat edge at the bottom. Corner A is the top corner (the
// top-left one when the top is flat), the rest follow anticlockwise.
half = 180 / sides;
theta0 = -90 + half;                       // angle of one corner, flat bottom edge
a_idx = search(max([for (i = [0 : sides - 1]) round(1e4 * sin(theta0 + i * 360 / sides) - cos(theta0 + i * 360 / sides))]),
               [for (i = [0 : sides - 1]) round(1e4 * sin(theta0 + i * 360 / sides) - cos(theta0 + i * 360 / sides))])[0];
function corner_angle(j) = theta0 + (a_idx + j) * 360 / sides;
letters = [for (i = [0 : sides - 1]) corner_letters[i]];

span_x = max([for (i = [0 : sides - 1]) cos(theta0 + i * 360 / sides)]) -
         min([for (i = [0 : sides - 1]) cos(theta0 + i * 360 / sides)]);
w_per = span_x / cos(half) / (2 * tan(half));

// Hanging hole: post diameter at the top (= wet hole size) and at the floor.
hanging_hole_index = search([hanging_hole_corner], letters)[0];
has_hanging_hole = hanging_hole_corner != "none" && hanging_hole_index != [];
post_diameter_top = hanging_hole_diameter / (1 - clay_shrinkage_percent / 100);
post_diameter_floor = post_diameter_top + 2 * slab_thickness * tan(hanging_post_taper);
// Distance from the tray's sharp corner point to the hole centre, far enough
// in to leave clay_around_hanging_hole of clay to both edges and to the rounded corner tip.
hanging_hole_inset = max((post_diameter_floor / 2 + clay_around_hanging_hole) / cos(half),
                 corner_radius / cos(half) - corner_radius + post_diameter_floor / 2 + clay_around_hanging_hole);
// Wider corners are shallower, so the hole and its corner letter may need a
// bigger margin than asked for; it grows just enough (never shrinks).
// The letter's reach along the corner's direction: its height when the corner
// points straight up (the triangle), more on a diagonal corner.
hanging_hole_angle = has_hanging_hole ? theta0 + (a_idx + hanging_hole_index) * 360 / sides : 90;
label_reach = letter_size * (0.5 * abs(sin(hanging_hole_angle)) + 0.55 * abs(cos(hanging_hole_angle)));
hanging_hole_room = 2 * label_reach + 2.5;         // groove-to-hole space the letter needs

// Cone size. Normally the settings as given; with fill_mode = "size" the
// whole cone (radius, top, height, tip) shrinks just enough for
// cones_per_edge to fit target_width, never growing past cone_base_radius. The cone
// size moves the corner margin, which moves the spacing, which moves the cone
// size, so it is solved by repeating the calculation until it settles.
groove_reach = grooves_around_cones ? groove_width : 0;
// Spacing a triangle's numbers need beyond the grooves (a two-digit number plus 1 mm each side).
num_room_tri = 1.3 * number_size + 2 * sqrt(3) * 0.5;
auto_size = target_width > 0 && fill_mode == "size";
function margin_for(m) = has_hanging_hole ? max(edge_margin, cos(half) * (hanging_hole_inset + post_diameter_floor / 2 + m + hanging_hole_room + 0.01)) : edge_margin;
function sp_for(m) = (target_width - (span_x / cos(half) * (margin_for(m) - corner_radius) + 2 * (corner_radius + wall_thickness)))
                     / (w_per * (cones_per_edge - 1));
// Biggest groove radius that keeps 2 mm between neighbours, and (on the
// triangle, whose numbers sit in the gaps) room for the numbers.
function moat_fit(spv) = min((spv - 2) / 2, (sides == 3 && show_cone_numbers) ? (spv - num_room_tri) / sqrt(3) : 1e9);
function solve_moat(m, i = 0) = i >= 15 ? m : solve_moat(min(cone_base_radius + groove_reach, moat_fit(sp_for(m))), i + 1);
size_factor = auto_size ? max(0.01, (solve_moat(cone_base_radius + groove_reach) - groove_reach) / cone_base_radius) : 1;
cone_base_radius_sized = cone_base_radius * size_factor;
cone_top_radius_sized = cone_top_radius * size_factor;
cone_height_sized = cone_height * size_factor;
cone_tip_rounding_sized = cone_tip_rounding * size_factor;

// Nominal smooth cone: every texture stays inside it.
slope = (cone_base_radius_sized - cone_top_radius_sized) / cone_height_sized;
function R(h) = cone_base_radius_sized - slope * h;
function uses(t) = len([for (x = textures) if (x == t) 1]) > 0;

// Some texture settings only work on a steep enough cone. Rather than refuse,
// soften them to the safe limit for this cone shape (and say so).
step_wall_angle_used = min(step_wall_angle, 0.8 * atan(slope));                   // steps must fit
ring_depth_used = min(ring_depth, 0.9 * slope * ring_spacing / PI);      // rings mustn't hook
flute_depth_used = min(flute_depth, 0.45 * flute_width);                           // flute must be a groove
crosshatch_wall_angle = 62;                                                     // degrees each V wall sits off radial
cone_tip_rounding_used = min(cone_tip_rounding_sized, 0.8 * cone_top_radius_sized, 0.5 * cone_height_sized);              // rounding must fit the top
// Pebble and dimple drops must run far enough to bury their far end in the
// cone; gentler cones need longer drops (the default cone keeps 2.5 radii).
sink = slope / sqrt(1 + slope * slope);                              // how fast the surface recedes per mm
pebble_drop = max(2.5, 1.4 / sink) * pebble_radius;
dimple_rise = max(2.5, 1.2 / sink) * dimple_radius;
crosshatch_twist_used = min(crosshatch_twist,
    0.75 * tan(crosshatch_wall_angle) * (1 - R(min(cone_height_sized + 1, (cone_base_radius_sized - 0.3) / slope)) / R(-0.5)) * 180 / PI);

z_floor = plastic_under_cones + cone_height_sized;
z_top = z_floor + slab_thickness;
footprint_r = cone_base_radius_sized + (grooves_around_cones ? groove_width : 0);

// Stepped-ring tiers for an n-step cone; n = 1 is the plain smooth cone.
function tier_dr(n) = cone_height_sized / n * tan(step_wall_angle_used);
function tier_ledge(n) = n > 1 ? (cone_base_radius_sized - cone_top_radius_sized - n * tier_dr(n)) / (n - 1) : 0;
function trb(n, i) = cone_base_radius_sized - i * (tier_dr(n) + tier_ledge(n));
function trt(n, i) = n == 1 ? cone_top_radius_sized : trb(n, i) - tier_dr(n);

hanging_hole_margin = cos(half) * (hanging_hole_inset + post_diameter_floor / 2 + footprint_r + hanging_hole_room + 0.01);
margin = has_hanging_hole ? max(edge_margin, hanging_hole_margin) : edge_margin;

// Spacing. The mold's width is w_per x (edge length) + w_fixed, so a target
// width can be solved for exactly: either for the spacing (fill_mode =
// spacing) or for the most cones per edge at no less than min_cone_spacing (cones).
w_fixed = span_x / cos(half) * (margin - corner_radius) + 2 * (corner_radius + wall_thickness);
spacing_floor = auto_size ? 2 * footprint_r + 2 : max(min_cone_spacing, 2 * footprint_r + 2);  // never closer than the cones allow
k_fit = floor((target_width - w_fixed) / (w_per * spacing_floor) + 1e-6);
spaces_per_edge = target_width > 0 && fill_mode == "cones" ? k_fit : cones_per_edge - 1;  // spaces along an edge
cone_spacing = target_width > 0 ? (target_width - w_fixed) / (w_per * spaces_per_edge) : spacing_floor;  // spacing actually used
grid_inr = spaces_per_edge * cone_spacing / (2 * tan(half));
// Ring-to-ring spacing. Triangle and hexagon rings are staggered, so they can
// sit closer (the exact triangle/hex lattice); other shapes need a full spacing.
ring_d = (sides == 3 || sides == 6) ? cone_spacing * sqrt(3) / 2 : cone_spacing;
tray_inr = grid_inr + margin;
corner_gap = margin / cos(half);           // corner cone to the tray's sharp corner point
tip_gap = corner_gap - (corner_radius / cos(half) - corner_radius);  // ... to its rounded tip
outer_inr = tray_inr + wall_thickness;
outer_vr = (outer_inr - corner_radius - wall_thickness) / cos(half);
outer_xs = [for (i = [0 : sides - 1]) outer_vr * cos(theta0 + i * 360 / sides)];
outer_ys = [for (i = [0 : sides - 1]) outer_vr * sin(theta0 + i * 360 / sides)];
outer_w = max(outer_xs) - min(outer_xs) + 2 * (corner_radius + wall_thickness);
outer_d = max(outer_ys) - min(outer_ys) + 2 * (corner_radius + wall_thickness);

assert(sides >= 3 && sides <= 12, "sides must be between 3 and 12");
assert(cones_per_edge >= 2, "cones_per_edge must be at least 2");
assert(len(corner_letters) >= sides, "corner_letters needs a letter for every corner");
assert(n_tex > 0, "Pick at least one texture");
assert(!auto_size || cone_base_radius_sized >= 4, str("Too many cones for this width: they would be under 8 mm across. Lower cones_per_edge or raise target_width"));
assert(cone_height_sized > 0 && cone_top_radius_sized > 0 && cone_base_radius_sized > cone_top_radius_sized + 1, "The cone needs cone_base_radius_sized at least 1 mm bigger than cone_top_radius_sized, and a positive height");
assert(!uses("stepped") || cone_height_sized / step_count > 0.6, "Too many steps for this cone height: lower step_count");
assert(target_width == 0 || spaces_per_edge >= 1, "target_width is too small for even two cones per edge");
assert(target_width == 0 || cone_spacing >= spacing_floor - 1e-6,
       str(cones_per_edge, " cones per edge need ", round(w_fixed + w_per * (cones_per_edge - 1) * spacing_floor),
           " mm at min_cone_spacing: raise target_width, lower cones_per_edge, or use fill_mode = cones"));
assert(min_gap() >= 2 * footprint_r + 1, "Cones overlap: raise min_cone_spacing");
assert(outer_w <= printer_bed_size && outer_d <= printer_bed_size,
       str("Mold is ", round(outer_w), " x ", round(outer_d), " mm, bigger than printer_bed_size: fewer cones_per_edge or a smaller min_cone_spacing"));
assert(hanging_hole_corner == "none" || has_hanging_hole, "hanging_hole_corner must be a corner letter this shape has, or none");
assert(!has_hanging_hole || corner_gap - hanging_hole_inset - post_diameter_floor / 2 > footprint_r + hanging_hole_room,
       "Hanging hole doesn't fit in the corner: raise edge_margin, or shrink hanging_hole_diameter or clay_around_hanging_hole");

if (margin > edge_margin) echo(str("NOTE: edge_margin grown to ", round(margin * 10) / 10, " mm to fit the hanging hole"));
if (auto_size) echo(str("Cones resized to ", round(cone_base_radius_sized * 20) / 10, " mm across and ", round(cone_height_sized * 10) / 10,
                         " mm tall (", round(size_factor * 100), "% of full size) to fit ", cones_per_edge, " per edge"));
if (!auto_size && spacing_floor > min_cone_spacing) echo(str("NOTE: cone spacing raised to at least ", round(spacing_floor * 10) / 10, " mm so the bigger cones don't touch"));
if (uses("stepped") && step_wall_angle_used < step_wall_angle) echo(str("NOTE: step_wall_angle eased to ", round(step_wall_angle_used * 10) / 10, " degrees to fit this cone"));
if (uses("rings") && ring_depth_used < ring_depth) echo(str("NOTE: ring_depth eased to ", round(ring_depth_used * 100) / 100, " mm so the rings release from the mold"));
if (uses("fluting") && flute_depth_used < flute_depth) echo(str("NOTE: flute_depth eased to ", round(flute_depth_used * 100) / 100, " mm"));
if (cone_tip_rounding_used < cone_tip_rounding_sized) echo(str("NOTE: cone_tip_rounding_sized eased to ", round(cone_tip_rounding_used * 10) / 10, " mm to fit the cone's top"));
if (uses("crosshatch") && crosshatch_twist_used < crosshatch_twist) echo(str("NOTE: crosshatch_twist eased to ", round(crosshatch_twist_used), " degrees so the lines release from the mold"));
echo(str("Cone spacing ", round(cone_spacing * 10) / 10, " mm, ", spaces_per_edge + 1, " cones per edge"));
echo(str(sides, " glazes, ", len(cones()), " cones; mold ", round(outer_w), " x ", round(outer_d), " x ", z_top,
         " mm; textures: ", textures));
if (!show_cone_numbers || min([for (n = [0 : len(cones()) - 1]) num_score(n)]) < 0)
    echo("NOTE: some cone numbers are tight for space; raise min_cone_spacing or edge_margin, or lower number_size");
for (n = [0 : len(cones()) - 1]) echo(recipe_line(n));

// Corner j of a polygon with inradius r, in tile coordinates (centre at the origin).
function corner_pt(r, j) = r / cos(half) * [cos(corner_angle(j)), sin(corner_angle(j))];

// Cones in rings: the outer ring has a cone at every corner and cones_per_edge
// along each edge; each ring inside is ring_d further in, with as many cones
// per edge as fit at about the cone spacing, ending in a centre cone if there's room.
function ring_r(m) = grid_inr - m * ring_d;
function ring_k(m) = floor(2 * ring_r(m) * tan(half) / cone_spacing + 0.1);  // never closer than the spacing
function ring_used(m) = ring_r(m) > -0.01 && (m == 0 || ring_k(m - 1) > 0);
function ring_pts(m) = ring_k(m) <= 0 ? [[0, 0]] :
    [for (j = [0 : sides - 1], t = [0 : ring_k(m) - 1])
        let (a = corner_pt(ring_r(m), j), b = corner_pt(ring_r(m), j + 1)) a + (b - a) * t / ring_k(m)];
function raw_cones() = [for (m = [0 : ceil(grid_inr / ring_d) + 1]) if (ring_used(m)) each ring_pts(m)];

// Numbered row by row from the top, left to right within a row.
function before(a, b) = round(a[1] * 100) > round(b[1] * 100) ||
                        (round(a[1] * 100) == round(b[1] * 100) && a[0] < b[0] - 0.01);
function sort_pts(v) = len(v) <= 1 ? v :
    let (p = v[floor(len(v) / 2)])
    concat(sort_pts([for (q = v) if (before(q, p)) q]),
           [for (q = v) if (!before(q, p) && !before(p, q)) q],
           sort_pts([for (q = v) if (before(p, q)) q]));
_cones = sort_pts(raw_cones());
function cones() = _cones;

function min_gap() = len(_cones) < 2 ? 1e9 :
    min([for (i = [0 : len(_cones) - 2], j = [i + 1 : len(_cones) - 1]) norm(_cones[i] - _cones[j])]);

// The corner cones in tile coordinates, in letter order.
function corner_cones() = [for (j = [0 : sides - 1]) corner_pt(grid_inr, j)];

// Hanging-hole centre in tile coordinates, on the corner's bisector.
function hang_pos() = let (c = corner_cones()[hanging_hole_index]) c + (corner_gap - hanging_hole_inset) * c / norm(c);

module rounded_poly(inr, r) {
    offset(r = r) rotate(theta0) circle(r = (inr - r) / cos(half), $fn = sides);
}

// --- Blend recipes: generalized barycentric (Wachspress) coordinates, which
// are the usual percentages on a triangle and the usual bilinear grid on a square.
function cross2(a, b, c) = (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]);
function on_edge(x, a, b) = abs(cross2(x, a, b)) < 1e-6 * norm(b - a) &&
                            (x - a) * (b - a) >= -1e-6 && (x - b) * (a - b) >= -1e-6;
function blend(x) = let (V = corner_cones(), N = sides,
        vert = [for (i = [0 : N - 1]) if (norm(x - V[i]) < 1e-6) i],
        edge = [for (i = [0 : N - 1]) if (on_edge(x, V[i], V[(i + 1) % N])) i])
    len(vert) > 0 ? [for (i = [0 : N - 1]) i == vert[0] ? 1 : 0] :
    len(edge) > 0 ? let (i = edge[0], t = norm(x - V[i]) / norm(V[(i + 1) % N] - V[i]))
                    [for (j = [0 : N - 1]) j == i ? 1 - t : j == (i + 1) % N ? t : 0] :
    let (w = [for (i = [0 : N - 1]) let (p = V[(i + N - 1) % N], c = V[i], n = V[(i + 1) % N])
                 cross2(p, c, n) / (cross2(x, p, c) * cross2(x, c, n))],
         s = w * [for (i = [0 : N - 1]) 1])
    w / s;
function pct(f) = round(f * 1000) / 10;
function join(v, sep, i = 0) = i >= len(v) ? "" : str(i > 0 ? sep : "", v[i], join(v, sep, i + 1));
function recipe_line(n) = let (b = blend(_cones[n]))
    str("Cone ", n + 1, ":  ", join([for (i = [0 : sides - 1]) if (pct(b[i]) > 0) str(letters[i], " ", pct(b[i]), "%")], "   "));

// --- Number placement. The triangle keeps its original spot (centred below
// each cone). Other shapes place numbers one at a time: each takes the spot
// nearest its own cone that has room, clear of cones, walls, corner letters,
// the hanging hole and the numbers already placed.
function wall_dist(q) = tray_inr - max([for (i = [0 : sides - 1]) q * [cos(theta0 + half + i * 360 / sides), sin(theta0 + half + i * 360 / sides)]]);
function label_pos(i) = let (c = corner_cones()[i], dir = c / norm(c),
        d_free = footprint_r + 0.45 * (tip_gap - footprint_r),
        d_hang = (footprint_r + corner_gap - hanging_hole_inset - post_diameter_floor / 2) / 2)
    c + (has_hanging_hole && i == hanging_hole_index ? d_hang : d_free) * dir;
function clearance(q) = min(concat(
    [for (j = [0 : len(_cones) - 1]) norm(q - _cones[j]) - footprint_r],
    [wall_dist(q) - 0.5],
    show_corner_letters ? [for (i = [0 : sides - 1]) norm(q - label_pos(i)) - 0.75 * letter_size] : [],
    has_hanging_hole ? [norm(q - hang_pos()) - post_diameter_floor / 2 - 1] : [])) - 0.65 * number_size;
num_angles = [270, 300, 240, 330, 210, 0, 180, 30, 150, 60, 120, 90];
function num_cands(n) = [for (a = num_angles, r = [footprint_r + 0.65 * number_size : 0.5 : 0.85 * cone_spacing])
                             _cones[n] + r * [cos(a), sin(a)]];
num_rmin = footprint_r + 0.65 * number_size;
function num_room(q, placed) = min(clearance(q),
    len(placed) == 0 ? 1e9 : min([for (pp = placed) norm(q - pp)]) - 1.6 * number_size);
// Enough room (1.5 mm) counts the same everywhere; after that, closer to the cone wins.
function num_pick(n, placed) = let (cs = num_cands(n),
        sc = [for (q = cs) min(num_room(q, placed), 1.5) - 0.03 * (norm(q - _cones[n]) - num_rmin)],
        best = max(sc))
    cs[search(1, [for (v = sc) v >= best - 1e-6 ? 1 : 0])[0]];
function place_nums(n = 0, placed = []) =
    n >= len(_cones) ? placed : place_nums(n + 1, concat(placed, [num_pick(n, placed)]));
// (On a spread-out triangle the number stays at the default distance, so it
// stays next to its own cone instead of drifting into the gap.)
_nums = sides == 3 ? [for (c = _cones) c - [0, min(cone_spacing, max(min_cone_spacing, footprint_r * sqrt(3) + num_room_tri)) / sqrt(3)]] : place_nums();
function num_pos(n) = _nums[n];
function num_score(n) = num_room(_nums[n], [for (i = [0 : len(_nums) - 1]) if (i != n) _nums[i]]);

module round_convex(r) { offset(r = r) offset(delta = -r) children(); }
module round_concave(r) { offset(r = -r) offset(delta = r) children(); }

// ---------------------------------------------------------------------------
// One clay cone, in tile coordinates: z up from the tile face, tip at cone_height_sized.

// 2D (radius, height) profile of an n-step cone with a rounded tip.
// Drawn mirrored about the axis so rounding never dents the centre, then cut
// to r >= 0. It extends slab_thickness below the face so it also clears the groove.
module stepped_profile(n) {
    ext = slab_thickness;
    h_t = cone_height_sized / n;
    top_i = n - 1;
    h0 = top_i * h_t;
    intersection() {
        round_concave(step_inner_rounding) union() {
            if (n > 1) round_convex(step_edge_rounding) {
                right = concat(
                    [[0, -ext], [cone_base_radius_sized, -ext]],
                    [for (i = [0 : n - 2]) each [[trb(n, i), i * h_t], [trt(n, i), (i + 1) * h_t]]],
                    [[0, h0]]);
                polygon(concat(right, [for (i = [len(right) - 1 : -1 : 0]) [-right[i][0], right[i][1]]]));
            }
            // Reach all the way down so the rounding never shrinks it to nothing;
            // the part below h0 is hidden inside the lower steps.
            e = h0 + ext;
            round_convex(min(cone_tip_rounding_used, 0.9 * h_t))
                polygon([[-trb(n, top_i), h0 - e], [trb(n, top_i), h0 - e], [trb(n, top_i), h0],
                         [trt(n, top_i), cone_height_sized], [-trt(n, top_i), cone_height_sized], [-trb(n, top_i), h0]]);
        }
        translate([0, -slab_thickness - 1]) square([cone_base_radius_sized + 1, cone_height_sized + slab_thickness + 2]);
    }
}

// The smooth cone with its rounded tip; every texture is trimmed to it.
module envelope() { rotate_extrude(convexity = 10) stepped_profile(1); }

// A 2D cross-section drawn at the base, extruded up with the cone's taper.
// Each slice is a shrunk (and, with twist, turned) copy of the one below, so
// nothing on it can hook into the mold.
texture_z0 = -0.5;
// Textures reach this far past the smooth outline so the outline trims them
// cleanly; surfaces that only just touch leave bad edges in the exported mesh.
texture_overshoot = 0.2;
// Runs a little past the tip so its top isn't level with the cone's flat top.
texture_z1 = min(cone_height_sized + 1, (cone_base_radius_sized - 0.3) / slope);
// Texture cores are turned half a facet so their facet edges never line up
// with the outline's (edges that coincide exactly also leave bad mesh edges).
module core_circle(r) { rotate(180 / $fn) circle(r = r); }
module taper(twist = 0) {
    translate([0, 0, texture_z0])
        linear_extrude(height = texture_z1 - texture_z0, scale = R(texture_z1) / R(texture_z0),
                       twist = twist, slices = twist == 0 ? 1 : 24, convexity = 10)
            children();
}

function pt(h, a, r) = [r * cos(a), r * sin(a), h];

// Staggered rows of [height, angle] points inside a wedge, for bumps and dents.
function dots(spacing, margin, a0, a1, hmin, hmax) = [
    for (j = [0 : floor((hmax - hmin) / (spacing * 0.866))])
        let (h = hmin + j * spacing * 0.866,
             step = spacing / R(h) * 180 / PI,
             m = margin / R(h) * 180 / PI,
             first = a0 + m + (j % 2) * step / 2)
        if (first <= a1 - m)
            for (a = [first : step : a1 - m]) [h, a]
];

module texture(t, a0, a1) {
    Rb = R(texture_z0);
    if (t == "smooth") {
        envelope();
    } else if (t == "stepped") {
        rotate_extrude(convexity = 10) stepped_profile(step_count);
    } else if (t == "rings") {
        rotate_extrude(convexity = 10) polygon(concat(
            [[0, -slab_thickness]], [[cone_base_radius_sized, -slab_thickness]],
            [for (h = [0 : 0.1 : cone_height_sized]) [R(h) + texture_overshoot - ring_depth_used * (0.5 + 0.5 * sin(360 * h / ring_spacing - 90)), h]],
            [[0, cone_height_sized]]));
    } else if (t == "ribs") {
        // Each rib is a 140-degree arc, not a half circle, so its sides only
        // ever face outwards and can't curl back under the mold.
        n = round(2 * PI * Rb / rib_spacing);
        rc = rib_width / 2 / sin(70);
        taper() union() {
            core_circle(Rb - rc * (1 - cos(70)));
            for (k = [0 : n - 1]) rotate((k + 0.37) * 360 / n) translate([Rb - rc + texture_overshoot, 0]) circle(r = rc, $fn = 36);
        }
    } else if (t == "fluting") {
        n = round(2 * PI * Rb / flute_spacing);
        taper() difference() {
            core_circle(Rb + texture_overshoot);
            // (offset 0.37 of a step so no flute lands exactly on an outline facet)
            for (k = [0 : n - 1]) rotate((k + 0.37) * 360 / n) translate([Rb + flute_width / 2 - flute_depth_used, 0]) circle(d = flute_width, $fn = 16);
        }
    } else if (t == "facets") {
        taper() circle(r = Rb + texture_overshoot, $fn = facet_count);
    } else if (t == "crosshatch") {
        w = (1 + crosshatch_depth) * tan(crosshatch_wall_angle);
        // intersection_for, not intersection(){for...}: a plain for would union the two.
        intersection_for (s = [-1, 1]) taper(s * crosshatch_twist_used) difference() {
            core_circle(Rb + texture_overshoot);
            // The second set is offset half a spacing and cut a little shallower,
            // so the two sets' V tips never meet exactly (that leaves bad mesh edges).
            for (k = [0 : crosshatch_lines - 1]) rotate((k + (s > 0 ? 0.5 : 0)) * 360 / crosshatch_lines)
                polygon([[Rb - crosshatch_depth * (s > 0 ? 0.8 : 1), 0], [Rb + 1, w], [Rb + 1, -w]]);
        }
    } else if (t == "pebbles") {
        // A smaller core with bumps reaching the nominal surface. Each bump is
        // drawn out downwards into a widening drop so its underside can't hook.
        union() {
            taper() core_circle(Rb - pebble_radius);
            for (p = dots(pebble_spacing, pebble_radius, a0, a1, 1.2 * pebble_radius, cone_height_sized - cone_tip_rounding_used - pebble_radius))
                hull() {
                    translate(pt(p[0], p[1], R(p[0]) - pebble_radius + texture_overshoot)) sphere(r = pebble_radius, $fn = 16);
                    translate(pt(p[0] - pebble_drop, p[1], R(p[0]) - pebble_radius + texture_overshoot)) sphere(r = 1.2 * pebble_radius, $fn = 16);
                }
        }
    } else if (t == "dimples") {
        // Each dent opens upwards and outwards into a widening drop, for the same reason.
        difference() {
            envelope();
            for (p = dots(dimple_spacing, dimple_radius, a0, a1, dimple_radius, cone_height_sized - cone_tip_rounding_used - dimple_radius))
                hull() {
                    translate(pt(p[0], p[1], R(p[0]) + dimple_radius - dimple_depth)) sphere(r = dimple_radius, $fn = 12);
                    translate(pt(p[0] + dimple_rise, p[1], R(p[0]) + dimple_radius - dimple_depth)) sphere(r = 1.15 * dimple_radius, $fn = 12);
                }
        }
    }
}

module wedge(a0, a1) {
    translate([0, 0, -slab_thickness - 1]) linear_extrude(cone_height_sized + slab_thickness + 2, convexity = 10)
        polygon(concat([[0, 0]], [for (k = [0 : 24]) 2 * cone_base_radius_sized * [cos(a0 + k * (a1 - a0) / 24), sin(a0 + k * (a1 - a0) / 24)]]));
}

module cone() {
    span = 360 / n_tex;
    // Below the tile face (in the mold, the tray space above the floor) the
    // cavity flares out slightly. It trims the groove ring's inner wall cleanly,
    // with a little draft, and nothing in it merely touches the cone's surfaces.
    rotate_extrude(convexity = 10)
        polygon([[0, 0], [cone_base_radius_sized, 0], [cone_base_radius_sized + 1, -slab_thickness], [0, -slab_thickness]]);
    for (i = [0 : n_tex - 1]) {
        a0 = texture_rotation + i * span - span / 2;
        a1 = a0 + span;
        intersection() {
            envelope();
            texture(textures[i], a0, a1);
            // Neighbouring wedges overlap by half a degree: wedges that only
            // touch on a shared plane leave thin fins in newer OpenSCAD (Manifold).
            if (n_tex > 1) wedge(a0 - 0.5, a1 + 0.5);
        }
    }
}

// ---------------------------------------------------------------------------

// Ring left standing on the tray floor; it forms the groove in the clay.
module groove_ring() {
    rotate_extrude(convexity = 10)
        round_convex(min(groove_width, groove_depth) / 3)
            polygon([[cone_base_radius_sized - 0.5, -0.5], [cone_base_radius_sized + groove_width, -0.5],
                     [cone_base_radius_sized + groove_width, 0], [cone_base_radius_sized + groove_width - groove_depth * tan(15), groove_depth],
                     [cone_base_radius_sized - 0.5, groove_depth]]);
}

// Labels as they should read on the finished tile (mirrored when cut into the mold).
module labels_2d() {
    // Corner letters sit on each corner's bisector; with the hole in that
    // corner, the letter moves to midway between groove and hole.
    if (show_corner_letters)
        for (i = [0 : sides - 1])
            translate(label_pos(i))
                text(letters[i], size = letter_size, font = font, halign = "center", valign = "center");
    if (show_cone_numbers)
        for (n = [0 : len(cones()) - 1])
            translate(num_pos(n))
                text(str(n + 1), size = number_size, font = font, halign = "center", valign = "center");
}

module tray_void() {
    flare = (slab_thickness + 1) * tan(wall_lean_angle);
    hull() {
        translate([0, 0, z_floor]) linear_extrude(0.01) rounded_poly(tray_inr, corner_radius);
        translate([0, 0, z_top + 1]) linear_extrude(0.01) rounded_poly(tray_inr + flare, corner_radius + flare);
    }
}

// Tapered post standing on the tray floor; forms the hanging hole in the clay.
// Placed in mold coordinates (mirrored, like the labels).
module hang_post() {
    if (has_hanging_hole) {
        p = hang_pos();
        translate([-p[0], p[1], z_floor - 0.5])
            cylinder(d1 = post_diameter_floor + 0.5 * 2 * tan(hanging_post_taper), d2 = post_diameter_top, h = slab_thickness + 0.5, $fn = 32);
    }
}

// Everything that sits on or rises from the tray floor: grooves, letters, post.
module floor_features() {
    if (grooves_around_cones) for (c = cones()) translate([c[0], c[1], z_floor]) groove_ring();
    translate([0, 0, z_floor - 0.01]) linear_extrude(text_depth + 0.01, convexity = 10) mirror([1, 0, 0]) labels_2d();
    hang_post();
}

// A cone placed in the mold: tip down, and mirrored like the labels so the
// wedges come out in the right order once the tile is turned out. (The cone
// grid is symmetric, so mirroring the positions too changes nothing.)
module cone_cavity(c) {
    // render() makes the preview (F5) build one cone and reuse it; without it
    // the textured cones swamp the preview and it shows nothing. No effect on F6.
    translate([c[0], c[1], z_floor]) mirror([0, 0, 1]) mirror([1, 0, 0]) render(convexity = 10) cone();
}

module mold() {
    difference() {
        linear_extrude(z_top, convexity = 10) rounded_poly(outer_inr, corner_radius + wall_thickness);
        difference() {
            tray_void();
            floor_features();
        }
        for (c = cones()) {
            cone_cavity(c);
            if (release_vents) translate([c[0], c[1], -1]) cylinder(d = vent_diameter, h = plastic_under_cones + 1.5, $fn = 16);
        }
    }
}

// The clay as it sits in the mold, in mold coordinates.
module clay_in_mold() {
    difference() {
        intersection() {
            tray_void();
            translate([0, 0, z_floor]) linear_extrude(slab_thickness) rounded_poly(tray_inr + 5, corner_radius);
        }
        floor_features();
    }
    for (c = cones()) cone_cavity(c);
}

// Flat card listing every cone's blend, for reading in the preview.
module recipe_card() {
    n = len(cones());
    lh = 7;
    color("black") {
        text(str(sides, "-glaze blend, ", n, " cones"), size = 6, font = font);
        for (i = [0 : n - 1]) translate([0, -(i + 1.5) * lh]) text(recipe_line(i), size = 4.5, font = font);
    }
}

// Preview of the finished tile: turned out of the mold, face up.
module tile() {
    rotate([0, 180, 0]) translate([0, 0, -z_top]) clay_in_mold();
}

if (show == "mold") mold();
else if (show == "tile") tile();
else if (show == "cone") cone();
else if (show == "cut") intersection() { mold(); translate([cones()[0][0] - 20, cones()[0][1], -1]) cube([40, 30, 40]); }
else if (show == "recipes") recipe_card();
