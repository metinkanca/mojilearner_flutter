"""Rebuilds the app's cozy room from the SVG you edit.

    edit  art_src/cozy-room-clean.svg   (in Inkscape, layers and all)
    run   python art_src/build_cozy_room.py
    get   assets/svgs/cozy_room.svg     (what the app loads)

The app does not load the file you edit, and should not. That one is built for
editing: an object is an outline plus its fills, side by side. The app's copy
is built for drawing: one path per colour, each fill grown a pixel under the
ink around it, so no two shapes share an edge and no hairline shows at a
fractional scale (flutter_svg ignores crispEdges). Hand-editing that one would
be miserable, and deleting a black pixel in it would reveal what is painted
beneath instead of the wall.

So this renders your file as it looks, reads the pixels, and writes the app's
copy from them. Because it works from the picture and not from the file's
syntax, it does not care how Inkscape saved it: curves, transforms, style
attributes and off-grid nodes all come out as the pixels they paint.

Keep to the room's six colours:

    wall #f2e3c6   wood #c58c56   glass #a8dcef
    coral #e98a7b  leaf #8cc56a   ink   #14120e

A seventh colour stops the build and says where it is (--snap rounds stray
colours to the nearest of the six instead). The window glass in particular is
named in the night tint in lib/constants/scenes.dart, so changing it there
means changing it here.

After a rebuild, hot RESTART the app: hot reload keeps the old picture cached.

Usage:  python build_cozy_room.py [file.svg] [--watch] [--snap] [--out path]

  --watch  rebuild every time the file is saved, until Ctrl+C
"""
from pathlib import Path

import scene_art

HERE = Path(__file__).resolve().parent

if __name__ == '__main__':
    scene_art.main(
        scene_art.COZY_ROOM,
        default_src=HERE / 'cozy-room-clean.svg',
        default_out=HERE.parent / 'assets' / 'svgs' / 'cozy_room.svg',
        what='cozy room')
