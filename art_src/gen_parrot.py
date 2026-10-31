# Builds the parrot sprite assets from art_src/parrot_cells.txt.
#
# The parrot is the one pet that is not three tones. Its body plumage is the
# recolourable coat, but the wing flash, the face patch, the beak and the perch
# it stands on are fixed markings -- a scarlet macaw reduced to coat and shade is just a
# bird-shaped blob, and these are what make the silhouette read. deseam ranks
# anything it does not know above the shade and below the outline, which is
# where all of them belong.
#
# Drawn in profile like the chick, so it shows one eye. It keeps the
# reference's perch pose -- legless, the body sitting straight on the bar with
# only its toes showing -- because that is what a macaw looks like and it is
# what lets the tail hang full length. What the reference got wrong is that the
# bar floated in mid-air; here it is the crossbar of a stand, with a post down
# the middle to a plinth resting on the same ground line the other pets' feet
# do. Standing the parrot on its own legs was tried first and read badly: two
# bare sticks under a bird that has no visible thighs.
#
# Re-run after any edit to parrot_cells.txt. Never hand-edit the output.
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_cells import OUTLINE, MAIN, SHADE, generate

PALETTE = {
    'M': MAIN,          # body plumage -- recolours
    'S': SHADE,         # its darker side -- recolours
    'B': '#4b70a6',     # wing blue
    'Y': '#f6cb1d',     # wing yellow
    'C': '#f6e6d6',     # bare face patch
    'T': '#e9c289',     # beak
    'W': '#968c8a',     # its shaded side, and the toes over the bar
    'D': '#4d3833',     # the dark tip of the lower mandible
    'P': '#d9a86c',     # the perch -- crossbar, post and plinth
    'Q': '#a97b45',     # its shaded side
    'K': OUTLINE,
    'E': OUTLINE,
}

generate('parrot', PALETTE, under='C', const_name='kParrotEyes')
