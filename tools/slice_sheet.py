#!/usr/bin/env python3
"""Slice the Prabowo character design sheet into per-animation frame folders.

The sheet is not a uniform grid: it has labeled strips (Idle/Walk/Run/Hurt/...).
For each named BAND (a rectangle covering one strip) we split figures by empty
vertical columns, trim each, and bottom-center it on a common canvas so the feet
share a baseline (the engine aligns on the feet 'axis').

Output: assets/prabowo/<anim>/000.png ... + a verification montage.
Edit BANDS coords if a strip is mis-captured. Requires Pillow.
"""
import os
from PIL import Image

SRC = "assets/prabowo/Pixel Art Politician Character Sprite Sheet-2.png"
OUT = "assets/prabowo"
CANVAS = (120, 150)          # per-frame canvas (w,h); axis = bottom-center
MIN_W = 28                   # ignore column runs narrower than this (noise/labels)
GAP = 6                      # empty-column run >= this splits two figures

# name -> (x0, y0, x1, y1, count): band rectangle + how many frames to split into
# (equal-width cells). Tune coords/counts if a strip is mis-captured.
BANDS = {
    "idle":      (0,   895, 330, 1040, 4),
    "walk_fwd":  (330, 895, 700, 1040, 5),
    "run":       (700, 895, 1024, 1040, 4),
    "hurt":      (0,  1312, 395, 1465, 4),
}


def col_opaque(band, x):
    return band.crop((x, 0, x + 1, band.height)).getchannel("A").getbbox() is not None


def split_figures(band):
    w = band.width
    runs, start = [], None
    for x in range(w):
        if col_opaque(band, x):
            if start is None:
                start = x
        else:
            if start is not None and x - start >= 1:
                runs.append((start, x))
                start = None
    if start is not None:
        runs.append((start, w))
    # merge runs separated by < GAP (same figure), drop too-narrow
    merged = []
    for r in runs:
        if merged and r[0] - merged[-1][1] < GAP:
            merged[-1] = (merged[-1][0], r[1])
        else:
            merged.append(list(r))
    return [tuple(r) for r in merged if r[1] - r[0] >= MIN_W]


def dekey(img):
    """Remove the light NEUTRAL-grey backing panel baked behind the strips, while
    keeping Prabowo's WARM cream uniform/skin (R>G>B). Panel pixels are near-grey
    (max-min channels small) and bright."""
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 0 and (max(r, g, b) - min(r, g, b)) <= 14 and min(r, g, b) >= 190:
                px[x, y] = (r, g, b, 0)
    return img


def place(fig):
    fig = fig.crop(fig.getbbox())
    cw, ch = CANVAS
    # scale down if taller/wider than canvas, keep aspect
    scale = min(cw / fig.width, ch / fig.height, 1.0)
    if scale < 1.0:
        fig = fig.resize((max(1, int(fig.width * scale)), max(1, int(fig.height * scale))), Image.NEAREST)
    canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    x = (cw - fig.width) // 2
    y = ch - fig.height            # feet on the bottom edge
    canvas.alpha_composite(fig, (x, y))
    return canvas


def main():
    sheet = Image.open(SRC).convert("RGBA")
    montage_rows = []
    for name, (x0, y0, x1, y1, count) in BANDS.items():
        band = sheet.crop((x0, y0, x1, y1))
        cell = band.width / count
        d = os.path.join(OUT, name)
        os.makedirs(d, exist_ok=True)
        for fn in os.listdir(d):
            if fn.endswith(".png"):
                os.remove(os.path.join(d, fn))
        frames = []
        for i in range(count):
            cx0 = int(round(i * cell))
            cx1 = int(round((i + 1) * cell))
            cellimg = band.crop((cx0, 0, cx1, band.height))
            cellimg = dekey(cellimg)
            if cellimg.getbbox() is None:
                continue
            out = place(cellimg)
            out.save(os.path.join(d, "%03d.png" % len(frames)))
            frames.append(out)
        print(f"{name}: {len(frames)} frames -> {d}")
        # montage row
        row = Image.new("RGBA", (CANVAS[0] * max(1, len(frames)), CANVAS[1]), (40, 40, 48, 255))
        for i, fr in enumerate(frames):
            row.alpha_composite(fr, (i * CANVAS[0], 0))
        montage_rows.append((name, row))
    # build montage
    mw = max(r.width for _, r in montage_rows)
    mh = sum(r.height for _, r in montage_rows)
    montage = Image.new("RGBA", (mw, mh), (20, 20, 24, 255))
    yy = 0
    for _, r in montage_rows:
        montage.alpha_composite(r, (0, yy))
        yy += r.height
    # walk_back = reuse walk_fwd frames (engine flips by facing).
    import shutil
    wf, wb = os.path.join(OUT, "walk_fwd"), os.path.join(OUT, "walk_back")
    if os.path.isdir(wf):
        if os.path.isdir(wb):
            shutil.rmtree(wb)
        shutil.copytree(wf, wb)
        print("walk_back: copied from walk_fwd")

    montage.save("/tmp/prabowo_montage.png")
    print("montage -> /tmp/prabowo_montage.png")


if __name__ == "__main__":
    main()
