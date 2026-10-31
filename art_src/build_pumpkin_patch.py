"""Rebuilds the app's pumpkin patch from the SVG you edit.

    edit  art_src/pumpkin-patch-editable.svg   (in Inkscape, layers and all)
    run   python art_src/build_pumpkin_patch.py
    get   assets/svgs/pumpkin_patch.svg        (what the app loads)

The master came from the owner's PNG by gen_pumpkin_patch.py, a one-time
conversion; from here on it is edited in place and the app copy is built from
it (see scene_art.py for why the app does not load the file you edit).

The picture is drawn on a 3px grid: one square of the art is 3x3 pixels, and
the outline is two of them thick. Snapping to the grid is what keeps the pixels
crisp at any phone size. After a build the script lists anything that leaves
the grid, so an edit with a stray odd coordinate is caught instead of quietly
drawn as a sliver.

Keep to the scene's six colours:

    sky  #b99cd8   grass  #88ca62   purple  #58348d   orange  #fb8630
    yellow  #f9df62   ink  #14120e

The stars and the bubbles are drawn with no outline, purple and green straight
on the sky, so those contacts are not reported as gaps. A seventh colour stops
the build and says where it is (--snap rounds stray colours to the nearest of
the six instead). Yellow, purple and the outline are named in the night tint in
lib/constants/scenes.dart, so changing any of them means changing it there too.

After a rebuild, hot RESTART the app: hot reload keeps the old picture cached.

Usage:  python build_pumpkin_patch.py [file.svg] [--watch] [--snap] [--out path]

  --watch  rebuild every time the file is saved, until Ctrl+C
"""
from pathlib import Path

import scene_art

HERE = Path(__file__).resolve().parent

if __name__ == '__main__':
    scene_art.main(
        scene_art.PUMPKIN_PATCH,
        default_src=HERE / 'pumpkin-patch-editable.svg',
        default_out=HERE.parent / 'assets' / 'svgs' / 'pumpkin_patch.svg',
        what='pumpkin patch')
