// The scenarios town, redrawn with pxl in the house style: one pixel = one 3-wu
// cell of the map (world 1026 x 2250 wu = 342 x 750 cells), a ONE-cell ink line
// (3 wu, the same weight as the finished pets' 9-unit borders at their 1/3
// on-map scale), flat fills only, no shading, no text or icons.
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/town.px.js [--only name,...]
// Export: python art_src/gen_town.py
//
// Every building is a symmetric `_x_body` part (left half + centre column,
// mirrored) stamped into the real sprite, which adds what is not symmetric
// (flag, chimney, tables) and the outer ink ring.
pal({
  k: "#14120e",   // ink
  c: "#f2e3c6",   // cream: walls, paving
  w: "#c58c56",   // wood
  g: "#a8dcef",   // glass
  r: "#e98a7b",   // coral
  l: "#8cc56a",   // lawn
  y: "#f0c24c",   // gold
  s: "#cdc3d9",   // lilac stone
  b: "#3f93c4",   // sea blue
  v: "#9a7cc8",   // violet
  d: "#2f6a4f",   // pine
  t: "#4e9a55",   // dark tree
  u: "#78b866",   // light tree
  n: "#9a6538",   // roof brown
})

// ---- helpers -------------------------------------------------------------

// A flat fill fenced by a one-cell ink line.
const boxed = (c, x, y, w, h, fill) => {
  c.rect(x, y, w, h, "k")
  c.rect(x + 1, y + 1, w - 2, h - 2, fill)
}

// A window: ink frame, a trim ring, glass, one cross of ink bars.
const win = (c, x, y, w, h, trim = "b", cross = true) => {
  boxed(c, x, y, w, h, trim)
  c.rect(x + 2, y + 2, w - 4, h - 4, "k")
  c.rect(x + 3, y + 3, w - 6, h - 6, "g")
  if (cross) {
    c.rect(x + (w >> 1), y + 3, 1, h - 6, "k")
    c.rect(x + 3, y + (h >> 1), w - 6, 1, "k")
  }
}


// Awning stripes from x0 to the centre column cx, symmetric about cx. The A
// stripes hang two rows lower (a scalloped edge); ink above and below.
const awn = (c, x0, cx, y, h, A, B) => {
  for (let x = x0; x <= cx; x++) {
    const col = Math.floor((Math.abs(x - cx) + 3) / 6) % 2 === 0 ? A : B
    const hh = col === A ? h + 2 : h
    c.rect(x, y, 1, hh, col)
    c.px(x, y - 1, "k")
    c.px(x, y + hh, "k")
  }
}

// ---- the town hall (job_interview) ----------------------------------------
// 147 cells wide, centre column 73, blue roof, cream walls, a portico.
sprite("_office_body", { w: 147, h: 101, mx: "c" }, (c) => {
  // roof: hip wing plus the raised central gable
  c.poly([0, 38, 12, 18, 74, 18, 74, 38], "b")
  c.poly([54, 18, 74, 0, 74, 18], "b")
  c.rect(12, 18, 42, 1, "k")            // ridge of the wing, under the gable
  c.rect(54, 18, 20, 1, "k")            // gable's foot
  c.rect(0, 37, 74, 1, "k")             // eave line
  // walls (every rect runs to the centre column 73 so the mirror leaves no seam)
  c.rect(3, 38, 71, 56, "c")
  c.rect(3, 38, 1, 56, "k")             // left corner
  c.rect(3, 62, 71, 3, "b")             // floor band
  c.rect(3, 62, 71, 1, "k")
  c.rect(3, 64, 71, 1, "k")
  // windows
  win(c, 14, 44, 26, 17)
  win(c, 14, 69, 26, 17)
  win(c, 61, 44, 25, 17)                // over the door (centred on 73)
  // portico: a column each side, a lintel, the door between
  boxed(c, 50, 68, 6, 25, "w")
  boxed(c, 60, 66, 27, 4, "b")          // lintel, centred on 73
  boxed(c, 63, 70, 21, 23, "w")         // door leaf frame
  c.rect(65, 72, 17, 21, "g")
  c.rect(73, 72, 1, 21, "k")
  c.rect(65, 82, 17, 1, "k")
  // steps
  c.rect(30, 93, 87, 1, "k")
  c.rect(30, 94, 87, 3, "s")
  c.rect(38, 97, 71, 1, "k")
  c.rect(38, 98, 71, 2, "s")
  c.rect(38, 100, 71, 1, "k")
})

sprite("office", { w: 147, h: 115, outline8: "k" },
  rect(73, 0, 1, 14, "w"),
  (c) => boxed(c, 74, 0, 12, 7, "b"),
  stamp("_office_body", 0, 14))


// ---- the school (right of the avenue, top) ---------------------------------
// 149 wide, centre 74: pine roofs, coral walls, a clock tower over the middle.
sprite("_school_body", { w: 149, h: 124, mx: "c" }, (c) => {
  // tower
  c.poly([58, 20, 75, 2, 75, 20], "d")
  c.rect(58, 20, 17, 1, "k")
  c.rect(63, 21, 12, 24, "r")
  c.rect(63, 21, 1, 24, "k")
  c.circ(74, 32, 7, "k")
  c.circ(74, 32, 5, "c")
  c.rect(74, 28, 1, 5, "k")
  c.rect(74, 32, 3, 1, "k")
  // wings' roof
  c.poly([0, 66, 10, 48, 54, 48, 54, 66], "d")
  c.rect(0, 65, 54, 1, "k")
  // central block
  c.rect(52, 44, 23, 6, "d")
  c.rect(52, 49, 23, 1, "k")
  c.rect(54, 50, 21, 67, "r")
  c.rect(54, 50, 1, 67, "k")
  c.rect(55, 50, 3, 67, "c")
  c.rect(58, 50, 1, 67, "k")
  win(c, 63, 56, 23, 16, "c")
  boxed(c, 63, 90, 23, 27, "c")
  c.rect(65, 92, 19, 25, "w")
  c.rect(66, 93, 17, 7, "g")
  c.rect(74, 93, 1, 24, "k")
  c.rect(65, 100, 19, 1, "k")
  // wings' walls
  c.rect(3, 66, 51, 51, "r")
  c.rect(3, 66, 1, 51, "k")
  c.rect(4, 66, 3, 51, "c")
  c.rect(7, 66, 1, 51, "k")
  c.rect(8, 87, 46, 1, "k")
  c.rect(8, 88, 46, 2, "c")
  c.rect(8, 90, 46, 1, "k")
  win(c, 14, 70, 13, 15, "c")
  win(c, 34, 70, 13, 15, "c")
  win(c, 14, 93, 13, 15, "c")
  win(c, 34, 93, 13, 15, "c")
  // foot and steps
  c.rect(3, 117, 72, 1, "k")
  c.rect(48, 118, 27, 3, "s")
  c.rect(48, 121, 27, 1, "k")
  c.rect(54, 122, 21, 2, "s")
})

sprite("school", { w: 149, h: 124, outline8: "k" }, stamp("_school_body", 0, 0))

// ---- the restaurant (left, upper row) -------------------------------------
sprite("_restaurant_body", { w: 145, h: 126, mx: "c" }, (c) => {
  c.poly([0, 46, 14, 22, 73, 22, 73, 46], "r")
  c.rect(0, 45, 73, 1, "k")
  c.rect(4, 46, 69, 77, "c")
  c.rect(4, 46, 1, 77, "k")
  win(c, 12, 52, 23, 17, "r")
  win(c, 62, 52, 21, 17, "r")
  // flower box under the left window
  c.rect(12, 69, 23, 1, "l")
  for (const x of [14, 18, 22, 26, 30]) c.px(x, 68, "r")
  boxed(c, 11, 70, 25, 5, "w")
  awn(c, 4, 72, 78, 8, "r", "y")
  win(c, 12, 92, 23, 17, "r")
  boxed(c, 63, 92, 19, 31, "w")
  c.rect(65, 94, 15, 10, "g")
  c.rect(72, 94, 1, 29, "k")
  c.rect(4, 123, 69, 1, "k")
  c.rect(58, 124, 15, 2, "s")
})

sprite("restaurant", { w: 145, h: 134, outline8: "k" },
  (c) => {
    boxed(c, 106, 2, 12, 34, "c")
    c.rect(106, 12, 12, 1, "k")
    c.rect(106, 20, 12, 1, "k")
    c.rect(104, 0, 16, 3, "k")
  },
  stamp("_restaurant_body", 0, 8),
  (c) => {
    // a table and two stools on the pavement, left of the door
    boxed(c, 6, 121, 24, 4, "w")
    c.rect(10, 125, 2, 8, "k")
    c.rect(24, 125, 2, 8, "k")
    boxed(c, 0, 128, 7, 3, "w")
    boxed(c, 29, 128, 7, 3, "w")
  })

// ---- the shop (right, upper row) --------------------------------------------
sprite("_shop_body", { w: 149, h: 126, mx: "c" }, (c) => {
  c.poly([0, 44, 14, 26, 75, 26, 75, 44], "b")
  c.poly([40, 26, 75, 2, 75, 26], "b")
  c.rect(40, 26, 35, 1, "k")
  c.rect(0, 43, 75, 1, "k")
  c.circ(74, 16, 7, "k")
  c.circ(74, 16, 5, "w")
  c.circ(74, 16, 3, "g")
  c.rect(4, 44, 71, 76, "v")
  c.rect(4, 44, 1, 76, "k")
  c.rect(5, 44, 5, 76, "c")
  c.rect(10, 44, 1, 76, "k")
  win(c, 16, 50, 17, 14, "c")
  win(c, 41, 50, 17, 14, "c")
  win(c, 66, 50, 17, 14, "c")
  awn(c, 11, 74, 70, 9, "b", "c")
  boxed(c, 14, 86, 33, 30, "w")
  c.rect(16, 88, 29, 26, "g")
  c.rect(30, 88, 1, 26, "k")
  c.rect(16, 100, 29, 1, "k")
  boxed(c, 64, 86, 21, 34, "w")
  c.rect(66, 88, 17, 12, "g")
  c.rect(74, 88, 1, 32, "k")
  c.rect(4, 120, 71, 1, "k")
  c.rect(60, 121, 15, 2, "s")
})

sprite("shop", { w: 149, h: 126, outline8: "k" }, stamp("_shop_body", 0, 0))

// ---- the clinic: a round building under a pine dome (left, lower row) ------
sprite("_clinic_body", { w: 145, h: 128, mx: "c" }, (c) => {
  c.ellipse(72, 72, 54, 46, "d")
  for (const dx of [18, 36]) {
    for (let y = 27; y <= 70; y++) {
      const t = (72 - y) / 46
      c.px(Math.round(72 - dx * Math.sqrt(1 - t * t)), y, "k")
    }
  }
  c.rect(72, 27, 1, 44, "k")
  c.rect(0, 78, 73, 50, "_")
  boxed(c, 65, 14, 15, 13, "b")
  c.rect(70, 8, 5, 6, "y")
  c.rect(18, 68, 55, 1, "k")
  c.rect(18, 69, 55, 8, "b")
  c.rect(18, 77, 55, 1, "k")
  c.rect(24, 78, 49, 44, "c")
  c.rect(24, 78, 1, 44, "k")
  c.ellipse(42, 100, 8, 13, "k")
  c.ellipse(42, 100, 6, 11, "g")
  c.rect(42, 90, 1, 21, "k")
  boxed(c, 62, 92, 21, 30, "w")
  c.rect(64, 94, 17, 28, "g")
  c.rect(72, 94, 1, 28, "k")
  c.rect(24, 122, 49, 1, "k")
  c.rect(56, 123, 17, 2, "s")
})

sprite("clinic", { w: 145, h: 128, outline8: "k" },
  stamp("_clinic_body", 0, 0),
  (c) => {
    boxed(c, 0, 100, 22, 6, "w")     // bench: back, seat, legs
    boxed(c, 0, 108, 22, 5, "w")
    boxed(c, 2, 113, 4, 9, "w")
    boxed(c, 16, 113, 4, 9, "w")
    boxed(c, 127, 108, 13, 14, "r")  // planter
    c.circ(133, 101, 7, "u")
  })

// ---- the cafe (right, lower row) --------------------------------------------
sprite("_cafe_body", { w: 139, h: 130, mx: "c" }, (c) => {
  c.poly([0, 46, 16, 28, 70, 28, 70, 46], "n")
  c.poly([38, 28, 70, 4, 70, 28], "n")
  c.poly([50, 28, 70, 12, 70, 28], "c")
  c.rect(0, 45, 70, 1, "k")
  c.rect(38, 28, 32, 1, "k")
  boxed(c, 64, 15, 11, 8, "g")
  c.rect(3, 46, 67, 76, "w")
  c.rect(3, 46, 1, 76, "k")
  for (const x of [60, 51, 42, 33, 24, 15, 6]) c.rect(x, 46, 1, 76, "k")
  awn(c, 3, 69, 64, 8, "r", "c")
  boxed(c, 10, 80, 31, 31, "c")
  c.rect(13, 83, 25, 25, "g")
  boxed(c, 58, 78, 23, 44, "c")
  c.rect(60, 80, 19, 42, "w")
  c.rect(62, 82, 15, 12, "g")
  c.circ(49, 110, 4, "u")
  boxed(c, 45, 113, 9, 9, "r")
  c.rect(3, 122, 67, 1, "k")
  c.rect(56, 123, 14, 2, "s")
})

sprite("cafe", { w: 139, h: 130, outline8: "k" }, stamp("_cafe_body", 0, 0))

// ---- the gazebo (bottom right) -------------------------------------------
sprite("_gazebo_body", { w: 69, h: 82, mx: "c" }, (c) => {
  c.poly([0, 34, 35, 6, 35, 34], "n")
  c.line(35, 7, 18, 33, "k")
  c.rect(35, 7, 1, 27, "k")
  c.rect(0, 33, 35, 1, "k")
  c.rect(0, 34, 35, 3, "r")
  c.rect(0, 37, 35, 1, "k")
  c.rect(2, 38, 33, 32, "n")
  boxed(c, 4, 38, 6, 33, "w")
  boxed(c, 32, 38, 5, 33, "w")
  c.rect(10, 56, 22, 3, "c")
  c.rect(10, 55, 22, 1, "k")
  c.rect(10, 59, 22, 1, "k")
  for (const x of [14, 20, 26]) c.rect(x, 60, 1, 10, "k")
  c.rect(2, 71, 33, 4, "s")
  c.rect(2, 70, 33, 1, "k")
  c.rect(2, 75, 33, 1, "k")
  c.circ(35, 3, 3, "r")
})

sprite("gazebo", { w: 82, h: 82, outline8: "k" },
  stamp("_gazebo_body", 0, 0),
  rect(72, 40, 2, 38, "w"),
  (c) => boxed(c, 70, 38, 11, 7, "c"))

// ============================================================================
// THE GROUND: 342 x 750 cells.
// ============================================================================
// Rows/cols (cells) of everything the paths and buildings hang off. gen_town.py
// reads these back out of the same numbers (see LAYOUT there), so change both.
const AVE = [157, 184]            // the avenue, inclusive
const TOP_WALK = [178, 198]       // the sidewalk the hall and school stand on
const MID_WALK = [337, 357]       // ... the restaurant's and the shop's
const ARM = [545, 577]            // the arms to the clinic and the cafe
const PLAZA = [171, 561, 65, 57]  // centre x, y and radii
const STUBS = [[61, 90, 506], [255, 284, 498]]   // [left col, right col, top row]
const GATE = [185, 282, 670, 684] // the gazebo's path: cols, then rows

// ---- trees, bushes, a bench ------------------------------------------------
for (const [name, col] of [["tree_u", "u"], ["tree_t", "t"]]) {
  sprite(name, { w: 21, h: 30, outline8: "k" },
    rect(8, 19, 5, 9, "w"),
    ellipse(10, 10, 10, 10, col))
}
sprite("tree_big_u", { w: 29, h: 40, outline8: "k" },
  rect(11, 26, 7, 12, "w"),
  ellipse(14, 14, 14, 14, "u"))
sprite("tree_big_t", { w: 29, h: 40, outline8: "k" },
  rect(11, 26, 7, 12, "w"),
  ellipse(14, 14, 14, 14, "t"))
sprite("bush", { w: 22, h: 12, outline8: "k" },
  ellipse(11, 7, 11, 5, "t"),
  px(5, 6, "r"), px(11, 4, "r"), px(16, 7, "r"))
sprite("bush_u", { w: 22, h: 12, outline8: "k" },
  ellipse(11, 7, 11, 5, "u"),
  px(6, 7, "r"), px(12, 5, "r"), px(17, 6, "r"))
sprite("bench", { w: 24, h: 17, outline8: "k" },
  (c) => {
    boxed(c, 0, 0, 24, 6, "w")
    boxed(c, 0, 8, 24, 5, "w")
    boxed(c, 2, 13, 4, 4, "w")
    boxed(c, 18, 13, 4, 4, "w")
  })

// ---- the fountain: a wide basin, one pedestal, a bowl, a jet ---------------
sprite("fountain", { w: 79, h: 64, mx: "c", outline8: "k" }, (c) => {
  c.ellipse(39, 46, 39, 17, "c")       // basin wall
  c.ellipse(39, 46, 34, 12, "g")       // water in it
  c.rect(33, 20, 13, 28, "c")          // pedestal
  c.ellipse(39, 20, 16, 7, "c")        // bowl
  c.ellipse(39, 20, 12, 5, "g")
  c.rect(38, 13, 3, 8, "g")            // the jet
  c.rect(36, 11, 7, 2, "g")
})

// ---- the pond --------------------------------------------------------------
sprite("pond", { w: 108, h: 66, outline8: "k" }, (c) => {
  c.ellipse(30, 22, 30, 20, "g")
  c.ellipse(66, 36, 38, 26, "g")
  c.ellipse(90, 30, 18, 14, "g")
  c.ellipse(36, 44, 24, 14, "g")
  for (const [x, y, w] of [[18, 20, 8], [60, 40, 10], [78, 28, 6], [34, 48, 7]]) c.rect(x, y, w, 1, "c")
})

// ---- the paving: one flat sprite, the ink round the whole of it ---------------
sprite("_paving", { w: 342, h: 750, outline8: "k" }, (c) => {
  const [al, ar] = AVE
  // sidewalks, arms, stubs and the gazebo's path
  const bands = [
    [0, TOP_WALK[0], 342, TOP_WALK[1] - TOP_WALK[0] + 1],
    [0, MID_WALK[0], 342, MID_WALK[1] - MID_WALK[0] + 1],
    [0, ARM[0], 342, ARM[1] - ARM[0] + 1],
    [GATE[0], GATE[2], GATE[1] - GATE[0] + 1, GATE[3] - GATE[2] + 1],
  ]
  for (const [x, y, w, h] of bands) c.rect(x, y, w, h, "c")
  for (const [l, r, top] of STUBS) c.rect(l, top, r - l + 1, ARM[0] - top + 4, "c")
  // joints between the slabs: across the sidewalks, along the avenue
  for (const [x, y, w, h] of bands) {
    if (w < 100) { for (let jx = x + 22; jx < x + w - 6; jx += 30) c.rect(jx, y, 1, h, "k"); continue }
    for (let jx = 20; jx < 342; jx += 30) c.rect(jx, y, 1, h, "k")
  }
  for (const [l, r, top] of STUBS) for (let jy = top + 14; jy < ARM[0]; jy += 16) c.rect(l, jy, r - l + 1, 1, "k")
  c.rect(al, 0, ar - al + 1, 750, "c")
  for (let jy = 10; jy < 750; jy += 24) c.rect(al, jy, ar - al + 1, 1, "k")
  // the plaza round the fountain: a wide ellipse, an inner ring, eight joints
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

sprite("ground", { w: 342, h: 750 },
  rect(0, 0, 342, 750, "l"),
  stamp("_paving", -1, -1),
  stamp("fountain", 131, 514),
  stamp("pond", 14, 622),
  stamp("bench", 62, 596),
  stamp("bush", 96, 600), stamp("bush_u", 120, 614), stamp("bush", 22, 604),
  // trees, back to front
  stamp("tree_big_t", 8, 8), stamp("tree_u", 44, 22), stamp("tree_t", 74, 6), stamp("tree_big_u", 112, 14),
  stamp("tree_t", 130, 30), stamp("tree_u", 196, 8), stamp("tree_big_t", 226, 4), stamp("tree_u", 266, 18),
  stamp("tree_t", 300, 4), stamp("tree_big_u", 306, 26),
  
  stamp("tree_big_u", 4, 360), stamp("tree_t", 140, 366), stamp("tree_u", 326, 356), stamp("tree_big_t", 192, 362),
  stamp("tree_t", 330, 520),
  stamp("tree_u", 316, 580), stamp("tree_t", 312, 628), stamp("bush", 200, 602), stamp("bush_u", 300, 700),
  stamp("tree_t", 205, 700), stamp("tree_big_u", 242, 706), stamp("tree_t", 290, 704), stamp("tree_u", 322, 712),
  stamp("tree_big_t", 4, 706), stamp("tree_u", 38, 716), stamp("tree_t", 70, 704), stamp("tree_big_u", 104, 708),
  stamp("tree_u", 136, 718), stamp("bush", 132, 738))
