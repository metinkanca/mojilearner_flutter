// The scenarios town, second pass (the flat first pass is town_v1_flat.px.js).
//
// Redrawn to sit with the pets: round, chubby shapes with soft stair-stepped
// corners, a two-cell ink silhouette (the pets' border is ~2.4% of their
// height; a one-cell line was only 0.9% of a building), and the pets' own
// rule for tone: every material gets ONE shade and ONE light patch, flat,
// never a gradient. One pixel = one 3-wu cell (world 342 x 750 cells).
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/town.px.js [--only name,...]
// Export: python art_src/gen_town.py [--svg]
//
// Keys: lower case = the base tone, UPPER case = its shade, and the light tone
// is the first letter listed beside it.
pal({
  k: "#14120e",   // ink
  c: "#f4e6c8", C: "#e0cba3", W: "#fffaf0",   // cream wall, shade, light
  w: "#c98f58", x: "#a56c3c", X: "#e3ae74",   // wood
  g: "#a8dcef", G: "#7cbfdf", h: "#eefaff",   // glass, its shade, its glint
  r: "#ea8b7c", R: "#cc6a5f", q: "#f7b8ac",   // coral
  b: "#3f93c4", B: "#2d76a4", e: "#74bce2",   // sea blue
  v: "#9a7cc8", V: "#7a5ca8", m: "#bda6e2",   // violet
  d: "#2f6a4f", D: "#22503b", f: "#4f8f6c",   // pine
  n: "#9a6538", N: "#78492a", o: "#b9824f",   // roof brown
  y: "#f0c24c", Y: "#d29d2c", z: "#fbe08e",   // gold
  l: "#8cc56a", L: "#78b25a", i: "#a5d781",   // lawn
  t: "#4e9a55", T: "#3b7f45", u: "#76bd6a",   // tree / bush
  s: "#cdc3d9", S: "#aea3c2", a: "#e6e0ef",   // lilac stone
  p: "#f2a7b8",                               // blossom pink
})

// ---- helpers -------------------------------------------------------------

// A rounded rectangle: the corners step in 1-3 cells, like the pets'.
const INS = [[1], [2, 1], [3, 2, 1]]
const rr = (c, x, y, w, h, col, r = 2) => {
  const ins = INS[r - 1], n = ins.length
  c.rect(x, y + n, w, h - 2 * n, col)
  for (let i = 0; i < n; i++) {
    c.rect(x + ins[i], y + i, w - 2 * ins[i], 1, col)
    c.rect(x + ins[i], y + h - 1 - i, w - 2 * ins[i], 1, col)
  }
}
// ... fenced by a one-cell ink line.
const rbox = (c, x, y, w, h, fill, r = 2) => {
  rr(c, x, y, w, h, "k", r)
  rr(c, x + 1, y + 1, w - 2, h - 2, fill, Math.max(1, r - 1))
}
const boxed = (c, x, y, w, h, fill) => {
  c.rect(x, y, w, h, "k")
  c.rect(x + 1, y + 1, w - 2, h - 2, fill)
}

// Overlapping blobs [cx, cy, rx, ry] drawn as ONE ink-fenced mass.
const puffs = (c, list, col) => {
  for (const [cx, cy, rx, ry] of list) c.ellipse(cx, cy, rx + 1, ry + 1, "k")
  for (const [cx, cy, rx, ry] of list) c.ellipse(cx, cy, rx, ry, col)
}

// A bush: green blobs, a light patch on top, a shade patch below, blossoms.
const bush = (c, list, blossoms = [], base = "t", shade = "T", light = "u") => {
  puffs(c, list, base)
  const top = Math.min(...list.map((b) => b[1] - b[3]))
  const bot = Math.max(...list.map((b) => b[1] + b[3]))
  c.recolor({ [base]: shade }, (x, y) => y > bot - 3)
  c.recolor({ [base]: light }, (x, y) => y < top + 3 && ((x + y) % 5) < 3)
  for (const [x, y, col] of blossoms) { c.px(x, y, col); c.px(x + 1, y, col) }
}

// A window: ink frame, a trim ring, glass with a shade band, a glint, a cross.
const win = (c, x, y, w, h, trim = "b", arch = false) => {
  rbox(c, x, y, w, h, trim, arch ? 3 : 2)
  if (!arch) { /* square-ish */ }
  rr(c, x + 2, y + 2, w - 4, h - 4, "k", arch ? 2 : 1)
  rr(c, x + 3, y + 3, w - 6, h - 6, "g", 1)
  c.rect(x + 3, y + 3, w - 6, 2, "G")
  c.rect(x + (w >> 1), y + 3, 1, h - 6, "k")
  c.rect(x + 3, y + (h >> 1), w - 6, 1, "k")
  c.px(x + 4, y + 7, "h"); c.px(x + 5, y + 6, "h")
}
const shutter = (c, x, y, h, col) => {
  rbox(c, x, y, 4, h, col, 1)
  for (let yy = y + 4; yy < y + h - 2; yy += 3) c.rect(x + 1, yy, 2, 1, "k")
}
// A hanging flower box: wood, with leaves and blossoms growing out of it.
const fbox = (c, x, y, w, cols) => {
  c.rect(x + 1, y - 3, w - 2, 3, "t")
  for (let i = 0, xx = x + 2; xx < x + w - 3; xx += 4, i++) {
    c.px(xx, y - 4, cols[i % cols.length]); c.px(xx + 1, y - 4, cols[i % cols.length])
    c.px(xx, y - 3, cols[(i + 1) % cols.length])
  }
  rbox(c, x, y, w, 5, "w", 1)
  c.rect(x + 1, y + 3, w - 2, 1, "x")
}

// Scalloped shingle rows on a roof colour: a shade scallop under each row and a
// light edge on top, mirrored about the centre column `cx`.
const shingles = (c, y0, y1, base, shade, light, cx, band = 6) => {
  const ph = (x, y) => (Math.abs(x - cx) + (Math.floor((y - y0) / band) % 2) * 3) % 6
  c.recolor({ [base]: shade }, (x, y) => {
    if (y < y0 || y >= y1) return false
    const r = (y - y0) % band
    return r === band - 1 || (r === band - 2 && ph(x, y) < 3)
  })
  c.recolor({ [base]: light }, (x, y) => y >= y0 && y < y1 && (y - y0) % band === 0 && ph(x, y) >= 3)
}

// Bunting along a sagging line: little triangles in turn.
const bunting = (c, x0, x1, y, cols, sag = 4) => {
  for (let x = x0, i = 0; x <= x1; x += 5, i++) {
    const t = (x - x0) / (x1 - x0)
    const yy = y + Math.round(sag * 4 * t * (1 - t))
    c.px(x, yy, "k"); c.px(x + 1, yy, "k"); c.px(x + 2, yy, "k"); c.px(x + 3, yy, "k")
    const col = cols[i % cols.length]
    c.rect(x, yy + 1, 4, 1, col); c.rect(x + 1, yy + 2, 2, 1, col); c.px(x + 1, yy + 3, "k"); c.px(x + 2, yy + 3, "k")
  }
}

// Awning stripes from x0 to the centre column cx (symmetric about cx): every A
// stripe hangs two rows lower, a scalloped edge with a shade row under the top.
const awn = (c, x0, cx, y, h, A, B, shadeA, shadeB) => {
  for (let x = x0; x <= cx; x++) {
    const isA = Math.floor((Math.abs(x - cx) + 3) / 6) % 2 === 0
    const col = isA ? A : B
    const hh = isA ? h + 2 : h
    c.rect(x, y, 1, hh, col)
    c.px(x, y, isA ? shadeA : shadeB)
    c.px(x, y - 1, "k")
    c.px(x, y + hh, "k")
  }
}

// An outline of two cells: the fill sprite, then two outline8 passes.
const twoRing = (name, w, h, ...items) => {
  sprite("_" + name + "_fill", { w, h }, ...items)
  sprite("_" + name + "_1", { base: "_" + name + "_fill", outline8: "k" })
  sprite(name, { base: "_" + name + "_1", outline8: "k" })
}

// ---- cartoon helpers ---------------------------------------------------------

// A bell-flared roof: rows y0..y1-1, the half-width growing from hwTop to hwBase
// along a curve (p > 1 flares at the eave), drawn full width about cx.
const flare = (c, cx, y0, y1, hwTop, hwBase, col, p = 1.7) => {
  const n = y1 - y0
  for (let i = 0; i < n; i++) {
    const t = n === 1 ? 1 : i / (n - 1)
    const hw = Math.round(hwTop + (hwBase - hwTop) * Math.pow(t, p))
    c.rect(cx - hw, y0 + i, 2 * hw + 1, 1, col)
  }
}
// A scalloped hem under a band: blobs of `col` hang at row y, ink under them.
const scallops = (c, cx, x0, x1, y, col, period = 6) => {
  for (let x = x0; x <= x1; x++) {
    if (Math.abs(x - cx) % period < period / 2) { c.px(x, y, col); c.px(x, y + 1, "k") }
    else c.px(x, y, "k")
  }
}
// A round window: ink ring, trim ring, glass, a cross, a glint.
const porthole = (c, x, y, r, trim = "W") => {
  c.circ(x, y, r + 1, "k"); c.circ(x, y, r, trim); c.circ(x, y, r - 2, "k"); c.circ(x, y, r - 3, "g")
  c.rect(x - r + 3, y - r + 3, 2 * r - 5, 1 + (r > 6 ? 1 : 0), "G")
  c.rect(x, y - r + 3, 1, 2 * r - 5, "k"); c.rect(x - r + 3, y, 2 * r - 5, 1, "k")
  c.px(x - 3, y - 2, "h"); c.px(x - 2, y - 3, "h")
}

// ---- the town hall (job_interview) ----------------------------------------
// 147 wide, centre 73: a gold onion cupola on a bell-flared blue roof, pennants
// between fat pillars, an arched door under a striped canopy.
sprite("_office_body", { w: 147, h: 142, mx: "c" }, (c) => {
  const cx = 73
  // walls first: the roof's hem is drawn over them
  rr(c, 6, 68, 135, 62, "c", 3)
  c.recolor({ c: "C" }, (x, y) => y >= 68 && y < 80)
  rbox(c, 6, 70, 6, 52, "b", 1); c.rect(7, 71, 1, 50, "e"); c.rect(10, 71, 1, 50, "B")
  shutter(c, 12, 88, 24, "b"); shutter(c, 44, 88, 24, "b")
  win(c, 17, 84, 26, 32, "W", true)
  fbox(c, 15, 119, 30, ["r", "y", "W"])
  // pillars and pennants
  rbox(c, 52, 90, 8, 34, "W", 1); c.rect(53, 91, 2, 32, "a"); c.rect(58, 91, 1, 32, "C")
  rbox(c, 50, 87, 12, 5, "y", 1); c.rect(51, 88, 10, 1, "z")
  bunting(c, 62, 84, 96, ["r", "y", "b", "W"], 3)
  // the door
  rr(c, 62, 98, 23, 32, "k", 3); rr(c, 63, 99, 21, 31, "W", 3)
  rr(c, 65, 101, 17, 29, "w", 3); c.rect(65, 116, 17, 14, "w")
  c.rect(73, 101, 1, 29, "k"); c.circ(69, 107, 2, "g"); c.px(68, 106, "h")
  c.rect(65, 126, 17, 4, "x"); c.px(71, 118, "y"); c.px(75, 118, "y")
  awn(c, 58, 73, 88, 7, "b", "W", "B", "C")
  // the onion cupola and the flared roof
  c.ellipse(cx, 14, 8, 10, "y")
  c.recolor({ y: "Y" }, (x, y) => y >= 19 && y < 25)
  c.recolor({ y: "z" }, (x, y) => x < cx - 1 && y < 14 && (x + y) % 3 < 2)
  c.circ(cx, 2, 2, "y")
  rbox(c, cx - 9, 25, 19, 11, "W", 1)
  c.circ(cx, 30, 4, "k"); c.circ(cx, 30, 3, "g"); c.px(cx - 1, 29, "h")
  flare(c, cx, 35, 64, 12, 71, "b", 1.7)
  shingles(c, 37, 62, "b", "B", "e", cx)
  rr(c, 0, 62, 148, 7, "B", 2); c.rect(0, 62, 148, 1, "k")
  scallops(c, cx, 0, cx, 69, "B")
  // the foot
  rr(c, 6, 123, 135, 8, "s", 2); c.recolor({ s: "S" }, (x, y) => y >= 129)
  rr(c, 34, 131, 79, 5, "s", 2); c.recolor({ s: "S" }, (x, y) => y >= 134)
  bush(c, [[12, 127, 8, 5], [23, 126, 9, 6], [32, 128, 6, 4]], [[10, 125, "p"], [21, 123, "y"], [28, 126, "W"], [33, 128, "p"]])
})
twoRing("office", 147, 160,
  (c) => {
    c.rect(73, 0, 2, 22, "w")                                       // flagpole
    rr(c, 75, 0, 15, 10, "r", 1); c.rect(75, 6, 15, 4, "R"); c.rect(75, 0, 15, 1, "q")
  },
  stamp("_office_body", 0, 16))

// ---- the school (right of the avenue, top) ---------------------------------
// 149 wide, centre 74: a tall sharpened-pencil tower, round porthole windows in
// the wings, bunting along them, pine bell-roofs.
sprite("_school_body", { w: 149, h: 142, mx: "c" }, (c) => {
  const cx = 74
  // wings: coral walls, a little bell roof each
  rr(c, 3, 100, 50, 30, "r", 2)
  c.recolor({ r: "R" }, (x, y) => y >= 100 && y < 104)
  rbox(c, 3, 100, 6, 30, "W", 1)
  porthole(c, 20, 118, 8); porthole(c, 40, 118, 8)
  bunting(c, 10, 52, 104, ["r", "y", "b", "W", "p"], 3)
  flare(c, 27, 82, 100, 8, 27, "d", 1.6)
  shingles(c, 84, 98, "d", "D", "f", 27, 5)
  rr(c, 0, 97, 55, 5, "D", 2); c.rect(0, 97, 55, 1, "k")
  scallops(c, 27, 0, 54, 102, "D")
  // central block
  rr(c, 52, 74, 45, 56, "r", 2)
  c.recolor({ r: "R" }, (x, y) => y >= 74 && y < 79)
  rbox(c, 52, 74, 5, 56, "W", 1)
  win(c, 62, 84, 25, 20, "W", true)
  rr(c, 62, 106, 25, 24, "k", 3); rr(c, 63, 107, 23, 23, "W", 3)
  rr(c, 65, 109, 19, 21, "w", 3); c.rect(65, 118, 19, 12, "w")
  c.rect(74, 109, 1, 21, "k"); c.circ(69, 114, 2, "g"); c.px(68, 113, "h")
  c.rect(65, 126, 19, 4, "x")
  rbox(c, 55, 110, 4, 7, "y", 1); c.px(56, 111, "z")
  // clock tower
  rr(c, 60, 40, 29, 36, "r", 1)
  c.recolor({ r: "R" }, (x, y) => y >= 70 && y < 76)
  c.circ(cx, 56, 10, "k"); c.circ(cx, 56, 9, "W")
  c.recolor({ W: "C" }, (x, y) => y > 60 && (x - cx) * (x - cx) + (y - 56) * (y - 56) < 81)
  c.rect(cx, 49, 1, 8, "k"); c.rect(cx, 56, 6, 1, "k")
  rr(c, 56, 35, 37, 7, "D", 2); c.rect(56, 35, 37, 1, "k")
  // the pencil: a long yellow cone, a wood tip, a lead point
  flare(c, cx, 0, 35, 0, 15, "y", 1.0)
  c.recolor({ y: "Y" }, (x, y) => y >= 9 && Math.abs(x - cx) >= Math.round(15 * y / 34) - 4)
  c.recolor({ y: "X" }, (x, y) => y < 9)
  c.recolor({ Y: "x" }, (x, y) => y < 9)
  c.rect(cx, 0, 1, 3, "k"); c.rect(cx - 1, 2, 3, 2, "k")
  // the foot
  rr(c, 3, 128, 71, 5, "s", 1); c.recolor({ s: "S" }, (x, y) => y >= 131)
  rr(c, 46, 132, 80, 5, "s", 2); c.recolor({ s: "S" }, (x, y) => y >= 135)
  bush(c, [[8, 130, 8, 4], [19, 129, 7, 4]], [[6, 129, "p"], [17, 127, "y"], [21, 130, "W"]])
})
twoRing("school", 149, 142, stamp("_school_body", 0, 0))

// ---- the restaurant (left, upper row) -------------------------------------
// 145 wide, centre 72: a muffin-top roof with cream frosting dripping off the
// eave, a crooked chef's-hat chimney, a scalloped awning.
sprite("_restaurant_body", { w: 145, h: 128, mx: "c" }, (c) => {
  const cx = 72
  rr(c, 4, 48, 137, 78, "c", 3)
  c.recolor({ c: "C" }, (x, y) => y >= 48 && y < 58)
  shutter(c, 8, 62, 20, "r"); shutter(c, 36, 62, 20, "r")
  win(c, 12, 61, 22, 20, "r")
  fbox(c, 10, 82, 26, ["r", "y", "p"])
  win(c, 61, 60, 23, 20, "r", true)
  awn(c, 4, cx, 88, 8, "r", "y", "R", "Y")
  win(c, 12, 102, 22, 16, "r")
  rr(c, 62, 98, 21, 28, "k", 3); rr(c, 63, 99, 19, 27, "w", 3); c.rect(63, 110, 19, 16, "w")
  c.rect(72, 99, 1, 27, "k"); c.circ(67, 104, 2, "g"); c.px(66, 103, "h")
  c.rect(63, 122, 19, 4, "x"); c.px(69, 114, "y"); c.px(75, 114, "y")
  c.rect(44, 92, 14, 2, "x"); c.rect(46, 94, 1, 3, "k"); c.rect(55, 94, 1, 3, "k")
  rbox(c, 43, 97, 15, 10, "y", 1); c.rect(44, 98, 13, 1, "z"); c.rect(44, 105, 13, 1, "Y")
  // the muffin-top roof and its frosting
  flare(c, cx, 6, 44, 18, 70, "r", 1.5)
  shingles(c, 8, 42, "r", "R", "q", cx)
  rr(c, 0, 42, 146, 7, "R", 2); c.rect(0, 42, 146, 1, "k")
  for (let x = 6, i = 0; x <= cx; x += 8, i++) {
    const h = [8, 11, 7, 10, 8][i % 5]
    rbox(c, x, 44, 7, h, "W", 2); c.rect(x + 1, 45, 1, h - 3, "a")
  }
  c.circ(cx, 4, 3, "y"); c.px(cx - 1, 3, "z")
  // the foot
  rr(c, 4, 120, 137, 7, "s", 1); c.recolor({ s: "S" }, (x, y) => y >= 125)
  bush(c, [[46, 124, 5, 3]], [[44, 123, "p"], [48, 123, "y"]])
})
twoRing("restaurant", 145, 134,
  (c) => {                                                       // the chimney leans, its top puffs out
    rbox(c, 106, 12, 12, 24, "c", 1); rbox(c, 108, 4, 12, 12, "c", 1)
    for (const yy of [20, 27]) c.rect(107, yy, 10, 1, "C")
    puffs(c, [[112, 4, 8, 4], [119, 5, 6, 4]], "W")
    c.recolor({ W: "a" }, (x, y) => y < 4 && x < 114)
    c.rect(108, 9, 12, 1, "C")
  },
  stamp("_restaurant_body", 0, 4),
  (c) => {                                                       // a table and two stools
    rr(c, 4, 123, 26, 4, "k", 1); rr(c, 5, 124, 24, 2, "W", 1)
    c.rect(8, 127, 3, 7, "k"); c.rect(24, 127, 3, 7, "k")
    c.rect(9, 127, 1, 6, "x"); c.rect(25, 127, 1, 6, "x")
    rbox(c, 0, 128, 8, 4, "r", 1); rbox(c, 28, 128, 8, 4, "r", 1)
  })

// ---- the shop (right, upper row) --------------------------------------------
// 149 wide, centre 74: the roof is a striped party hat with a gold pom-pom.
sprite("_shop_body", { w: 149, h: 134, mx: "c" }, (c) => {
  const cx = 74
  rr(c, 4, 64, 141, 62, "v", 3)
  c.recolor({ v: "V" }, (x, y) => y >= 64 && y < 72)
  rbox(c, 4, 64, 6, 58, "W", 1); c.rect(8, 65, 1, 56, "C")
  awn(c, 11, cx, 72, 9, "b", "W", "B", "C")
  // display windows showing what it sells
  rbox(c, 13, 88, 34, 32, "w", 3)
  rr(c, 15, 90, 30, 28, "g", 2); c.rect(15, 90, 30, 3, "G")
  c.rect(30, 90, 1, 28, "k"); c.px(18, 96, "h"); c.px(19, 95, "h")
  rbox(c, 17, 110, 12, 8, "x", 1)
  c.poly([20, 110, 23, 100, 26, 110], "r"); c.rect(21, 105, 5, 1, "y"); c.px(23, 99, "y")
  rbox(c, 32, 110, 12, 8, "x", 1)
  c.rect(34, 102, 8, 8, "y"); c.px(34, 101, "y"); c.px(37, 100, "y"); c.px(41, 101, "y"); c.rect(34, 107, 8, 1, "Y")
  rr(c, 63, 86, 23, 40, "k", 3); rr(c, 64, 87, 21, 39, "W", 3)
  rr(c, 66, 89, 17, 37, "w", 3); c.rect(66, 106, 17, 20, "w")
  c.rect(74, 89, 1, 37, "k"); rr(c, 68, 91, 5, 8, "g", 1); c.px(69, 92, "h")
  c.rect(66, 122, 17, 4, "x"); c.px(71, 110, "y"); c.px(77, 110, "y")
  c.rect(54, 86, 8, 2, "x"); rbox(c, 54, 89, 8, 7, "y", 1)
  // little hip roofs either side, then the party hat on top
  flare(c, 28, 52, 62, 12, 30, "b", 1.4)
  shingles(c, 54, 62, "b", "B", "e", 28, 5)
  rr(c, 0, 60, 62, 6, "B", 2); c.rect(0, 60, 62, 1, "k")
  scallops(c, 28, 0, 58, 66, "B")
  flare(c, cx, 6, 54, 1, 27, "r", 1.1)
  c.recolor({ r: "y" }, (x, y) => y > 10 && y < 56 && (x + 2 * y) % 16 < 5)
  c.recolor({ r: "R" }, (x, y) => y > 12 && y < 56 && Math.abs(x - cx) >= Math.round(27 * (y - 6) / 48) - 4)
  c.recolor({ y: "Y" }, (x, y) => y > 12 && y < 56 && Math.abs(x - cx) >= Math.round(27 * (y - 6) / 48) - 4)
  c.circ(cx, 20, 8, "k"); c.circ(cx, 20, 7, "w"); c.circ(cx, 20, 5, "g")
  c.rect(cx, 15, 1, 10, "k"); c.rect(69, 20, 11, 1, "k"); c.px(71, 18, "h")
  rr(c, 46, 50, 57, 6, "B", 2); c.rect(46, 50, 57, 1, "k")
  scallops(c, cx, 46, cx, 56, "B")
  c.circ(cx, 4, 5, "y")
  c.recolor({ y: "z" }, (x, y) => y < 4 && x < cx)
  // the foot
  rr(c, 4, 120, 141, 7, "s", 1); c.recolor({ s: "S" }, (x, y) => y >= 125)
  bush(c, [[9, 123, 8, 4], [20, 122, 7, 4]], [[7, 122, "p"], [18, 120, "y"], [22, 123, "W"]])
})
twoRing("shop", 149, 134, stamp("_shop_body", 0, 0))

// ---- the clinic: a spotted green mushroom cottage (left, lower row) -----------
sprite("_clinic_body", { w: 145, h: 148, mx: "c" }, (c) => {
  const cx = 72
  // the cap, spots, gills under its rim
  c.ellipse(cx, 66, 64, 46, "d")
  c.recolor({ d: "D" }, (x, y) => y >= 66)
  c.recolor({ d: "f" }, (x, y) => ((x - 46) * (x - 46)) / 130 + ((y - 32) * (y - 32)) / 14 < 1 || ((x - 30) * (x - 30)) / 30 + ((y - 46) * (y - 46)) / 10 < 1)
  c.rect(0, 82, 73, 60, "_")
  for (const [x, y, r] of [[34, 56, 7], [56, 36, 6], [14, 76, 4], [76, 24, 5]]) {
    c.circ(x, y, r + 1, "k"); c.circ(x, y, r, "W"); c.px(x + 2, y + 2, "C"); c.px(x + 1, y + 3, "C")
  }
  // the stem: a fat cream cottage under the cap
  rr(c, 26, 82, 93, 54, "c", 3)
  c.recolor({ c: "C" }, (x, y) => y >= 82 && y < 90)
  shutter(c, 30, 98, 22, "b")
  porthole(c, 48, 108, 11, "W")
  fbox(c, 36, 124, 24, ["r", "y", "W"])
  rr(c, 59, 100, 27, 36, "k", 3); rr(c, 60, 101, 25, 35, "W", 3)
  rr(c, 62, 103, 21, 33, "g", 3); c.rect(62, 103, 21, 4, "G")
  c.rect(72, 103, 1, 33, "k"); c.rect(62, 118, 21, 1, "k"); c.px(65, 108, "h"); c.px(66, 107, "h")
  rr(c, 26, 132, 93, 7, "s", 1); c.recolor({ s: "S" }, (x, y) => y >= 137)
  rr(c, 52, 138, 42, 5, "s", 2)
  rr(c, 8, 68, 130, 14, "W", 2); c.rect(8, 68, 130, 1, "k"); c.rect(8, 81, 130, 1, "k")
  c.rect(9, 78, 128, 3, "C")
  for (let x = cx; x >= 10; x -= 5) { c.rect(x, 71, 1, 7, "C") }
  // the sprout
  c.rect(71, 10, 3, 12, "t"); c.rect(73, 10, 1, 12, "T")
  puffs(c, [[65, 9, 6, 3]], "u")
  c.recolor({ u: "i" }, (x, y) => y < 9)
})
twoRing("clinic", 145, 152,
  stamp("_clinic_body", 0, 2),
  (c) => {
    rbox(c, 0, 114, 21, 6, "w", 1); rbox(c, 0, 122, 21, 5, "w", 1); c.rect(1, 123, 19, 1, "X")
    rbox(c, 2, 127, 4, 9, "x", 1); rbox(c, 15, 127, 4, 9, "x", 1)
    rbox(c, 125, 126, 14, 12, "r", 1); c.rect(126, 127, 12, 2, "q"); c.rect(126, 135, 12, 2, "R")
    bush(c, [[132, 120, 7, 7], [127, 122, 4, 4]], [[130, 118, "p"], [134, 122, "y"]])
  })

// ---- the cafe (right, lower row) --------------------------------------------
// 139 wide, centre 69: a cottage with a wavy brown roof, a steaming chimney and
// donut-ring windows (pink icing, sprinkles).
sprite("_cafe_body", { w: 139, h: 134, mx: "c" }, (c) => {
  const cx = 69
  rr(c, 3, 50, 133, 78, "w", 3)
  for (const x of [60, 51, 42, 33, 24, 15, 6]) c.rect(x, 50, 1, 78, "x")
  c.recolor({ w: "x" }, (x, y) => y >= 50 && y < 56)
  bunting(c, 5, 66, 54, ["y", "r", "b", "W"], 3)
  awn(c, 3, cx, 62, 8, "r", "W", "R", "C")
  // donut windows
  for (const x of [28]) {
    c.circ(x, 96, 17, "k"); c.circ(x, 96, 16, "q"); c.circ(x, 96, 8, "k"); c.circ(x, 96, 7, "g")
    c.recolor({ q: "R" }, (xx, yy) => yy > 104 && (xx - x) * (xx - x) + (yy - 96) * (yy - 96) < 256)
    c.rect(x - 5, 91, 11, 2, "G"); c.px(x - 3, 94, "h"); c.px(x - 2, 93, "h")
    for (const [dx, dy, col] of [[-12, -6, "y"], [-9, 8, "b"], [11, 4, "W"], [10, -9, "y"], [-1, -13, "r"], [3, 12, "W"], [-14, 3, "W"], [14, 12, "b"]]) {
      c.px(x + dx, 96 + dy, col); c.px(x + dx + 1, 96 + dy, col)
    }
  }
  rr(c, 56, 78, 27, 50, "k", 3); rr(c, 57, 79, 25, 49, "W", 3)
  rr(c, 59, 81, 21, 47, "w", 3); c.rect(59, 108, 21, 20, "w")
  rr(c, 62, 85, 15, 14, "g", 2); c.rect(62, 85, 15, 2, "G"); c.rect(69, 85, 1, 14, "k"); c.px(64, 88, "h")
  c.rect(59, 124, 21, 4, "x"); c.px(65, 112, "y")
  rbox(c, 44, 118, 9, 9, "r", 1); bush(c, [[48, 114, 5, 4]], [[47, 113, "y"]])
  rbox(c, 36, 66, 5, 7, "y", 1); c.px(37, 67, "z"); c.rect(38, 62, 1, 4, "k")   // a hanging lantern
  // the wavy roof
  flare(c, cx, 14, 48, 14, 68, "n", 1.5)
  shingles(c, 16, 46, "n", "N", "o", cx)
  rr(c, 0, 46, 140, 7, "N", 2); c.rect(0, 46, 140, 1, "k")
  scallops(c, cx, 0, cx, 53, "N", 8)
  c.circ(cx, 12, 3, "y"); c.px(cx - 1, 11, "z")
  rr(c, 3, 124, 133, 6, "s", 1); c.recolor({ s: "S" }, (x, y) => y >= 128)
})
twoRing("cafe", 139, 142,
  (c) => {                                                       // the chimney and its steam
    rbox(c, 102, 18, 13, 28, "n", 1); for (const yy of [26, 33]) c.rect(103, yy, 11, 1, "N")
    rr(c, 100, 14, 17, 6, "N", 1)
    puffs(c, [[108, 8, 5, 3], [114, 2, 4, 3]], "W")
    c.recolor({ W: "a" }, (x, y) => y < 6)
  },
  stamp("_cafe_body", 0, 8))

// ---- the gazebo (bottom right) ---------------------------------------------
sprite("_gazebo_body", { w: 69, h: 90, mx: "c" }, (c) => {
  const cx = 34
  c.rect(3, 48, 62, 28, "N")                                      // the inside
  rbox(c, 3, 46, 7, 32, "w", 1); rbox(c, 31, 46, 7, 32, "w", 1)
  for (const x of [4, 32]) for (let y = 48; y < 76; y += 6) { c.rect(x, y, 5, 2, "W"); c.rect(x, y + 2, 5, 1, "X") }
  c.rect(10, 62, 21, 4, "W"); c.rect(10, 61, 21, 1, "k"); c.rect(10, 66, 21, 1, "k")
  for (const x of [13, 18, 23, 28]) rbox(c, x, 67, 3, 10, "W", 1)
  for (const x of [11, 17, 24, 29]) { c.px(x, 59, "p"); c.px(x + 1, 58, "y"); c.px(x + 2, 59, "r") }
  rbox(c, 15, 50, 5, 7, "y", 1); c.px(16, 51, "z")
  // the onion dome and its curly tip
  c.ellipse(cx, 28, 24, 17, "r")
  c.recolor({ r: "q" }, (x, y) => Math.abs(x - cx) % 10 < 4 && y < 40)
  c.recolor({ r: "R" }, (x, y) => y >= 38)
  c.recolor({ q: "R" }, (x, y) => y >= 38)
  c.rect(0, 42, 72, 6, "_")
  flare(c, cx, 4, 14, 0, 6, "r", 0.8)
  c.circ(cx, 4, 3, "y"); c.px(cx - 1, 3, "z")
  rr(c, 0, 39, 71, 7, "R", 2); c.rect(0, 39, 71, 1, "k")
  scallops(c, cx, 0, cx, 46, "R", 6)
  rr(c, 1, 76, 68, 6, "s", 2); c.recolor({ s: "S" }, (x, y) => y >= 80)
  bush(c, [[7, 82, 7, 4]], [[5, 81, "p"], [9, 82, "y"]])
})
twoRing("gazebo", 88, 92,
  stamp("_gazebo_body", 0, 2),
  (c) => {
    c.rect(74, 46, 3, 44, "w"); c.rect(75, 46, 1, 44, "X")
    rbox(c, 71, 40, 14, 7, "W", 1)
    rbox(c, 73, 52, 12, 6, "y", 1)
    bush(c, [[78, 88, 7, 3]], [[76, 87, "p"], [80, 88, "y"]])
  })

// ============================================================================
// THE GROUND: 342 x 750 cells.
// ============================================================================
// Rows/cols (cells) of everything the paths and buildings hang off. gen_town.py
// has the same numbers (LAYOUT, RING, FEET): change both.
const AVE = [157, 184]            // the avenue, inclusive
const TOP_WALK = [178, 198]       // the sidewalk the hall and school stand on
const MID_WALK = [337, 357]       // ... the restaurant's and the shop's
const ARM = [545, 577]            // the arms to the clinic and the cafe
const PLAZA = [171, 561, 65, 57]  // centre x, y and radii
const STUBS = [[61, 90, 506], [255, 284, 498]]   // [left col, right col, top row]
const GATE = [185, 282, 670, 684] // the gazebo's path: cols, then rows

// ---- trees: fluffy lobed crowns, a shade patch below, a light patch top left ----
const tree = (name, k, base, shade, light, dots, dotc) => {
  const lobes = [[13, 11, 10, 9], [7, 16, 7, 7], [19, 16, 7, 7], [13, 17, 9, 6]]
    .map(([x, y, rx, ry]) => [Math.round(x * k), Math.round(y * k), Math.round(rx * k), Math.round(ry * k)])
  const w = Math.round(26 * k), h = Math.round(34 * k)
  twoRing(name, w, h,
    (c) => {
      const tw = Math.round(5 * k), tx = Math.round(13 * k) - (tw >> 1)
      rbox(c, tx, Math.round(21 * k), tw, h - Math.round(21 * k), "w", 1)
      c.rect(tx + tw - 2, Math.round(23 * k), 1, h - Math.round(24 * k), "x")
      puffs(c, lobes, base)
      c.recolor({ [base]: shade }, (x, y) => y >= Math.round(19 * k))
      c.recolor({ [base]: light }, (x, y) => x < Math.round(15 * k) && y < Math.round(13 * k) && ((x + y) % 4) < 2)
      for (const [dx, dy] of dots) { c.px(Math.round(dx * k), Math.round(dy * k), dotc); c.px(Math.round(dx * k) + 1, Math.round(dy * k), dotc) }
    })
}
const BERRIES = [[8, 9], [17, 7], [12, 15], [20, 14], [5, 17], [22, 19], [14, 20]]
tree("tree_t", 1, "t", "T", "u", [], "r")
tree("tree_u", 1, "u", "t", "i", [], "r")
tree("tree_bt", 1.35, "t", "T", "u", BERRIES, "r")
tree("tree_bu", 1.35, "u", "t", "i", BERRIES, "y")
tree("tree_pink", 1.15, "p", "r", "W", BERRIES, "q")
tree("tree_apple", 1.15, "t", "T", "u", BERRIES, "r")

// ---- bushes, flower beds, bench, lamp ---------------------------------------
twoRing("bush", 30, 16, (c) => bush(c, [[8, 10, 7, 5], [15, 8, 8, 6], [22, 10, 7, 5]], [[6, 10, "p"], [14, 6, "y"], [20, 9, "W"], [24, 11, "p"]]))
twoRing("bush_u", 30, 16, (c) => bush(c, [[8, 10, 7, 5], [15, 8, 8, 6], [22, 10, 7, 5]], [[7, 9, "r"], [13, 7, "W"], [19, 6, "p"], [23, 10, "y"]], "u", "t", "i"))
twoRing("bed", 34, 14, (c) => {
  puffs(c, [[17, 8, 15, 5]], "x")
  c.recolor({ x: "w" }, (x, y) => y < 7)
  for (const [x, y, col] of [[5, 5, "r"], [9, 3, "W"], [13, 5, "y"], [17, 3, "p"], [21, 5, "r"], [25, 3, "y"], [29, 5, "W"]]) {
    c.rect(x, y, 3, 3, col); c.px(x + 1, y + 1, col === "y" ? "r" : "y"); c.px(x + 1, y + 3, "t")
  }
})
twoRing("bench", 26, 18, (c) => {
  rbox(c, 0, 0, 26, 6, "w", 1); c.rect(1, 1, 24, 1, "X")
  for (const x of [8, 17]) c.rect(x, 1, 1, 4, "x")
  rbox(c, 0, 8, 26, 5, "w", 1); c.rect(1, 9, 24, 1, "X")
  rbox(c, 2, 13, 4, 5, "x", 1); rbox(c, 20, 13, 4, 5, "x", 1)
})
twoRing("lamp", 11, 44, (c) => {
  rbox(c, 4, 12, 3, 30, "N", 1)
  rbox(c, 1, 38, 9, 6, "N", 1)
  rbox(c, 1, 2, 9, 11, "y", 1); c.rect(2, 3, 7, 2, "z"); c.rect(3, 6, 2, 4, "z")
  rr(c, 0, 0, 11, 3, "N", 1)
})

// ---- the fountain: a wide stone basin, a pedestal, two bowls, a jet and its drops -----
twoRing("fountain", 83, 54, (c) => {
  puffs(c, [[41, 36, 39, 15]], "s")
  c.recolor({ s: "S" }, (x, y) => y >= 44)
  c.recolor({ s: "a" }, (x, y) => y < 28)
  c.ellipse(41, 35, 33, 11, "g")
  c.recolor({ g: "G" }, (x, y) => y < 31 || (x - 41) * (x - 41) / 1089 + (y - 35) * (y - 35) / 121 > 0.7)
  for (const [x, y] of [[26, 37], [27, 36], [52, 38], [53, 37], [38, 41], [46, 40]]) c.px(x, y, "h")
  rbox(c, 36, 16, 11, 20, "s", 1); c.rect(37, 17, 2, 18, "a"); c.rect(44, 17, 2, 18, "S")
  puffs(c, [[41, 16, 17, 6]], "s")
  c.ellipse(41, 15, 12, 3, "g"); c.rect(33, 14, 16, 1, "G"); c.px(34, 15, "h")
  rbox(c, 38, 8, 7, 9, "s", 1)
  puffs(c, [[41, 8, 9, 4]], "s")
  c.ellipse(41, 7, 6, 2, "g")
  c.rect(40, 0, 3, 7, "g"); c.rect(41, 0, 1, 7, "h")
  for (const [x, y] of [[34, 2], [48, 3], [31, 6], [51, 7]]) { c.px(x, y, "h"); c.px(x, y + 1, "g") }
})

// ---- the pond: a sand rim, lily pads with blossoms, reeds ------------------------
sprite("_pond_fill", { w: 112, h: 70 }, (c) => {
  c.ellipse(30, 24, 30, 20, "g")
  c.ellipse(68, 38, 40, 26, "g")
  c.ellipse(94, 30, 18, 14, "g")
  c.ellipse(38, 46, 26, 14, "g")
  c.recolor({ g: "G" }, (x, y) => y < 12 || (y < 18 && x > 70 && x < 100))
  for (const [x, y, w] of [[18, 22, 8], [62, 42, 10], [82, 28, 6], [34, 50, 7], [48, 30, 5]]) c.rect(x, y, w, 1, "h")
  for (const [x, y] of [[40, 40], [74, 24], [26, 50]]) {
    puffs(c, [[x, y, 6, 3]], "u"); c.recolor({ u: "t" }, (xx, yy) => yy > y + 1 && xx > x - 7 && xx < x + 7 && yy < y + 4)
    c.px(x, y - 1, "p"); c.px(x + 1, y - 1, "W"); c.px(x - 1, y - 1, "W"); c.px(x, y - 2, "p")
  }
  for (const x of [100, 104, 108]) { c.rect(x, 12, 1, 22, "t"); c.rect(x - 1, 10, 3, 5, "x") }
})
sprite("_pond_1", { base: "_pond_fill", outline8: "C" })
sprite("_pond_2", { base: "_pond_1", outline8: "C" })
sprite("pond", { base: "_pond_2", outline8: "k" })

// ---- lawn texture: tufts, a few blossoms ------------------------------------------
sprite("_tuft_a", "L.L.L\n.LLL.")
sprite("_tuft_b", "i.i\n.i.")
sprite("_fl_r", ".r.\nryr\n.r.")
sprite("_fl_w", ".W.\nWyW\n.W.")
sprite("_fl_p", ".p.\npyp\n.p.")
sprite("_fl_y", ".y.\nyWy\n.y.")
group("tufts", ["_tuft_a", "_tuft_a", "_tuft_b"])
group("blossoms", ["_fl_r", "_fl_w", "_fl_p", "_fl_y"])

// ---- the paving: cobbles in a running bond, a soft curb, ink round the whole ---------
const brick = (c, x0, y0, w, h, bh, bw) => {
  c.recolor({ c: "C" }, (x, y) => {
    if (x < x0 || x >= x0 + w || y < y0 || y >= y0 + h) return false
    const r = Math.floor((y - y0) / bh)
    if (r > 0 && (y - y0) % bh === 0) return true
    const off = (r % 2) * (bw >> 1)
    return (x - x0 - off) % bw === 0 && x > x0
  })
}
sprite("_paving", { w: 342, h: 750 }, (c) => {
  const [al, ar] = AVE
  const bands = [
    [0, TOP_WALK[0], 342, TOP_WALK[1] - TOP_WALK[0] + 1],
    [0, MID_WALK[0], 342, MID_WALK[1] - MID_WALK[0] + 1],
    [0, ARM[0], 342, ARM[1] - ARM[0] + 1],
    [GATE[0], GATE[2], GATE[1] - GATE[0] + 1, GATE[3] - GATE[2] + 1],
  ]
  for (const [x, y, w, h] of bands) c.rect(x, y, w, h, "c")
  for (const [l, r, top] of STUBS) c.rect(l, top, r - l + 1, ARM[0] - top + 4, "c")
  c.rect(al, 0, ar - al + 1, 750, "c")
  const [px0, py0, rx, ry] = PLAZA
  c.ellipse(px0, py0, rx, ry, "c")
  // the curb: the cells along the edge of the paving, a shade
  c.recolor({ c: "C" }, (x, y) => c.is(x - 1, y, ".") || c.is(x + 1, y, ".") || c.is(x, y - 1, ".") || c.is(x, y + 1, "."))
  // cobbles
  for (const [x, y, w, h] of bands) brick(c, x, y, w, h, 7, 15)
  for (const [l, r, top] of STUBS) brick(c, l, top, r - l + 1, ARM[0] - top, 8, 15)
  brick(c, al, 0, ar - al + 1, 750, 12, 14)
  // the plaza: its own pattern over the avenue's
  c.ellipse(px0, py0, rx, ry, "c")
  c.recolor({ c: "C" }, (x, y) => {
    const u = (x - px0) / rx, v = (y - py0) / ry
    const r = Math.sqrt(u * u + v * v)
    if (r >= 1 || r < 0.62) return false
    const sector = Math.floor((Math.atan2(v, u) + Math.PI) / (2 * Math.PI) * 16)
    return sector % 2 === 0 || r > 0.97
  })
  c.recolor({ c: "W" }, (x, y) => {
    const u = (x - px0) / rx, v = (y - py0) / ry
    return u * u + v * v < 0.62 * 0.62
  })
  c.ellipse(px0, py0, Math.round(rx * 0.62), Math.round(ry * 0.62), "C", true)
})
sprite("paving", { base: "_paving", outline8: "k" })

sprite("ground", { w: 342, h: 750 },
  rect(0, 0, 342, 750, "l"),
  scatter("tufts", 0, 0, 342, 750, 560, { on: "l", clip: true, seed: 3 }),
  scatter("blossoms", 0, 0, 342, 750, 90, { on: "l", clip: true, seed: 8 }),
  stamp("paving", -1, -1),
  // lawn furniture, back to front
  stamp("pond", 8, 614),
  stamp("bench", 48, 590), stamp("bed", 86, 602), stamp("bed", 194, 622),
  stamp("lamp", 92, 496), stamp("lamp", 237, 488),
  stamp("fountain", 128, 523),
  // trees, bushes
  stamp("tree_bt", 2, 0), stamp("tree_u", 40, 8), stamp("tree_pink", 116, 2),
  stamp("tree_t", 192, 4), stamp("tree_u", 224, 12), stamp("tree_bu", 286, 2), stamp("tree_t", 312, 14),
  stamp("tree_bu", 0, 516), stamp("tree_t", 306, 498),
  stamp("tree_apple", 312, 590), stamp("bush_u", 316, 640), stamp("bush", 12, 596),
  stamp("tree_t", 2, 708), stamp("tree_bu", 28, 700), stamp("tree_pink", 66, 708), stamp("tree_bt", 98, 698), stamp("bush", 132, 724),
  stamp("tree_u", 194, 706), stamp("tree_bt", 226, 700), stamp("tree_apple", 270, 710), stamp("tree_t", 304, 704),
  stamp("bush_u", 192, 646))
