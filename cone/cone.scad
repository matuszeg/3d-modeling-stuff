// Simple cone, from Mom's sketch: 5" across the base, 1/2" flat tip,
// 3 1/2" side.
//
// The 3 1/2" is written along the sloped side, so by default it is used as the
// SLANT length (base edge to tip). If it was meant to be the straight-up
// height instead, set side_is_slant = false.

/* [Size, in inches] */
base_diameter_in = 5;
side_in          = 3.5;
// true: side_in is measured along the slope. false: it's the vertical height
side_is_slant    = true;

/* [Shape] */
// 0 = solid cone. Otherwise the wall thickness (mm) of a hollow cone, open at the bottom
wall_mm          = 0;
// Diameter of the flat top/tip, in inches (0 = sharp point)
tip_diameter_in  = 0.5;

/* [Hidden] */
$fn = 180;
IN = 25.4;

r = base_diameter_in * IN / 2;
tip_r = tip_diameter_in * IN / 2;
s = side_in * IN;
// The slope runs from the base edge to the tip edge, so it spans r - tip_r
h = side_is_slant ? sqrt(s*s - (r - tip_r)^2) : s;

assert(!side_is_slant || s > r - tip_r,
       "Slant side must be longer than the base radius");

echo(str("Cone: ", base_diameter_in, "\" base, ",
         h / IN, "\" tall (", h, " mm), slant ",
         sqrt(h*h + (r - tip_r)^2) / IN, "\", tip ", tip_diameter_in, "\""));

module cone_body(r0, r1, hh) cylinder(h = hh, r1 = r0, r2 = r1);

if (wall_mm <= 0) {
    cone_body(r, tip_r, h);
} else {
    // Offset the inside surface by wall_mm measured perpendicular to the slope
    // and leave a wall_mm thick roof under the flat tip
    slope = atan(h / (r - tip_r));    // side angle from the bed
    dr    = wall_mm / sin(slope);     // horizontal inset that gives that wall
    difference() {
        cone_body(r, tip_r, h);
        translate([0, 0, -0.01])
            intersection() {
                cone_body(r - dr, 0, (r - dr) * tan(slope) + 0.01);
                cylinder(h = h - wall_mm + 0.01, r = r);
            }
    }
}
