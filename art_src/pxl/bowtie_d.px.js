// Bow tie, variant D: bubble bow, for the cat: one pixel = one 3-unit cell of cat2's grid, flat
// colours, no shading, TWO-cell border (see collar.px.js). Owner (2026-10-28 d): the
// bow tie "is supposed to look cute, which it does not": two round balls and a cream knot with a gold bead: the simplest, roundest option.
// Fill col c is x = 89 + 3c, fill row r is y = 163 + 3r; the box is x80..164 so the
// knot (cols 10..13) is on the face centre, x122.
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/bowtie_d.px.js
// Export: python art_src/gen_cat_hats.py [--ship] bowtie_d
pal({
  k: "#1f2223",   // pet ink
  v: "#c9b8e8",   // lilac
  w: "#efeae1",   // knot
  g: "#f8b230",   // bead
})

const ball = (mirror) => {
  const x = (c, w) => mirror ? 24 - c - w : c
  return [
    rect(x(2, 6), 0, 6, 1, "v"),
    rect(x(1, 8), 1, 8, 1, "v"),
    rect(x(0, 10), 2, 10, 6, "v"),
    rect(x(1, 8), 8, 8, 1, "v"),
    rect(x(2, 6), 9, 6, 1, "v"),
  ]
}
sprite("_bwd_fill", { w: 24, h: 10 },
  ...ball(false), ...ball(true),
  rect(10, 3, 4, 4, "w"),
  rect(11, 4, 2, 2, "g"))
sprite("_bwd_1", { base: "_bwd_fill", outline8: "k" })
sprite("bowtie_d", { base: "_bwd_1", outline8: "k" })
