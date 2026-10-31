"""Reference contours from pet_goal.png at the existing pet canvas scale.

The image supplies shapes, not line weight: a three-cell (six art-unit)
border matches rabbit/hamster/parrot and sits within the cat/dog's 6-8 unit
range. Color gradients in the reference are reduced to the existing palette.
"""
from collections import Counter
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

import lib_roster as L

HERE = Path(__file__).resolve().parent
ORDER = [
    'fox', 'raccoon', 'red-panda', 'otter', 'hedgehog', 'chinchilla',
    'squirrel', 'mouse', 'bat', 'fennec', 'skunk', 'beaver',
    'koala', 'wombat', 'panda', 'sloth', 'capybara', 'piglet',
    'frog', 'axolotl', 'gecko', 'chameleon', 'seal', 'penguin',
]
# Some tails cross the sheet's nominal 256px columns. Explicit crops keep
# those borders closed and exclude the labels below each row.
CROPS = [
    (35,50,250,248), (265,60,485,248), (510,58,738,248),
    (765,78,960,248), (1030,95,1230,249), (1260,48,1502,249),
    (35,298,252,493), (282,320,473,493), (519,300,735,493),
    (775,282,1000,493), (1012,298,1255,494), (1262,328,1495,493),
    (33,545,249,736), (278,555,502,736), (548,534,743,736),
    (778,550,980,736), (1033,543,1270,736), (1290,555,1500,736),
    (46,803,220,958), (241,782,494,958), (511,795,739,958),
    (769,784,998,958), (1005,797,1268,958), (1313,780,1500,958),
]
# Points inside the reference's eyes. Explicit seeds distinguish a capybara's
# visible eye from nostrils, and a panda's eyes from its larger dark patches.
EYE_SEEDS = {
    'fox': [(170, 130), (218, 130)],
    'raccoon': [(386, 138), (433, 138)],
    'red-panda': [(644, 133), (693, 133)],
    'otter': [(874, 125), (925, 125)],
    'hedgehog': [(1158, 179), (1193, 179)],
    'chinchilla': [(1390, 136), (1435, 136)],
    'squirrel': [(187, 388), (233, 388)],
    'mouse': [(397, 398), (440, 398)],
    'bat': [(636, 397), (680, 397)],
    'fennec': [(877, 397), (925, 397)],
    'skunk': [(1180, 391), (1220, 391)],
    'beaver': [(1407, 374), (1454, 374)],
    'koala': [(130, 621), (184, 621)],
    'wombat': [(406, 635), (458, 635)],
    'panda': [(631, 608), (682, 608)],
    'sloth': [(880, 610), (933, 610)],
    'capybara': [(1170, 600)],
    'piglet': [(1408, 630), (1455, 630)],
    'frog': [(128, 838), (189, 838)],
    'axolotl': [(376, 864), (430, 864)],
    'gecko': [(655, 842), (712, 842)],
    'chameleon': [(929, 858), (977, 858)],
    'seal': [(1167, 846), (1210, 846)],
    'penguin': [(1409, 841), (1454, 841)],
}


def skeleton(mask):
    """Zhang-Suen thinning, preserving the shape of internal drawn lines."""
    a = np.pad(mask.astype(np.uint8), 1)
    while True:
        changed = False
        for phase in (0, 1):
            p = [a[:-2, 1:-1], a[:-2, 2:], a[1:-1, 2:], a[2:, 2:],
                 a[2:, 1:-1], a[2:, :-2], a[1:-1, :-2], a[:-2, :-2]]
            n = sum(p)
            turns = sum((p[i] == 0) & (p[(i+1) % 8] == 1) for i in range(8))
            if phase == 0:
                ends = (p[0]*p[2]*p[4] == 0) & (p[2]*p[4]*p[6] == 0)
            else:
                ends = (p[0]*p[2]*p[6] == 0) & (p[0]*p[4]*p[6] == 0)
            remove = (a[1:-1, 1:-1] != 0) & (n >= 2) & (n <= 6) & (turns == 1) & ends
            if remove.any():
                a[1:-1, 1:-1][remove] = 0
                changed = True
        if not changed:
            return a[1:-1, 1:-1].astype(bool)


def reference(pet):
    index = ORDER.index(pet)
    x0, y0, x1, y1 = CROPS[index]
    im = Image.open(HERE/'pet_goal.png').convert('RGB').crop((x0, y0, x1, y1))
    rgb = np.asarray(im)
    # The outline's antialiased pixels reach grey 100; thresholding only its
    # black center leaves cracks through which flood-fill eats the whole head.
    ink = rgb.max(axis=2) < 105
    filled = ndi.binary_fill_holes(ndi.binary_closing(ink, structure=np.ones((3,3))))
    labels, count = ndi.label(filled)
    sizes = np.bincount(labels.ravel())
    sizes[0] = 0
    shape = labels == sizes.argmax()
    ys, xs = np.where(shape)
    box = (int(xs.min()), int(ys.min()), int(xs.max()+1), int(ys.max()+1))
    l, t, r, b = box
    return rgb[t:b, l:r], shape[t:b, l:r], (x0+l, y0+t)


def eye_boxes(pet, rgb, offset, width, height):
    """Find reference eye rectangles, expressed in the output's two-unit grid."""
    ink = rgb.max(axis=2) < 15
    labels, _ = ndi.label(ink)
    boxes = []
    for gx, gy in EYE_SEEDS[pet]:
        x, y = gx-offset[0], gy-offset[1]
        # Small seed tolerance absorbs antialiasing at a point's edge.
        candidates = []
        for ny in range(max(0, y-5), min(ink.shape[0], y+6)):
            for nx in range(max(0, x-5), min(ink.shape[1], x+6)):
                if labels[ny, nx]:
                    candidates.append(((nx-x)**2+(ny-y)**2, labels[ny, nx]))
        if not candidates:
            raise ValueError(f'{pet}: no ink near eye {(gx, gy)}')
        component = labels == min(candidates)[1]
        ys, xs = np.where(component)
        l, t, r, b = xs.min(), ys.min(), xs.max()+1, ys.max()+1
        if r-l > 24 or b-t > 30:
            raise ValueError(f'{pet}: eye seed found a marking, bbox {(l,t,r,b)}')
        sx, sy = width/rgb.shape[1], height/rgb.shape[0]
        boxes.append((round(l*sx), round(t*sy), max(2, round((r-l)*sx)),
                      max(3, round((b-t)*sy))))
    if len(boxes) == 2:
        a, b = boxes
        y, w, h = min(a[1], b[1]), max(a[2], b[2]), max(a[3], b[3])
        boxes = [(a[0], y, w, h), (b[0], y, w, h)]
    return boxes


def clean_colors(grid, pet, roles, eyes):
    """Keep the existing flat palette; don't trace the PNG's mottled texture."""
    main, shade, light = roles
    moving = {main}
    for role in (shade, light):
        moving.update(() if role is None else (role,) if isinstance(role, str) else role)
    height, width = len(grid), len(grid[0])
    # Ear pink is a marking, not a substitute for the warm-colored shadow
    # under a cream chin. The reference's gradients can be equally close to
    # both; restrict these fixed pigments to their actual anatomical regions.
    ear_bottom = min(y for x,y,w,h in eyes)
    for y in range(height):
        for x in range(width):
            c = grid[y][x]
            if c in (None, L.OUTLINE) or c in moving:
                continue
            if pet in ('fennec','chinchilla','bat') and y >= ear_bottom:
                grid[y][x] = main
            elif pet == 'mouse' and y >= ear_bottom and x >= width*.32:
                grid[y][x] = main
    # The frog/lizard speckling is texture in the PNG. The requested change
    # is its border drawing, so don't introduce a new spotted coat.
    if pet in ('frog', 'gecko', 'chameleon') and isinstance(shade, str):
        grid = [[main if c == shade else c for c in row] for row in grid]
    # These lighter flecks are texture on dark fur/spines, not a pale belly.
    # Mapping them to the shared highlight tone would turn brown spines cream.
    if pet in ('hedgehog', 'skunk') and isinstance(light, str):
        grid = [[main if c == light else c for c in row] for row in grid]
    for fill in sorted(moving):
        mask = np.array([[c == fill for c in row] for row in grid])
        labels, count = ndi.label(mask)
        for i in range(1, count+1):
            component = labels == i
            if component.sum() >= 32:
                continue
            ring = ndi.binary_dilation(component) & ~component
            neighbors = Counter(grid[y][x] for y,x in zip(*np.where(ring))
                                if grid[y][x] not in (None,L.OUTLINE,fill))
            replacement = neighbors.most_common(1)[0][0] if neighbors else main
            for y,x in zip(*np.where(component)):
                grid[y][x] = replacement
    return grid


def trace(pet, width, height, colors, roles):
    rgb, silhouette, offset = reference(pet)
    eyes = eye_boxes(pet, rgb, offset, width, height)
    # Pixel-center sampling avoids inventing intermediate border colors.
    rgb = np.asarray(Image.fromarray(rgb).resize((width, height), Image.Resampling.BOX))
    shape = np.asarray(Image.fromarray(silhouette).resize((width, height), Image.Resampling.NEAREST))
    raw_ink = (rgb.max(axis=2) < 25) & shape
    raw_ink = ndi.binary_closing(raw_ink, structure=ndi.generate_binary_structure(2, 1))
    nonink = [c for c in colors if c != L.OUTLINE]
    palette = np.array([[int(c[i:i+2], 16) for i in (1, 3, 5)] for c in nonink])
    nearest = ((rgb.astype(float)[:, :, None, :] - palette)**2).sum(axis=3).argmin(axis=2)
    # Flat color regions use the family drawing grid. Ink is handled
    # separately so a minority-vote border or toe cannot vanish in this step.
    for y in range(0, height, 3):
        for x in range(0, width, 3):
            tile = nearest[y:y+3, x:x+3]
            valid = shape[y:y+3, x:x+3] & ~raw_ink[y:y+3, x:x+3]
            if valid.any():
                tile[:] = np.bincount(tile[valid], minlength=len(nonink)).argmax()
    # Remove eyes before widening lines. They are regenerated independently
    # for blinking, using the measured boxes returned above.
    for x, y, w, h in eyes:
        raw_ink[max(0,y-1):min(height,y+h+1), max(0,x-1):min(width,x+w+1)] = False
    edge = shape & ~ndi.binary_erosion(shape, iterations=3, border_value=0)
    inner = raw_ink & ndi.binary_erosion(shape, iterations=3, border_value=0)
    widened = ndi.binary_dilation(skeleton(inner), structure=np.ones((3, 3)))
    internal_lines = ndi.binary_closing(inner | widened, structure=np.ones((3,3)))
    ink = edge | (internal_lines & shape)
    out = [[None if not shape[y,x] else L.OUTLINE if ink[y,x]
            else nonink[nearest[y,x]] for x in range(width)] for y in range(height)]
    out = clean_colors(out, pet, roles, eyes)
    # Continue the actual facial marking behind a blink. Using main coat for
    # every pet punched pale rectangles into the raccoon/panda eye patches.
    eye_backing = {
        'raccoon': '#49463f', 'panda': '#393936', 'sloth': '#78583b',
        'hedgehog': '#ffe0a7', 'penguin': '#f8e7c5',
    }.get(pet, roles[0])
    for x,y,w,h in eyes:
        # Color was sampled on three-cell tiles. Clear the complete tiles
        # beneath an eye as well as its pixel box; otherwise the black source
        # pupil leaves a brown/grey fringe beside the regenerated colored eye.
        left, top = (x//3)*3, (y//3)*3
        right, bottom = min(width, ((x+w+2)//3)*3), min(height, ((y+h+2)//3)*3)
        for j in range(top,bottom):
            for i in range(left,right):
                out[j][i] = eye_backing
    return out, eyes
