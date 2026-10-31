// Redesign preview (owner 2026-10-28: the first masks/mustaches "still don't work visually").
// One pixel = one 3-unit cell of cat2's grid, flat colours, no shading, two-cell border.
// Neater, smaller handlebar; centred on x125 (fill x92..158).
pal({
  k: "#1f2223",
  m: "#865134",
})
const HALF = [[0, 2], [0, 3], [1, 4], [2, 5], [2, 6], [1, 6], [1, 6], [1, 6], [1, 6], [0, 6], [0, 6]]
const cols = []
HALF.forEach(([r0, r1], c) => {
  cols.push(rect(c, r0, 1, r1 - r0 + 1, "m"))
  cols.push(rect(21 - c, r0, 1, r1 - r0 + 1, "m"))
})
sprite("_f", { w: 22, h: 7 }, ...cols)
sprite("_1", { base: "_f", outline8: "k" })
sprite("mustache_d", { base: "_1", outline8: "k" })
