// Condensate pump inlet grommet, v6: snaps into the lid hole and clamps the drain tube.
//
// Install: thread the tube's free end through the grommet (collet end first), push the
// snap fingers down through the lid hole until they click, slide the tube to depth,
// then tighten a mini stainless hose clamp (8 mm band) in the collet groove until the
// tube won't slide. A zip tie also works.
//
// Prints with NO supports: the STL comes out upside down, collet end on the bed.
// The top of the flange is a 45-degree cone so it builds without overhangs.

// Measured 2026-10-19
hole_d     = 34.6;  // lid hole diameter
tube_od    = 13.0;  // drain tube outside diameter (ID is 10)
sleeve_len = 12;    // drop sleeve below the lid; keep it clear of the float (0 = none)
motor_gap  = 0;     // gap between the hole's edge and the motor housing (0 = touching).
                    // Everything above the lid is shaved flat on that side (+X) to clear it.

// Fit tweaks
tube_clear = 0.4;   // bore is this much bigger than the tube; the clamp does the gripping
hole_clear = 0.4;   // fingers are this much smaller than the hole
// The lid thickness is unknown, so each finger has a row of ratchet teeth: whichever
// one clears the underside of the lid catches it. Covers a lid ~1 to ~4.3 mm thick.
tooth_tops = [1.4, 2.4, 3.4, 4.4];  // depth of each tooth's catch face below the lid top
tooth_lip  = 0.5;   // how far each tooth sticks out past the hole edge
ramp_h     = 6;     // lead-in ramp below the last tooth
finger_t   = 1.6;   // finger wall thickness
finger_n   = 8;     // narrow fingers bend far more easily than wide curved ones
finger_gap = 2.5;

// Shape
rim_t      = 1.6;   // flat edge of the flange before the cone starts
flange_d   = hole_d + 6;
collet_free = 16;   // collet length above the cone, where the hose clamp goes
collet_wall = 2.4;
collet_slits = 4;
slit_w     = 1.2;
ziptie_w   = 9;     // clamp groove: fits an 8 mm (5/16") mini hose clamp band
ziptie_d   = 0.6;
sleeve_wall = 1.6;
vent_d     = 3.5;
vent_n     = 4;

$fn = 120;
eps = 0.01;
bore      = tube_od + tube_clear;
collet_d  = bore + 2*collet_wall;
sleeve_d  = bore + 2*sleeve_wall;
cone_h    = (flange_d - collet_d)/2;
top_h     = rim_t + cone_h + collet_free;
finger_od = hole_d - hole_clear;
finger_id = finger_od - 2*finger_t;
finger_len = tooth_tops[len(tooth_tops)-1] + ramp_h;

// Built the way it sits in the pump: lid top at z=0, tank below.
module above_lid() {
    cylinder(d=flange_d, h=rim_t);
    translate([0,0,rim_t-eps]) cylinder(d1=flange_d, d2=collet_d, h=cone_h);
    difference() {
        cylinder(d=collet_d, h=top_h);
        translate([0,0,top_h - collet_free + (collet_free - ziptie_w)/2]) difference() {
            cylinder(d=collet_d+1, h=ziptie_w);
            translate([0,0,-eps]) cylinder(d=collet_d-2*ziptie_d, h=ziptie_w+2*eps);
        }
        for (i=[0:collet_slits-1]) rotate(i*360/collet_slits)
            translate([0,-slit_w/2,top_h - collet_free + 1]) cube([collet_d, slit_w, collet_free]);
    }
}

module fingers() {
    ro = finger_od/2;
    ri = finger_id/2;
    n  = len(tooth_tops);
    // (r, z) outline of one finger wall, lid top at z=0: straight down to the first
    // tooth, then sawtooth steps, then the lead-in ramp to the tip.
    profile = concat(
        [[ri, 0], [ro, 0]],
        [for (i=[0:n-1]) each [[ro, -tooth_tops[i]], [ro + tooth_lip, -tooth_tops[i]]]],
        [[ro - 0.2, -finger_len], [ri, -finger_len]]
    );
    difference() {
        rotate_extrude() polygon(profile);
        for (i=[0:finger_n-1]) rotate(i*360/finger_n)
            translate([0,-finger_gap/2,-finger_len-1]) cube([finger_od, finger_gap, finger_len+1-0.01]);
    }
    // fillet inside each finger root so it doesn't snap off at the flange
    translate([0,0,-2]) difference() {
        cylinder(d=finger_id+eps, h=2+eps);
        translate([0,0,-eps]) cylinder(d1=finger_id, d2=finger_id-4, h=2+3*eps);
        for (i=[0:finger_n-1]) rotate(i*360/finger_n)
            translate([0,-finger_gap/2,-1]) cube([finger_od, finger_gap, 4]);
    }
}

module grommet() {
    difference() {
        union() {
            above_lid();
            fingers();
            if (sleeve_len > 0) translate([0,0,-sleeve_len]) cylinder(d=sleeve_d, h=sleeve_len+eps);
        }
        translate([0,0,-100]) cylinder(d=bore, h=200);
        for (i=[0:vent_n-1]) rotate(i*360/vent_n)
            translate([(sleeve_d/2 + finger_id/2)/2, 0, -1]) cylinder(d=vent_d, h=top_h);
        // flat on the motor side, above the lid only
        translate([hole_d/2 + motor_gap - 0.5, -50, 0]) cube([100, 100, 100]);
    }
}

// Flip for printing: collet end down on the bed, fingers pointing up.
rotate([180,0,0]) grommet();
