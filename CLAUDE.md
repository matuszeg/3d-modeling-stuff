# 3D modeling stuff

OpenSCAD models for printing on a Bambu Lab P2S (256 x 256 x 256 mm bed,
0.4 nozzle). PETG is filament 3 in the default project; PLA is 1 and 2.

## Working with the owner

- One question or one idea at a time, short messages. Talk a design through
  before building it; don't jump to a finished design.
- They like to see things: show a picture before asking them to decide.
- Every picture must be rendered from the real model file, not a separate
  sketch. If a part is only a test piece, say so and say how the real one
  differs.
- Before a big print, make a small test kit for the fits that matter, and
  adjust from what they report.
- Give honest filament estimates measured from the model, not guesses.

## Tooling

- `openscad` (install with apt if missing); render PNGs headless with
  `xvfb-run -a openscad -o out.png --imgsize=W,H --camera=... file.scad`.
- Look at every render before showing it; check framing, overlaps and that
  the part prints without supports in the orientation it's exported in.
- `tools/bambu_project.py`: writes Bambu Studio projects (.3mf) with
  multiple plates from STLs, carrying the P2S profiles and per-object
  settings such as brim. Use it for anything the owner will print.
- `tools/check_bambu_project.py out.3mf tools/bambu_templates/reference_p2s_project.3mf`:
  run on every generated project before handing it over.
- See `tools/bambu_templates/README.md` for how the format was worked out.

## Projects

- `cat-baluster-guard/`: a 2 ft wall on the loft side of the balusters to
  keep cats from squeezing through. See its README.
