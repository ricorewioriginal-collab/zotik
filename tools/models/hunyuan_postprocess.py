#!/usr/bin/env python3
"""Post-processes a raw Hunyuan3D-2.1 GLB into a game-ready PLACEHOLDER test model.

Steps: drop the generated ground plate, keep the figure, decimate, put the feet
at y=0 (height 1.0, facing +Z), and - when the mesh came back untextured -
project the reference image onto it as vertex colours (front projection with
a depth test; back-facing / hidden vertices take a blurred colour of the same
region). Output is a single-material GLB with COLOR_0.

pip install trimesh fast-simplification pillow numpy scipy
usage: hunyuan_postprocess.py raw.glb reference.png out.glb [target_faces]
"""
import sys
import numpy as np
import trimesh
import fast_simplification
from PIL import Image, ImageFilter

raw, ref, out = sys.argv[1:4]
target = int(sys.argv[4]) if len(sys.argv) > 4 else 24000

m = trimesh.load(raw, force="mesh", process=True)
v, f = m.vertices, m.faces
# 1) ground plate: faces lying flat at the very bottom of the bounds
ymin = v[:, 1].min()
low = (v[f][:, :, 1] < ymin + 0.02).all(axis=1)
m.update_faces(~low)
m.remove_unreferenced_vertices()
# keep components that are big enough (figure, sword, tail), drop specks
parts = m.split(only_watertight=False)
parts = sorted(parts, key=lambda p: len(p.faces), reverse=True)
keep = [p for p in parts if len(p.faces) > 0.01 * len(parts[0].faces)]
m = trimesh.util.concatenate(keep)
print("faces after cleanup", len(m.faces), "components", len(keep), "of", len(parts))

# 2) decimate
ratio = max(0.0, 1.0 - target / len(m.faces))
vs, fs = fast_simplification.simplify(m.vertices.astype(np.float32), m.faces.astype(np.int32), ratio)
m = trimesh.Trimesh(vs, fs, process=True)
print("faces after decimation", len(m.faces))

# 3) normalise: feet on y=0, height 1, centred on x/z of the lower body
v = m.vertices
lo, hi = v.min(axis=0), v.max(axis=0)
h = hi[1] - lo[1]
legs = v[v[:, 1] < lo[1] + 0.25 * h]
centre = np.array([np.median(legs[:, 0]), lo[1], np.median(legs[:, 2])])
m.vertices = (v - centre) / h
v = m.vertices
n = m.vertex_normals

# 4) colours: front projection of the reference image
img = Image.open(ref).convert("RGB")
W, H = img.size
arr = np.asarray(img).astype(np.float32) / 255.0
# foreground mask of the reference (background = sky/frame: low saturation or bluish)
mx, mn = arr.max(axis=2), arr.min(axis=2)
sat = (mx - mn) / np.maximum(mx, 1e-3)
bluish = (arr[:, :, 2] > arr[:, :, 0] + 0.02)
fg = (sat > 0.25) & ~bluish
# background pixels take the colour of the nearest foreground pixel (no sky fringe at the silhouette)
from scipy.ndimage import distance_transform_edt, binary_erosion
core = binary_erosion(fg, iterations=2)
_, (iy, ix) = distance_transform_edt(~core, return_indices=True)
arr = arr[iy, ix]
blur = np.asarray(Image.fromarray((arr * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(18))).astype(np.float32) / 255.0
# silhouette of the mesh, front orthographic (x right, y up)
def raster_depth(scale, ox, oy):
    """z-buffer of the mesh projected into image pixels: px = ox + x*scale, py = oy - y*scale"""
    zb = np.full((H, W), -np.inf, dtype=np.float32)
    px = ox + v[:, 0] * scale
    py = oy - v[:, 1] * scale
    for tri in m.faces:
        xs, ys, zs = px[tri], py[tri], v[tri, 2]
        x0, x1 = int(max(0, np.floor(xs.min()))), int(min(W - 1, np.ceil(xs.max())))
        y0, y1 = int(max(0, np.floor(ys.min()))), int(min(H - 1, np.ceil(ys.max())))
        if x0 > x1 or y0 > y1:
            continue
        gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        d = (ys[1] - ys[2]) * (xs[0] - xs[2]) + (xs[2] - xs[1]) * (ys[0] - ys[2])
        if abs(d) < 1e-9:
            continue
        a = ((ys[1] - ys[2]) * (gx - xs[2]) + (xs[2] - xs[1]) * (gy - ys[2])) / d
        b = ((ys[2] - ys[0]) * (gx - xs[2]) + (xs[0] - xs[2]) * (gy - ys[2])) / d
        c = 1 - a - b
        inside = (a >= -1e-4) & (b >= -1e-4) & (c >= -1e-4)
        if not inside.any():
            continue
        z = a * zs[0] + b * zs[1] + c * zs[2]
        sub = zb[y0:y1 + 1, x0:x1 + 1]
        upd = inside & (z > sub)
        sub[upd] = z[upd]
    return zb

# align: the figure's height spans the foreground's rows; search x offset/scale on a coarse grid (vertex splat IoU)
rows = np.where(fg.mean(axis=1) > 0.02)[0]
top, bot = rows.min(), rows.max()
best = None
for s in np.linspace(0.9, 1.1, 9) * (bot - top):
    for oxf in np.linspace(0.3, 0.7, 41):
        ox, oy = oxf * W, bot
        px = (ox + v[:, 0] * s).astype(int)
        py = (oy - v[:, 1] * s).astype(int)
        ok = (px >= 0) & (px < W) & (py >= 0) & (py < H)
        score = fg[py[ok], px[ok]].mean() * ok.mean()
        if best is None or score > best[0]:
            best = (score, s, ox, oy)
_, s, ox, oy = best
print("alignment score %.3f scale %.1f ox %.1f oy %.1f" % best)
zb = raster_depth(s, ox, oy)
px = np.clip(ox + v[:, 0] * s, 0, W - 1).astype(int)
py = np.clip(oy - v[:, 1] * s, 0, H - 1).astype(int)
visible = (v[:, 2] >= zb[py, px] - 0.02) & (n[:, 2] > 0.0)
front = arr[py, px]
back = blur[py, px]
w = np.clip(n[:, 2] * 3.0, 0.0, 1.0) * visible
col = front * w[:, None] + back * (1 - w[:, None])
print("vertices front-visible %.1f%%" % (100 * visible.mean()))
m.visual = trimesh.visual.ColorVisuals(m, vertex_colors=np.c_[np.clip(col * 255, 0, 255), np.full(len(col), 255)].astype(np.uint8))
m.export(out)
print("wrote", out, len(m.vertices), "verts", len(m.faces), "faces")
