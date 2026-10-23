#!/usr/bin/env python3
"""Generate a manifest.json for a hero sprite directory (for the Fight engine).

Usage:  python3 tools/make_manifest.py assets/<hero_dir>

Scans each animation subfolder (idle/, walk_fwd/, stand_lp/, ...), counts the
NNN.png frames, reads the canvas size from the first frame, and writes
<hero_dir>/manifest.json. Defaults: 5 ticks/frame, axis = center-bottom of the
canvas, loop = true for idle/walk*/run/crouch/guard*. Review `axis` afterwards so
the feet sit on the floor line, and tune `durs` for timing.
"""
import json
import os
import struct
import sys

LOOPING = ("idle", "walk_fwd", "walk_back", "run", "crouch", "guard", "guard_crouch")
DEFAULT_DUR = 5


def png_size(path):
    """Return (w, h) by reading the PNG IHDR chunk (no external deps)."""
    with open(path, "rb") as f:
        head = f.read(24)
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path} is not a PNG")
    w, h = struct.unpack(">II", head[16:24])
    return w, h


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)
    base = sys.argv[1].rstrip("/")
    if not os.path.isdir(base):
        print(f"Not a directory: {base}")
        sys.exit(1)

    anims = {}
    canvas = None
    for name in sorted(os.listdir(base)):
        d = os.path.join(base, name)
        if not os.path.isdir(d):
            continue
        frames = sorted(fn for fn in os.listdir(d) if fn.lower().endswith(".png"))
        if not frames:
            continue
        if canvas is None:
            canvas = list(png_size(os.path.join(d, frames[0])))
        anims[name] = {
            "frames": len(frames),
            "durs": [DEFAULT_DUR] * len(frames),
            "loop": name in LOOPING,
        }

    if not anims:
        print(f"No animation folders with PNGs found under {base}")
        sys.exit(1)
    if canvas is None:
        canvas = [64, 64]

    manifest = {
        "canvas": canvas,
        "axis": [canvas[0] // 2, canvas[1] - 1],  # center-bottom; adjust to the feet
        "anims": anims,
    }
    out = os.path.join(base, "manifest.json")
    with open(out, "w") as f:
        json.dump(manifest, f, indent=2)
    print(f"Wrote {out}: {len(anims)} anims, canvas {canvas}, axis {manifest['axis']}")
    print("→ Periksa 'axis' (titik tumpu kaki) dan 'durs' (timing) lalu sesuaikan.")


if __name__ == "__main__":
    main()
