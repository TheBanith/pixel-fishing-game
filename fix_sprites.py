#!/usr/bin/env python3
"""Fix sprite backgrounds: drop near-black and dark-magenta fringe to transparent."""
import os, sys
from PIL import Image

ASSETS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "assets")
# ponytail: single sprite pair; append more (src_jpg, out_png) tuples if needed
SRC = [
    ("pixel_art_16-bit_retro_pixel_a.jpg", "fisherman.png"),
    ("pixel_art_16-bit_retro_pixel_a (3).jpg", "dock.png"),
]

def fix(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if r < 15 and g < 15 and b < 15:          # near-black
                px[x, y] = (0, 0, 0, 0)
            elif r > 60 and b > 60 and g < 40:        # dark magenta/purple fringe
                px[x, y] = (0, 0, 0, 0)
    return img

def main():
    for src, out in SRC:
        path = os.path.join(ASSETS, src)
        if not os.path.exists(path):
            print(f"skip (missing): {path}")
            continue
        fix(Image.open(path)).save(os.path.join(ASSETS, out))
        print(f"wrote {out}")

def selftest():
    im = Image.new("RGB", (3, 1), (0, 0, 0))
    im.putpixel((1, 0), (200, 10, 200))   # dark magenta -> clear
    im.putpixel((2, 0), (100, 100, 100))  # grey -> keep
    out = fix(im)
    assert out.getpixel((0, 0))[3] == 0, "black not cleared"
    assert out.getpixel((1, 0))[3] == 0, "magenta not cleared"
    assert out.getpixel((2, 0))[3] == 255, "grey wrongly cleared"
    print("selftest OK")

if __name__ == "__main__":
    selftest() if sys.argv[1:] == ["--test"] else main()
