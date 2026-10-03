"""Builds game/zotik/assets/characters/custom/zotik_rig.glb (pip install pygltflib numpy).

Procedural stylised Zotik body (placeholder, no third-party mesh data). It reuses the skeleton, rest pose and the
76 animations of the CC0 KayKit Rogue.glb (assets/characters/kaykit), replaces the body meshes with a fox-like Zotik
(ears, muzzle, big eyes, scarf, vest, boots) skinned to the same bones, and adds 6 tail bones (Tail_00..Tail_05).
Run from the repository root: python tools/make_zotik_rig.py
"""
import math
import numpy as np
from pygltflib import (GLTF2, Node, Mesh, Primitive, Attributes, Accessor, BufferView, Material,
                       PbrMetallicRoughness, FLOAT, UNSIGNED_SHORT, VEC3, VEC4, SCALAR, MAT4,
                       ARRAY_BUFFER, ELEMENT_ARRAY_BUFFER)

SRC = "game/zotik/assets/characters/kaykit/Rogue.glb"
DST = "game/zotik/assets/characters/custom/zotik_rig.glb"
rng = np.random.default_rng(7)


def lin(h):  # sRGB hex -> linear rgb (glTF vertex colours are linear)
    c = np.array([int(h[i:i + 2], 16) / 255 for i in (1, 3, 5)])
    return c ** 2.2


ORANGE, DARK_FUR, CREAM = lin("#F2781A"), lin("#C8571A"), lin("#FFE6C8")
LEATHER, PANTS, BRONZE = lin("#5A3320"), lin("#34221C"), lin("#B9803A")
GREEN, RED, EYE = lin("#2E9A3C"), lin("#A52A2A"), lin("#35C24A")
NOSE, EARTIP, EARIN, BLUE, WHITE = lin("#2A1A18"), lin("#2A1713"), lin("#F4B6A0"), lin("#2E7BFF"), lin("#FFFFFF")

g = GLTF2().load(SRC)
blob = g.binary_blob()


def q2m(q):
    x, y, z, w = q
    return np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
                     [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
                     [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])


WORLD = {}


def walk(i, parent):
    n = g.nodes[i]
    m = np.eye(4)
    if n.rotation:
        m[:3, :3] = q2m(n.rotation)
    if n.scale:
        m[:3, :3] = m[:3, :3] @ np.diag(n.scale)
    if n.translation:
        m[:3, 3] = n.translation
    t = parent @ m
    WORLD[n.name] = t
    for c in n.children or []:
        walk(c, t)


for r in g.scenes[0].nodes:
    walk(r, np.eye(4))
skin = g.skins[0]
JI = {g.nodes[j].name: k for k, j in enumerate(skin.joints)}  # joint name -> index in JOINTS_0

# --- tail bones -----------------------------------------------------------------------------------------------
NB = 6
TAIL_LEN = 1.0


def tail_pt(t):  # world rest position of the tail spine (back = -Z, curving up)
    return np.array([0.0, 0.50 + 0.55 * t * t + 0.10 * t, -0.18 - TAIL_LEN * t * (1 - 0.25 * t)])


tail_pos = [tail_pt(i / (NB - 1)) for i in range(NB)]
hips_pos = WORLD["hips"][:3, 3]
hips_node = next(i for i, n in enumerate(g.nodes) if n.name == "hips")
first_tail = len(g.nodes)
for i in range(NB):
    parent_pos = hips_pos if i == 0 else tail_pos[i - 1]
    g.nodes.append(Node(name=f"Tail_{i:02d}", translation=(tail_pos[i] - parent_pos).tolist(),
                        children=[first_tail + i + 1] if i < NB - 1 else []))
g.nodes[hips_node].children.append(first_tail)
for i in range(NB):
    JI[f"Tail_{i:02d}"] = len(skin.joints)
    skin.joints.append(first_tail + i)

# --- geometry helpers -----------------------------------------------------------------------------------------
V, N, C, J, W, I = [], [], [], [], [], []


def smooth(a, b, v):
    t = min(max((v - a) / (b - a), 0.0), 1.0)
    return t * t * (3 - 2 * t)


def seg_weights(v, joints, bounds, bw):
    """joints along increasing v, bounds[k] = where joints[k+1] takes over (blend half-width bw[k])."""
    s = [smooth(b - w, b + w, v) for b, w in zip(bounds, bw)] + [0.0]
    out = {}
    prev = 1.0
    for k, jn in enumerate(joints):
        wk = (prev - s[k]) if k < len(bounds) else prev
        prev = s[k]
        if wk > 1e-3:
            out[jn] = wk
    return out


def single(jn):
    return lambda p: {jn: 1.0}


def torso_w(p):
    return seg_weights(p[1], ["hips", "spine", "chest"], [0.55, 0.88], [0.10, 0.10])


def arm_w(side):
    return lambda p: seg_weights(abs(p[0]), [f"upperarm.{side}", f"lowerarm.{side}", f"wrist.{side}", f"hand.{side}"],
                                 [0.454, 0.713, 0.787], [0.06, 0.03, 0.02])


def leg_w(side):
    return lambda p: seg_weights(-p[1], [f"upperleg.{side}", f"lowerleg.{side}", f"foot.{side}"],
                                 [-0.292, -0.145], [0.05, 0.03])


def tail_w(p):
    # project onto the tail polyline by nearest-bone blend
    d = [np.linalg.norm(p - b) for b in tail_pos]
    a, b = np.argsort(d)[:2]
    wa, wb = 1 / (d[a] + 1e-4), 1 / (d[b] + 1e-4)
    return {f"Tail_{a:02d}": wa / (wa + wb), f"Tail_{b:02d}": wb / (wa + wb)}


def push(p, n, col, wd, jitter):
    if jitter:
        col = np.clip(col * (1 + rng.uniform(-jitter, jitter)), 0, 1)
    jj, ww = [0, 0, 0, 0], [0.0, 0, 0, 0]
    items = sorted(wd.items(), key=lambda kv: -kv[1])[:4]
    tot = sum(w for _, w in items)
    for k, (name, w) in enumerate(items):
        jj[k], ww[k] = JI[name], w / tot
    V.append(p); N.append(n / (np.linalg.norm(n) + 1e-9)); C.append([*col, 1.0]); J.append(jj); W.append(ww)
    return len(V) - 1


def add_tris(tris):
    for a, b, c in tris:
        n = np.cross(V[b] - V[a], V[c] - V[a])
        if np.dot(n, N[a] + N[b] + N[c]) < 0:
            b, c = c, b
        I.extend([a, b, c])


def ellipsoid(c, r, col, wfn, jitter=0.04, nlat=9, nlon=16):
    c, r = np.array(c, float), np.array(r, float)
    rows = []
    for i in range(nlat + 1):
        th = math.pi * i / nlat
        row = []
        for j in range(nlon):
            ph = 2 * math.pi * j / nlon
            d = np.array([math.sin(th) * math.cos(ph), math.cos(th), math.sin(th) * math.sin(ph)])
            p = c + r * d
            row.append(push(p, d / r, col, wfn(p), jitter))
        rows.append(row)
    for i in range(nlat):
        for j in range(nlon):
            a, b = rows[i][j], rows[i][(j + 1) % nlon]
            add_tris([(a, rows[i + 1][j], b), (b, rows[i + 1][j], rows[i + 1][(j + 1) % nlon])])


def frame(d):
    d = d / np.linalg.norm(d)
    ref = np.array([0, 0, 1.0]) if abs(d[2]) < 0.9 else np.array([1.0, 0, 0])
    u = np.cross(d, ref); u /= np.linalg.norm(u)
    return d, u, np.cross(d, u)


def tube(p0, p1, r0, r1, col, wfn, rings=5, sides=12, jitter=0.03, colfn=None, squash=1.0, caps=(True, True)):
    p0, p1 = np.array(p0, float), np.array(p1, float)
    d, u, w = frame(p1 - p0)
    rr = []
    for i in range(rings + 1):
        t = i / rings
        c = p0 * (1 - t) + p1 * t
        r = r0 * (1 - t) + r1 * t
        cc = colfn(t) if colfn else col
        row = []
        for j in range(sides):
            a = 2 * math.pi * j / sides
            n = math.cos(a) * u + math.sin(a) * w
            p = c + n * r * (squash if abs(math.sin(a)) > 0.5 else 1.0)
            row.append(push(p, n, cc, wfn(p), jitter))
        rr.append(row)
    for i in range(rings):
        for j in range(sides):
            a, b = rr[i][j], rr[i][(j + 1) % sides]
            add_tris([(a, rr[i + 1][j], b), (b, rr[i + 1][j], rr[i + 1][(j + 1) % sides])])
    for use, (row, c, nd, cc) in zip(caps, ((rr[0], p0, -d, colfn(0) if colfn else col), (rr[-1], p1, d, colfn(1) if colfn else col))):
        if not use:
            continue
        ci = push(c, nd, cc, wfn(c), 0)
        for j in range(sides):
            add_tris([(ci, row[j], row[(j + 1) % sides])])


def cone(base, direction, h, r, col, wfn, **kw):
    d = np.array(direction, float); d /= np.linalg.norm(d)
    tube(base, np.array(base, float) + d * h, r, 0.004, col, wfn, **kw)


def torus(c, R, rz, r, col, wfn, ny=28, nr=8):
    c = np.array(c, float)
    rows = []
    for i in range(ny):
        a = 2 * math.pi * i / ny
        ctr = c + np.array([math.cos(a) * R, 0, math.sin(a) * rz])
        radial = np.array([math.cos(a), 0, math.sin(a)])
        row = []
        for j in range(nr):
            b = 2 * math.pi * j / nr
            n = math.cos(b) * radial + math.sin(b) * np.array([0, 1.0, 0])
            p = ctr + n * r
            row.append(push(p, n, col, wfn(p), 0.02))
        rows.append(row)
    for i in range(ny):
        for j in range(nr):
            a, b = rows[i][j], rows[i][(j + 1) % nr]
            add_tris([(a, rows[(i + 1) % ny][j], b), (b, rows[(i + 1) % ny][j], rows[(i + 1) % ny][(j + 1) % nr])])


# --- Zotik body (rest pose = KayKit T-pose, +Z is the front) ---------------------------------------------------
head = single("head")
# head: skull, cheeks, muzzle, nose, eyes, ears, hair tufts
ellipsoid((0, 1.62, 0.0), (0.47, 0.42, 0.43), ORANGE, head, nlat=12, nlon=20)
for s in (-1, 1):
    ellipsoid((s * 0.36, 1.46, 0.10), (0.13, 0.12, 0.17), CREAM, head)                 # cheek fluff
    ellipsoid((s * 0.21, 1.66, 0.36), (0.10, 0.115, 0.05), WHITE, head, jitter=0)     # eye white
    ellipsoid((s * 0.21, 1.66, 0.395), (0.078, 0.10, 0.04), EYE, head, jitter=0)      # iris
    ellipsoid((s * 0.21, 1.66, 0.425), (0.032, 0.055, 0.02), NOSE, head, jitter=0)      # pupil
    ellipsoid((s * 0.18, 1.70, 0.435), (0.02, 0.02, 0.015), WHITE, head, jitter=0)      # highlight
    ear_dir = (s * 0.38, 1.0, -0.10)
    cone((s * 0.25, 1.90, -0.03), ear_dir, 0.55, 0.26, ORANGE, head, sides=14, rings=8, squash=0.45)
    cone((s * 0.25, 1.91, 0.05), ear_dir, 0.46, 0.17, EARIN, head, sides=14, rings=6, jitter=0.0, squash=0.35)
    cone((s * 0.25 + s * 0.157, 2.34, -0.06), ear_dir, 0.15, 0.065, EARTIP, head, sides=10, rings=2, jitter=0, squash=0.45)
ellipsoid((0, 1.50, 0.38), (0.17, 0.12, 0.22), CREAM, head)                              # muzzle
ellipsoid((0, 1.535, 0.58), (0.045, 0.032, 0.035), NOSE, head, jitter=0)                    # nose
ellipsoid((0, 1.44, 0.36), (0.12, 0.05, 0.12), CREAM, head)                              # chin
for k, x in enumerate((-0.26, -0.13, 0.0, 0.13, 0.26)):                                   # hair tufts
    cone((x, 1.98 + 0.01 * (k % 2), 0.15), (x * 0.8, 0.9, 0.55), 0.26 - 0.04 * (k % 2), 0.085, DARK_FUR, head,
         sides=8, rings=3)
ellipsoid((0, 1.9, 0.06), (0.30, 0.12, 0.28), DARK_FUR, head)

# neck + scarf
ellipsoid((0, 1.28, 0.0), (0.16, 0.14, 0.16), ORANGE, single("head"))
torus((0, 1.20, 0.0), 0.27, 0.24, 0.115, GREEN, lambda p: seg_weights(p[1], ["chest", "head"], [1.2], [0.05]), ny=30, nr=10)
ellipsoid((0.12, 1.02, -0.25), (0.13, 0.26, 0.04), GREEN, single("chest"), jitter=0.02)  # scarf tail
ellipsoid((-0.05, 0.98, -0.27), (0.10, 0.22, 0.04), GREEN, single("chest"), jitter=0.02)
ellipsoid((0.05, 1.08, 0.24), (0.14, 0.12, 0.08), GREEN, single("chest"), jitter=0.02)   # knot

# torso: fur chest/belly, vest, belt, crystal, pants, red cloth
ellipsoid((0, 0.98, 0.0), (0.31, 0.27, 0.20), ORANGE, torso_w, nlat=10, nlon=18)
ellipsoid((0, 0.80, 0.02), (0.25, 0.25, 0.19), CREAM, torso_w)
ellipsoid((0, 1.0, -0.03), (0.325, 0.26, 0.19), LEATHER, torso_w, nlat=10, nlon=18)       # vest back/sides
ellipsoid((0.0, 1.0, 0.13), (0.30, 0.24, 0.10), LEATHER, torso_w)
for sx in (-1, 1):
    ellipsoid((sx * 0.14, 1.02, 0.18), (0.10, 0.20, 0.06), LEATHER, torso_w)              # vest front panels
tube((-0.25, 1.17, 0.14), (0.22, 0.72, 0.20), 0.035, 0.035, LEATHER, torso_w, rings=6, sides=8)  # strap
ellipsoid((-0.07, 0.93, 0.24), (0.055, 0.075, 0.03), BLUE, torso_w, jitter=0)             # crystal
ellipsoid((0, 0.56, 0.0), (0.285, 0.20, 0.22), PANTS, torso_w, nlat=10, nlon=18)
torus((0, 0.60, 0.0), 0.285, 0.215, 0.045, LEATHER, torso_w, ny=30)
ellipsoid((0.0, 0.60, 0.25), (0.06, 0.05, 0.02), BRONZE, torso_w, jitter=0)               # buckle
ellipsoid((-0.12, 0.44, 0.22), (0.10, 0.17, 0.05), RED, torso_w, jitter=0.03)             # red cloth
ellipsoid((0.19, 0.44, 0.20), (0.07, 0.15, 0.05), RED, torso_w, jitter=0.03)

# arms (T-pose along +-X)
for sd, sx in (("l", 1), ("r", -1)):
    aw = arm_w(sd)
    ellipsoid((sx * 0.22, 1.10, 0.0), (0.13, 0.13, 0.13), ORANGE, lambda p, sd=sd: {"chest": 0.5, f"upperarm.{sd}": 0.5})
    tube((sx * 0.20, 1.107, 0.0), (sx * 0.47, 1.107, -0.014), 0.105, 0.085, ORANGE, aw, rings=6)
    tube((sx * 0.47, 1.107, -0.014), (sx * 0.64, 1.107, -0.005), 0.085, 0.075, ORANGE, aw, rings=4)
    tube((sx * 0.52, 1.107, -0.012), (sx * 0.73, 1.107, 0.0), 0.105, 0.098, LEATHER, aw, rings=4)       # bracer
    tube((sx * 0.60, 1.107, -0.008), (sx * 0.64, 1.107, -0.005), 0.112, 0.112, BRONZE, aw, rings=1)      # band
    ellipsoid((sx * 0.80, 1.107, 0.0), (0.095, 0.085, 0.085), PANTS, aw, jitter=0.02)                    # glove
    ellipsoid((sx * 0.87, 1.107, 0.02), (0.05, 0.05, 0.05), ORANGE, aw)                                   # paw

# legs
for sd, sx in (("l", 1), ("r", -1)):
    lw = leg_w(sd)
    ellipsoid((sx * 0.171, 0.44, 0.0), (0.155, 0.13, 0.155), PANTS, lw)
    tube((sx * 0.171, 0.48, 0.0), (sx * 0.171, 0.28, 0.01), 0.15, 0.13, PANTS, lw, rings=4)
    tube((sx * 0.171, 0.30, 0.008), (sx * 0.171, 0.06, 0.0), 0.125, 0.11, LEATHER, lw, rings=5)          # boot shaft
    tube((sx * 0.171, 0.31, 0.008), (sx * 0.171, 0.27, 0.01), 0.14, 0.14, BRONZE, lw, rings=1)           # cuff
    ellipsoid((sx * 0.171, 0.075, 0.10), (0.125, 0.075, 0.21), LEATHER, single(f"foot.{sd}"), jitter=0.03)
    ellipsoid((sx * 0.171, 0.035, 0.10), (0.13, 0.03, 0.215), BRONZE, single(f"foot.{sd}"), jitter=0.0)  # sole
    ellipsoid((sx * 0.171, 0.07, 0.25), (0.10, 0.06, 0.09), LEATHER, single(f"toes.{sd}"), jitter=0.03)

# tail: bushy, orange with white tip
def tail_col(t):
    k = smooth(0.62, 0.82, t)
    base = DARK_FUR * (1 - t) + ORANGE * t if t < 0.5 else ORANGE
    return base * (1 - k) + CREAM * k


def tail_r(t):
    return 0.07 + 0.19 * math.sin(min(t / 0.6, 1) * math.pi / 2) ** 1.1 if t < 0.6 else 0.26 * (1 - (t - 0.6) / 0.4) ** 0.55 + 0.012


prev = None
rings = 22
pts = [tail_pt(i / rings) for i in range(rings + 1)]
for i in range(rings):
    t0, t1 = i / rings, (i + 1) / rings
    tube(pts[i], pts[i + 1], tail_r(t0), tail_r(t1), tail_col((t0 + t1) / 2), tail_w, rings=1, sides=14, jitter=0.02,
         caps=(i == 0, i == rings - 1))

# --- write into the glTF ---------------------------------------------------------------------------------------
Vn = np.array(V, np.float32); Nn = np.array(N, np.float32); Cn = np.array(C, np.float32)
Jn = np.array(J, np.uint16); Wn = np.array(W, np.float32); In = np.array(I, np.uint32)
if Vn.shape[0] < 65535:
    In = In.astype(np.uint16)
_acc = g.accessors[skin.inverseBindMatrices]
_off = g.bufferViews[_acc.bufferView].byteOffset + (_acc.byteOffset or 0)
ibm_old = np.frombuffer(blob[_off:_off + _acc.count * 64], np.float32).reshape(-1, 16)
ibm_new = [np.array([[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [*(-p), 1]], np.float32).reshape(16) for p in tail_pos]
IBM = np.concatenate([ibm_old, np.array(ibm_new)]).astype(np.float32)

extra = bytearray()


def add_view(arr, target=None):
    while len(extra) % 4:
        extra.append(0)
    g.bufferViews.append(BufferView(buffer=0, byteOffset=len(blob) + len(extra), byteLength=arr.nbytes, target=target))
    extra.extend(arr.tobytes())
    return len(g.bufferViews) - 1


def add_acc(arr, view, ctype, atype, mm=False):
    a = Accessor(bufferView=view, componentType=ctype, count=len(arr), type=atype)
    if mm:
        a.min, a.max = arr.min(0).tolist(), arr.max(0).tolist()
    g.accessors.append(a)
    return len(g.accessors) - 1


# the blob may need padding before our data
pad = (-len(blob)) % 4
blob += b"\0" * pad
aP = add_acc(Vn, add_view(Vn, ARRAY_BUFFER), FLOAT, VEC3, True)
aN = add_acc(Nn, add_view(Nn, ARRAY_BUFFER), FLOAT, VEC3)
aC = add_acc(Cn, add_view(Cn, ARRAY_BUFFER), FLOAT, VEC4)
aJ = add_acc(Jn, add_view(Jn, ARRAY_BUFFER), UNSIGNED_SHORT, VEC4)
aW = add_acc(Wn, add_view(Wn, ARRAY_BUFFER), FLOAT, VEC4)
aI = add_acc(In, add_view(In, ELEMENT_ARRAY_BUFFER), 5123 if In.dtype == np.uint16 else 5125, SCALAR)
skin.inverseBindMatrices = add_acc(IBM, add_view(IBM), FLOAT, MAT4)

g.materials.append(Material(name="ZotikFur", pbrMetallicRoughness=PbrMetallicRoughness(
    baseColorFactor=[1, 1, 1, 1], metallicFactor=0.0, roughnessFactor=0.9), doubleSided=False))
g.meshes.append(Mesh(name="Zotik_Body", primitives=[Primitive(
    attributes=Attributes(POSITION=aP, NORMAL=aN, COLOR_0=aC, JOINTS_0=aJ, WEIGHTS_0=aW), indices=aI,
    material=len(g.materials) - 1)]))
zi = len(g.meshes) - 1
rig = next(i for i, n in enumerate(g.nodes) if n.name == "Rig")
g.nodes.append(Node(name="Zotik_Body", mesh=zi, skin=0))
g.nodes[rig].children.append(len(g.nodes) - 1)
for n in g.nodes:                      # drop Rogue body meshes and the cape
    if n.name.startswith("Rogue_"):
        n.mesh = None

blob = blob + bytes(extra)


def compact(g, blob):
    """Drop unreferenced meshes, accessors and buffer views (the Rogue body meshes) and rebuild the binary blob."""
    used_m = sorted({n.mesh for n in g.nodes if n.mesh is not None})
    mm = {o: k for k, o in enumerate(used_m)}
    g.meshes = [g.meshes[o] for o in used_m]
    for n in g.nodes:
        if n.mesh is not None:
            n.mesh = mm[n.mesh]
    acc = set()
    for m in g.meshes:
        for pr in m.primitives:
            acc.update(v for v in vars(pr.attributes).values() if isinstance(v, int))
            if pr.indices is not None:
                acc.add(pr.indices)
    for an in g.animations:
        for sm in an.samplers:
            acc.update((sm.input, sm.output))
    acc.add(g.skins[0].inverseBindMatrices)
    acc = sorted(acc)
    am = {o: k for k, o in enumerate(acc)}
    for m in g.meshes:
        for pr in m.primitives:
            for k, v in list(vars(pr.attributes).items()):
                if isinstance(v, int):
                    setattr(pr.attributes, k, am[v])
            if pr.indices is not None:
                pr.indices = am[pr.indices]
    for an in g.animations:
        for sm in an.samplers:
            sm.input, sm.output = am[sm.input], am[sm.output]
    g.skins[0].inverseBindMatrices = am[g.skins[0].inverseBindMatrices]
    g.accessors = [g.accessors[o] for o in acc]
    views = sorted({a.bufferView for a in g.accessors if a.bufferView is not None} |
                   {im.bufferView for im in (g.images or []) if im.bufferView is not None})
    vm = {o: k for k, o in enumerate(views)}
    out = bytearray()
    newviews = []
    for o in views:
        bv = g.bufferViews[o]
        while len(out) % 4:
            out.append(0)
        newviews.append(BufferView(buffer=0, byteOffset=len(out), byteLength=bv.byteLength, byteStride=bv.byteStride,
                                   target=bv.target))
        out.extend(blob[bv.byteOffset:bv.byteOffset + bv.byteLength])
    g.bufferViews = newviews
    for a in g.accessors:
        if a.bufferView is not None:
            a.bufferView = vm[a.bufferView]
    for im in g.images or []:
        if im.bufferView is not None:
            im.bufferView = vm[im.bufferView]
    return bytes(out)


blob = compact(g, blob)
g.set_binary_blob(blob)
g.buffers[0].byteLength = len(blob)
g.save_binary(DST)
print("verts", len(Vn), "tris", len(In) // 3, "joints", len(skin.joints))
