// Simple cone, from Mom's sketch: 5" across the base, 3 1/2" side.
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
// Diameter of a small flat at the tip (0 = sharp point). A few mm prints cleaner
tip_flat_mm      = 2;

/* [Hidden] */
$fn = 180;
IN = 25.4;

r = base_diameter_in * IN / 2;
s = side_in * IN;
h = side_is_slant ? sqrt(s*s - r*r) : s;
tip_r = tip_flat_mm / 2;

assert(!side_is_slant || s > r,
       "Slant side must be longer than the base radius");

echo(str("Cone: ", base_diameter_in, "\" base, ",
         h / IN, "\" tall (", h, " mm), slant ",
         sqrt(h*h + r*r) / IN, "\""));

module cone_body(r0, r1, hh) cylinder(h = hh, r1 = r0, r2 = r1);

if (wall_mm <= 0) {
    cone_body(r, tip_r, h);
} else {
    // Offset the inside surface by wall_mm measured perpendicular to the slope
    slope = atan(h / r);              // side angle from the bed
    dr    = wall_mm / sin(slope);     // horizontal inset that gives that wall
    difference() {
        cone_body(r, tip_r, h);
        translate([0, 0, -0.01])
            cone_body(r - dr, 0, (r - dr) * tan(slope) + 0.01);
    }
}
