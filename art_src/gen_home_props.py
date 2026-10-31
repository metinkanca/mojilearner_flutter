"""Cuts one piece out of a generated home-props sheet and prints it as the
pixel-grid rows `lib/components/home_action_bar.dart` draws.

The sheet is the 3x4 props sheet made from the prompt in ROADMAP item 10, one
object per cell on magenta. The tool draws on no real pixel grid, so the piece
is read at `--cell` source pixels to a cell (about half the sheet's own
chunkiness, which keeps the oblique edges), snapped to the cozy room's six
colours, and cleaned: only the colours the piece should use, no specks, a
closed one-cell outline, and the largest blob kept.

    python gen_home_props.py home-props-sheet-v2.png 5 --colours Xwscl
        (piece 5 = row 2, column 2, counting 0.. in reading order)

Prints the Dart list; paste it over the matching rows in home_action_bar.dart.
"""
import argparse
import numpy as np
from PIL import Image
from scipy import ndimage

PAL = {'X': (0x14, 0x12, 0x0e), 'w': (0xf2, 0xe3, 0xc6), 'o': (0xc5, 0x8c, 0x56),
       's': (0xa8, 0xdc, 0xef), 'c': (0xe9, 0x8a, 0x7b), 'l': (0x8c, 0xc5, 0x6a)}


def is_magenta(px):
    return (abs(px[..., 0] - 255) < 80) & (px[..., 1] < 120) & (abs(px[..., 2] - 255) < 80)


def pieces(a):
    fg = ~is_magenta(a)
    lab, _ = ndimage.label(ndimage.binary_dilation(fg, iterations=5))
    boxes = [(s[0].start, s[0].stop, s[1].start, s[1].stop)
             for s in ndimage.find_objects(lab)
             if (s[0].stop - s[0].start) * (s[1].stop - s[1].start) > 3000]
    return sorted(boxes, key=lambda b: (round(b[0] / 250), b[2]))


def quantise(sub, cell, ink_share=0.4, ox=0.5, oy=0.25):
    keys = list(PAL)
    cols = np.array([PAL[k] for k in keys])
    h, w = sub.shape[:2]
    rows = []
    for cy in range(int((h - oy) // cell + 1)):
        r = ''
        for cx in range(int((w - ox) // cell + 1)):
            blk = sub[int(oy + cy * cell):int(oy + (cy + 1) * cell),
                      int(ox + cx * cell):int(ox + (cx + 1) * cell)].reshape(-1, 3)
            if len(blk) == 0 or is_magenta(blk).mean() > 0.5:
                r += '.'
                continue
            blk = blk[~is_magenta(blk)]
            near = ((blk[:, None, :] - cols[None]) ** 2).sum(2).argmin(1)
            share = np.bincount(near, minlength=len(keys)) / len(blk)
            if share[0] >= ink_share:
                r += 'X'
            else:
                share[0] = 0
                r += keys[share.argmax()]
        rows.append(list(r))
    return rows


def clean(rows, colours):
    h, w = len(rows), len(rows[0])
    fills = [c for c in colours if c != 'X']

    def at(y, x):
        return rows[y][x] if 0 <= y < h and 0 <= x < w else '.'

    def around(y, x):
        return [at(y + dy, x + dx) for dy in (-1, 0, 1) for dx in (-1, 0, 1) if dy or dx]

    for _ in range(2):
        new = [r[:] for r in rows]
        for y in range(h):
            for x in range(w):
                ch = rows[y][x]
                if ch == '.':
                    continue
                nb = around(y, x)
                cand = [n for n in nb if n in fills]
                vote = max(set(cand), key=cand.count) if cand else 'X'
                if ch not in colours or (ch != 'X' and sum(n == ch for n in nb) <= 1) \
                        or (ch == 'X' and not any(n == 'X' for n in nb)):
                    new[y][x] = vote
        rows = new
    new = [r[:] for r in rows]
    for y in range(h):
        for x in range(w):
            if rows[y][x] != '.' and any(at(y + dy, x + dx) == '.'
                                          for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                new[y][x] = 'X'
    rows = new
    m = np.array([[c != '.' for c in r] for r in rows])
    lab, n = ndimage.label(m, structure=np.ones((3, 3)))
    keep = 1 + int(np.argmax(ndimage.sum(m, lab, range(1, n + 1))))
    txt = [''.join(c if lab[y][x] == keep else '.' for x, c in enumerate(r))
           for y, r in enumerate(rows)]
    return trim(txt)


def trim(txt):
    # Empty rows, and the one-cell nubs the read leaves on a peak.
    thin = lambda r: sum(c != '.' for c in r) < 6
    while thin(txt[0]):
        txt.pop(0)
    while thin(txt[-1]):
        txt.pop()
    left = min(len(r) - len(r.lstrip('.')) for r in txt)
    right = max(len(r.rstrip('.')) for r in txt)
    return [r[left:right] for r in txt]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('sheet')
    ap.add_argument('piece', type=int)
    ap.add_argument('--cell', type=float, default=3.43)
    ap.add_argument('--colours', default='Xwscl', help='the palette letters the piece may use')
    ap.add_argument('--name', default='pieceRows')
    args = ap.parse_args()
    a = np.array(Image.open(args.sheet).convert('RGB')).astype(int)
    y0, y1, x0, x1 = pieces(a)[args.piece]
    txt = clean(quantise(a[y0:y1, x0:x1], args.cell), args.colours + '.')
    print(f'const List<String> {args.name} = [')
    for r in txt:
        print(f"  '{r}',")
    print('];')


if __name__ == '__main__':
    main()
