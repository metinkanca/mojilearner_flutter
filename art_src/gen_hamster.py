# Builds the hamster sprite assets from art_src/hamster_cells.txt.
#
# The hamster reads inverted next to the other pets: its lighter belly and face
# are the main coat and its darker gold back is the shade, which is the way
# round recolorBodyLayer wants them (shade is always a darkened main).
#
# Re-run after any edit to hamster_cells.txt. Never hand-edit the output.
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_cells import OUTLINE, MAIN, SHADE, generate

# P (paw pads, inner ears) and N (the crease across each paw) are the two
# details that do not fit three tones. They fold into the coat and the outline
# rather than becoming a fourth fill, because a fourth fill would survive
# recolouring unchanged and leave a pink-eared blue hamster. The paws still
# read: they are drawn as outlined shapes, not as colour alone.
PALETTE = {
    'M': MAIN,
    'P': MAIN,
    'S': SHADE,
    'K': OUTLINE,
    'N': OUTLINE,
    'E': OUTLINE,
}

generate('hamster', PALETTE, under='M', const_name='kHamsterEyes')
