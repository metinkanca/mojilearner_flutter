// Redesign preview (owner 2026-10-28: the first masks/mustaches "still don't work visually").
// One pixel = one 3-unit cell of cat2's grid, flat colours, no shading, two-cell border.
// Handlebar with a heavier, rounder middle; centred on x125.
pal({
  k: "#1f2223",
  m: "#865134",
})
const HALF = [[0, 2], [0, 3], [1, 4], [2, 5], [3, 6], [3, 7], [3, 8], [2, 8], [1, 8], [1, 8], [1, 8], [0, 8], [0, 8]]
const cols = []
HALF.forEach(([r0, r1], c) => {
  cols.push(rect(c, r0, 1, r1 - r0 + 1, "m"))
  cols.push(rect(25 - c, r0, 1, r1 - r0 + 1, "m"))
})
sprite("_f", { w: 26, h: 9 }, ...cols)
sprite("_1", { base: "_f", outline8: "k" })
sprite("mustache_c", { base: "_1", outline8: "k" })
