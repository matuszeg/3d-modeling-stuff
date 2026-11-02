// Adjustable Clay Threader: one tool that cuts screw threads on a range of pot
// sizes, built like a 3-jaw lathe chuck.
//
//  - A BODY disc has 3 radial channels. A JAW slides in each one.
//  - Each jaw has a LEG hanging below the body with a comb of thread teeth on
//    both faces: inner face = DIE (cuts the outside thread on a pot's neck),
//    outer face = TAP (cuts the inside thread of a lid).
//  - A SCROLL disc sits on top. A spiral ridge on its underside runs in grooves
//    on the jaws, so turning the scroll moves all three jaws in or out together.
//  - A KNOB on the centre post clamps the scroll to lock the setting.
//
// Set the size with the rulers engraved on the underside (read at the leg:
// DIE scale at the leg's inner face, TAP scale at its outer face; both are
// labelled in NECK diameter, so set both to the same number for a matching pot
// and lid). Fine-tune with the dial ticks on the scroll (1 tick = 1 mm).
//
// Units: mm. Use Window > Customizer. F5 prints the ranges in the console.

/* [What to make] */
// Part to output. "assembly" is for looking at, not printing
part = "assembly"; // [assembly, exploded, body, scroll, knob, jaws, jaw1, jaw2, jaw3]
// small: about 18-83 mm necks on a 150 mm tool. large: about 60-183 mm on a 250 mm tool
tool = "small"; // [small, large, custom]
// custom only: tool diameter
custom_body_d = 200; // [100:5:256]
// custom only: smallest neck the die closes down to
custom_min_neck = 40; // [17:1:200]

/* [Thread the jaws cut] */
// Distance between thread teeth (each pitch needs its own set of jaws)
pitch = 4; // [2:0.25:8]
// Included V angle. 90 prints cleanly on the upright legs; 60 matches the fixed dies but the teeth may droop
flank_angle = 90; // [60:5:100]
// Tooth height. 0 = auto (as deep as the pitch allows, max 0.47 x pitch)
depth = 0; // [0:0.05:4]
// Flat at the tip of each tooth, as a fraction of pitch
crest_frac = 0.13; // [0.05:0.01:0.3]
// Full-depth teeth on each leg (how much thread length it can cut)
comb_teeth = 3; // [1:1:8]
// Shallower starter teeth at the bottom of each leg
lead_in_teeth = 2; // [0:1:4]
// Interleaved threads (lid travels starts x pitch per turn)
starts = 1; // [1:1:3]
left_hand = false;
// Radial gap between the pot's thread and the lid's at the same ruler setting (fired size)
clay_clearance = 0.5; // [0:0.05:3]

/* [Clay shrinkage] */
// Ruler labels and thread sizes are FIRED sizes; the tool is scaled up to cut the wet clay
account_for_shrinkage = false;
shrinkage_percent = 12; // [0:0.5:25]

/* [Mechanism] */
// Spiral pitch: how far the jaws move per turn of the scroll. 0 = auto (6 small, 8 large)
scroll_pitch = 0; // [0:0.5:12]
// Printing clearance between sliding parts. Raise if parts bind, lower if sloppy
fit = 0.35; // [0.15:0.05:0.6]
// Jaw position for the assembly view, as a fraction of the range
preview_open = 0.5; // [0:0.05:1]

/* [Printer] */
bed_size = 256;

/* [Hidden] */
$fn = 96;
eps = 0.01;
N = 3;                         // jaws

// ------------------------------------------------------------- tool size
body_d   = tool == "small" ? 150 : tool == "large" ? 250 : custom_body_d;
min_neck = tool == "small" ? 18  : tool == "large" ? 60  : custom_min_neck;
PS       = scroll_pitch > 0 ? scroll_pitch : (body_d < 200 ? 6 : 8);

// ------------------------------------------------------------- shrinkage + thread
k        = account_for_shrinkage ? 100 / (100 - shrinkage_percent) : 1;
P        = pitch * k;
half_a   = flank_angle / 2;
tanh_a   = tan(half_a);
crest_w  = crest_frac * P;
DEPTH    = depth > 0 ? depth * k : min(0.47 * P, (0.9 * P - crest_w) / (2 * tanh_a));
base_w   = crest_w + 2 * DEPTH * tanh_a;
CLAY_C   = clay_clearance * k;
LEAD     = P * starts;

// ------------------------------------------------------------- mechanism sizes
t        = 6;      // leg thickness between tooth roots (radial)
wl       = 8;      // leg width (tangential)
w_tip    = 3;      // width of the leg's toothed faces (narrow so curvature doesn't matter)
wc       = 14;     // jaw carriage width
Lc       = 26;     // jaw carriage length (radial)
Tf       = 4;      // body floor under the channels
hc       = 6;      // channel depth = carriage height below the body top
hr       = 2.5;    // spiral ridge height
g        = 0.6;    // vertical running gap
Ts       = 4;      // scroll plate thickness
wall_t   = 4;      // body outer wall
ledge    = 3;      // ledge the scroll rests on
ridge_w  = PS / 2 - 0.6;
Tb       = Tf + hc;            // body top
z_scroll = Tb + hr + g;        // scroll underside
H_top    = z_scroll + Ts;      // top of scroll and wall
R_o      = body_d / 2;
R_s      = R_o - wall_t - fit; // scroll radius
R_l      = R_o - wall_t - ledge;

post_r   = 5;      // centre post thread root
post_p   = 2;
post_dp  = 1;
boss_r   = 8;      // scroll bears on this around the post
knob_r   = body_d < 200 ? 15 : 20;
knob_h   = 10;

r_leg_min = min_neck / 2 + t / 2;
r_leg_max = R_l - fit - Lc + t / 2;
u0        = 3;     // first groove, from the carriage's inner end
rc_min    = r_leg_min - t / 2 + u0;          // innermost groove contact radius
rc_max    = r_leg_max - t / 2 + Lc;          // outermost

// legs: comb length below the body
n_teeth  = comb_teeth + lead_in_teeth;
Lcomb    = (n_teeth + 1) * P + 1;
xe       = t / 2 + DEPTH;                    // tooth tips from the leg centre

die_neck = function(r_leg) (2 * (r_leg - t / 2)) / k;                 // fired neck
tap_neck = function(r_leg) (2 * (r_leg + t / 2 + DEPTH - CLAY_C)) / k;

echo(str("\n=== Adjustable Clay Threader (", tool, ") ===",
  "\nTool: ", body_d, " mm across. Scroll: ", PS, " mm of jaw travel per turn = ", 2 * PS, " mm of diameter",
  "\nThread: pitch ", P, " mm, depth ", DEPTH, " mm, ", flank_angle, " deg, ", starts, " start(s)",
  "\nDIE cuts necks ", die_neck(r_leg_min), " to ", die_neck(r_leg_max), " mm", (k > 1 ? " (fired)" : ""),
  "\nTAP cuts lids for necks ", tap_neck(r_leg_min), " to ", tap_neck(r_leg_max), " mm",
  "\nThrow a lid opening at about neck - ", 2 * (DEPTH - CLAY_C) / k, " mm", (k > 1 ? " (fired)" : ""),
  "\nLegs reach ", Lcomb, " mm below the tool: max thread length per pass",
  "\n"));

assert(base_w < P, str("Teeth wider than the pitch: lower depth (", base_w, " >= ", P, ")"));
assert(body_d <= bed_size, "Tool is bigger than the bed");
assert(r_leg_max > r_leg_min + 5, "No adjustment range left: make the tool bigger or raise min neck");
assert(min_neck / 2 >= boss_r + fit + 0.5, "min neck too small for the centre post");

// ------------------------------------------------------------- helpers
function smooth(x) = x <= 0 ? 0 : x >= 1 ? 1 : x * x * (3 - 2 * x);

// one helical thread tooth (used for the centre post and knob)
module helix(r_root, dir, dp, p, turns, lead, z0, cw, ha, embed = 0.4) {
  segs = 72;
  n    = ceil(turns * segs);
  bw   = cw + 2 * dp * tan(ha);
  r_in = r_root - dir * embed;
  hw_in = bw / 2 + embed * tan(ha);
  pts = [for (i = [0:n]) let(
      tt = turns * i / n, a = 360 * tt, z = z0 + bw / 2 + p * tt,
      f  = lead <= 0 ? 1 : smooth(min(tt / lead, (turns - tt) / lead)),
      rc = r_root + dir * ((dp + 0.1) * f - 0.1),
      hc_ = cw / 2 + (1 - f) * dp * tan(ha),
      prof = [[r_in, z - hw_in], [rc, z - hc_], [rc, z + hc_], [r_in, z + hw_in]]
    ) each [for (q = prof) [q[0] * cos(a), q[0] * sin(a), q[1]]]];
  sides = [for (i = [0:n - 1]) for (j = [0:3]) let(a = 4 * i + j, b = 4 * i + (j + 1) % 4)
            each (dir < 0 ? [[a, b, b + 4], [a, b + 4, a + 4]] : [[a, a + 4, b + 4], [a, b + 4, b]])];
  caps  = dir < 0 ? [[3, 2, 1, 0], [4 * n, 4 * n + 1, 4 * n + 2, 4 * n + 3]]
                  : [[0, 1, 2, 3], [4 * n + 3, 4 * n + 2, 4 * n + 1, 4 * n]];
  polyhedron(pts, concat(sides, caps), convexity = 10);
}

module scallops(r, h, n, sr) {
  for (i = [0:n - 1]) rotate(360 * i / n + 180 / n)
    translate([r + sr * 0.55, 0, -1]) cylinder(r = sr, h = h + 2, $fn = 32);
}

// ------------------------------------------------------------- jaw
// Built in place: slot at angle 0, leg centre at radius r_leg.
// Jaw j (0..2) sits in slot j at 120 j degrees. The jaws differ: each one's
// grooves are shifted j/3 of a scroll turn and its teeth j/3 of a thread lead,
// so all three follow the same spiral and the same helix. They're numbered.
function tooth_phase(j) = let(o = (left_hand ? -1 : 1) * LEAD * j / N) o - P * floor(o / P);

module comb_profile(j) {
  ph = tooth_phase(j);
  z_first = -Lcomb + 0.5 + base_w / 2 + ph;
  zs = [for (n = [0:n_teeth + 1]) z_first + n * P];
  union() {
    translate([-t / 2, -Lcomb]) square([t, Lcomb + Tf + 1]);
    for (i = [0:len(zs) - 1]) let(z = zs[i],
        f = i < lead_in_teeth ? (i + 1) / (lead_in_teeth + 1) : 1,
        hc_ = crest_w / 2 + (1 - f) * DEPTH * tanh_a)
      if (z + base_w / 2 <= -1)
        for (s = [-1, 1]) polygon([
          [s * (t / 2 - 0.2), z - base_w / 2 - 0.2 * tanh_a],
          [s * (t / 2 + DEPTH * f), z - hc_],
          [s * (t / 2 + DEPTH * f), z + hc_],
          [s * (t / 2 - 0.2), z + base_w / 2 + 0.2 * tanh_a]]);
  }
}

module leg_footprint() {
  c = (wl - w_tip) / 2;
  polygon([[-xe, -w_tip / 2], [-xe + c, -wl / 2], [xe - c, -wl / 2], [xe, -w_tip / 2],
           [xe, w_tip / 2], [xe - c, wl / 2], [-xe + c, wl / 2], [-xe, w_tip / 2]]);
}

// grooves for the scroll ridge, in carriage coords (x = 0 at the carriage's inner end).
// Across the jaw's width the ridge both curves round the centre and creeps outward
// (it's a spiral). Both effects shrink as the radius grows, so each groove is the
// union of the real ridge shape at the smallest and largest radius it meets: the
// ridge then fits at every setting in between.
module ridge_patch(rr, w) {
  pm = asin(min(1, (wc / 2 + 1) / (rr - w)));
  n  = 24;
  arc = function(off) [for (i = [0:n]) let(ph = -pm + 2 * pm * i / n,
          r = rr + PS * ph / 360 + off) [r * cos(ph) - rr, r * sin(ph)]];
  polygon(concat(arc(w / 2), [for (q = [n:-1:0]) arc(-w / 2)[q]]));
}

module groove(u) {
  w = ridge_w + 2 * fit;
  for (rr = [rc_min, rc_max]) translate([u, 0]) ridge_patch(rr, w);
}

module jaw(j, r_leg) {
  x0 = r_leg - t / 2;                 // carriage inner end
  difference() {
    union() {
      // carriage
      translate([x0, -wc / 2, Tf]) cube([Lc, wc, hc + hr]);
      // leg with the tooth comb on both faces
      translate([r_leg, 0, 0]) intersection() {
        rotate([90, 0, 0]) linear_extrude(height = wl + 2, center = true) comb_profile(j);
        translate([0, 0, -Lcomb - 1]) linear_extrude(Lcomb + Tf + 2) leg_footprint();
      }
    }
    // spiral grooves on top, shifted j/3 pitch for jaw j
    translate([x0, 0, Tb]) linear_extrude(hr + 1) intersection() {
      union() for (n = [-1:ceil(Lc / PS) + 1]) groove(u0 + PS * (n + j / N));
      translate([0, -wc / 2 - 1]) square([Lc, wc + 2]);
    }
    // jaw number on the side
    translate([x0 + Lc * 0.6, wc / 2 - 0.6, Tf + 1.2]) rotate([90, 0, 180])
      linear_extrude(1) text(str(j + 1), size = 4.5, halign = "center", font = "Liberation Sans:style=Bold");
  }
}

// ------------------------------------------------------------- body
module ruler_marks() {
  step  = body_d < 200 ? 2 : 5;      // tick every 'step' mm of neck diameter
  label = body_d < 200 ? 10 : 20;
  so    = wl / 2 + fit;              // slot half width
  // DIE scale: ticks where the leg's inner face sits for each neck size
  for (D = [ceil(die_neck(r_leg_min) / step) * step : step : die_neck(r_leg_max)]) let(
      x = D * k / 2, long = D % label == 0)
    translate([x, 0]) {
      translate([-0.3, so + 0.6]) square([0.6, long ? 4 : 2.2]);
      if (long) translate([0, so + 5.2]) mirror([0, 1, 0]) rotate(90)
        text(str(D), size = 3.2, halign = "left", valign = "center", font = "Liberation Sans:style=Bold");
    }
  // TAP scale: ticks where the leg's outer face sits for each neck size
  for (D = [ceil(tap_neck(r_leg_min) / step) * step : step : tap_neck(r_leg_max)]) let(
      x = (D * k / 2) + CLAY_C - DEPTH, long = D % label == 0)
    translate([x, 0]) {
      translate([-0.3, -so - 0.6 - (long ? 4 : 2.2)]) square([0.6, long ? 4 : 2.2]);
      if (long) translate([0, -so - 5.2]) mirror([0, 1, 0]) rotate(90)
        text(str(D), size = 3.2, halign = "right", valign = "center", font = "Liberation Sans:style=Bold");
    }
  // scale names, just past the outer end of the slot
  translate([r_leg_max + xe + 4, so + 3]) mirror([0, 1, 0])
    text("DIE", size = 3.5, valign = "center", font = "Liberation Sans:style=Bold");
  translate([r_leg_max + xe + 4, -so - 3]) mirror([0, 1, 0])
    text("TAP", size = 3.5, valign = "center", font = "Liberation Sans:style=Bold");
}

module body() {
  slot_in  = r_leg_min - xe - fit;
  slot_out = r_leg_max + xe + fit;
  ch_in    = r_leg_min - t / 2 - fit;
  n_grip   = floor(2 * PI * R_o / 22);
  difference() {
    union() {
      cylinder(r = R_l, h = Tb);
      // outer wall with the ledge the scroll sits on
      difference() {
        cylinder(r = R_o, h = H_top, $fn = 240);
        translate([0, 0, z_scroll]) cylinder(r = R_s + fit, h = H_top, $fn = 240);
        translate([0, 0, -1]) cylinder(r = R_l - eps, h = z_scroll + 1, $fn = 240);
      }
      cylinder(r = boss_r, h = z_scroll);
      // centre post with the knob thread
      cylinder(r = post_r, h = H_top + knob_h - 0.5);
      helix(post_r, 1, post_dp, post_p, (H_top + knob_h - z_scroll - 3.5) / post_p - 0.5, 0.5,
            z_scroll + 0.5, 0.25, 30);
    }
    for (j = [0:N - 1]) rotate(360 * j / N) {
      // carriage channel
      translate([ch_in, -wc / 2 - fit, Tf]) cube([R_l - ch_in - eps, wc + 2 * fit, hc + 1]);
      // leg slot through the floor
      translate([slot_in, -wl / 2 - fit, -1]) cube([slot_out - slot_in, wl + 2 * fit, Tf + 2]);
      // slot number on the wall top
      translate([R_o - wall_t / 2 - 0.3, 0, H_top - 0.6]) linear_extrude(1)
        rotate(-90) text(str(j + 1), size = 3, halign = "center", valign = "center",
                         font = "Liberation Sans:style=Bold");
    }
    // dial index: a notch in the wall top, beside slot 1
    rotate(12) translate([R_s, 0, H_top - 1.2]) cylinder(r = 1.2, h = 2, $fn = 4);
    // rulers on the underside, along slot 1, readable when the tool is flipped over
    translate([0, 0, -1]) linear_extrude(1.6) ruler_marks();
    scallops(R_o, H_top, n_grip, 4);
  }
}

// ------------------------------------------------------------- scroll
// Archimedean spiral ridge: r = r_a + PS * angle / 360, on the underside.
module spiral_2d(r_a, r_b) {
  turns = (r_b - r_a) / PS;
  n = ceil(turns * 120);
  outer = [for (i = [0:n]) let(a = 360 * turns * i / n, r = r_a + PS * a / 360 + ridge_w / 2) [r * cos(a), r * sin(a)]];
  inner = [for (i = [n:-1:0]) let(a = 360 * turns * i / n, r = r_a + PS * a / 360 - ridge_w / 2) [r * cos(a), r * sin(a)]];
  polygon(concat(outer, inner));
}

module scroll() {
  r_a = boss_r + fit + ridge_w / 2 + 0.5;
  r_b = R_l - fit - ridge_w / 2;
  dimple_r = body_d < 200 ? 7 : 9;
  difference() {
    union() {
      translate([0, 0, z_scroll]) cylinder(r = R_s, h = Ts, $fn = 240);
      translate([0, 0, Tb + g]) linear_extrude(hr + eps) intersection() {
        spiral_2d(r_a, r_b);
        circle(r = R_l - fit, $fn = 240);
      }
    }
    translate([0, 0, -1]) cylinder(r = post_r + post_dp + fit + 0.2, h = H_top + 2);
    // finger dimples for turning it
    for (i = [0:2]) rotate(120 * i + 60)
      translate([R_s * 0.62, 0, H_top + dimple_r * 1.2 - 2]) sphere(r = dimple_r * 1.2);   // 2 mm deep
    // dial: one tick per mm of neck diameter (2 x PS ticks per turn)
    for (i = [0:2 * PS - 1]) rotate(360 * i / (2 * PS))
      translate([R_s - (i % 5 == 0 ? 6 : 3.5), -0.4, H_top - 0.6]) cube([i % 5 == 0 ? 5 : 2.5, 0.8, 1]);
    // which way is open: turning the scroll clockwise (from above) opens the jaws
    rotate(-30) translate([R_s - 11, 0, H_top - 0.6]) linear_extrude(1) rotate(90)
      text("CW = OPEN", size = 3.2, halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
  }
}

// scroll rotation that lines the spiral up with jaws at r_leg (for the assembly view)
function scroll_angle(r_leg) = let(
  r_a = boss_r + fit + ridge_w / 2 + 0.5,
  target = r_leg - t / 2 + u0)           // centre of jaw 1's first groove
  360 * (r_a - target) / PS;

// ------------------------------------------------------------- knob
module knob() {
  r_root = post_r + post_dp + fit;     // internal thread root
  difference() {
    cylinder(r = knob_r, h = knob_h);
    translate([0, 0, -1]) cylinder(r = r_root - post_dp, h = knob_h + 2);
    scallops(knob_r, knob_h, 10, 3);
    translate([0, 0, knob_h - 0.8]) cylinder(r1 = r_root - post_dp, r2 = r_root - post_dp + 1, h = 1);
  }
  intersection() {
    helix(r_root, -1, post_dp, post_p, knob_h / post_p, 0.5, -post_p, 0.25, 30);
    cylinder(r = r_root + 0.4, h = knob_h);
  }
}

// ------------------------------------------------------------- output
r_prev = r_leg_min + preview_open * (r_leg_max - r_leg_min);

module jaw_for_print(j) {
  // grooved top on the bed, leg pointing up
  rotate([180, 0, 0]) translate([-(r_leg_min - t / 2), 0, -(Tb + hr)]) jaw(j, r_leg_min);
}

if (part == "assembly") {
  color("BurlyWood") body();
  for (j = [0:N - 1]) rotate(360 * j / N) color("Peru") jaw(j, r_prev);
  // the spiral needs a matching rotation for the jaws' position
  color("Tan", 0.9) rotate(scroll_angle(r_prev)) scroll();
  color("SaddleBrown") translate([0, 0, H_top + 0.5]) knob();
} else if (part == "exploded") {
  e = body_d * 0.12;
  color("BurlyWood") body();
  for (j = [0:N - 1]) rotate(360 * j / N) color("Peru") translate([0, 0, e]) jaw(j, r_prev);
  color("Tan") translate([0, 0, 2.6 * e]) rotate(scroll_angle(r_prev)) scroll();
  color("SaddleBrown") translate([0, 0, H_top + 3.6 * e]) knob();
} else if (part == "body") body();
else if (part == "scroll") translate([0, 0, H_top]) rotate([180, 0, 0]) scroll();
else if (part == "knob") knob();
else if (part == "jaws") for (j = [0:N - 1]) translate([0, j * (wc + 6), 0]) jaw_for_print(j);
else if (part == "jaw1") jaw_for_print(0);
else if (part == "jaw2") jaw_for_print(1);
else if (part == "jaw3") jaw_for_print(2);
