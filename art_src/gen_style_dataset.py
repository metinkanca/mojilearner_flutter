# -*- coding: utf-8 -*-
"""Training images for a style model: the art the owner calls finished.

The owner (2026-10-18): the pets, the bosses and the home backgrounds are
exactly how the rest of the art should be. This renders those, as they are in
the app, into a set a LoRA can learn the style from:

  * pets and bosses: the app's own SVG, rasterised crisp at a whole number of
    pixels to a unit (so every art pixel stays one flat square), centred on a
    flat magenta 1024 x 1024 canvas -- the ground the props sheets use;
  * home scenes: 1024 x 1024 windows cut from the scene at a whole number of
    pixels to a unit, picked by hand so each holds objects, not empty sky;
  * a caption for each, in a .txt of the same name. Captions describe what is
    drawn and leave the style out (the trigger word carries that), which is
    what the trainers advise.

    python gen_style_dataset.py                  # -> style_dataset/ + .zip
    python gen_style_dataset.py --skip fox,seal  # leave pets out of the set

Pets that still want fixing go in SKIP_PETS (or --skip) so the model does not
learn their flaws. Output: style_dataset/NNN_name.png + .txt, manifest.json,
style_dataset.zip (what the trainer takes) and style_dataset_preview.png.
"""
import json
import os
import pathlib
import re
import subprocess
import sys
import tempfile
import zipfile

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
SVGS = os.path.normpath(os.path.join(HERE, '..', 'assets', 'svgs'))
OUT = os.path.join(HERE, 'style_dataset')
ZIP = os.path.join(HERE, 'style_dataset.zip')
PREVIEW = os.path.join(HERE, 'style_dataset_preview.png')

TRIGGER = 'mmkn'              # the word the style is tied to; unlike any real one
SIZE = 1024                   # the trainers want at least 1024 x 1024
MAGENTA = (255, 0, 255)
SKIP_PETS = []                # pets to leave out; --skip adds to it

# The pets as the app draws them: the seven reworked ones (3-unit pixels, whole
# sprite on the shared canvas) and the roster (2-unit pixels). Each: the file,
# pixels to an art unit, and what is drawn. Every pet is the house grey coat.
# The scale is the biggest whole one that keeps the sprite inside the canvas.
PETS = [
    ('cat2', 3, 'a grey cat sitting and facing the viewer, with whiskers and a curled tail'),
    ('dog2', 3, 'a grey puppy sitting and facing the viewer, with floppy dark grey ears'),
    ('bird2', 3, 'a round grey chick standing on two thin legs, with a darker belly patch and a brown cheek'),
    ('rabbit2', 3, 'a grey rabbit sitting and facing the viewer, with long upright ears with pink insides'),
    ('raccoon2', 3, 'a grey raccoon sitting and facing the viewer, with a dark eye mask and a ringed tail'),
    ('axolotl2', 3, 'a grey axolotl seen from the side, with red feathery gills and a red tail'),
    ('penguin2', 3, 'a grey penguin standing, with a cream belly, an orange beak and orange feet'),
    ('bat', 4, 'a small grey bat sitting, with large pink ears and folded wings'),
    ('beaver', 4, 'a grey beaver sitting, with buck teeth and a flat dark tail'),
    ('capybara', 4, 'a grey capybara seen from the side, with a dark snout'),
    ('chameleon', 4, 'a grey chameleon seen from the side, with a tightly curled tail'),
    ('chinchilla', 4, 'a grey chinchilla sitting, with round pink ears and a fluffy tail'),
    ('fennec', 4, 'a grey fennec fox sitting, with huge pink ears'),
    ('fox', 4, 'a grey fox sitting, with a cream chest and a fluffy cream-tipped tail'),
    ('frog', 4, 'a grey frog sitting, with a pale belly and a wide smile'),
    ('gecko', 4, 'a grey gecko seen from the side, with a curled tail'),
    ('hamster', 4, 'a plump grey hamster sitting and facing the viewer, with small round ears'),
    ('hedgehog', 4, 'a grey hedgehog seen from the side, with a spiky back and a cream face'),
    ('koala', 4, 'a grey koala sitting, with big round fluffy ears and a dark nose'),
    ('mouse', 4, 'a grey mouse sitting, with big round pink ears and a long pink tail'),
    ('otter', 4, 'a grey otter sitting upright, with a pale chest and belly'),
    ('panda', 4, 'a panda sitting, with dark ears, arms and legs and a pale belly'),
    ('parrot', 3, 'a grey parrot perched on a wooden stand, with a blue crest and blue and yellow wings'),
    ('piglet', 4, 'a grey piglet seen from the side, with a curly tail and a dark snout'),
    ('red-panda', 4, 'a grey red panda sitting, with cream ears and face markings and a ringed tail'),
    ('seal', 4, 'a grey seal lying on its belly, seen from the side'),
    ('skunk', 4, 'a grey skunk with a big white tail and a white stripe'),
    ('sloth', 4, 'a grey sloth sitting, with a pale face and dark eye patches'),
    ('squirrel', 4, 'a grey squirrel sitting, with a big dark bushy tail'),
    ('wombat', 4, 'a stout grey wombat seen from the side'),
]

# The bosses, each shut-mouthed and open-mouthed. Their art is finer (one art
# pixel to a unit) and carries more shading tones than the pets', so the
# captions say so: that keeps the extra shading tied to the boss words and
# not to the style, and props made later come out as flat as the pets.
BOSS_SCALE = 7
BOSSES = [
    ('mossback_boss', 'a huge mossy tortoise boss with a grey stone shell topped with green moss and spikes, a green head and legs and a cream belly'),
    ('amethyst_boss', 'a big purple bear-like boss with purple amethyst crystals on its back and head and a pale chest'),
    ('witch_boss', 'an owl boss in a purple witch hat with a gold buckle, perched on a broomstick, with big yellow eyes'),
    ('angler_boss', 'a blue anglerfish boss with a glowing golden lantern on a long stalk, striped fins and a wide smile with two small teeth'),
    ('sphinx_boss', 'a lion sphinx boss lying down, wearing a striped blue and gold headdress, with a cream chest'),
    ('dragon_boss', 'a red dragon boss with orange wings, cream horns, a cream belly and a flame on the tip of its tail'),
]
BOSS_TAIL = ', drawn with several extra shading and highlight tones'

# The home scenes: the file, pixels to a unit, and the windows, in units of the
# scene: (left, top, what the window holds). A window is SIZE / scale units.
SCENES = [
    ('cozy_room', 2, [
        (0, 500, 'a cozy room interior: a window with pink curtains on a cream wall above a wooden floor'),
        (340, 700, 'a cozy room interior: a small wooden bookshelf with books and a potted plant, a round pink pet bed, on a wooden floor'),
        (100, 1150, 'a cozy room interior: a big oval pink rug on a wooden plank floor'),
    ]),
    ('enchanted_meadow', 4, [
        (260, 120, 'the edge of a huge purple moon with craters, and small sparkling stars on a lilac night sky'),
        (520, 60, 'small sparkling stars in orange and white on a lilac night sky'),
        (60, 440, 'a lilac night sky with sparkling stars, a small floating island with teal crystals and the tip of an orange pointy roof'),
        (80, 830, 'the lower part of a white stone tower with round teal windows, purple bushes and teal crystals, on a purple ground'),
        (560, 830, 'orange mushrooms with white stems and a swirly purple tree, on a purple ground'),
    ]),
    ('mushroom_glade', 4, [
        (20, 840, 'a big red mushroom with white spots and two small ones beside teal bushes, on a teal ground under a light blue sky'),
        (600, 800, 'tall red spotted mushrooms with white stems, with small red mushrooms and teal bushes, on a teal ground under a light blue sky'),
        (560, 700, 'the cap of a big red mushroom with white spots against a light blue sky'),
    ]),
    ('pumpkin_patch', 3, [
        (20, 330, 'a crooked purple witch house with a pointed hat roof, a yellow glowing window and a round door, under a purple sky with stars'),
        (511, 700, 'a purple cauldron bubbling with green potion, jack-o-lanterns and orange pumpkins with green vines, on a green ground'),
        (0, 1100, 'a carved jack-o-lantern and orange pumpkins with curly green vines, on a green ground'),
        (0, 100, 'the pointed roof of a crooked purple witch house under a purple sky with purple sparkles and a floating green leaf'),
    ]),
]


def chrome():
    for p in ('C:/Program Files/Google/Chrome/Application/chrome.exe',
              'C:/Program Files (x86)/Google/Chrome/Application/chrome.exe',
              'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'):
        if os.path.exists(p):
            return p
    raise SystemExit('no Chrome or Edge here to rasterise the SVGs with')


def render(svg_name, scale):
    """The SVG as pixels, [scale] to a unit, on magenta. crispEdges keeps every
    edge on a pixel (no blended ones): the art is whole units."""
    path = os.path.join(SVGS, svg_name + '.svg')
    svg = open(path, encoding='utf-8').read()
    w, h = [float(v) for v in
            re.search(r'viewBox="([^"]+)"', svg).group(1).split()[2:]]
    W, H = int(round(w * scale)), int(round(h * scale))
    if 'shape-rendering' not in svg:
        svg = svg.replace('<svg ', '<svg shape-rendering="crispEdges" ', 1)
    with tempfile.TemporaryDirectory() as tmp:
        with open(os.path.join(tmp, 'a.svg'), 'w', encoding='utf-8',
                  newline='\n') as f:
            f.write(svg)
        html = os.path.join(tmp, 'a.html')
        with open(html, 'w', encoding='utf-8') as f:
            f.write('<!doctype html><html><body style="margin:0;'
                    'background:#ff00ff"><img src="a.svg" style="display:block;'
                    'width:%dpx;height:%dpx;image-rendering:pixelated">'
                    '</body></html>' % (W, H))
        shot = os.path.join(tmp, 'a.png')
        subprocess.run(
            [chrome(), '--headless', '--disable-gpu', '--hide-scrollbars',
             '--force-device-scale-factor=1', '--screenshot=' + shot,
             '--window-size=%d,%d' % (W, H), pathlib.Path(html).as_uri()],
            check=True, capture_output=True, timeout=180)
        im = Image.open(shot).convert('RGB')
        im.load()
    assert im.size == (W, H), (svg_name, im.size, (W, H))
    return im


def sprite(svg_name, scale):
    """A sprite centred on the magenta canvas."""
    im = render(svg_name, scale)
    a = np.asarray(im)
    ink = ~((a[..., 0] == 255) & (a[..., 1] == 0) & (a[..., 2] == 255))
    ys, xs = np.nonzero(ink)
    sp = im.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
    assert sp.width <= SIZE - 24 and sp.height <= SIZE - 24, (
        '%s is %dx%d at %dx: too big for the canvas' % (
            svg_name, sp.width, sp.height, scale))
    canvas = Image.new('RGB', (SIZE, SIZE), MAGENTA)
    canvas.paste(sp, ((SIZE - sp.width) // 2, (SIZE - sp.height) // 2))
    return canvas


def window(whole, scale, left, top):
    """A SIZE x SIZE window of a scene: [whole] is the scene at one pixel to a
    unit, the window is cut from it and enlarged with no blending."""
    span = SIZE // scale
    left = max(0, min(left, whole.width - span))
    top = max(0, min(top, whole.height - span))
    return whole.crop((left, top, left + span, top + span)).resize(
        (SIZE, SIZE), Image.NEAREST)


def build(skip):
    items = []                                   # (file name, image, caption)

    def add(name, im, caption):
        items.append(('%03d_%s' % (len(items) + 1, name), im,
                      '%s, %s' % (TRIGGER, caption)))

    for name, scale, what in PETS:
        key = name.rstrip('2')
        if key in skip or name in skip:
            continue
        add('pet_' + key, sprite(name, scale), what + ', on a flat magenta background')
    for name, what in BOSSES:
        key = name.replace('_boss', '')
        add('boss_' + key, sprite(name, BOSS_SCALE),
            what + BOSS_TAIL + ', on a flat magenta background')
        add('boss_%s_open' % key, sprite(name + '_open', BOSS_SCALE),
            what + ', with its mouth open' + BOSS_TAIL + ', on a flat magenta background')
    for name, scale, windows in SCENES:
        whole = render(name, 1)
        for i, (left, top, what) in enumerate(windows, 1):
            add('scene_%s_%d' % (name, i), window(whole, scale, left, top), what)
    return items


def preview(items, path, cols=8, cell=176):
    rows = (len(items) + cols - 1) // cols
    out = Image.new('RGB', (cols * cell, rows * (cell + 14)), (40, 40, 40))
    d = ImageDraw.Draw(out)
    for i, (name, im, _) in enumerate(items):
        x, y = (i % cols) * cell, (i // cols) * (cell + 14)
        out.paste(im.resize((cell - 4, cell - 4), Image.NEAREST), (x + 2, y + 14))
        d.text((x + 3, y + 1), name[4:], fill=(255, 255, 255))
    out.save(path)


def main(argv):
    skip = set(SKIP_PETS)
    if '--skip' in argv:
        skip |= set(argv[argv.index('--skip') + 1].split(','))
    items = build(skip)
    os.makedirs(OUT, exist_ok=True)
    for f in os.listdir(OUT):
        os.remove(os.path.join(OUT, f))
    manifest = []
    for name, im, caption in items:
        im.save(os.path.join(OUT, name + '.png'))
        with open(os.path.join(OUT, name + '.txt'), 'w', encoding='utf-8',
                  newline='\n') as f:
            f.write(caption + '\n')
        manifest.append({'image': name + '.png', 'caption': caption})
    with open(os.path.join(OUT, 'manifest.json'), 'w', encoding='utf-8',
              newline='\n') as f:
        json.dump(manifest, f, indent=1)
        f.write('\n')
    with zipfile.ZipFile(ZIP, 'w', zipfile.ZIP_DEFLATED) as z:
        for name, _, _ in items:
            z.write(os.path.join(OUT, name + '.png'), name + '.png')
            z.write(os.path.join(OUT, name + '.txt'), name + '.txt')
    preview(items, PREVIEW)
    kinds = [name[4:].split('_')[0] for name, _, _ in items]
    print('%d images (%d pets, %d bosses, %d scene windows), zip %.1f MB' % (
        len(items), kinds.count('pet'), kinds.count('boss'),
        kinds.count('scene'), os.path.getsize(ZIP) / 1e6))
    print('preview:', PREVIEW)


if __name__ == '__main__':
    main(sys.argv[1:])
