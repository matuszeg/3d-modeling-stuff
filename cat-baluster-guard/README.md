# Loft Cat Wall

A 2 ft tall wall on the loft side of the balusters, so the cats can't squeeze
through the gaps. All renders below come from `loft_cat_wall.scad` itself.

![install guide](images/install_guide.png)
![how it connects](images/how_it_connects.png)

## How it works

- A slim I-beam **post** stands in front of every other baluster (13 posts).
  Each post is 3 sections of 203 mm that stack; a stub on the bottom of each
  section drops into a recess in the top of the one below.
- At the top of each post section is a **clamp block** with a V-notch in its
  back. A printed **U-bolt** goes around the back of the baluster and through
  the block, and two **nuts** pull it tight. The baluster is held between two
  V's, so it can't rock. The clamps are all on the round part of the baluster,
  never the square block.
- The nuts sit at the bottom of round pockets and get covered by snap-in
  **caps**, so the loft side is flat.
- Each **panel** spans two gaps. Its sides sit in the slots between the
  posts' front and back flanges, and its top corners are notched around the
  clamp blocks.
- Rows of panels lock together: a V-ridge along each panel's top edge fits a
  V-groove along the bottom edge of the panel above. So the panels come in
  three kinds: bottom row (ridge only), middle row (both), top row (groove
  only).

## Putting up one level

1. Stand the panels in place (on the oak for the first level, on the panels
   below after that).
2. Slide the post sections down from above so their slots go over the panel
   edges.
3. Put a U-bolt around the back of each baluster, through the clamp block, and
   tighten both nuts with the wrench.
4. Press in the caps. Repeat for the next level.

## Parts (whole wall, not counting the two ends)

| File | Count | Notes |
|---|---|---|
| `stl/post_0.stl` | 13 | bottom level |
| `stl/post_1.stl` | 13 | middle level |
| `stl/post_2.stl` | 13 | top level |
| `stl/panel_0.stl` | 12 | bottom row, 250 × 203 mm, prints flat, face down |
| `stl/panel_1.stl` | 12 | middle row |
| `stl/panel_2.stl` | 12 | top row |
| `stl/ubolt_0.stl` | 13 | arm length for the bottom level |
| `stl/ubolt_1.stl` | 13 | middle level |
| `stl/ubolt_2.stl` | 13 | top level |
| `stl/nut.stl` | 78 | |
| `stl/cap.stl` | 78 | |
| `stl/wrench.stl` | 1 | |

Roughly 6 kg of PETG in total (panels ~3.4, posts ~2, the rest ~0.6).

## Bambu Studio plates (`3mf/`)

`loft_cat_wall_all_plates.3mf` is a Bambu Studio project with all 12 plates.
It opens with the P2S, 0.20mm Standard and PETG (filament 3) selected, with
4 walls, 30% gyroid infill, no supports, and a brim on the U-bolts only.
The numbered files are the same plates one per project.

| # | Plate | Print it |
|---|---|---|
| 1 | One U-bolt of each level | first, and try them on the railing |
| 2 | Posts bottom ×13 | 1× |
| 3 | Posts middle ×13 | 1× |
| 4 | Posts top ×13 | 1× |
| 5 | Panel, bottom row | 12× |
| 6 | Panel, middle row | 12× |
| 7 | Panel, top row | 12× |
| 8 | U-bolts bottom ×13 | 1× |
| 9 | U-bolts middle ×13 | 1× |
| 10 | U-bolts top ×13 | 1× |
| 11 | Nuts ×78 and the wrench | 1× |
| 12 | Caps ×78 | 1× |

Rebuild them with `python3 cat-baluster-guard/make_3mf.py` (uses
`tools/bambu_project.py`).

## Print settings (Bambu P2S, PETG)

Already set in the 3MF projects:
- 0.2 mm layers, 4 walls, 30% gyroid infill, no supports
- Posts print with the clamp block on the bed, U-bolts stand on their arm
  ends with a brim, panels lie face down
- No brim on the panels: at 250 mm they only just fit the bed

## Still needed

- **Baluster thickness at the clamps.** The U-bolt arm lengths assume the
  baluster is 25, 22 and 19 mm thick at 7⅜", 15⅜" and 23⅜" above the oak.
  Measure those and set `clamp_d` before printing the U-bolts.
- **Oak depth.** The front of the wall sits 23.5 mm in front of the square
  blocks; the oak should stick out at least that far.
- End pieces for the wall (left) and the wooden post (right).

`stl/test_kit_v2/` holds the test kit that was printed and checked.
