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

def plates(stl):
    P = lambda n: os.path.join(stl, n + '.stl')
    out = []
    out.append(('ubolts_try_one_of_each', [(f'ubolt_{lv}', P(f'ubolt_{i}'), [(BED / 2 + (i - 1) * (fp(P('ubolt_0'))[0] + 15), BED / 2)])
                                         for i, lv in enumerate(['bottom', 'middle', 'top'])]))
    for i, lv in enumerate(['bottom', 'middle', 'top']):
        w, d = fp(P(f'post_{i}'))
        out.append((f'posts_{lv}_x13', [(f'post_{lv}', P(f'post_{i}'), grid(13, w, d, 10))]))
    out.append(('panel_x1', [('panel', P('panel'), [(BED / 2, BED / 2)])]))
    for i, lv in enumerate(['bottom', 'middle', 'top']):
        w, d = fp(P(f'ubolt_{i}'))
        out.append((f'ubolts_{lv}_x13', [(f'ubolt_{lv}', P(f'ubolt_{i}'), grid(13, w, d, 12))]))
    nw, nd = fp(P('nut')); ww, wd = fp(P('wrench'))
    nuts = [(x, y + 25) for x, y in grid(78, nw, nd, 3, cols=13)]
    out.append(('nuts_x78_and_wrench', [('nut', P('nut'), nuts),
                                        ('wrench', P('wrench'), [(BED / 2, min(y for _, y in nuts) - nd / 2 - 8 - wd / 2)])]))
    cw, cd = fp(P('cap'))
    out.append(('caps_x78', [('cap', P('cap'), grid(78, cw, cd, 2, cols=9))]))
    return out

def mesh_xml(path):
    v, t = load_stl(path)
    x0, x1, y0, y1, z0, z1 = bbox(v)
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    vx = ''.join(f'<vertex x="{a - cx:.4f}" y="{b - cy:.4f}" z="{c - z0:.4f}"/>' for a, b, c in v)
    tx = ''.join(f'<triangle v1="{a}" v2="{b}" v3="{c}"/>' for a, b, c in t)
    return f'<mesh><vertices>{vx}</vertices><triangles>{tx}</triangles></mesh>'

# Bambu Studio lays plates out in a grid: ceil-ish(sqrt(n)) columns, each plate
# one bed width plus a fifth apart, later rows going toward -y
def plate_origin(i, n):
    s = n ** 0.5
    cols = round(s) + 1 if s > round(s) else round(s)
    stride = BED * 1.2
    return (i % cols) * stride, -(i // cols) * stride

def write_bambu_project(out, plate_list):
    import uuid
    U = lambda: str(uuid.uuid4())
    files, res, items, rels = {}, [], [], []
    settings_obj, settings_plates = [], []
    oid, ident = 1, 100
    n = len(plate_list)
    for pi, (pname, objs) in enumerate(plate_list):
        ox, oy = plate_origin(pi, n)
        inst = []
        for name, path, places in objs:
            mesh_id, obj_id = oid, oid + 1
            oid += 2
            fname = f'/3D/Objects/object_{mesh_id}.model'
            files[fname[1:]] = ('<?xml version="1.0" encoding="UTF-8"?>'
                '<model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" '
                'xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" requiredextensions="p">'
                '<metadata name="BambuStudio:3mfVersion">1</metadata>'
                f'<resources><object id="{mesh_id}" p:UUID="{U()}" type="model">{mesh_xml(path)}</object></resources>'
                '<build/></model>')
            rels.append(f'<Relationship Target="{fname}" Id="rel-{mesh_id}" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>')
            res.append(f'<object id="{obj_id}" p:UUID="{U()}" type="model"><components>'
                       f'<component p:path="{fname}" objectid="{mesh_id}" p:UUID="{U()}" transform="1 0 0 0 1 0 0 0 1 0 0 0"/></components></object>')
            for k, (px, py) in enumerate(places):
                items.append(f'<item objectid="{obj_id}" p:UUID="{U()}" transform="1 0 0 0 1 0 0 0 1 {ox + px:.3f} {oy + py:.3f} 0" printable="1"/>')
                inst.append((obj_id, k, ident)); ident += 1
            settings_obj.append(f'<object id="{obj_id}"><metadata key="name" value="{name}"/><metadata key="extruder" value="1"/>'
                                f'<part id="{mesh_id}" subtype="normal_part"><metadata key="name" value="{name}"/>'
                                '<metadata key="matrix" value="1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1"/></part></object>')
        mi = ''.join(f'<model_instance><metadata key="object_id" value="{o}"/><metadata key="instance_id" value="{k}"/>'
                     f'<metadata key="identify_id" value="{i}"/></model_instance>' for o, k, i in inst)
        settings_plates.append(f'<plate><metadata key="plater_id" value="{pi + 1}"/><metadata key="plater_name" value="{pname}"/>'
                               f'<metadata key="locked" value="false"/>{mi}</plate>')
    main = ('<?xml version="1.0" encoding="UTF-8"?>'
            '<model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" '
            'xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" requiredextensions="p">'
            '<metadata name="Application">BambuStudio-01.10.00.00</metadata>'
            '<metadata name="BambuStudio:3mfVersion">1</metadata>'
            '<metadata name="Title">Loft Cat Wall</metadata>'
            f'<resources>{"".join(res)}</resources><build p:UUID="{U()}">{"".join(items)}</build></model>')
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
        z.writestr('[Content_Types].xml', '<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/><Default Extension="png" ContentType="image/png"/><Default Extension="config" ContentType="text/xml"/></Types>')
        z.writestr('_rels/.rels', '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Target="/3D/3dmodel.model" Id="rel-1" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/></Relationships>')
        z.writestr('3D/3dmodel.model', main)
        z.writestr('3D/_rels/3dmodel.model.rels', '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' + ''.join(rels) + '</Relationships>')
        for k, v in files.items(): z.writestr(k, v)
        z.writestr('Metadata/model_settings.config', '<?xml version="1.0" encoding="UTF-8"?><config>' + ''.join(settings_obj) + ''.join(settings_plates) + '</config>')

if __name__ == '__main__':
    stl, out = sys.argv[1], sys.argv[2]
    os.makedirs(out, exist_ok=True)
    pl = plates(stl)
    for pname, objs in pl:
        write_3mf(f'{out}/{pname}.3mf', objs)
    write_bambu_project(f'{out}/loft_cat_wall_all_plates.3mf', pl)
    print('done')
