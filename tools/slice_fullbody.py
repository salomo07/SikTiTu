#!/usr/bin/env python3
"""Slice ONE full-body standing sprite into cutout-rig parts (first-pass).

Usage:  python3 tools/slice_fullbody.py assets/prabowo/fullbody.png

Finds the opaque bounding box of the figure and cuts it into parts by human
proportions, writing PNGs (transparency kept) to <same dir>/parts/:
  Head Torso ArmFrontUpper ArmFrontLower ArmBackUpper ArmBackLower
  LegFrontUpper LegFrontLower LegBackUpper LegBackLower

This is a ROUGH first pass (a straight-standing pose has arms overlapping the
torso). Open the parts in any editor to clean the seams, then drop them into
fight/rig/hero_rig.tscn slots (or let RigAnimator.load_parts auto-load by name)
and nudge each part's pivot/offset in the Godot editor.

Requires Pillow:  pip install pillow
"""
import os
import sys

try:
    from PIL import Image
except ImportError:
    print("Butuh Pillow: pip install pillow")
    sys.exit(1)


def opaque_bbox(img):
    bbox = img.getbbox()  # bounding box of non-zero (incl. alpha) region
    return bbox if bbox else (0, 0, img.width, img.height)


def save(img, box, out):
    img.crop(box).save(out)
    print("  ", os.path.basename(out), box)


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)
    src = sys.argv[1]
    img = Image.open(src).convert("RGBA")
    x0, y0, x1, y1 = opaque_bbox(img)
    w, h = x1 - x0, y1 - y0
    outdir = os.path.join(os.path.dirname(src) or ".", "parts")
    os.makedirs(outdir, exist_ok=True)

    cx = x0 + w // 2
    # Vertical bands (fractions of figure height).
    head_b = y0 + int(h * 0.00), y0 + int(h * 0.20)
    torso_b = y0 + int(h * 0.18), y0 + int(h * 0.52)
    thigh_b = y0 + int(h * 0.50), y0 + int(h * 0.76)
    shin_b = y0 + int(h * 0.74), y1
    # Arm columns: outer thirds over the torso band, split upper/lower at mid.
    arm_mid = y0 + int(h * 0.35)
    arm_w = max(6, int(w * 0.22))

    print(f"Figure bbox {(x0, y0, x1, y1)} ({w}x{h}) -> {outdir}")
    save(img, (cx - w // 4, head_b[0], cx + w // 4, head_b[1]), f"{outdir}/Head.png")
    save(img, (cx - int(w * 0.22), torso_b[0], cx + int(w * 0.22), torso_b[1]), f"{outdir}/Torso.png")
    # Front = figure's left on screen (facing right). Back = right side.
    save(img, (x0, torso_b[0], x0 + arm_w, arm_mid), f"{outdir}/ArmFrontUpper.png")
    save(img, (x0, arm_mid, x0 + arm_w, torso_b[1]), f"{outdir}/ArmFrontLower.png")
    save(img, (x1 - arm_w, torso_b[0], x1, arm_mid), f"{outdir}/ArmBackUpper.png")
    save(img, (x1 - arm_w, arm_mid, x1, torso_b[1]), f"{outdir}/ArmBackLower.png")
    # Legs: split figure into left/right halves.
    save(img, (cx - int(w * 0.26), thigh_b[0], cx, thigh_b[1]), f"{outdir}/LegFrontUpper.png")
    save(img, (cx - int(w * 0.26), shin_b[0], cx, shin_b[1]), f"{outdir}/LegFrontLower.png")
    save(img, (cx, thigh_b[0], cx + int(w * 0.26), thigh_b[1]), f"{outdir}/LegBackUpper.png")
    save(img, (cx, shin_b[0], cx + int(w * 0.26), shin_b[1]), f"{outdir}/LegBackLower.png")
    print("Selesai. Bersihkan seam di editor, lalu atur pivot tiap part di Godot.")


if __name__ == "__main__":
    main()
