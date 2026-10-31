// Redesign preview (owner 2026-10-28: the first masks/mustaches "still don't work visually").
// One pixel = one 3-unit cell of cat2's grid, flat colours, no shading, two-cell border.
// Handlebar with a deep, sloped dip under the middle (not a split) and rounded ends; centred on x125 (24 x 6 fill: x89..161, y139).
pal({
  k: "#1f2223",
  m: "#865134",
})
const HALF = [[0,2],[0,4],[1,5],[2,5],[2,5],[2,5],[2,5],[1,5],[1,5],[1,5],[0,4],[0,3]]
const cols = []
HALF.forEach(([r0, r1], c) => {
  cols.push(rect(c, r0, 1, r1 - r0 + 1, "m"))
  cols.push(rect(23 - c, r0, 1, r1 - r0 + 1, "m"))
})
sprite("_f", { w: 24, h: 6 }, ...cols)
sprite("_1", { base: "_f", outline8: "k" })
sprite("mustache_b", { base: "_1", outline8: "k" })
