// The scenarios town, fourth pass: FLAT. (The earlier passes are town_v1_flat and
// town_v3_shaded; they write the same sprite names, so rebuild only one.)
//
// The owner's rules (TOWN_ART.md section 7): flat fills only -- no shading, no
// lighter/darker tints, no glints -- and no text or icons. So: eleven colours for
// the whole town, at most five per building, round chubby stair-stepped shapes, a
// two-cell ink silhouette, and ONE themed shape per building instead of detail.
// One pixel = one 3-wu cell (world 342 x 750 cells = 1026 x 2250 wu).
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/town.px.js [--only name,...]
// Export: python art_src/gen_town.py [--svg]
pal({
  k: "#14120e",   // ink
  c: "#f4e6c8",   // cream: walls, paving, steps
  w: "#c98f58",   // wood: doors, posts, benches, the cafe's roof
  g: "#a8dcef",   // glass and water
  r: "#ea8b7c",   // coral
  y: "#f0c24c",   // gold
  l: "#8cc56a",   // lawn
  t: "#4e9a55",   // trees and bushes
  b: "#3f93c4",   // blue
  v: "#9a7cc8",   // violet
  d: "#2f6a4f",   // pine
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
// Overlapping blobs [cx, cy, rx, ry] drawn as ONE ink-fenced mass.
const puffs = (c, list, col) => {
  for (const [cx, cy, rx, ry] of list) c.ellipse(cx, cy, rx + 1, ry + 1, "k")
  for (const [cx, cy, rx, ry] of list) c.ellipse(cx, cy, rx, ry, col)
}
const bush = (c, list) => puffs(c, list, "t")
// A bell-flared roof: rows y0..y1-1, the half-width growing from hwTop to hwBase
// along a curve (p > 1 flares at the eave), full width about cx.
const flare = (c, cx, y0, y1, hwTop, hwBase, col, p = 1.7) => {
  const n = y1 - y0
  for (let i = 0; i < n; i++) {
    const t = n === 1 ? 1 : i / (n - 1)
    const hw = Math.round(hwTop + (hwBase - hwTop) * Math.pow(t, p))
    c.rect(cx - hw, y0 + i, 2 * hw + 1, 1, col)
  }
}
// A roof's fat eave: a rounded band with an ink line above and below.
const eave = (c, x, y, w, col) => {
  rr(c, x, y, w, 7, col, 2); c.rect(x, y, w, 1, "k"); c.rect(x, y + 7, w, 1, "k")
}
// Awning stripes from x0 to the centre column cx, symmetric about cx.
const awn = (c, x0, cx, y, h, A, B) => {
  for (let x = x0; x <= cx; x++) {
    const col = Math.floor((Math.abs(x - cx) + 4) / 8) % 2 === 0 ? A : B
    c.rect(x, y, 1, h, col); c.px(x, y - 1, "k"); c.px(x, y + h, "k")
  }
}
// An outline of two cells: the fill sprite, then two outline8 passes.
const twoRing = (name, w, h, ...items) => {
  sprite("_" + name + "_fill", { w, h }, ...items)
  sprite("_" + name + "_1", { base: "_" + name + "_fill", outline8: "k" })
  sprite(name, { base: "_" + name + "_1", outline8: "k" })
}
const door = (c, x, y, w, h) => {                 // an arched wooden door, a seam down the middle
  rr(c, x, y, w, h, "k", 3); rr(c, x + 1, y + 1, w - 2, h - 2, "w", 3)
  c.rect(x + (w >> 1), y + 3, 1, h - 3, "k")
}

// ---- the town hall (job_interview) ----------------------------------------
// A gold onion cupola on a bell-flared blue roof, two big windows, fat pillars.
sprite("_office_body", { w: 147, h: 142, mx: "c" }, (c) => {
  const cx = 73
  rr(c, 6, 66, 135, 64, "c", 3)
  rbox(c, 16, 78, 28, 34, "g", 3)
  rbox(c, 52, 86, 8, 42, "c", 1)
  door(c, 61, 92, 25, 38)
  c.ellipse(cx, 14, 8, 10, "y"); c.circ(cx, 2, 2, "y")
  rbox(c, cx - 8, 25, 17, 10, "c", 1); c.circ(cx, 30, 3, "g")
  flare(c, cx, 34, 62, 12, 71, "b", 1.7)
  eave(c, 0, 60, 148, "b")
  rbox(c, 34, 126, 79, 7, "c", 2); rbox(c, 44, 133, 59, 6, "c", 2)
  bush(c, [[12, 126, 8, 5], [23, 125, 9, 6], [32, 127, 6, 4]])
})
twoRing("office", 147, 160,
  (c) => { c.rect(73, 0, 2, 22, "w"); rbox(c, 75, 0, 15, 10, "r", 1) },
  stamp("_office_body", 0, 16))

// ---- the school (right of the avenue, top) ---------------------------------
// A tall sharpened-pencil tower (gold cone, wood tip, ink point), round windows.
sprite("_school_body", { w: 149, h: 142, mx: "c" }, (c) => {
  const cx = 74
  rr(c, 3, 100, 50, 30, "r", 2)
  for (const x of [20, 40]) { c.circ(x, 117, 8, "k"); c.circ(x, 117, 7, "g") }
  flare(c, 27, 82, 100, 8, 27, "d", 1.6)
  eave(c, 0, 97, 55, "d")
  rr(c, 52, 74, 45, 56, "r", 2)
  rbox(c, 62, 84, 25, 22, "g", 3)
  door(c, 62, 106, 25, 24)
  rr(c, 60, 40, 29, 36, "r", 1)
  c.circ(cx, 56, 10, "k"); c.circ(cx, 56, 9, "c"); c.rect(cx, 49, 1, 8, "k"); c.rect(cx, 56, 6, 1, "k")
  eave(c, 56, 35, 37, "d")
  flare(c, cx, 0, 35, 0, 15, "y", 1.0)
  c.recolor({ y: "w" }, (x, y) => y < 9)
  c.rect(cx, 0, 1, 3, "k"); c.rect(cx - 1, 2, 3, 2, "k")
  rbox(c, 46, 128, 80, 6, "c", 2)
  bush(c, [[8, 130, 8, 4], [19, 129, 7, 4]])
})
twoRing("school", 149, 142, stamp("_school_body", 0, 0))

// ---- the restaurant (left, upper row) -------------------------------------
// A muffin-top roof with cream frosting dripping off the eave, a chef's-hat chimney.
sprite("_restaurant_body", { w: 145, h: 128, mx: "c" }, (c) => {
  const cx = 72
  rr(c, 4, 48, 137, 78, "c", 3)
  rbox(c, 12, 60, 24, 22, "g", 2); rbox(c, 61, 60, 23, 22, "g", 3)
  awn(c, 4, cx, 88, 8, "r", "y")
  rbox(c, 12, 100, 24, 18, "g", 2)
  door(c, 62, 98, 21, 28)
  flare(c, cx, 6, 42, 18, 70, "r", 1.5)
  eave(c, 0, 42, 146, "r")
  for (let x = 6, i = 0; x <= cx; x += 12, i++) rbox(c, x, 47, 8, [8, 12, 9][i % 3], "c", 2)
  c.circ(cx, 4, 3, "y")
  rbox(c, 56, 124, 34, 4, "c", 2)
})
twoRing("restaurant", 145, 134,
  (c) => {
    rbox(c, 106, 12, 12, 24, "c", 1); rbox(c, 108, 4, 12, 12, "c", 1)
    puffs(c, [[112, 4, 8, 4], [119, 5, 6, 4]], "c")
  },
  stamp("_restaurant_body", 0, 4))

// ---- the shop (right, upper row) --------------------------------------------
// A coral party-hat cone for a roof, a gold pom-pom, violet walls.
sprite("_shop_body", { w: 149, h: 134, mx: "c" }, (c) => {
  const cx = 74
  rr(c, 4, 64, 141, 62, "v", 3)
  awn(c, 11, cx, 72, 9, "b", "c")
  rbox(c, 13, 88, 34, 32, "w", 3); rr(c, 15, 90, 30, 28, "k", 2); rr(c, 16, 91, 28, 26, "g", 2)
  door(c, 63, 86, 23, 40)
  flare(c, 28, 52, 62, 12, 30, "b", 1.4)
  eave(c, 0, 60, 62, "b")
  flare(c, cx, 6, 54, 1, 27, "r", 1.1)
  eave(c, 46, 50, 57, "b")
  c.circ(cx, 28, 8, "k"); c.circ(cx, 28, 7, "g")
  c.circ(cx, 4, 5, "y")
  bush(c, [[9, 123, 8, 4], [20, 122, 7, 4]])
})
twoRing("shop", 149, 134, stamp("_shop_body", 0, 0))

// ---- the clinic: a spotted green mushroom cottage (left, lower row) -----------
sprite("_clinic_body", { w: 145, h: 148, mx: "c" }, (c) => {
  const cx = 72
  c.ellipse(cx, 66, 64, 46, "d")
  c.rect(0, 82, 73, 60, "_")
  for (const [x, y, r] of [[34, 56, 7], [56, 36, 6], [14, 76, 4], [72, 28, 5]]) c.circ(x, y, r, "c")
  rr(c, 8, 68, 130, 14, "c", 2); c.rect(8, 68, 130, 1, "k"); c.rect(8, 81, 130, 1, "k")
  rr(c, 26, 82, 93, 54, "c", 3)
  for (const x of [40]) { c.circ(x, 108, 10, "k"); c.circ(x, 108, 9, "g") }
  rr(c, 59, 100, 27, 36, "k", 3); rr(c, 60, 101, 25, 35, "g", 3); c.rect(72, 103, 1, 33, "k")
  rbox(c, 52, 136, 42, 6, "c", 2)
  c.rect(71, 10, 3, 12, "t"); puffs(c, [[65, 9, 6, 3]], "t")
})
twoRing("clinic", 145, 152,
  stamp("_clinic_body", 0, 2),
  (c) => {
    rbox(c, 0, 114, 21, 6, "w", 1); rbox(c, 0, 122, 21, 5, "w", 1)
    rbox(c, 2, 127, 4, 9, "w", 1); rbox(c, 15, 127, 4, 9, "w", 1)
    rbox(c, 125, 126, 14, 12, "r", 1)
    bush(c, [[132, 120, 7, 7], [127, 122, 4, 4]])
  })

// ---- the cafe (right, lower row) --------------------------------------------
// A cream cottage under a wood roof, donut-ring windows, a steaming chimney.
sprite("_cafe_body", { w: 139, h: 134, mx: "c" }, (c) => {
  const cx = 69
  rr(c, 3, 50, 133, 78, "c", 3)
  c.circ(28, 96, 17, "k"); c.circ(28, 96, 16, "r"); c.circ(28, 96, 8, "k"); c.circ(28, 96, 7, "g")
  door(c, 56, 78, 27, 50)
  rbox(c, 62, 85, 15, 14, "g", 2)
  flare(c, cx, 14, 44, 14, 68, "w", 1.5)
  eave(c, 0, 46, 140, "w")
  c.circ(cx, 12, 3, "y")
  rbox(c, 44, 118, 9, 9, "r", 1); bush(c, [[48, 114, 5, 4]])
  rbox(c, 50, 124, 40, 4, "c", 2)
})
twoRing("cafe", 139, 142,
  (c) => {
    rbox(c, 102, 18, 13, 28, "w", 1); rr(c, 100, 14, 17, 6, "w", 1)
    puffs(c, [[108, 8, 5, 3], [114, 2, 4, 3]], "c")
  },
  stamp("_cafe_body", 0, 8))

// ---- the gazebo (bottom right) ---------------------------------------------
// A coral onion dome on a wood frame, a blank signpost.
sprite("_gazebo_body", { w: 69, h: 90, mx: "c" }, (c) => {
  const cx = 34
  c.rect(3, 48, 62, 28, "c")
  rbox(c, 3, 46, 7, 32, "w", 1); rbox(c, 31, 46, 7, 32, "w", 1)
  rbox(c, 10, 62, 21, 5, "c", 1)
  for (const x of [13, 18, 23, 28]) rbox(c, x, 67, 3, 10, "c", 1)
  c.ellipse(cx, 28, 24, 17, "r"); c.rect(0, 42, 72, 6, "_")
  flare(c, cx, 4, 14, 0, 6, "r", 0.8); c.circ(cx, 4, 3, "y")
  eave(c, 0, 39, 71, "r")
  rbox(c, 1, 76, 68, 6, "c", 2)
  bush(c, [[7, 82, 7, 4]])
})
twoRing("gazebo", 88, 92,
  stamp("_gazebo_body", 0, 2),
  (c) => {
    c.rect(74, 46, 3, 44, "w"); rbox(c, 71, 40, 14, 7, "c", 1)
    bush(c, [[78, 88, 7, 3]])
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

// ---- trees: lobed round crowns, one green -----------------------------------
const tree = (name, k) => {
  const lobes = [[13, 11, 10, 9], [7, 16, 7, 7], [19, 16, 7, 7], [13, 17, 9, 6]]
    .map(([x, y, rx, ry]) => [Math.round(x * k), Math.round(y * k), Math.round(rx * k), Math.round(ry * k)])
  const w = Math.round(26 * k), h = Math.round(34 * k)
  twoRing(name, w, h, (c) => {
    const tw = Math.round(5 * k), tx = Math.round(13 * k) - (tw >> 1)
    rbox(c, tx, Math.round(21 * k), tw, h - Math.round(21 * k), "w", 1)
    puffs(c, lobes, "t")
  })
}
tree("tree_t", 1)
tree("tree_bt", 1.35)
twoRing("bush", 34, 20, (c) => bush(c, [[8, 10, 7, 5], [15, 8, 8, 6], [22, 10, 7, 5]]))
twoRing("bench", 26, 18, (c) => {
  rbox(c, 0, 0, 26, 6, "w", 1)
  rbox(c, 0, 8, 26, 5, "w", 1)
  rbox(c, 2, 13, 4, 5, "w", 1); rbox(c, 20, 13, 4, 5, "w", 1)
})

// ---- the fountain: a wide basin, a pedestal, a bowl, a jet -------------------
twoRing("fountain", 83, 54, (c) => {
  puffs(c, [[41, 36, 39, 15]], "c")
  c.ellipse(41, 35, 33, 11, "g")
  rbox(c, 36, 16, 11, 20, "c", 1)
  puffs(c, [[41, 16, 17, 6]], "c")
  c.ellipse(41, 15, 12, 3, "g")
  rbox(c, 38, 8, 7, 9, "c", 1)
  puffs(c, [[41, 8, 9, 4]], "c")
  c.ellipse(41, 7, 6, 2, "g")
  c.rect(40, 0, 3, 7, "g")
})

// ---- the pond: water, a few lily pads ---------------------------------------
sprite("_pond_fill", { w: 112, h: 70 }, (c) => {
  c.ellipse(30, 24, 30, 20, "g")
  c.ellipse(68, 38, 40, 26, "g")
  c.ellipse(94, 30, 18, 14, "g")
  c.ellipse(38, 46, 26, 14, "g")
  for (const [x, y] of [[40, 40], [74, 24], [26, 50]]) puffs(c, [[x, y, 6, 3]], "t")
})
sprite("pond", { base: "_pond_fill", outline8: "k" })

// ---- the paving: cream slabs, ink round the whole, a few ink joints ------------
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
  for (const [x, y, w, h] of bands) {
    if (w < 100) { for (let jx = x + 22; jx < x + w - 6; jx += 30) c.rect(jx, y, 1, h, "k"); continue }
    for (let jx = 20; jx < 342; jx += 30) c.rect(jx, y, 1, h, "k")
  }
  for (const [l, r, top] of STUBS) for (let jy = top + 14; jy < ARM[0]; jy += 16) c.rect(l, jy, r - l + 1, 1, "k")
  c.rect(al, 0, ar - al + 1, 750, "c")
  for (let jy = 10; jy < 750; jy += 24) c.rect(al, jy, ar - al + 1, 1, "k")
  // the plaza: one ring and eight joints round the fountain
  const [px0, py0, rx, ry] = PLAZA
  c.ellipse(px0, py0, rx, ry, "c")
  c.ellipse(px0, py0, Math.round(rx * 0.74), Math.round(ry * 0.74), "k", true)
  for (let k = 0; k < 8; k++) {
    const a = (k + 0.5) * Math.PI / 4
    for (let t = 0.48; t <= 1; t += 0.005) {
      c.px(Math.round(px0 + Math.cos(a) * rx * t), Math.round(py0 + Math.sin(a) * ry * t), "k")
    }
  }
})
sprite("paving", { base: "_paving", outline8: "k" })

sprite("ground", { w: 342, h: 750 },
  rect(0, 0, 342, 750, "l"),
  stamp("paving", -1, -1),
  stamp("pond", 8, 614), stamp("bench", 48, 590),
  stamp("fountain", 128, 523),
  // trees, bushes
  stamp("tree_bt", 2, 0), stamp("tree_t", 40, 8), stamp("tree_t", 116, 2),
  stamp("tree_t", 192, 4), stamp("tree_t", 224, 12), stamp("tree_bt", 286, 2), stamp("tree_t", 312, 14),
  stamp("tree_bt", 0, 516), stamp("tree_t", 306, 498),
  stamp("tree_t", 312, 590), stamp("bush", 316, 640), stamp("bush", 12, 596),
  stamp("tree_t", 2, 708), stamp("tree_bt", 28, 700), stamp("tree_t", 66, 708), stamp("tree_bt", 98, 698), stamp("bush", 132, 724),
  stamp("tree_t", 194, 706), stamp("tree_bt", 226, 700), stamp("tree_t", 270, 710), stamp("tree_t", 304, 704),
  stamp("bush", 192, 646))
