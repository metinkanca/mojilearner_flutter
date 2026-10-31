// Pumpkin witch hat for the cat, drawn with pxl: one pixel = one 3-unit cell of cat2's grid,
// border three cells (9 units) like the other hats, flat colours, no shading.
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/pumpkinwitch.px.js
// Export: python art_src/gen_cat_hats.py [--ship] pumpkinwitch
//
// The original: a plum witch hat whose tip bends over to the left and hooks down, a little
// orange jack-o'-lantern dangling from it. Same frame as the wizard hat (cone through the
// notch between the ears, brim on top of the ears' bases): fill 56 x 40 cells, origin
// x23 y-47, axis between cols 27 and 28 (x107), brim rows 34..39.
//   Cone: rows 14..35, 6 wide at the top flaring to 24 at the brim, like the original's fat
//         swooping cone (a straight 14-wide cone read as a lamp post, and an 18-wide one still did:
//         the three-cell border eats six cells of every width).
//   Bend: rows 5..13, 6 wide, stepping left half a cell a row (5 cells over the 9 rows), so the hook stays compact.
//   Hook: a crook across rows 3..4, the tip hanging down cols 10..12 to row 9. The gap between
//         the tip and the bend is 7+ cells, so the three-cell border leaves it open.
//   Pumpkin: 9 x 8 cells, cols 7..15, rows 12..19, on a green stem; carved face in ink.
//   Band: rows 31..33, pumpkin orange, like the wizard hat's gold one.
pal({
  k: "#1f2223",   // pet ink
  h: "#663b72",   // plum felt
  o: "#f5951a",   // pumpkin
  s: "#3e8e41",   // stem
})

const parts = []
// the cone: a witch hat's concave flare, 6 wide at the top to 24 at the brim
for (let r = 14; r < 36; r++) {
  const t = (r - 14) / 21
  const w = 2 * Math.round((6 + 18 * Math.pow(t, 1.8)) / 2)
  parts.push(rect(28 - w / 2, r, w, 1, (r >= 31 && r <= 33) ? "o" : "h"))
}
// the bend to the left
for (let r = 13; r >= 5; r--) {
  const c = 28 - Math.round((14 - r) * 0.55)
  parts.push(rect(c - 3, r, 6, 1, "h"))
}
// the crook and the hanging tip
parts.push(rect(10, 3, 16, 2, "h"), rect(10, 5, 3, 5, "h"))
// the stem and the pumpkin
parts.push(rect(11, 10, 1, 2, "s"))
const P = (c, r, w, h, col) => rect(7 + c, 12 + r, w, h, col)
parts.push(
  P(2, 0, 5, 1, "o"), P(1, 1, 7, 1, "o"), P(0, 2, 9, 4, "o"), P(1, 6, 7, 1, "o"), P(2, 7, 5, 1, "o"),
  P(2, 2, 2, 2, "k"), P(5, 2, 2, 2, "k"),            // eyes
  P(2, 4, 1, 1, "k"), P(3, 5, 3, 1, "k"), P(6, 4, 1, 1, "k"))   // smile

sprite("_pw_fill", { w: 56, h: 40 },
  ...parts,
  rect(12, 34, 32, 1, "h"),
  rect(6, 35, 44, 1, "h"),
  rect(0, 36, 56, 2, "h"),
  rect(4, 38, 48, 1, "h"),
  rect(10, 39, 36, 1, "h"))

sprite("_pw_1", { base: "_pw_fill", outline: "k" })
sprite("_pw_2", { base: "_pw_1", outline: "k" })
sprite("pumpkinwitch", { base: "_pw_2", outline: "k" })
