// Baby gate handle: a replacement for the D-shaped handle on the end bar of a
// roll-up mesh baby gate. The loop hooks into the clip on the wall.
//
// The collar is a split clamp: a slot runs down the front, with a clamp rib on
// either side of it. Two M3 screws go across the slot into nuts held in hex
// pockets; tightening them closes the slot and squeezes the bar all the way around.
//
// Install: drop an M3 nut into each hex pocket, slide the collar down over the top
// of the gate bar to where the wall clip is, put the screws in from the other side
// and tighten them evenly until it won't slide.
//
// Prints with NO supports: standing up, the way it sits on the gate. The bore is
// vertical, the top of the loop opening is a short bridge, and the hex pockets have
// a point at the top.
//
// Axes: Z = up along the gate bar, X = across the gate (the loop sticks out
// toward -X, the mesh goes off toward +X), Y = front to back.

// ---- Measured (mm) ----
bar_w     = 15.4;   // gate bar, the long way (same direction the loop sticks out)
bar_t     = 10.0;   // gate bar, front to back
collar_h  = 69;     // height of the collar
loop_h    = 66;     // loop, outside height
loop_in_h = 41.15;  // loop, inside height
gap_w     = 18.07;  // opening, from the collar face to the clip bar
clip_w    = 10.6;   // clip bar, the way the loop sticks out
clip_t    = 9.5;    // clip bar (and the arms), front to back

// ---- Fit ----
bar_clear = 0.3;    // bore is this much bigger than the bar each way (slides on loose,
                    // the clamp takes up the gap)
wall      = 2.5;    // collar wall around the bar

// ---- Clamp (M3 machine screws + nuts, 14-16 mm long) ----
slot_w    = 2.5;    // the split down the front; tightening can close it this much
rib_w     = 6;      // width of each clamp rib (the screw passes through both)
rib_out   = 9.5;    // how far the ribs stick out from the front of the collar
screw_zs  = [12, 57]; // screw heights above the bottom of the collar
screw_d   = 3.4;    // M3 clearance hole
nut_flats = 5.5 + 0.3; // M3 nut is 5.5 across flats; + clearance so it drops in
nut_depth = 3;      // pocket depth (the nut is 2.4 thick, so it sits a bit below the face)

// ---- Shape ----
collar_r  = 2;      // vertical corner rounding of the collar
loop_r_out = 6;     // outer corners of the loop
loop_r_in  = 2.5;   // inner corners of the opening on the clip-bar side
edge_r    = 1.2;    // rounding of the loop's edges (keeps the 10.6 x 9.5 size)
lead_in   = 0.8;    // chamfer at both ends of the bore so it starts onto the bar
// The loop sits flush with the bottom of the collar (3 mm of collar sticks up above
// it) so it prints on the bed. Centring it (1.5) would leave it floating and need
// supports under the bottom arm.
loop_lift = 0;

$fn = 64;
eps = 0.01;

col_w = bar_w + 2*bar_clear + 2*wall;
col_t = bar_t + 2*bar_clear + 2*wall;
bore_w = bar_w + 2*bar_clear;
bore_t = bar_t + 2*bar_clear;
loop_z0 = loop_lift;
arm_h = (loop_h - loop_in_h)/2;
reach = gap_w + clip_w;                     // collar face to the outside of the clip bar

module rrect(w, h, r) {                     // rounded rectangle, corner at origin
    translate([r, r]) offset(r) square([w - 2*r, h - 2*r]);
}

module stadium(w, t) {                      // the bar's cross-section, centred
    hull() for (s = [-1, 1]) translate([s*(w - t)/2, 0]) circle(d=t);
}

// Loop side profile in the X-Z plane (x measured from the collar face, going out).
module loop_profile() {
    difference() {
        // runs 3 mm into the collar so it's fused, square on the collar side
        translate([-3, 0]) union() {
            rrect(reach + 3, loop_h, loop_r_out);
            square([loop_r_out + 3, loop_h]);
        }
        translate([0, arm_h]) union() {
            translate([-3, 0]) rrect(gap_w + 3, loop_in_h, loop_r_in);
            translate([-3, 0]) square([loop_r_in + 3, loop_in_h]);
        }
    }
}

module loop() {
    // Shrink by edge_r, then grow back with a sphere: outside size stays exact.
    translate([-col_w/2, 0, loop_z0])
    rotate([90, 0, 0]) mirror([1, 0, 0])   // profile x -> world -X, profile y -> world Z
    minkowski() {
        translate([0, 0, -clip_t/2 + edge_r])
            linear_extrude(clip_t - 2*edge_r) offset(-edge_r) loop_profile();
        sphere(r=edge_r, $fn=32);
    }
}

module collar_body() {
    translate([0, 0, 0]) linear_extrude(collar_h)
        translate([-col_w/2, -col_t/2]) rrect(col_w, col_t, collar_r);
}

rib_x = slot_w/2 + rib_w;                   // outer faces of the clamp ribs (+/-)
screw_y = -(col_t/2 + rib_out/2 + 0.25);    // screw axis, front to back

module clamp_ribs() {
    // one block across the front; the slot splits it into two ribs
    linear_extrude(collar_h)
        translate([-rib_x, -(col_t/2 + rib_out)])
        rrect(2*rib_x, rib_out + col_t/2, 2);
}

module slot() {
    translate([-slot_w/2, -(col_t/2 + rib_out + 1), -eps])
        cube([slot_w, col_t/2 + rib_out + 1, collar_h + 2*eps]);
}

module clamp_holes() {
    for (z = screw_zs) translate([0, screw_y, z]) {
        // screw hole straight through both ribs
        rotate([0, 90, 0]) cylinder(d=screw_d, h=2*rib_x + 2, center=true, $fn=24);
        // hex nut pocket in the +X rib, point up so its top prints without support
        translate([rib_x - nut_depth, 0, 0]) rotate([0, 90, 0])
            cylinder(d=nut_flats/cos(30), h=nut_depth + 1, $fn=6);
    }
}

module bore() {
    translate([0, 0, -eps]) linear_extrude(collar_h + 2*eps) stadium(bore_w, bore_t);
    // lead-in chamfers
    for (z = [0, collar_h]) translate([0, 0, z])
        mirror([0, 0, z > 0 ? 1 : 0])
        translate([0, 0, -eps])
        linear_extrude(lead_in + eps, scale=[bore_w/(bore_w + 2*lead_in), bore_t/(bore_t + 2*lead_in)])
            stadium(bore_w + 2*lead_in, bore_t + 2*lead_in);
}

module handle() {
    difference() {
        union() {
            collar_body();
            loop();
            clamp_ribs();
        }
        bore();
        slot();
        clamp_holes();
    }
}

handle();
