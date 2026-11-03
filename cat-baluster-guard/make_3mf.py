import sys, zipfile, os

BED = 256.0

def load_stl(path):
    verts, idx, tris = [], {}, []
    cur = []
    with open(path) as f:
        for line in f:
            s = line.split()
            if s and s[0] == 'vertex':
                v = tuple(round(float(x), 5) for x in s[1:4])
                if v not in idx:
                    idx[v] = len(verts); verts.append(v)
                cur.append(idx[v])
                if len(cur) == 3:
                    if len(set(cur)) == 3: tris.append(tuple(cur))
                    cur = []
    return verts, tris

def bbox(verts):
    xs, ys, zs = zip(*verts)
    return min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)

def grid(n, w, d, gap, cols=None):
    # positions (centers) for n parts of footprint w x d, centered on the bed
    if cols is None:
        cols = int((BED - 10 + gap) // (w + gap))
    rows = -(-n // cols)
    tw, td = cols * w + (cols - 1) * gap, rows * d + (rows - 1) * gap
    assert tw <= BED - 6 and td <= BED - 6, (n, w, d, tw, td)
    x0, y0 = (BED - tw) / 2 + w / 2, (BED - td) / 2 + d / 2
    return [(x0 + (i % cols) * (w + gap), y0 + (i // cols) * (d + gap)) for i in range(n)]

def write_3mf(out, objects):
    # objects: list of (name, stl_path, [(cx, cy), ...]) placed by footprint center
    res, items, oid = [], [], 1
    for name, path, places in objects:
        v, t = load_stl(path)
        x0, x1, y0, y1, z0, z1 = bbox(v)
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        vx = ''.join(f'<vertex x="{a - cx:.4f}" y="{b - cy:.4f}" z="{c - z0:.4f}"/>' for a, b, c in v)
        tx = ''.join(f'<triangle v1="{a}" v2="{b}" v3="{c}"/>' for a, b, c in t)
        res.append(f'<object id="{oid}" name="{name}" type="model"><mesh><vertices>{vx}</vertices><triangles>{tx}</triangles></mesh></object>')
        for (px, py) in places:
            for (ex, ey) in [(px - (x1 - x0) / 2, py - (y1 - y0) / 2), (px + (x1 - x0) / 2, py + (y1 - y0) / 2)]:
                assert 0 <= ex <= BED and 0 <= ey <= BED, (name, ex, ey)
            items.append(f'<item objectid="{oid}" transform="1 0 0 0 1 0 0 0 1 {px:.3f} {py:.3f} 0"/>')
        oid += 1
    model = ('<?xml version="1.0" encoding="UTF-8"?>'
             '<model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">'
             '<metadata name="Application">OpenSCAD + script</metadata>'
             f'<resources>{"".join(res)}</resources><build>{"".join(items)}</build></model>')
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
        z.writestr('[Content_Types].xml', '<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/></Types>')
        z.writestr('_rels/.rels', '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Target="/3D/3dmodel.model" Id="rel0" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/></Relationships>')
        z.writestr('3D/3dmodel.model', model)

def fp(path):
    x0, x1, y0, y1, _, _ = bbox(load_stl(path)[0]); return x1 - x0, y1 - y0

stl, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
P = lambda n: os.path.join(stl, n + '.stl')

w, d = fp(P('panel'));  write_3mf(f'{out}/panel_x1.3mf', [('panel', P('panel'), [(BED / 2, BED / 2)])])
for i, lv in enumerate(['bottom', 'middle', 'top']):
    w, d = fp(P(f'post_{i}')); write_3mf(f'{out}/posts_{lv}_x13.3mf', [(f'post_{lv}', P(f'post_{i}'), grid(13, w, d, 10))])
    w, d = fp(P(f'ubolt_{i}')); write_3mf(f'{out}/ubolts_{lv}_x13.3mf', [(f'ubolt_{lv}', P(f'ubolt_{i}'), grid(13, w, d, 12))])
# one U-bolt of each level, to try before printing the rest
w, d = fp(P('ubolt_0'))
write_3mf(f'{out}/ubolts_try_one_of_each.3mf', [(f'ubolt_{lv}', P(f'ubolt_{i}'), [(BED / 2 + (i - 1) * (w + 15), BED / 2)]) for i, lv in enumerate(['bottom', 'middle', 'top'])])
# 78 nuts plus the wrench
nw, nd = fp(P('nut')); ww, wd = fp(P('wrench'))
nuts = [(x, y + 25) for x, y in grid(78, nw, nd, 3, cols=13)]
write_3mf(f'{out}/nuts_x78_and_wrench.3mf', [('nut', P('nut'), nuts), ('wrench', P('wrench'), [(BED / 2, min(y for _, y in nuts) - nd / 2 - 8 - wd / 2)])])
cw, cd = fp(P('cap')); write_3mf(f'{out}/caps_x78.3mf', [('cap', P('cap'), grid(78, cw, cd, 2, cols=9))])
print('done')
