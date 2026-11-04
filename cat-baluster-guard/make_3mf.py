#!/usr/bin/env python3
"""Build the Bambu Studio projects for the loft cat wall from the STLs.

    python3 cat-baluster-guard/make_3mf.py

writes cat-baluster-guard/3mf/loft_cat_wall_all_plates.3mf (every plate in one
project) and one project per plate next to it.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "tools"))
from bambu_project import footprint, grid, write_project  # noqa: E402

STL = os.path.join(HERE, "stl")
OUT = os.path.join(HERE, "3mf")
BED = 256.0
LEVELS = ["bottom", "middle", "top"]
P = lambda n: os.path.join(STL, n + ".stl")

# print settings on top of the 0.20mm Standard P2S profile
SETTINGS = {
    "wall_loops": "4",
    "sparse_infill_density": "30%",
    "sparse_infill_pattern": "gyroid",
    "enable_support": "0",
    "brim_type": "no_brim",       # the panels fill the bed; the U-bolts get their own brim
}
UBOLT = {"brim_type": "outer_only"}
PETG_SLOT = 3                     # Generic PETG is filament 3 in the P2S project


def plates():
    out = []
    uw, _ = footprint(P("ubolt_0"))
    out.append({"name": "Try one U-bolt of each", "objects": [
        {"stl": P(f"ubolt_{i}"), "name": f"ubolt_{lv}", "settings": UBOLT,
         "positions": [(BED / 2 + (i - 1) * (uw + 15), BED / 2)]} for i, lv in enumerate(LEVELS)]})
    for i, lv in enumerate(LEVELS):
        w, d = footprint(P(f"post_{i}"))
        out.append({"name": f"Posts {lv} x13", "objects": [
            {"stl": P(f"post_{i}"), "name": f"post_{lv}", "positions": grid(13, w, d, 10)}]})
    for i, lv in enumerate(LEVELS):
        out.append({"name": f"Panel {lv} row (print 12 times)", "objects": [
            {"stl": P(f"panel_{i}"), "name": f"panel_{lv}", "positions": [(BED / 2, BED / 2)]}]})
    for i, lv in enumerate(LEVELS):
        w, d = footprint(P(f"ubolt_{i}"))
        out.append({"name": f"U-bolts {lv} x13", "objects": [
            {"stl": P(f"ubolt_{i}"), "name": f"ubolt_{lv}", "settings": UBOLT, "positions": grid(13, w, d, 12)}]})
    nw, nd = footprint(P("nut"))
    ww, wd = footprint(P("wrench"))
    nuts = [(x, y + 25) for x, y in grid(78, nw, nd, 2.5, cols=13)]
    out.append({"name": "Nuts x78 and wrench", "objects": [
        {"stl": P("nut"), "name": "nut", "positions": nuts},
        {"stl": P("wrench"), "name": "wrench", "positions": [(BED / 2, min(y for _, y in nuts) - nd / 2 - 8 - wd / 2)]}]})
    cw, cd = footprint(P("cap"))
    out.append({"name": "Caps x78", "objects": [
        {"stl": P("cap"), "name": "cap", "positions": grid(78, cw, cd, 2, cols=9)}]})
    return out


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for f in os.listdir(OUT):
        if f.endswith(".3mf"):
            os.remove(os.path.join(OUT, f))
    pl = plates()
    write_project(os.path.join(OUT, "loft_cat_wall_all_plates.3mf"), pl, SETTINGS, PETG_SLOT, title="Loft Cat Wall")
    for i, p in enumerate(pl):
        slug = p["name"].lower().replace(" (print 12 times)", "_print_12x").replace(" ", "_").replace("-", "")
        write_project(os.path.join(OUT, f"{i + 1:02d}_{slug}.3mf"), [p], SETTINGS, PETG_SLOT, title=p["name"])
    print("wrote", len(pl), "plates")
