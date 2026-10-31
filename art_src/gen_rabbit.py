# Builds the rabbit sprite assets from art_src/rabbit_cells.txt.
#
# The rabbit is a front-facing sit, and the cleanest three-tone fit of the six
# new animals on the reference roster: coat, one shade for the inner ears, the
# chest band and the nose, and the outline. Two eyes, no tail worth rigging
# (its tail is a puff fused into the body silhouette).
#
# Re-run after any edit to rabbit_cells.txt. Never hand-edit the output.
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_cells import OUTLINE, MAIN, SHADE, generate

# Back-most first. N is the nose: a shade-toned wedge in the reference, which
# is exactly what darken(coat, 0.72) gives once the coat is recoloured.
PALETTE = {
    'M': MAIN,
    'S': SHADE,
    'N': SHADE,
    'K': OUTLINE,
    'E': OUTLINE,
}

generate('rabbit', PALETTE, under='M', const_name='kRabbitEyes')
