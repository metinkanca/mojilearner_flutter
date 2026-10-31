"""Rebuilds the app's mushroom glade from the SVG you edit.

    edit  art_src/mushroom-glade-editable.svg   (in Inkscape, layers and all)
    run   python art_src/build_mushroom_glade.py
    get   assets/svgs/mushroom_glade.svg        (what the app loads)

Like the enchanted meadow there is no separate "clean" copy: the file is edited
in place and the app copy is built from it (see scene_art.py for why the app
does not load the file you edit).

The picture is drawn on a 2px grid, so snapping to it is what keeps the pixels
crisp at any phone size. After a build the script lists anything that leaves
the grid, so an edit with a stray odd coordinate is caught instead of quietly
drawn as a sliver.

Keep to the scene's five colours:

    sky  #a8dcef   moss  #5db89a   cream  #f6f0dc   cap  #e8766a   ink  #14120e

The moss is the ground and the clumps at its edge. It was a yellow-green
(#8cc56a) until a glade of giant toadstools was thought to want something more
mystical; it is a cool jade now. A sixth colour stops the build and says where
it is (--snap rounds stray colours to the nearest of the five instead). Moss
and cap are named in the night tint in lib/constants/scenes.dart, so changing
either means changing it there too.

The caps' cream spots touch the red with no outline between them, on purpose;
those are not reported as gaps.

The app's copy has one colour more than the file you edit. Any cream that
touches a cap is a spot, and the build paints the spots in #f6f0dd, one unit
off the stems' cream, so that night can keep them cream while the stems go
dark (it is named in the night tint in lib/constants/scenes.dart). You keep
drawing both in #f6f0dc. A stem that touched a cap with no outline between
them would be taken for a spot, so keep the ink between them.

After a rebuild, hot RESTART the app: hot reload keeps the old picture cached.

Usage:  python build_mushroom_glade.py [file.svg] [--watch] [--snap] [--out path]

  --watch  rebuild every time the file is saved, until Ctrl+C
"""
from pathlib import Path

import scene_art

HERE = Path(__file__).resolve().parent

if __name__ == '__main__':
    scene_art.main(
        scene_art.MUSHROOM_GLADE,
        default_src=HERE / 'mushroom-glade-editable.svg',
        default_out=HERE.parent / 'assets' / 'svgs' / 'mushroom_glade.svg',
        what='mushroom glade')
