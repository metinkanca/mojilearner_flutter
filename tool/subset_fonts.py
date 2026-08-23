"""Rebuild the bundled pixel fonts for the scripts Latin cannot cover.

Run this when the translations gain characters, or to move to a newer upstream
release:

    pip install fonttools
    python tool/subset_fonts.py <work_dir>

It downloads nothing. Put these in <work_dir> first:

  ark/12px/ark-pixel-12px-proportional-{ja,zh_cn,zh_tw}.ttf
      from https://github.com/TakWolf/ark-pixel-font/releases (the
      "12px-proportional-ttf" archive). 12px is the only size upstream has
      drawn CJK at in bulk: 18,299 ideographs, against 1,076 at 10px and 97
      at 16px.
  galmuri/Galmuri11-Bold.ttf
      from https://github.com/quiple/galmuri/releases. Ark Pixel has no
      Hangul at any size; Galmuri11 is drawn on the same 12px grid.
  Unihan.zip
      from https://www.unicode.org/Public/UCD/latest/ucd/Unihan.zip, for the
      standard character sets below.

Both fonts are SIL OFL 1.1; their licence files are bundled beside them.

Why subset at all: the full 12px cuts are 4.76 MB each. Modern Japanese lives
inside JIS X 0208, Simplified Chinese inside GB 2312 and Traditional inside
Big5 Level 1, so each cut keeps its own standard's set, everything that is not
an ideograph at all (kana, both kinds of punctuation, Latin, fullwidth forms),
and every character the app's own translations use whatever standard it falls
outside of. That lands each around 1.4 MB.

Ark's 12px CJK is about 87% of the Unified Ideographs block, so a few common
characters (変, 資, 薬) are still missing and fall back to the platform's Noto.
Nothing here can fix that; only upstream drawing them can.
"""

import io, json, os, sys, zipfile, collections
from fontTools.subset import Subsetter, Options
from fontTools.ttLib import TTFont

work = sys.argv[1] if len(sys.argv) > 1 else 'build/fonts'
repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
assets = os.path.join(repo, 'assets', 'fonts')

# --- the standard sets, from Unihan -----------------------------------------
fields = collections.defaultdict(dict)
with zipfile.ZipFile(os.path.join(work, 'Unihan.zip')) as z:
    for name in ['Unihan_OtherMappings.txt', 'Unihan_IRGSources.txt']:
        for line in io.TextIOWrapper(z.open(name), encoding='utf-8'):
            if line.startswith('#') or '\t' not in line:
                continue
            cp, field, val = line.rstrip('\n').split('\t', 2)
            if field in ('kJis0', 'kJis1', 'kJoyoKanji', 'kJinmeiyoKanji',
                         'kGB0', 'kBigFive', 'kTGH'):
                fields[field][int(cp[2:], 16)] = val

jis = set(fields['kJis0']) | set(fields['kJoyoKanji']) | set(fields['kJinmeiyoKanji'])
gb = set(fields['kGB0'])
# Big5 Level 1 — the frequently used half; Level 2 starts at 0xC940.
def big5_code(v):
    # A trailing apostrophe marks a duplicate mapping; the code is the rest.
    return int(v.rstrip("'"), 16)


big5_l1 = {cp for cp, v in fields['kBigFive'].items() if big5_code(v) < 0xC940}

# --- what the app's own strings need ----------------------------------------
def arb_chars(code):
    path = os.path.join(repo, 'lib', 'l10n', f'app_{code}.arb')
    data = json.load(io.open(path, encoding='utf-8'))
    out = set()
    for k, v in data.items():
        if not k.startswith('@') and isinstance(v, str):
            out.update(ord(c) for c in v)
    return out

ui = set()
for code in ['ja', 'zh', 'ko', 'en']:
    ui |= arb_chars(code)

# --- everything that is not an ideograph ------------------------------------
keep_blocks = [
    (0x0020, 0x024F),   # Latin and its extensions
    (0x0300, 0x036F),   # combining marks
    (0x0370, 0x04FF),   # Greek and Cyrillic
    (0x2000, 0x206F),   # general punctuation
    (0x20A0, 0x20BF),   # currency
    (0x2100, 0x214F),   # letterlike
    (0x2190, 0x21FF),   # arrows
    (0x2460, 0x24FF),   # enclosed alphanumerics
    (0x25A0, 0x25FF),   # geometric shapes
    (0x2600, 0x26FF),   # misc symbols
    (0x3000, 0x303F),   # CJK punctuation
    (0x3040, 0x30FF),   # kana
    (0x31F0, 0x31FF),   # kana extensions
    (0x3200, 0x33FF),   # enclosed CJK and compatibility
    (0xFF00, 0xFFEF),   # halfwidth and fullwidth forms
]
non_ideograph = {cp for a, b in keep_blocks for cp in range(a, b + 1)}
# The Korean face needs the same furniture minus the kana and CJK-only blocks.
non_latin_punctuation = {cp for a, b in keep_blocks
                         if not (0x3040 <= a <= 0x33FF)
                         for cp in range(a, b + 1)}

cuts = {
    'ja': jis,
    'zh_cn': gb,
    'zh_tw': big5_l1,
}

# Hangul syllables and jamo, Latin, punctuation. No ideographs or kana in the
# Korean face: Ark draws those, and Korean UI text has neither.
hangul = set()
for a, b in [(0x1100, 0x11FF), (0x3130, 0x318F), (0xA960, 0xA97F),
             (0xAC00, 0xD7A3), (0xD7B0, 0xD7FF)]:
    hangul |= set(range(a, b + 1))


def write_subset(src, keep, out):
    font = TTFont(src)
    options = Options()
    options.layout_features = ['*']
    options.name_IDs = ['*']
    options.notdef_outline = True
    options.recalc_bounds = True
    sub = Subsetter(options=options)
    sub.populate(unicodes=keep & set(font.getBestCmap()))
    sub.subset(font)
    font.save(out)
    kept = len(set(TTFont(out).getBestCmap()))
    print(f'{os.path.basename(out):42s} {kept:6d} codepoints  '
          f'{os.path.getsize(out) / 1048576:5.2f} MB '
          f'(from {os.path.getsize(src) / 1048576:.2f} MB)')


for cut, ideographs in cuts.items():
    write_subset(
        os.path.join(work, 'ark', '12px', f'ark-pixel-12px-proportional-{cut}.ttf'),
        ideographs | non_ideograph | ui,
        os.path.join(assets, 'ark', f'ark-pixel-12px-proportional-{cut}.ttf'),
    )

write_subset(
    os.path.join(work, 'galmuri', 'Galmuri11-Bold.ttf'),
    hangul | non_latin_punctuation | ui,
    os.path.join(assets, 'galmuri', 'Galmuri11-Bold.ttf'),
)
