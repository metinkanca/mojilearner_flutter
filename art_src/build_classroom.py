"""Rebuilds the app's quiz classroom from the SVG you edit.

    edit  art_src/classroom-editable.svg          (made once by gen_classroom.py)
    run   python art_src/build_classroom.py
    get   assets/svgs/quiz_classroom.svg          (what the app loads)
          lib/constants/quiz_classroom_art.dart   (where the board, the floor
                                                   and the pets are in it)

Like the home scenes (see build_cozy_room.py), the app does not load the file
you edit: this renders it as it looks, reads the pixels, and writes the app's
copy from them, one path per colour, each fill grown a pixel under the ink.

It also measures the finished picture for the quiz screen, which writes the
question on the board's green and stands the pets on the floor under it, and
rewrites the Dart table with what it found. So moving or resizing the board in
the editable file is fine, as long as it stays one patch of green with a frame
round it, a tray under it, and wall above and below it.

Keep to the classroom's nine colours:

    wall #f2e3c6   wood #c58c56   dark #a56e45   board #3f6654   coral #e98a7b
    sky  #a8dcef   leaf #8cc56a   felt #76716d   ink   #14120e

Wall and wood must stay exactly those: the screen paints flat wall above the
picture and flat floor below it. So the top row of the picture must be all wall
and the bottom row all wood.

After a rebuild, hot RESTART the app: hot reload keeps the old picture cached.

Usage:  python build_classroom.py [file.svg] [--watch] [--snap] [--out path]
"""
from pathlib import Path

import scene_art
import gen_classroom

HERE = Path(__file__).resolve().parent


def write_table(classes):
    h, w = classes.shape
    if (classes[0] != gen_classroom.WALL).any():
        print('  heads up: the top row is not all wall; the screen paints flat wall above it')
    if (classes[-1] != gen_classroom.WOOD).any():
        print('  heads up: the bottom row is not all wood; the screen paints flat floor below it')
    m = gen_classroom.write_dart(classes)
    print('wrote %s: board face %g..%g x %g..%g, floor line %g, feet on %g' % (
        gen_classroom.DART.name, m['faceLeft'], m['faceRight'], m['faceTop'],
        m['faceBottom'], m['floorLine'], m['standRow']))


if __name__ == '__main__':
    scene_art.main(
        scene_art.QUIZ_CLASSROOM,
        default_src=HERE / 'classroom-editable.svg',
        default_out=HERE.parent / 'assets' / 'svgs' / 'quiz_classroom.svg',
        what='quiz classroom',
        after=write_table)
