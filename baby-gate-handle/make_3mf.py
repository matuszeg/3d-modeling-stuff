"""Package stl/baby_gate_handle.stl as a Bambu Studio 3MF for the P2S.

Centres the part on the 256 x 256 plate in its print orientation and stores the
print settings as per-object overrides (4 walls, 40% gyroid, no supports), so
they apply on top of whatever printer and PETG filament presets are selected.

    python3 make_3mf.py   ->  baby_gate_handle.3mf
"""
import struct, zipfile, os

HERE = os.path.dirname(os.path.abspath(__file__))
STL = os.path.join(HERE, "stl", "baby_gate_handle.stl")
OUT = os.path.join(HERE, "baby_gate_handle.3mf")
NAME = "baby_gate_handle"
PLATE = 256.0
SETTINGS = {
    "wall_loops": "4",
    "sparse_infill_density": "40%",
    "sparse_infill_pattern": "gyroid",
    "enable_support": "0",
    "layer_height": "0.2",
}

def read_stl(path):
    data = open(path, "rb").read()
    tris = []
    if data[:5] == b"solid" and b"facet" in data[:300]:
        cur = []
        for line in data.decode().splitlines():
            p = line.split()
            if p and p[0] == "vertex":
                cur.append(tuple(float(v) for v in p[1:4]))
                if len(cur) == 3:
                    tris.append(cur); cur = []
    else:
        n = struct.unpack("<I", data[80:84])[0]
        for i in range(n):
            f = struct.unpack("<12f", data[84 + 50*i: 84 + 50*i + 48])
            tris.append([f[3:6], f[6:9], f[9:12]])
    return tris

tris = read_stl(STL)
vid, verts, faces = {}, [], []
for t in tris:
    idx = []
    for v in t:
        k = tuple(round(c, 5) for c in v)
        if k not in vid:
            vid[k] = len(verts); verts.append(k)
        idx.append(vid[k])
    if len(set(idx)) == 3:
        faces.append(idx)

xs, ys, zs = zip(*verts)
cx, cy, z0 = (min(xs) + max(xs))/2, (min(ys) + max(ys))/2, min(zs)
verts = [(x - cx, y - cy, z - z0) for x, y, z in verts]   # centred in XY, sitting on z=0

vx = "\n".join(f'     <vertex x="{x:.5f}" y="{y:.5f}" z="{z:.5f}"/>' for x, y, z in verts)
tx = "\n".join(f'     <triangle v1="{a}" v2="{b}" v3="{c}"/>' for a, b, c in faces)
model = f'''<?xml version="1.0" encoding="UTF-8"?>
<model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">
 <metadata name="Application">BambuStudio-02.00.00.00</metadata>
 <metadata name="Title">{NAME}</metadata>
 <resources>
  <object id="1" name="{NAME}" type="model">
   <mesh>
    <vertices>
{vx}
    </vertices>
    <triangles>
{tx}
    </triangles>
   </mesh>
  </object>
 </resources>
 <build>
  <item objectid="1" transform="1 0 0 0 1 0 0 0 1 {PLATE/2} {PLATE/2} 0" printable="1"/>
 </build>
</model>
'''

meta = "\n".join(f'    <metadata key="{k}" value="{v}"/>' for k, v in SETTINGS.items())
model_settings = f'''<?xml version="1.0" encoding="UTF-8"?>
<config>
  <object id="1">
    <metadata key="name" value="{NAME}"/>
    <metadata key="extruder" value="1"/>
{meta}
    <part id="1" subtype="normal_part">
      <metadata key="name" value="{NAME}"/>
      <metadata key="matrix" value="1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1"/>
    </part>
  </object>
  <plate>
    <metadata key="plater_id" value="1"/>
    <metadata key="plater_name" value=""/>
    <metadata key="locked" value="false"/>
    <model_instance>
      <metadata key="object_id" value="1"/>
      <metadata key="instance_id" value="0"/>
    </model_instance>
  </plate>
</config>
'''

content_types = '''<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
 <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
 <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>
 <Default Extension="config" ContentType="text/xml"/>
</Types>
'''
rels = '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
 <Relationship Target="/3D/3dmodel.model" Id="rel-1" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>
</Relationships>
'''

with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("[Content_Types].xml", content_types)
    z.writestr("_rels/.rels", rels)
    z.writestr("3D/3dmodel.model", model)
    z.writestr("Metadata/model_settings.config", model_settings)
print(f"{OUT}: {len(verts)} vertices, {len(faces)} triangles, "
      f"{max(xs)-min(xs):.1f} x {max(ys)-min(ys):.1f} x {max(zs)-min(zs):.1f} mm")
