"""Render a contact sheet of the shipped SVG geometry and natural coats."""
import os
import sys
from PIL import Image, ImageDraw
import deseam
from gen_roster_pets import NATURAL_COAT

HERE = os.path.dirname(os.path.abspath(__file__))
PETS = ['cat', 'dog', 'bird', 'hamster', 'rabbit', 'parrot'] + list(NATURAL_COAT)

def render(pet):
    names = ([pet + suffix for suffix in ('_tail', '_base', '_mouth', '_eyes')]
             if pet == 'cat' else [pet])
    shapes = []
    for name in names:
        svg = open(os.path.join(HERE, '../assets/svgs', name + '.svg'), encoding='utf-8').read()
        shapes.extend(deseam.shapes(svg))
    fills = list(dict.fromkeys(f for f, _ in shapes))
    buf = [-1] * (222 * 328)
    for f, subs in shapes:
        deseam.rasterise(subs, buf, fills.index(f))
    coat = NATURAL_COAT.get(pet, '#959379')
    rgb = tuple(int(coat[i:i+2], 16) for i in (1, 3, 5))
    palette = {'#959379': rgb, '#959279': rgb,
               '#606659': tuple(round(c * .72) for c in rgb),
               '#c8c6b3': tuple(round(255 - (255-c)*.45) for c in rgb)}
    colors = [palette.get(f, tuple(int(f[i:i+2], 16) for i in (1, 3, 5))) for f in fills]
    im = Image.new('RGB', (222, 328))
    im.putdata([colors[v] if v >= 0 else (239, 235, 218) for v in buf])
    return im

def main():
    sheet = Image.new('RGB', (6*242, 5*358), '#efebda')
    draw = ImageDraw.Draw(sheet)
    for i, pet in enumerate(PETS):
        x, y = (i % 6)*242, (i//6)*358
        sheet.paste(render(pet), (x+10, y))
        draw.text((x+14, y+334), pet, fill='#1f2223')
    sheet.save(sys.argv[1])

if __name__ == '__main__':
    main()
