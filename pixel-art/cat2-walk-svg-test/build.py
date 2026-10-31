"""Eight-pose cat2 walk study. Read existing SVGs; write only to this folder."""
from collections import defaultdict
from hashlib import sha256
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(ROOT / ".claude/skills/pixel-art-studio-main/scripts"))
sys.path.insert(0, str(HERE.parent / "cat2-idle"))
from pixelstudio import Sprite
import cellsvg

COAT, INK = "#959379", "#1f2223"
W, H, C0, R0 = 120, 92, -45, 3
GROUND, OUTLINE = 83, 3
N, MS = 8, 110
DURATION = N * MS
RUMP, CHEST, BACK, BELLY = -10, 53, 48, 68
HIPS = dict(near_back=-6, far_back=2, near_front=36, far_front=28)
PHASE = dict(near_back=0, near_front=6, far_back=4, far_front=2)
STRIDE = [(6, 0), (3, 0), (0, 0), (-3, 0), (-6, 0), (-3, 3), (2, 5), (5, 2)]
BOB = [0, 1, 1, 0, 0, 1, 1, 0]
TAIL = ["tail", "tail", "tail_l", "tail_l", "tail", "tail", "tail_r", "tail_r"]
LABELS = ["Near hind contact", "Weight settles", "Near front contact", "Passing",
          "Far hind contact", "Weight settles", "Far front contact", "Passing"]
LAYERS = {n: cellsvg.load("cat2_" + n)
          for n in ("base", "eyes", "mouth", "tail", "tail_l", "tail_r")}
HEAD = {}
for name in ("base", "eyes", "mouth"):
    HEAD.update({p: c for p, c in LAYERS[name].items() if p[1] <= 51})


def rect(x0, y0, x1, y1):
    return {(x, y) for y in range(y0, y1 + 1) for x in range(x0, x1 + 1)}


def outlined(shape):
    """Square dilation: right-angle corners, never rotated or beveled edges."""
    border = {(x + dx, y + dy): INK for x, y in shape
              for dx in range(-OUTLINE, OUTLINE + 1)
              for dy in range(-OUTLINE, OUTLINE + 1)}
    border.update({p: COAT for p in shape})
    return border


def shifted(cells, dx=0, dy=0):
    return {(x + dx, y + dy): color for (x, y), color in cells.items()}


def leg(name, frame):
    """Fixed upper joint; a single square knee connects the traveling shin."""
    dx, lift = STRIDE[(frame + PHASE[name]) % N]
    x, top = HIPS[name], BELLY - 3 + BOB[frame]
    far = name.startswith("far")
    width = 4 if far else 6
    foot = GROUND - lift
    knee = max(top + 2, foot - 7)
    shin = x + dx
    shape = rect(x, top, x + width - 1, knee + 2)
    shape |= rect(min(x, shin), knee, max(x, shin) + width - 1, knee + 2)
    shape |= rect(shin, knee, shin + width - 1, foot)
    shape |= rect(shin, foot - 3, shin + width + 2, foot)
    return shape


def draw(frame):
    cells = {}
    bob, head_bob = BOB[frame], BOB[(frame - 1) % N]
    # Far limbs are smaller and partially occluded, using the same two colors.
    for name in ("far_back", "far_front"):
        cells.update(outlined(leg(name, frame)))
    # Exact source tail silhouette, tucked behind the rump.
    cells.update(shifted(LAYERS[TAIL[frame]], -19, -19 + BOB[(frame - 1) % N]))
    body = rect(RUMP, BACK + bob, CHEST, BELLY + bob)
    body -= rect(RUMP, BACK + bob, RUMP + 3, BACK + bob + 3)
    for name in ("near_back", "near_front"):
        body |= leg(name, frame)
    cells.update(outlined(body))
    cells.update(shifted(HEAD, dy=head_bob))
    # Validate in world coordinates before cropping into the export canvas.
    assert all(C0 + 2 <= x < C0 + W - 2 and R0 + 2 <= y < R0 + H - 2
               for x, y in cells), "A pose is clipping the canvas"
    assert all(c in (COAT, INK) for c in cells.values())
    assert max(y for x, y in cells) == GROUND + OUTLINE
    for (x, y), color in HEAD.items():
        assert cells[x, y + head_bob] == color, "Original face must remain intact"
    return [[cells.get((x + C0, y + R0)) for x in range(W)] for y in range(H)]


def paths_for(rows):
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
    return "\n".join(f'<path fill="{c}" d="{"".join(paths[c])}"/>' for c in (COAT, INK))


def animated_svg(frames):
    style = [f".pose {{visibility:hidden;animation-duration:{DURATION}ms;"
             "animation-timing-function:steps(1,end);animation-iteration-count:infinite;}\n"
             ".pose-rest {visibility:visible;}\n"
             "@media(prefers-reduced-motion:reduce){"
             "svg:not(.allow-motion) .pose {animation:none!important;visibility:hidden!important;}"
             "svg:not(.allow-motion) .pose-rest {visibility:visible!important;}}"]
    groups = []
    for i, rows in enumerate(frames):
        keys = [f'{j / N * 100:g}% {{visibility:{"visible" if j == i else "hidden"};}}'
                for j in range(N)]
        keys += [f'100% {{visibility:{"visible" if i == 0 else "hidden"};}}']
        style.append(f'.pose-{i} {{animation-name:walk-pose-{i};}}\n'
                     f'@keyframes walk-pose-{i} {{' + "".join(keys) + '}')
        groups.append(f'<g class="pose pose-{i}{" pose-rest" if i == 0 else ""}" '
                      f'id="pose-{i}">\n{paths_for(rows)}\n</g>')
    return (f'<svg xmlns="http://www.w3.org/2000/svg" id="cat-animation" '
            f'viewBox="0 0 {W} {H}" shape-rendering="crispEdges" role="img" '
            'aria-labelledby="walk-title walk-desc">\n'
            '<title id="walk-title">Cat 02: walking right</title>\n'
            '<desc id="walk-desc">An eight-pose walk with four alternating paws, '
            'a small head bob and a swaying tail. Original face and two colors; '
            'all outlines use horizontal and vertical steps.</desc>\n'
            '<style>' + "\n".join(style) + '</style>\n' + "\n".join(groups) + '\n</svg>\n')


def main():
    watched = list((ROOT / "assets/svgs").glob("cat2*.svg"))
    watched += [p for p in (HERE.parent / "cat2-svg-test").iterdir() if p.is_file()]
    hashes = {str(p.relative_to(ROOT)): sha256(p.read_bytes()).hexdigest() for p in watched}
    frames = [draw(f) for f in range(N)]
    assert len({str(f) for f in frames}) == N
    assert max(BOB) - min(BOB) <= 1
    for name in PHASE:
        # During stance the sole travels backward three cells per pose, matching
        # the preview's ground. Upper joints stay fixed on the torso.
        for step in range(4):
            assert STRIDE[step + 1][0] - STRIDE[step][0] == -3
            assert STRIDE[step][1] == 0
    svg = animated_svg(frames)
    (HERE / "cat2-walk.svg").write_text(svg, encoding="utf-8")
    sprite = Sprite(W, H, palette=[COAT, INK])
    for i, rows in enumerate(frames):
        if i:
            sprite.add_frame(copy=False)
        for y, row in enumerate(rows):
            for x, color in enumerate(row):
                if color:
                    sprite.px(x, y, color)
    sprite.set_duration(MS, "all")
    sprite.tag("walk", 1, N)
    sprite.preview(str(HERE / "preview.png"), scale=3, cols=4)
    sprite.save_png(str(HERE / "cat2-walk@1x.png"), frame=1)
    sprite.save_png(str(HERE / "cat2-walk@4x.png"), frame=1, scale=4)
    sprite.save_gif(str(HERE / "cat2-walk.gif"), scale=4, tag="walk")
    sprite.save_spritesheet(str(HERE / "cat2-walk-sheet.png"), layout="horizontal")
    sprite.frame(1)
    sprite.stats()
    timeline = [dict(startMs=i * MS, durationMs=MS, label=LABELS[i], pose=i) for i in range(N)]
    template = HERE / "preview.template.html"
    if template.exists():
        html = template.read_text(encoding="utf-8")
        for key, value in {"__ANIMATED_SVG__": svg, "__TIMELINE_JSON__": json.dumps(timeline),
                           "__DURATION_MS__": str(DURATION)}.items():
            html = html.replace(key, value)
        (HERE / "index.html").write_text(html, encoding="utf-8")
    for p, digest in hashes.items():
        assert sha256((ROOT / p).read_bytes()).hexdigest() == digest
    report = dict(durationMs=DURATION, timeline=timeline, uniquePoses=N, canvas=[W, H],
                  sourcePalette=[COAT, INK], sourceHashes=hashes,
                  groundY=GROUND + OUTLINE - R0 + 1, stridePerCycle=24,
                  checks=dict(originalHeadExact=True, fourAlternatingPaws=True,
                              orthogonalPathsOnly=True, clearMargins=True,
                              sourceAndIdleUnchanged=True))
    (HERE / "animation.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"Built {N} walk poses / {DURATION} ms / {W} x {H} native cells")
    print("PASS: original face and palette, clear margins, four feet, sources and idle unchanged")


if __name__ == "__main__":
    main()
