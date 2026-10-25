import sys
out = sys.argv[1]
W, H = 1400, 1060
CLIP, ROD, WOOD, BAL, INK, RED, MUTED = "#f28c28", "#4a9be0", "#c8945a", "#ffffff", "#333", "#d6342c", "#777"
s = []
a = s.append
a(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" font-family="Helvetica, Arial, sans-serif">')
a('<defs>'
  f'<marker id="ah" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" fill="{INK}"/></marker>'
  f'<marker id="ahr" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" fill="{RED}"/></marker>'
  f'<marker id="ahg" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" fill="#2a8a3e"/></marker>'
  '</defs>')
a(f'<rect width="{W}" height="{H}" fill="#fafafa"/>')

def text(x, y, t, size=16, anchor="start", weight="normal", fill=INK):
    a(f'<text x="{x:.1f}" y="{y:.1f}" font-size="{size}" text-anchor="{anchor}" font-weight="{weight}" fill="{fill}">{t}</text>')

def lead(x1, y1, x2, y2):
    a(f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" stroke="{MUTED}" stroke-width="1.2"/>'
      f'<circle cx="{x2:.1f}" cy="{y2:.1f}" r="3" fill="{MUTED}"/>')

def rect(x, y, w, h, fill, stroke=INK, sw=1.2, extra=""):
    a(f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" {extra}/>')

# ------------------------------------------------------------ panel 1: front view
text(40, 50, "1. Seen from the loft (where you stand)", 22, weight="bold")
text(40, 76, "Not to scale. Orange = printed clips, blue = dowels you buy.", 15, fill=MUTED)

s1 = 0.78               # px per mm
fx, fy = 330, 950        # origin: center of railing, top of bottom rail
X = lambda x: fx + x * s1
Y = lambda y: fy - y * s1
pitch, blk, blk_h, turned, gap_h, rod_d = 120, 32, 110, 24, 760, 12.7
bals = [-180, -60, 60, 180]

rect(X(-235), Y(0), 470 * s1, 22 * s1, WOOD)                     # bottom rail
rect(X(-235), Y(gap_h + 50), 470 * s1, 50 * s1, WOOD)            # handrail
for b in bals:
    rect(X(b - turned / 2), Y(gap_h - blk_h), turned * s1, (gap_h - 2 * blk_h) * s1, BAL)
    rect(X(b - blk / 2), Y(blk_h), blk * s1, blk_h * s1, BAL)
    rect(X(b - blk / 2), Y(gap_h), blk * s1, blk_h * s1, BAL)
for g, gc in enumerate([-120, 0, 120]):
    for dx in (-20, 20):
        rect(X(gc + dx - rod_d / 2), Y(gap_h - 4), rod_d * s1, (gap_h - 4) * s1, ROD, stroke="#2d6ea8")
    stag = 22 if g == 1 else 0
    for z0 in (8 + stag, gap_h - blk_h + 30 + stag):
        rect(X(gc - pitch / 2 - 19), Y(z0 + 15), (pitch + 38) * s1, 15 * s1, CLIP, stroke="#a85a10", extra='rx="2"')

lx = X(240) + 20
def label(yv, t1, t2, tx, ty):
    text(lx + 8, Y(yv) + 5, t1, 16, weight="bold")
    if t2: text(lx + 8, Y(yv) + 24, t2, 14, fill=MUTED)
    lead(lx, Y(yv), tx, ty)
label(gap_h + 25, "Handrail", "", X(225), Y(gap_h + 25))
label(gap_h - 60, "Top clip", "snaps on the square blocks", X(150), Y(gap_h - blk_h + 52))
label(gap_h - 250, "2 dowels per gap", "1/2&quot; wood or clear acrylic", X(140), Y(gap_h - 250))
label(gap_h - 420, "Baluster (existing)", "nothing is drilled or glued", X(180 + turned / 2), Y(gap_h - 420))
label(190, "Middle gap's clips sit", "higher so clips never overlap", X(60), Y(42))
label(70, "Bottom clip", "sits right on the rail", X(150), Y(15))
label(-12, "Bottom rail", "dowels stand on it", X(225), Y(-10))

# ------------------------------------------------------------ panel 2: top view
ox = 760
text(ox, 50, "2. Looking straight down at one clip", 22, weight="bold")
text(ox, 76, "Cut through the bottom of one gap, roughly to scale.", 15, fill=MUTED)

s2 = 3.6
tx0, ty0 = ox + 300, 375
TX = lambda x: tx0 + x * s2
TY = lambda y: ty0 - y * s2          # +y = drop side, drawn upward

rect(ox, TY(60), 600, 0, "none", stroke="none")
a(f'<rect x="{ox}" y="{TY(78):.1f}" width="600" height="{40 * s2 * 0.0 + 46:.1f}" fill="#e9eef5"/>')
text(tx0, TY(78) + 28, "DROP SIDE &#8212; living room below", 16, "middle", "bold", "#4b5d73")
a(f'<rect x="{ox}" y="{TY(-46):.1f}" width="600" height="74" fill="#f3efe6"/>')
text(tx0, TY(-46) + 28, "LOFT SIDE &#8212; you (and the cats)", 16, "middle", "bold", "#7a6438")

c, wall, lip = 32.6, 2.6, 2.2
hi, ho, ow = c / 2, c / 2 + wall, c / 2 - lip
for Xb in (-60, 60):
    rect(TX(Xb - 16), TY(16), 32 * s2, 32 * s2, BAL, stroke=MUTED, sw=1.5)
    pts = [(-ho, -ho), (-ho, ho), (ho, ho), (ho, -ho), (ow, -ho), (ow, -hi), (hi, -hi), (hi, hi),
           (-hi, hi), (-hi, -hi), (-ow, -hi), (-ow, -ho)]
    d = " ".join(f"{'M' if i == 0 else 'L'}{TX(Xb + px):.1f},{TY(py):.1f}" for i, (px, py) in enumerate(pts)) + " Z"
    a(f'<path d="{d}" fill="{CLIP}" stroke="#a85a10" stroke-width="1.2" stroke-linejoin="round"/>')
rect(TX(-60 + hi), TY(10.65), (120 - 2 * hi) * s2, 4 * s2, CLIP, stroke="#a85a10")
for xr in (-20, 20):
    a(f'<circle cx="{TX(xr):.1f}" cy="{TY(0):.1f}" r="{7.95 * s2:.1f}" fill="none" stroke="{CLIP}" stroke-width="{wall * s2:.1f}"/>')
    rect(TX(xr - 5.08), TY(-3), 10.16 * s2, 8 * s2, "#fafafa", stroke="none")
    a(f'<circle cx="{TX(xr):.1f}" cy="{TY(0):.1f}" r="{6.35 * s2:.1f}" fill="{ROD}" stroke="#2d6ea8" stroke-width="1.2"/>')

# install arrows (from the loft side)
for xa in (-60, 60):
    a(f'<line x1="{TX(xa):.1f}" y1="{TY(-42):.1f}" x2="{TX(xa):.1f}" y2="{TY(-22):.1f}" stroke="{INK}" stroke-width="2.5" marker-end="url(#ah)"/>')
for xa in (-20, 20):
    a(f'<line x1="{TX(xa):.1f}" y1="{TY(-42):.1f}" x2="{TX(xa):.1f}" y2="{TY(-11):.1f}" stroke="#2d6ea8" stroke-width="2.5" marker-end="url(#ah)"/>')
text(TX(-60), TY(-46) + 56, "&#9312; push clip onto blocks", 14, "middle")
text(TX(60), TY(-46) + 56, "&#9312; push clip onto blocks", 14, "middle")
text(TX(0), TY(-46) + 56, "&#9313; press dowels in", 14, "middle", fill="#2d6ea8")

# labels
text(TX(-60), TY(-2), "baluster", 13, "middle", fill=MUTED)
text(TX(60), TY(-2), "baluster", 13, "middle", fill=MUTED)
text(TX(0), TY(12) - 10, "back wall of clip", 13, "middle", fill="#a85a10")
lead(TX(-60) - 40, TY(-30), TX(-60 - 14.1), TY(-17.6))
text(TX(-60) - 44, TY(-30) + 5, "small lips hook", 13, "end", fill="#a85a10")
text(TX(-60) - 44, TY(-30) + 21, "the corners", 13, "end", fill="#a85a10")

# ------------------------------------------------------------ panel 3: force
fy0 = 690
text(ox, fy0, "3. What happens when a cat pushes", 22, weight="bold")
by = fy0 + 40
a(f'<rect x="{ox}" y="{by}" width="600" height="320" fill="#fff" stroke="#ddd" rx="8"/>')
def bullet(y, color, head, lines):
    a(f'<circle cx="{ox + 26}" cy="{y - 5}" r="7" fill="{color}"/>')
    text(ox + 44, y, head, 16, weight="bold")
    for i, l in enumerate(lines):
        text(ox + 44, y + 22 + i * 20, l, 14.5, fill="#444")
bullet(by + 40, "#2a8a3e", "Pushing outward (toward the drop): solid", [
    "The dowel presses on the back wall of the clip, and the back wall",
    "presses on the back of the balusters. Plastic on wood, no snap",
    "involved. Same as how the balusters already hold a cat in."])
bullet(by + 140, "#e0a020", "Pulling inward (toward the loft): only the lips", [
    "Unlikely for a cat. If one ever pops off, the dowel falls",
    "onto the loft floor, not over the edge."])
bullet(by + 225, "#4a9be0", "Up and down", [
    "Dowels stand on the bottom rail, so they can't drop. Clips grip by",
    "friction; a dab of removable mounting tape keeps the top ones up."])

# force arrows on the top view
a(f'<line x1="{TX(20):.1f}" y1="{TY(-2):.1f}" x2="{TX(20):.1f}" y2="{TY(30):.1f}" stroke="{RED}" stroke-width="4" marker-end="url(#ahr)"/>')
text(TX(26), TY(30) + 2, "cat pushes", 14, fill=RED, weight="bold")
for xa in (-60, 60):
    a(f'<line x1="{TX(xa):.1f}" y1="{TY(34):.1f}" x2="{TX(xa):.1f}" y2="{TY(20):.1f}" stroke="#2a8a3e" stroke-width="4" marker-end="url(#ahg)"/>')
text(TX(-60), TY(34) - 6, "baluster pushes back", 13, "middle", fill="#2a8a3e", weight="bold")
text(TX(60), TY(34) - 6, "baluster pushes back", 13, "middle", fill="#2a8a3e", weight="bold")

a('</svg>')
open(out, "w").write("\n".join(s))
