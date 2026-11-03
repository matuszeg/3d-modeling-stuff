#!/usr/bin/env python3
"""Write a Bambu Studio project (.3mf) with several plates from STL files.

The file layout copies what Bambu Studio itself saves (see
bambu_templates/README.md), including a project_settings.config taken from a
real project, so the printer, process and filament profiles come along.

Use it from Python:

    from bambu_project import write_project
    write_project("out.3mf", [
        {"name": "posts", "objects": [
            {"stl": "post.stl", "name": "post", "positions": [(60, 60), (120, 60)],
             "settings": {"brim_type": "outer_only"}},
        ]},
    ], settings={"wall_loops": "4"}, filament=3)

or from the command line with a JSON file of the same shape:

    python3 tools/bambu_project.py plates.json out.3mf

Positions are where each part's footprint center goes on the plate, in mm
from the front-left corner of the bed. Parts are placed as they are in the
STL (no rotation) with their lowest point on the bed.
"""
import json
import os
import struct
import sys
import uuid
import zipfile
from datetime import date

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_TEMPLATE = os.path.join(HERE, "bambu_templates", "p2s_project_settings.config")

# ---------------------------------------------------------------- meshes

def load_stl(path):
    """Return (vertices, triangles) with shared vertices merged."""
    with open(path, "rb") as f:
        data = f.read()
    tris_raw = []
    if data[:5] == b"solid" and b"facet" in data[:400]:
        cur = []
        for line in data.decode("ascii", "replace").splitlines():
            s = line.split()
            if s and s[0] == "vertex":
                cur.append(tuple(float(x) for x in s[1:4]))
                if len(cur) == 3:
                    tris_raw.append(cur)
                    cur = []
    else:
        n = struct.unpack_from("<I", data, 80)[0]
        for i in range(n):
            vals = struct.unpack_from("<12f", data, 84 + i * 50)
            tris_raw.append([vals[3:6], vals[6:9], vals[9:12]])
    verts, index, tris = [], {}, []
    for tri in tris_raw:
        ids = []
        for v in tri:
            key = tuple(round(c, 5) for c in v)
            if key not in index:
                index[key] = len(verts)
                verts.append(key)
            ids.append(index[key])
        if len(set(ids)) == 3:
            tris.append(tuple(ids))
    return verts, tris


def bbox(verts):
    xs, ys, zs = zip(*verts)
    return (min(xs), max(xs)), (min(ys), max(ys)), (min(zs), max(zs))


def footprint(path):
    """Width and depth of an STL, for laying parts out."""
    (x0, x1), (y0, y1), _ = bbox(load_stl(path)[0])
    return x1 - x0, y1 - y0


def grid(n, w, d, gap, bed=(256.0, 256.0), cols=None, margin=5):
    """Centers for n parts of footprint w x d in a grid centered on the bed."""
    if cols is None:
        cols = max(1, int((bed[0] - 2 * margin + gap) // (w + gap)))
    rows = -(-n // cols)
    tw, td = cols * w + (cols - 1) * gap, rows * d + (rows - 1) * gap
    if tw > bed[0] - 2 * margin or td > bed[1] - 2 * margin:
        raise ValueError(f"{n} parts of {w:.0f}x{d:.0f} mm don't fit the bed in {cols} columns")
    x0, y0 = (bed[0] - tw) / 2 + w / 2, (bed[1] - td) / 2 + d / 2
    return [(x0 + (i % cols) * (w + gap), y0 + (i // cols) * (d + gap)) for i in range(n)]


# ---------------------------------------------------------------- plates

def plate_origin(i, n, bed):
    """Where Bambu Studio puts plate i of n: a grid of columns, each plate a
    bed width plus a fifth apart, later rows toward -y."""
    s = n ** 0.5
    cols = round(s) + 1 if s > round(s) else round(s)
    return (i % cols) * bed[0] * 1.2, -(i // cols) * bed[1] * 1.2


# ---------------------------------------------------------------- writer

XMLNS = ('xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" '
         'xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" '
         'xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" requiredextensions="p"')


def _esc(s):
    return str(s).replace("&", "&amp;").replace('"', "&quot;").replace("<", "&lt;").replace(">", "&gt;")


def write_project(out, plates, settings=None, filament=1, template=DEFAULT_TEMPLATE, title=""):
    """plates: [{"name": str, "objects": [{"stl", "name", "positions", "settings"?}]}]
    settings: process settings to change from the template (string values);
              they're recorded as changes from the preset, like Bambu Studio does
    filament: which filament slot (1-based) the parts use"""
    with open(template) as f:
        project = json.load(f)
    bed_pts = [tuple(float(v) for v in p.split("x")) for p in project.get("printable_area", ["0x0", "256x256"])]
    bed = (max(p[0] for p in bed_pts), max(p[1] for p in bed_pts))
    height = float(project.get("printable_height", 256))
    version = project.get("version", "02.00.00.00")

    if settings:
        changed = [k for k in project.get("different_settings_to_system", [""])[0].split(";") if k]
        for k, v in settings.items():
            if k not in project:
                raise KeyError(f"unknown setting {k!r}")
            project[k] = v
            if k not in changed:
                changed.append(k)
        diffs = project.get("different_settings_to_system", [""])
        diffs[0] = ";".join(sorted(changed))
        project["different_settings_to_system"] = diffs

    U = lambda: str(uuid.uuid4())
    files = {}
    res, items, rels, cut, objs_cfg, plates_cfg, assemble = [], [], [], [], [], [], []
    next_id, ident, mesh_cache = 1, 1000, {}
    n = len(plates)
    for pi, plate in enumerate(plates):
        ox, oy = plate_origin(pi, n, bed)
        instances = []
        for obj in plate["objects"]:
            path = obj["stl"]
            if path not in mesh_cache:
                mesh_cache[path] = load_stl(path)
            verts, tris = mesh_cache[path]
            (x0, x1), (y0, y1), (z0, z1) = bbox(verts)
            if z1 - z0 > height:
                raise ValueError(f"{path} is taller than the printer")
            cx, cy, cz = (x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2
            mesh_id, obj_id = next_id, next_id + 1
            next_id += 2
            fname = f"3D/Objects/object_{mesh_id}.model"
            vx = "".join(f'<vertex x="{a - cx:.5f}" y="{b - cy:.5f}" z="{c - cz:.5f}"/>' for a, b, c in verts)
            tx = "".join(f'<triangle v1="{a}" v2="{b}" v3="{c}"/>' for a, b, c in tris)
            files[fname] = (f'<?xml version="1.0" encoding="UTF-8"?>\n<model unit="millimeter" xml:lang="en-US" {XMLNS}>\n'
                            ' <metadata name="BambuStudio:3mfVersion">1</metadata>\n'
                            f' <resources>\n  <object id="{mesh_id}" p:UUID="{U()}" type="model">\n'
                            f'   <mesh><vertices>{vx}</vertices><triangles>{tx}</triangles></mesh>\n'
                            '  </object>\n </resources>\n <build/>\n</model>\n')
            rels.append(f' <Relationship Target="/{fname}" Id="rel-{len(rels) + 1}" '
                        'Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>')
            res.append(f'  <object id="{obj_id}" p:UUID="{U()}" type="model">\n   <components>\n'
                       f'    <component p:path="/{fname}" objectid="{mesh_id}" p:UUID="{U()}" transform="1 0 0 0 1 0 0 0 1 0 0 0"/>\n'
                       '   </components>\n  </object>')
            cut.append(f' <object id="{len(cut) + 1}">\n  <cut_id id="0" check_sum="1" connectors_cnt="0"/>\n </object>')
            name = _esc(obj.get("name", os.path.basename(path)))
            extra = "".join(f'\n    <metadata key="{_esc(k)}" value="{_esc(v)}"/>' for k, v in obj.get("settings", {}).items())
            objs_cfg.append(
                f'  <object id="{obj_id}">\n    <metadata key="name" value="{name}"/>\n'
                f'    <metadata key="extruder" value="{filament}"/>{extra}\n    <metadata face_count="{len(tris)}"/>\n'
                f'    <part id="{mesh_id}" subtype="normal_part" uuid="{U()}">\n'
                f'      <metadata key="name" value="{name}"/>\n'
                '      <metadata key="matrix" value="1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1"/>\n'
                f'      <metadata key="source_file" value="{_esc(os.path.basename(path))}"/>\n'
                '      <metadata key="source_object_id" value="0"/>\n      <metadata key="source_volume_id" value="0"/>\n'
                f'      <metadata key="source_offset_x" value="{cx}"/>\n      <metadata key="source_offset_y" value="{cy}"/>\n'
                f'      <metadata key="source_offset_z" value="{cz}"/>\n'
                f'      <mesh_stat face_count="{len(tris)}" edges_fixed="0" degenerate_facets="0" facets_removed="0" facets_reversed="0" backwards_edges="0"/>\n'
                '    </part>\n  </object>')
            for k, (px, py) in enumerate(obj["positions"]):
                for ex, ey in ((px - (x1 - x0) / 2, py - (y1 - y0) / 2), (px + (x1 - x0) / 2, py + (y1 - y0) / 2)):
                    if not (0 <= ex <= bed[0] and 0 <= ey <= bed[1]):
                        raise ValueError(f"{name} at ({px:.0f}, {py:.0f}) on plate {pi + 1} hangs off the bed")
                t = f"1 0 0 0 1 0 0 0 1 {ox + px:.4f} {oy + py:.4f} {cz - z0:.5f}"
                items.append(f'  <item objectid="{obj_id}" p:UUID="{U()}" transform="{t}" printable="1"/>')
                assemble.append(f'   <assemble_item object_id="{obj_id}" instance_id="{k}" transform="{t}" offset="0 0 0" />')
                instances.append((obj_id, k, ident))
                ident += 1
            assemble.append(f'   <assemble_item object_id="{obj_id}" volume_id="0" transform="1 0 0 0 1 0 0 0 1 0 0 0" />')
        mi = "".join(f'\n    <model_instance>\n      <metadata key="object_id" value="{o}"/>\n'
                     f'      <metadata key="instance_id" value="{k}"/>\n      <metadata key="identify_id" value="{i}"/>\n'
                     '    </model_instance>' for o, k, i in instances)
        plates_cfg.append(f'  <plate>\n    <metadata key="plater_id" value="{pi + 1}"/>\n'
                          f'    <metadata key="plater_name" value="{_esc(plate.get("name", ""))}"/>\n'
                          '    <metadata key="locked" value="false"/>\n'
                          f'    <metadata key="filament_map_mode" value="Auto For Flush"/>{mi}\n  </plate>')

    today = date.today().isoformat()
    meta = "".join(f' <metadata name="{k}">{_esc(v)}</metadata>\n' for k, v in [
        ("Application", f"BambuStudio-{version}"), ("BambuStudio:3mfVersion", "1"), ("Copyright", ""),
        ("CreationDate", today), ("Description", ""), ("Designer", ""), ("DesignerCover", ""), ("License", ""),
        ("ModificationDate", today), ("Origin", ""), ("ProfileCover", ""), ("ProfileDescription", ""),
        ("ProfileTitle", ""), ("Title", title)])
    main = (f'<?xml version="1.0" encoding="UTF-8"?>\n<model unit="millimeter" xml:lang="en-US" {XMLNS}>\n{meta}'
            f' <resources>\n' + "\n".join(res) + f'\n </resources>\n <build p:UUID="{U()}">\n' + "\n".join(items)
            + '\n </build>\n</model>\n')

    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml",
                   '<?xml version="1.0" encoding="UTF-8"?>\n<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\n'
                   ' <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\n'
                   ' <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>\n'
                   ' <Default Extension="png" ContentType="image/png"/>\n'
                   ' <Default Extension="gcode" ContentType="text/x.gcode"/>\n</Types>\n')
        z.writestr("_rels/.rels",
                   '<?xml version="1.0" encoding="UTF-8"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
                   ' <Relationship Target="/3D/3dmodel.model" Id="rel-1" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>\n'
                   '</Relationships>\n')
        z.writestr("3D/3dmodel.model", main)
        z.writestr("3D/_rels/3dmodel.model.rels",
                   '<?xml version="1.0" encoding="UTF-8"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
                   + "\n".join(rels) + "\n</Relationships>\n")
        for name, text in files.items():
            z.writestr(name, text)
        z.writestr("Metadata/project_settings.config", json.dumps(project, indent=4) + "\n")
        z.writestr("Metadata/model_settings.config",
                   '<?xml version="1.0" encoding="UTF-8"?>\n<config>\n' + "\n".join(objs_cfg) + "\n" + "\n".join(plates_cfg)
                   + "\n  <assemble>\n" + "\n".join(assemble) + "\n  </assemble>\n</config>\n")
        z.writestr("Metadata/cut_information.xml",
                   '<?xml version="1.0" encoding="utf-8"?>\n<objects>\n' + "\n".join(cut) + "\n</objects>\n")
        z.writestr("Metadata/slice_info.config",
                   '<?xml version="1.0" encoding="UTF-8"?>\n<config>\n  <header>\n'
                   '    <header_item key="X-BBL-Client-Type" value="slicer"/>\n'
                   f'    <header_item key="X-BBL-Client-Version" value="{version}"/>\n  </header>\n</config>\n')
        z.writestr("Metadata/filament_sequence.json", json.dumps(
            {f"plate_{i + 1}": {"nozzle_sequence": [], "optimal_assignment": [], "sequence": []} for i in range(n)}))


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    with open(sys.argv[1]) as f:
        spec = json.load(f)
    if isinstance(spec, list):
        spec = {"plates": spec}
    write_project(sys.argv[2], spec["plates"], spec.get("settings"), spec.get("filament", 1),
                  spec.get("template", DEFAULT_TEMPLATE), spec.get("title", ""))
