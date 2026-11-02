// Clay Threader: a parametric die (and matching tap) for cutting screw threads
// into leather-hard clay, so a pot and its lid screw together after firing.
//
//  DIE: a ring with the thread on the inside. Throw the pot's neck to the
//       "throw the neck at" size echoed in the console, let it firm up to leather
//       hard, then twist the die down over the neck. The tapered start pulls it
//       on straight and the teeth cut the outside (male) thread.
//  TAP: a threaded plug with a grip flange. Throw the lid's opening to the
//       "throw the lid opening at" size, then screw the tap into it to cut the
//       inside (female) thread. It uses the same pitch as the die plus some clearance.
//
// All sizes are in mm. Open in OpenSCAD and use Window > Customizer, or edit the
// values below. The console (F5/F6) echoes the clay sizes to throw at.

/* [What to make] */
// Which part(s) to output
part = "die"; // [die, tap, both]

/* [Size] */
// Outside diameter of the threaded neck you want. This is the die's bore (thread root).
neck_d = 27.8; // [10:0.1:240]

/* [Clay shrinkage] */
// Tick if neck_d is the size you want AFTER firing. The thread is scaled up so the clay shrinks to size.
account_for_shrinkage = false;
// Total shrinkage of your clay body, wet to final firing, in percent (check the bag or test a tile)
shrinkage_percent = 12; // [0:0.5:25]

/* [Thread] */
// Distance between neighbouring teeth. 0 = auto: 2.7 mm on the original, grows with diameter, capped at 6
pitch = 2.7; // [0:0.1:10]
// How far each tooth cuts into the clay. 0 = auto (0.47 x pitch, like the original)
depth = 0; // [0:0.05:5]
// Included angle of the V tooth. 60 is standard; bigger is blunter and easier on soft clay
flank_angle = 60; // [40:5:90]
// Width of the flat at the tip of each tooth, as a fraction of pitch
crest_frac = 0.13; // [0.05:0.01:0.3]
// Full-depth turns of thread (how far the lid turns to close). Original rings: 0.25 = 6 mm tall, 1 = 8 mm, 2 = 11 mm
turns = 1; // [0.25:0.25:6]
// Turns at each end where the tooth ramps from nothing up to full depth
lead_in_turns = 0.5; // [0:0.25:2]
// Separate interleaved threads. 2-3 starts make the lid travel further per turn, so use fewer turns with them
starts = 1; // [1:1:4]
// Right-hand closes clockwise, like a normal jar
left_hand = false;

/* [Fit] */
// Gap between the pot's thread and the lid's thread (radial, at final size). More = looser, glaze-friendly
clay_clearance = 0.5; // [0:0.05:3]

/* [Tool body] */
// Ring wall outside the thread root. 0 = auto (3.6 mm on the original, thicker on big rings)
wall = 0; // [0:0.5:30]
// Finger scallops around the outside. -1 = auto (only when the wall is thick enough), 0 = none
grips = -1; // [-1:1:60]
// Tap: how far the grip flange sticks out past the thread crests
tap_flange = 6; // [3:0.5:30]
// Tap: flange thickness
tap_flange_t = 3; // [2:0.5:10]

/* [Printer] */
// Largest part that fits on your bed (square bed side)
bed_size = 256;

/* [Hidden] */
eps = 0.01;
embed = 0.4;            // how far each tooth's root sinks into the ring so they fuse
end_margin = 0.6;       // plain band at each face of the ring, beyond the thread
chamfer = 1.0;          // 45-degree chamfers on edges and bore entries
$fn = 96;

// ---------------------------------------------------------------- derived sizes
k = account_for_shrinkage ? 100 / (100 - shrinkage_percent) : 1;   // fired -> wet

D_tool   = neck_d * k;                       // die bore = wet neck size
auto_p   = min(6, max(2.7, D_tool * 0.097)); // 0.097 x D matches the original (2.7 / 27.8)
P        = (pitch > 0 ? pitch * k : auto_p);
DEPTH    = (depth > 0 ? depth * k : 0.47 * P);
CLEAR    = clay_clearance * k;
half_a   = flank_angle / 2;
tanh_a   = tan(half_a);
crest_w  = crest_frac * P;
base_w   = crest_w + 2 * DEPTH * tanh_a;     // tooth width at its root
LEAD     = P * starts;                       // rise per revolution of one start
T_TOTAL  = turns + 2 * lead_in_turns;        // revolutions of each start
THREAD_H = LEAD * T_TOTAL + base_w;     // every start spans the same height
H        = THREAD_H + 2 * end_margin;        // ring height

WALL     = wall > 0 ? wall : max(3.6, 0.06 * D_tool);  // 3.6 = the original, 35 mm ring

// die
die_root_r  = D_tool / 2;
die_crest_r = die_root_r - DEPTH;
die_out_r   = die_root_r + WALL;

// tap: cuts a lid thread that clears the neck thread by CLEAR all round
tap_crest_r = die_root_r + CLEAR;
tap_root_r  = die_crest_r + CLEAR;
tap_wall    = max(3, 0.6 * WALL);
tap_in_r    = tap_root_r - tap_wall;
tap_out_r   = tap_crest_r + tap_flange;

fired = function(x) x / k;

echo(str("\n=== Clay Threader ===",
  "\nScale for shrinkage: x", k, (account_for_shrinkage ? str(" (", shrinkage_percent, "%)") : " (off)"),
  "\nPitch ", P, " mm, depth ", DEPTH, " mm, ", starts, " start(s), lead ", LEAD, " mm/turn",
  "\nThrow the NECK at:         ", D_tool, " mm outside diameter (wet). Fired: ~", fired(D_tool),
  "\nThrow the LID OPENING at:  ", 2 * tap_root_r, " mm inside diameter (wet). Fired: ~", fired(2 * tap_root_r),
  "\nDie: ", 2 * die_out_r, " mm across, ", H, " mm tall",
  "\nTap: ", 2 * tap_out_r, " mm across, ", H + tap_flange_t, " mm tall",
  "\n"));

assert(base_w < P, str("Teeth are wider than the pitch: lower depth or flank_angle (base ", base_w, " >= pitch ", P, ")"));
assert(tap_in_r > 2, "Neck is too small for a tap at this thread depth");
assert(part == "tap" || 2 * die_out_r <= bed_size,
       str("Die is ", 2 * die_out_r, " mm across, bigger than the ", bed_size, " mm bed. Lower neck_d or wall."));
assert(part == "die" || 2 * tap_out_r <= bed_size,
       str("Tap is ", 2 * tap_out_r, " mm across, bigger than the ", bed_size, " mm bed. Lower neck_d or tap_flange."));

// ---------------------------------------------------------------- thread
// One helical tooth as a polyhedron. dir = -1 points the teeth inward (die),
// +1 outward (tap). The tooth ramps in and out over lead_in_turns, keeping its
// flank angle, so the first cut is shallow.
function smooth(x) = x <= 0 ? 0 : x >= 1 ? 1 : x * x * (3 - 2 * x);
function taper(t) = lead_in_turns <= 0 ? 1
  : smooth(min(t / lead_in_turns, (T_TOTAL - t) / lead_in_turns));

module helix_tooth(r_root, dir, z0) {
  segs  = max(72, ceil(PI * 2 * r_root / 1.2));   // ~1.2 mm chords
  n     = ceil(T_TOTAL * segs);
  r_in  = r_root - dir * embed;                    // buried end of the tooth
  hw_in = base_w / 2 + embed * tanh_a;
  pts = [for (i = [0:n]) let(
      t  = T_TOTAL * i / n,
      a  = 360 * t,
      z  = z0 + LEAD * t,
      f  = taper(t),
      rc = r_root + dir * ((DEPTH + 0.1) * f - 0.1),   // ends sink 0.1 below the surface
      hc = crest_w / 2 + (1 - f) * DEPTH * tanh_a,
      prof = [[r_in, z - hw_in], [rc, z - hc], [rc, z + hc], [r_in, z + hw_in]]
    ) each [for (p = prof) [p[0] * cos(a), p[0] * sin(a), p[1]]]];
  // dir decides which way round the profile goes, so flip the winding with it
  sides = [for (i = [0:n - 1]) for (j = [0:3]) let(a = 4 * i + j, b = 4 * i + (j + 1) % 4)
            each (dir < 0 ? [[a, b, b + 4], [a, b + 4, a + 4]]
                          : [[a, a + 4, b + 4], [a, b + 4, b]])];  // triangles: the quads twist
  caps  = dir < 0 ? [[3, 2, 1, 0], [4 * n, 4 * n + 1, 4 * n + 2, 4 * n + 3]]
                  : [[0, 1, 2, 3], [4 * n + 3, 4 * n + 2, 4 * n + 1, 4 * n]];
  polyhedron(pts, concat(sides, caps), convexity = 10);
}

module thread(r_root, dir, z_bottom) {
  mirror([left_hand ? 1 : 0, 0, 0])
    for (s = [0:starts - 1])
      rotate(360 * s / starts + 0.5)   // off the body's mesh seam
        helix_tooth(r_root, dir, z_bottom + base_w / 2);
}

// ---------------------------------------------------------------- grips
function grip_count(r_out) =
  grips >= 0 ? grips : (WALL >= 5 ? max(6, floor(2 * PI * r_out / 22)) : 0);

module grip_cuts(r_out, h, wall_t) {
  n  = grip_count(r_out);
  gr = min(8, 0.9 * wall_t);              // scallop radius
  if (n > 0)
    for (i = [0:n - 1]) rotate(360 * i / n)
      translate([r_out + gr * 0.55, 0, -1]) cylinder(r = gr, h = h + 2, $fn = 40);
}

// ---------------------------------------------------------------- parts
module die() {
  difference() {
    union() {
      difference() {
        rotate_extrude($fn = 180) polygon([
          [die_root_r, 0], [die_out_r - chamfer, 0], [die_out_r, chamfer],
          [die_out_r, H - chamfer], [die_out_r - chamfer, H], [die_root_r, H]]);
        grip_cuts(die_out_r, H, WALL);
      }
      intersection() {
        thread(die_root_r, -1, end_margin);
        cylinder(r = die_root_r + embed, h = H, $fn = 180);
      }
    }
    // entry chamfers on the bore, top and bottom, so the die starts square
    for (z = [0, H]) translate([0, 0, z]) mirror([0, 0, z > 0 ? 1 : 0])
      translate([0, 0, -eps])
        cylinder(r1 = die_root_r + chamfer, r2 = die_crest_r - eps, h = chamfer + DEPTH + eps, $fn = 180);
  }
}

module tap() {
  ft = tap_flange_t;
  difference() {
    union() {
      // grip flange on the bed, threaded barrel rising from it
      difference() {
        rotate_extrude($fn = 180) polygon([
          [tap_in_r, 0], [tap_out_r - chamfer, 0], [tap_out_r, chamfer],
          [tap_out_r, ft], [tap_in_r, ft]]);
        grip_cuts(tap_out_r, ft, tap_flange);
      }
      rotate_extrude($fn = 180) polygon([
        [tap_in_r, ft - eps], [tap_root_r, ft - eps],
        [tap_root_r, ft + H - chamfer], [tap_root_r - chamfer, ft + H], [tap_in_r, ft + H]]);
      intersection() {
        thread(tap_root_r, 1, ft + end_margin);
        translate([0, 0, ft]) cylinder(r = tap_crest_r + 1, h = H, $fn = 180);
      }
    }
    // lead chamfer on the free end so the tap starts square in the lid
    translate([0, 0, ft + H + eps]) mirror([0, 0, 1])
      difference() {
        cylinder(r = tap_crest_r + 2, h = chamfer + DEPTH + eps, $fn = 180);
        cylinder(r1 = tap_root_r - chamfer, r2 = tap_crest_r + eps, h = chamfer + DEPTH + eps, $fn = 180);
      }
  }
}

if (part == "die") die();
else if (part == "tap") tap();
else {
  gap = 8;
  total = 2 * die_out_r + gap + 2 * tap_out_r;
  if (total > bed_size)
    echo(str("WARNING: die + tap side by side are ", total, " mm, wider than the bed. Print them separately."));
  translate([-(total / 2) + die_out_r, 0, 0]) die();
  translate([(total / 2) - tap_out_r, 0, 0]) tap();
}
