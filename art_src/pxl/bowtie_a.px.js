// Bow tie, variant A: ribbon with loops and tails, for the cat: one pixel = one 3-unit cell of cat2's grid, flat
// colours, no shading, TWO-cell border (see collar.px.js). Owner (2026-10-28 d): the
// bow tie "is supposed to look cute, which it does not": a ribbon bow: two round loops with a pale inside, a small knot, and two tails hanging below.
// Fill col c is x = 89 + 3c, fill row r is y = 163 + 3r; the box is x80..164 so the
// knot (cols 10..13) is on the face centre, x122.
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/bowtie_a.px.js
// Export: python art_src/gen_cat_hats.py [--ship] bowtie_a
pal({
  k: "#1f2223",   // pet ink
  r: "#e3664f",   // ribbon
  p: "#f4aaa0",   // inside of the loops
  d: "#b8453a",   // knot
})

const loop = (mirror) => {
  const x = (c, w) => mirror ? 24 - c - w : c
  return [
    rect(x(2, 8), 0, 8, 1, "r"),
    rect(x(1, 9), 1, 9, 1, "r"),
    rect(x(0, 10), 2, 10, 4, "r"),
    rect(x(1, 9), 6, 9, 1, "r"),
    rect(x(2, 8), 7, 8, 1, "r"),
    rect(x(2, 6), 2, 6, 4, "p"),   // the pale inside
  ]
}
sprite("_bwa_fill", { w: 24, h: 12 },
  ...loop(false), ...loop(true),
  rect(10, 2, 4, 4, "d"),          // the knot
  rect(10, 6, 2, 2, "r"),          // the tails
  rect(12, 6, 2, 2, "r"),
  rect(8, 8, 3, 4, "r"),
  rect(13, 8, 3, 4, "r"))
sprite("_bwa_1", { base: "_bwa_fill", outline8: "k" })
sprite("bowtie_a", { base: "_bwa_1", outline8: "k" })
