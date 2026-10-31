"""Rebuilds the app's enchanted meadow from the SVG you edit.

    edit  art_src/enchanted-meadow-editable.svg   (in Inkscape, layers and all)
    run   python art_src/build_enchanted_meadow.py
    get   assets/svgs/enchanted_meadow.svg        (what the app loads)

Unlike the cozy room there is no separate "clean" copy: this file was already
tidy when it arrived. Every edge sits on its 2px grid, there is no stray
colour, and every outline is closed. What it needed was the app copy, which is
built here (see scene_art.py for why the app does not load the file you edit).

The picture is drawn on a 2px grid: one square of the art is 2x2 pixels, and
snapping to it is what keeps the pixels crisp at any phone size. After a build
the script lists anything that leaves the grid, so an edit with a stray odd
coordinate is caught instead of quietly drawn as a sliver.

Keep to the scene's seven colours:

    sky    #d9c8f0   ground #9a7cc8   shade #70549b   stone #f6f0dc
    gold   #f0a93c   mint   #8fe3d0   ink   #14120e

An eighth colour stops the build and says where it is (--snap rounds stray
colours to the nearest of the seven instead). Mint and gold are named in the
night tint in lib/constants/scenes.dart, so changing either means changing it
there too.

The gold flowers have off-white centres that touch the gold with no outline
between them, on purpose; those are not reported as gaps.

After a rebuild, hot RESTART the app: hot reload keeps the old picture cached.

Usage:  python build_enchanted_meadow.py [file.svg] [--watch] [--snap] [--out path]

  --watch  rebuild every time the file is saved, until Ctrl+C
"""
from pathlib import Path

import scene_art

HERE = Path(__file__).resolve().parent

if __name__ == '__main__':
    scene_art.main(
        scene_art.ENCHANTED_MEADOW,
        default_src=HERE / 'enchanted-meadow-editable.svg',
        default_out=HERE.parent / 'assets' / 'svgs' / 'enchanted_meadow.svg',
        what='enchanted meadow')
