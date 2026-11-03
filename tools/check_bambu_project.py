#!/usr/bin/env python3
"""Sanity-check a Bambu Studio project (.3mf) before handing it over.

    python3 tools/check_bambu_project.py project.3mf [reference.3mf]

Checks that every XML part parses, every component points at a mesh file that
exists and is listed in the relationships, every mesh is closed, every build
item is on a plate in model_settings.config and lies inside that plate's bed,
and the settings JSON loads. With a reference project saved by Bambu Studio,
it also lists files and model_settings.config keys the reference has that the
project doesn't (thumbnails excepted).
"""
import json
import re
import sys
import zipfile
import xml.etree.ElementTree as ET
from collections import Counter

NS = "{http://schemas.microsoft.com/3dmanufacturing/core/2015/02}"
P = "{http://schemas.microsoft.com/3dmanufacturing/production/2015/06}"


def check(path, reference=None):
    z = zipfile.ZipFile(path)
    names = set(z.namelist())
    problems = []
    required = ["[Content_Types].xml", "_rels/.rels", "3D/3dmodel.model", "3D/_rels/3dmodel.model.rels",
                "Metadata/model_settings.config", "Metadata/project_settings.config"]
    missing = [n for n in required if n not in names]
    if missing:
        print(f"{path}:")
        for n in missing:
            print(f"  PROBLEM: missing {n} (Bambu Studio will only load the geometry)")
        return False
    for n in names:
        if n.endswith((".model", ".config", ".rels", ".xml")) and n != "Metadata/project_settings.config":
            ET.fromstring(z.read(n))
    settings = json.loads(z.read("Metadata/project_settings.config"))
    bed = [tuple(float(v) for v in p.split("x")) for p in settings["printable_area"]]
    bw, bd = max(p[0] for p in bed), max(p[1] for p in bed)

    rels = ET.fromstring(z.read("3D/_rels/3dmodel.model.rels"))
    rel_targets = {r.get("Target").lstrip("/") for r in rels}
    root = ET.fromstring(z.read("3D/3dmodel.model"))
    app = [m.text for m in root.findall(NS + "metadata") if m.get("name") == "Application"]
    if not app or not app[0].startswith("BambuStudio-"):
        problems.append("Application metadata isn't BambuStudio-...")

    extents = {}
    for obj in root.find(NS + "resources"):
        comp = obj.find(NS + "components")[0]
        target = comp.get(P + "path").lstrip("/")
        if target not in names:
            problems.append(f"object {obj.get('id')}: missing {target}")
            continue
        if target not in rel_targets:
            problems.append(f"{target} not in 3D/_rels/3dmodel.model.rels")
        mesh = ET.fromstring(z.read(target))
        vs = [(float(v.get("x")), float(v.get("y")), float(v.get("z"))) for v in mesh.iter(NS + "vertex")]
        edges = Counter()
        for t in mesh.iter(NS + "triangle"):
            a, b, c = (int(t.get(k)) for k in ("v1", "v2", "v3"))
            for e in ((a, b), (b, c), (c, a)):
                edges[tuple(sorted(e))] += 1
        open_edges = sum(1 for v in edges.values() if v != 2)
        if open_edges:
            problems.append(f"object {obj.get('id')} ({target}): {open_edges} open edges")
        xs, ys, zs = zip(*vs)
        extents[obj.get("id")] = (min(xs), max(xs), min(ys), max(ys), min(zs))

    cfg = ET.fromstring(z.read("Metadata/model_settings.config"))
    plates = cfg.findall("plate")
    on_plate = {}
    for i, plate in enumerate(plates):
        for mi in plate.findall("model_instance"):
            md = {m.get("key"): m.get("value") for m in mi.findall("metadata")}
            on_plate[(md["object_id"], int(md["instance_id"]))] = i
    s = len(plates) ** 0.5
    cols = round(s) + 1 if s > round(s) else round(s)

    seen = Counter()
    for item in root.find(NS + "build"):
        oid = item.get("objectid")
        k = seen[oid]
        seen[oid] += 1
        if (oid, k) not in on_plate:
            problems.append(f"object {oid} instance {k} isn't on any plate")
            continue
        i = on_plate[(oid, k)]
        ox, oy = (i % cols) * bw * 1.2, -(i // cols) * bd * 1.2
        t = [float(v) for v in item.get("transform").split()]
        x0, x1, y0, y1, z0 = extents[oid]
        if not (ox - 0.01 <= t[9] + x0 and t[9] + x1 <= ox + bw + 0.01 and oy - 0.01 <= t[10] + y0 and t[10] + y1 <= oy + bd + 0.01):
            problems.append(f"object {oid} instance {k} is off plate {i + 1}")
        if abs(t[11] + z0) > 0.01:
            problems.append(f"object {oid} instance {k} isn't sitting on the bed (z {t[11] + z0:.3f})")
    if len(on_plate) != sum(seen.values()):
        problems.append(f"{len(on_plate)} plate instances but {sum(seen.values())} build items")

    if reference:
        r = zipfile.ZipFile(reference)
        thumb = re.compile(r"Metadata/(plate|top|pick|plate_no_light)_?\w*\.(png|json)$")
        for n in sorted(set(r.namelist()) - names):
            if not thumb.match(n) and not n.startswith("3D/Objects/"):
                problems.append(f"reference has {n}, project doesn't")
        rcfg = ET.fromstring(r.read("Metadata/model_settings.config"))
        keys = lambda c, tag: {m.get("key") for e in c.iter(tag) for m in e.findall("metadata") if m.get("key")}
        for tag in ("object", "part", "plate"):
            missing = keys(rcfg, tag) - keys(cfg, tag) - {"thumbnail_file", "thumbnail_no_light_file", "top_file",
                                                          "pick_file", "filament_maps", "filament_volume_maps"}
            if missing:
                problems.append(f"<{tag}> metadata keys in the reference but not the project: {sorted(missing)}")

    print(f"{path}: {len(plates)} plates, {sum(seen.values())} parts, {len(extents)} objects")
    for p in problems:
        print("  PROBLEM:", p)
    if not problems:
        print("  ok")
    return not problems


if __name__ == "__main__":
    if len(sys.argv) not in (2, 3):
        sys.exit(__doc__)
    sys.exit(0 if check(*sys.argv[1:]) else 1)
