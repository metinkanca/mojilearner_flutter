// Bow tie, variant C: striped bow tie, for the cat: one pixel = one 3-unit cell of cat2's grid, flat
// colours, no shading, TWO-cell border (see collar.px.js). Owner (2026-10-28 d): the
// bow tie "is supposed to look cute, which it does not": a classic bow tie with rounded outer corners and two-column cream stripes.
// Fill col c is x = 89 + 3c, fill row r is y = 163 + 3r; the box is x80..164 so the
// knot (cols 10..13) is on the face centre, x122.
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/bowtie_c.px.js
// Export: python art_src/gen_cat_hats.py [--ship] bowtie_c
pal({
  k: "#1f2223",   // pet ink
  r: "#e3664f",   // bow
  w: "#efeae1",   // stripes
  d: "#b8453a",   // knot
})

const wing = (mirror) => {
  const out = []
  const H = [7, 9, 9, 9, 9, 9, 9, 9, 7, 5]     // column heights, outer edge first
  H.forEach((h, c) => {
    const col = mirror ? 23 - c : c
    out.push(rect(col, (9 - h) / 2, 1, h, Math.floor(c / 2) % 2 === 0 ? "r" : "w"))
  })
  return out
}
sprite("_bwc_fill", { w: 24, h: 9 },
  ...wing(false), ...wing(true),
  rect(10, 2, 4, 5, "d"))
sprite("_bwc_1", { base: "_bwc_fill", outline8: "k" })
sprite("bowtie_c", { base: "_bwc_1", outline8: "k" })
