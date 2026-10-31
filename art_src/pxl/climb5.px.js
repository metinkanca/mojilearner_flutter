// Floor 5 of the boss climb map, Sableth's: a desert, drawn with pxl in the
// games' house style (flat colours, one-cell ink outline, nothing shaded, at
// most two details a piece).
//
// Sableth is a lion-sphinx, gold with a navy-striped headdress, and its desert
// is cream sand with gold dunes, sandstone and broken brown pillars. The floor
// opens at the bottom into the floor below (the same cream sand, the path
// starting under that floor's gateway) and at the top through a gateway like
// that one, onto the next zone's ground: Pyrewing's volcano, deep purple, whose
// lilac spires and flames stand over the wall.
//
// 130 x 281 cells (a home scene's 864 x 1872 shape). Build:
//   node <skill>/bin/pxl.js build art_src/pxl/climb5.px.js
//   python art_src/pxl/export_climb.py 5
pal({
  k: "#14120e",   // ink
  w: "#f2e3c6",   // cream: the sand, the ground
  t: "#dfc6a0",   // sandstone: the wall, the pads
  g: "#f0a93c",   // gold: dunes, scrub, the headdress
  c: "#c58c56",   // brown: the gateway, the pillars
  u: "#2f4663",   // navy: the headdress's stripes
  d: "#58348d",   // Pyrewing's ground, beyond the gateway
  s: "#b99cd8",   // its lilac spires
  o: "#fb8630",   // its flames
})

// ------------------------------------------------------------------ the stops
// A round sandstone with a ring carved in it, and the small slabs between.
sprite("pad", { w: 21, h: 21, outline: "k" },
  circ(10, 10, 10, "t"),
  ring(10, 10, 7, "k"))

sprite("slab", { w: 7, h: 7, outline: "k" },
  rect(0, 0, 7, 7, "g"), px(0, 0, "_"), px(6, 0, "_"), px(0, 6, "_"), px(6, 6, "_"))

sprite("start", { w: 15, h: 15, outline: "k" },
  rect(0, 0, 15, 15, "t"), px(0, 0, "_"), px(14, 0, "_"), px(0, 14, "_"), px(14, 14, "_"))

// ------------------------------------------------------------------ the desert
sprite("dune_big", { w: 31, h: 9, outline: "k" },
  poly([0, 8, 6, 5, 13, 1, 15, 0, 18, 2, 24, 5, 30, 8], "g"))

sprite("dune_small", { w: 19, h: 6, outline: "k" },
  poly([0, 5, 4, 3, 9, 0, 13, 2, 18, 5], "g"))

sprite("boulder", { w: 20, h: 13, outline: "k" },
  poly([0, 12, 2, 5, 6, 1, 13, 0, 17, 3, 19, 12], "t"))

sprite("scrub", { outline: "k" }, `
  .g.....g...
  .gg...gg.g.
  ..g...g.gg.
  ..gg.gggg..
  ...ggggg...
  ....ggg....
  ....ggg....`)

// A broken pillar, brown, its top snapped off at a slant.
sprite("pillar", { outline: "k" }, `
  ....cc.
  ...ccc.
  ..cccc.
  .ccccc.
  .ccccc.
  .ccccc.
  .ccccc.
  .ccccc.
  .ccccc.
  ccccccc
  ccccccc`)

sprite("pebble", { w: 5, h: 3, outline: "k" },
  rect(0, 0, 5, 3, "t"), px(0, 0, "_"), px(4, 0, "_"))

// ------------------------------------------------------------------ the gateway
// The wall across the top and its gateway, one piece with the left half drawn
// and mirrored: courses of sandstone with their joints, and brown stones round
// the opening, straight legs up to a round head. The opening shows the next
// zone's ground, and a line of ink across its foot is the doorstep.
sprite("gate", { w: 130, h: 32, mx: true, outline: "k" },
  rect(0, 5, 65, 27, "t"),
  hline(0, 14, 65, "k"), hline(0, 23, 65, "k"),
  vline(18, 5, 9, "k"), vline(42, 5, 9, "k"),
  vline(6, 15, 8, "k"), vline(30, 15, 8, "k"),
  vline(18, 24, 8, "k"), vline(42, 24, 8, "k"),
  circ(64, 18, 16, "c"), rect(48, 18, 17, 14, "c"),
  clip([0, 0, 65, 18], ring(64, 18, 16, "k")),
  vline(48, 18, 14, "k"), hline(49, 25, 5, "k"),
  circ(64, 18, 11, "_"), rect(54, 18, 11, 14, "_"),
  hline(54, 31, 11, "k"))

// The sphinx's headdress on the gateway: a lintel in gold and navy stripes,
// wider at the foot, the stripes running out from the middle.
const lintelRows = []
for (let r = 0; r < 4; r++) {
  const width = 25 + 2 * r, centre = (width - 1) / 2, pad = ".".repeat(3 - r)
  let row = pad
  for (let x = 0; x < width; x++) row += Math.floor(Math.abs(x - centre) / 3 + 0.5) % 2 === 0 ? "g" : "u"
  lintelRows.push(row + pad)
}
sprite("lintel", { outline: "k" }, lintelRows.join("\n"))

// What stands over the wall in the next zone: Pyrewing's spires and flames.
sprite("spire_a", { w: 13, h: 24, outline: "k" },
  poly([6, 0, 9, 6, 12, 23, 0, 23, 3, 6], "s"))
sprite("spire_b", { w: 9, h: 14, outline: "k" },
  poly([4, 0, 7, 4, 8, 13, 0, 13, 1, 4], "s"))
sprite("flame", { outline: "k" }, `
  ...o...
  ..oo.o.
  .ooooo.
  .ooooo.
  ooooooo`)

// ------------------------------------------------------------------ the floor
// Where the five stops' centres are, bottom to top; the pads below are stamped
// on them, and the slabs between are laid along the lines joining them, a pad's
// edge and a slab's width from each end.
const stops = [[48.5, 236.5], [84.5, 198.5], [44.5, 158.5], [84.5, 118.5], [65.5, 80.5]]
const slabs = []
for (let i = 0; i + 1 < stops.length; i++) {
  const [ax, ay] = stops[i], [bx, by] = stops[i + 1]
  const len = Math.hypot(bx - ax, by - ay), ux = (bx - ax) / len, uy = (by - ay) / len
  const along = len > 46 ? [18.5, len - 18.5] : [len / 2]
  for (const d of along) slabs.push(stamp("slab", Math.round(ax + ux * d - 4.5), Math.round(ay + uy * d - 4.5)))
}

scene("floor5", { w: 130, h: 281, bg: "w" },
  // The volcano beyond the wall, Pyrewing's ground, spires and flames.
  rect(0, 0, 130, 46, "d"),
  stamp("spire_a", 10, 0), stamp("spire_b", 28, 8), stamp("flame", 40, 12),
  stamp("flame", 83, 12), stamp("spire_b", 93, 8), stamp("spire_a", 107, 0),
  stamp("gate", -1, 13),
  stamp("lintel", 49, 11),
  // Dunes at the foot of the wall, either side of the gateway.
  stamp("dune_small", 22, 44), stamp("dune_small", 89, 44),

  // The rest of the desert.
  stamp("dune_big", 2, 62), stamp("dune_big", 96, 66),
  stamp("scrub", 8, 100), stamp("boulder", 104, 94),
  stamp("pillar", 8, 122), stamp("scrub", 112, 146),
  stamp("dune_small", 104, 168), stamp("scrub", 8, 190),
  stamp("pillar", 110, 218), stamp("boulder", 4, 252),
  stamp("dune_small", 96, 252),
  stamp("pebble", 24, 110), stamp("pebble", 98, 150), stamp("pebble", 24, 210),
  stamp("pebble", 100, 276), stamp("pebble", 22, 272),

  // The way up: the start, under the gateway of the floor below, the slabs, and
  // the five stops.
  stamp("start", 57, 262),
  stamp("slab", 53, 251),
  ...slabs,
  stamp("pad", 37, 225), stamp("pad", 73, 187),
  stamp("pad", 33, 147), stamp("pad", 73, 107),
  stamp("pad", 54, 69))
