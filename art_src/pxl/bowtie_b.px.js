// Bow tie, variant B: puffy bow with polka dots, for the cat: one pixel = one 3-unit cell of cat2's grid, flat
// colours, no shading, TWO-cell border (see collar.px.js). Owner (2026-10-28 d): the
// bow tie "is supposed to look cute, which it does not": chubby round loops, cream polka dots and a round knot.
// Fill col c is x = 89 + 3c, fill row r is y = 163 + 3r; the box is x80..164 so the
// knot (cols 10..13) is on the face centre, x122.
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/bowtie_b.px.js
// Export: python art_src/gen_cat_hats.py [--ship] bowtie_b
pal({
  k: "#1f2223",   // pet ink
  r: "#e3664f",   // bow
  w: "#efeae1",   // dots
  d: "#b8453a",   // knot
})

const puff = (mirror) => {
  const x = (c, w) => mirror ? 24 - c - w : c
  return [
    rect(x(3, 9), 0, 9, 1, "r"),
    rect(x(1, 11), 1, 11, 1, "r"),
    rect(x(0, 12), 2, 12, 5, "r"),
    rect(x(1, 11), 7, 11, 1, "r"),
    rect(x(3, 9), 8, 9, 1, "r"),
    rect(x(2, 2), 2, 2, 2, "w"),   // dots
    rect(x(6, 2), 5, 2, 2, "w"),
  ]
}
sprite("_bwb_fill", { w: 24, h: 9 },
  ...puff(false), ...puff(true),
  rect(10, 2, 4, 5, "d"))
sprite("_bwb_1", { base: "_bwb_fill", outline8: "k" })
sprite("bowtie_b", { base: "_bwb_1", outline8: "k" })
