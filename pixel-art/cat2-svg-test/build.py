"""Standalone cat2 SVG study. Reads app artwork; writes only beside this script.

Run from any directory: python pixel-art/cat2-svg-test/build.py
Uses the local Pixel Art Studio for raster previews; SVG is pure orthogonal paths.
"""
from collections import defaultdict
from hashlib import sha256
import json
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
ASSETS = ROOT / "assets" / "svgs"
sys.path.insert(0, str(ROOT / ".claude/skills/pixel-art-studio-main/scripts"))
from pixelstudio import Sprite

COAT, INK = "#959379", "#1f2223"
W, H, C0, R0 = 85, 90, -13, 3
SOURCE_HASHES = {}


def read_cells(name):
    """Recover the SVG's exact 3-unit cells using nonzero winding, without AA."""
    path = ASSETS / (name + ".svg")
    SOURCE_HASHES[path.name] = sha256(path.read_bytes()).hexdigest()
    cells = {}
    for element in ET.parse(path).getroot():
        assert element.tag.endswith("}path")
        color, d = element.attrib["fill"], element.attrib["d"]
        assert color in (COAT, INK)
        assert set(re.findall(r"[A-Za-z]", d)) <= set("MHVZ")
        tokens = re.findall(r"[MHVZ]|-?\d+(?:\.\d+)?", d)
        paths, points, i = [], [], 0
        while i < len(tokens):
            command = tokens[i]
            i += 1
            if command == "M":
                x, y = int(tokens[i]), int(tokens[i + 1])
                points = [(x, y)]
                i += 2
            elif command in "HV":
                value = int(tokens[i])
                i += 1
                x, y = (value, y) if command == "H" else (x, value)
                points.append((x, y))
            else:
                assert command == "Z"
                paths.append(points)
        edges = [(a, b) for p in paths for a, b in zip(p, p[1:] + p[:1])]
        assert all(a[0] == b[0] or a[1] == b[1] for a, b in edges)
        assert all((x - 2) % 3 == 0 and (y - 1) % 3 == 0
                   for p in paths for x, y in p)
        rows = range((min(y for p in paths for x, y in p) - 1) // 3,
                     (max(y for p in paths for x, y in p) - 1) // 3)
        for row in rows:
            sample_y = 1 + row * 3 + 1.5
            crosses = sorted((a[0], 1 if b[1] > a[1] else -1)
                             for a, b in edges
                             if min(a[1], b[1]) <= sample_y < max(a[1], b[1]))
            winding = 0
            for x, delta in crosses:
                if winding == 0:
                    start = x
                winding += delta
                if winding == 0:
                    for col in range((start - 2) // 3, (x - 2) // 3):
                        cells[col, row] = color
    return cells


LAYERS = {name: read_cells("cat2_" + name)
          for name in ("base", "tail", "tail_l", "tail_r", "eyes", "mouth")}
ORIGINAL = read_cells("cat2")


def pose(breath="rest", tail="tail", blink=0, ear=0):
    cells = {}
    for name in ("base", tail, "eyes", "mouth"):
        cells.update(LAYERS[name])
    # Seven-cell eyes close downward to a single horizontal ink row.
    for (x, y) in LAYERS["eyes"]:
        if y < 35 + blink:
            cells[x, y] = COAT
    # Shorten the left ear by dropping only repeated rows, without rotation.
    if ear:
        dropped = [16, 13][:ear]
        patch = {p: color for p, color in cells.items()
                 if 10 <= p[0] < 31 and 9 <= p[1] < 19}
        for p in patch:
            del cells[p]
        for (x, y), color in patch.items():
            if y not in dropped:
                cells[x, y + sum(r > y for r in dropped)] = color
    rows = [[cells.get((C0 + x, R0 + y)) for x in range(W)] for y in range(H)]

    def delete_row(rows, row):
        i = row - R0
        return [[None] * W] + rows[:i] + rows[i + 1:]

    def repeat_row(rows, row):
        i = row - R0
        return rows[1:i + 1] + [list(rows[i])] + rows[i + 1:]

    if breath == "settle":
        rows = repeat_row(delete_row(rows, 73), 62)  # torso leads the head
    elif breath == "down":
        rows = delete_row(rows, 73)
    elif breath == "recover":
        rows = delete_row(rows, 62)  # head follows the torso back up
    return rows


# Four breathing poses; variable holds separate breathing, tail and ear gestures.
# Each tuple is duration, label, breathing pose, tail pose, closed eye rows, ear dip.
SCORE = [
    (650, "Rest", "rest", "tail", 0, 0),
    (220, "Tail left", "rest", "tail_l", 0, 0),
    (240, "Tail returns", "rest", "tail", 0, 0),
    (140, "Breathe out", "settle", "tail", 0, 0),
    (420, "Head follows", "down", "tail_r", 0, 0),
    (60, "Blink closes", "down", "tail_r", 3, 0),
    (100, "Blink", "down", "tail_r", 6, 0),
    (60, "Blink opens", "down", "tail_r", 3, 0),
    (360, "Rest low", "down", "tail", 0, 0),
    (140, "Breathe in", "recover", "tail", 0, 0),
    (260, "Head returns", "rest", "tail_l", 0, 0),
    (400, "Rest", "rest", "tail", 0, 0),
    (80, "Ear twitch", "rest", "tail", 0, 2),
    (120, "Ear returns", "rest", "tail", 0, 1),
    (440, "Rest", "rest", "tail", 0, 0),
    (140, "Breathe out", "settle", "tail", 0, 0),
    (400, "Head follows", "down", "tail_r", 0, 0),
    (320, "Tail returns", "down", "tail", 0, 0),
    (140, "Breathe in", "recover", "tail", 0, 0),
    (220, "Head returns", "rest", "tail_l", 0, 0),
    (650, "Rest", "rest", "tail", 0, 0),
]
DURATION = sum(item[0] for item in SCORE)


def paths_for(rows):
    """Merge horizontal cell runs. All closed edges are axis aligned."""
    paths = defaultdict(list)
    for y, row in enumerate(rows):
        x = 0
        while x < W:
            color, end = row[x], x + 1
            while end < W and row[end] == color:
                end += 1
            if color:
                paths[color].append(f"M{x} {y}H{end}V{y + 1}H{x}Z")
            x = end
    return "\n".join(f'<path fill="{color}" d="{"".join(paths[color])}"/>'
                     for color in (COAT, INK))


def build():
    original_rows = [[ORIGINAL.get((C0 + x, R0 + y)) for x in range(W)] for y in range(H)]
    assert pose() == original_rows, "The resting pose must exactly match cat2.svg"
    frames = [pose(*item[2:]) for item in SCORE]
    ground = original_rows[83:]
    for rows in frames:
        assert rows[83:] == ground, "Paws must stay planted"
        assert all(v is None for row in rows[:2] + rows[-2:] for v in row)
        assert all(v is None for row in rows for v in row[:2] + row[-2:])
        assert {v for row in rows for v in row if v} == {COAT, INK}
    assert frames[0] == frames[-1], "The loop must close at rest"

    unique, indices = [], []
    for rows in frames:
        if rows not in unique:
            unique.append(rows)
        indices.append(unique.index(rows))
    timeline, start = [], 0
    for item, index in zip(SCORE, indices):
        timeline.append(dict(startMs=start, durationMs=item[0], label=item[1], pose=index))
        start += item[0]

    styles = [f".pose {{visibility:hidden;animation-duration:{DURATION}ms;"
              "animation-timing-function:steps(1,end);animation-iteration-count:infinite;}\n"
              ".pose-rest {visibility:visible;}\n"
              "@media (prefers-reduced-motion:reduce) {\n"
              "svg:not(.allow-motion) .pose {animation:none!important;visibility:hidden!important;}\n"
              "svg:not(.allow-motion) .pose-rest {visibility:visible!important;}\n}"]
    groups = []
    for i, rows in enumerate(unique):
        # Explicit on/off values at every boundary prevent overlap or crossfades.
        keys = []
        for entry in timeline:
            visibility = "visible" if entry["pose"] == i else "hidden"
            keys.append(f'{entry["startMs"] / DURATION * 100:.8f}% {{visibility:{visibility};}}')
        keys.append(f'100% {{visibility:{"visible" if i == 0 else "hidden"};}}')
        styles.append(f".pose-{i} {{animation-name:cat2-pose-{i};}}\n"
                      f"@keyframes cat2-pose-{i} {{\n" + "\n".join(keys) + "\n}")
        groups.append(f'<g class="pose pose-{i}{" pose-rest" if i == 0 else ""}" '
                      f'id="pose-{i}">\n{paths_for(rows)}\n</g>')
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" id="cat-animation" '
           f'viewBox="0 0 {W} {H}" shape-rendering="crispEdges" role="img" '
           'aria-labelledby="cat-title cat-desc">\n'
           '<title id="cat-title">Cat 02: a quiet idle</title>\n'
           '<desc id="cat-desc">A pixel cat breathes, blinks, twitches one ear and swishes '
           'its tail. Every edge stays horizontal or vertical. Original two-color palette.</desc>\n'
           '<style>\n' + "\n".join(styles) + '\n</style>\n' + "\n".join(groups) + '\n</svg>\n')
    (HERE / "cat2-animated.svg").write_text(svg, encoding="utf-8")
    original_svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" '
                    'shape-rendering="crispEdges" role="img" aria-label="Original cat2 artwork">'
                    + paths_for(original_rows) + '</svg>')

    sprite = Sprite(W, H, palette=[COAT, INK])
    for i, rows in enumerate(frames):
        if i:
            sprite.add_frame(copy=False)
        for y, row in enumerate(rows):
            for x, color in enumerate(row):
                if color:
                    sprite.px(x, y, color)
        sprite.set_duration(SCORE[i][0], [i + 1])
    sprite.tag("idle", 1, len(frames))
    sprite.preview(str(HERE / "preview.png"), scale=3, cols=7)
    sprite.save_png(str(HERE / "cat2@1x.png"), frame=1)
    sprite.save_png(str(HERE / "cat2@4x.png"), frame=1, scale=4)
    sprite.save_gif(str(HERE / "cat2-animated.gif"), scale=4, tag="idle")
    sprite.save_spritesheet(str(HERE / "cat2-sheet.png"), layout="grid")
    sprite.frame(1)
    sprite.stats()

    template = HERE / "preview.template.html"
    if template.exists():
        html = template.read_text(encoding="utf-8")
        for key, value in {"__ANIMATED_SVG__": svg, "__ORIGINAL_SVG__": original_svg,
                           "__TIMELINE_JSON__": json.dumps(timeline),
                           "__DURATION_MS__": str(DURATION)}.items():
            html = html.replace(key, value)
        (HERE / "index.html").write_text(html, encoding="utf-8")
    for name, digest in SOURCE_HASHES.items():
        assert sha256((ASSETS / name).read_bytes()).hexdigest() == digest
    report = dict(durationMs=DURATION, timeline=timeline, uniquePoses=len(unique),
                  canvas=[W, H], sourcePalette=[COAT, INK], sourceHashes=SOURCE_HASHES,
                  checks=dict(originalPoseExact=True, fixedPaws=True,
                              orthogonalPathsOnly=True, transparentMargin=True,
                              seamlessRest=True, sourceFilesUnchanged=True))
    (HERE / "animation.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"Built {len(frames)} timed frames / {len(unique)} poses / {DURATION} ms")
    print("PASS: exact original rest, two colors, fixed paws, clear margins, unchanged source SVGs")


if __name__ == "__main__":
    build()
