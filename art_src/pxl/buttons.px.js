// Mimikin home buttons, drawn with pxl: the toy chest and the boss tower.
//
// House style (docs/svg-style-reference.md, TOWN_ART.md section 7, boss-climb-map notes):
// the cozy room's flat colours, one flat fill per material, a one-cell ink
// outline (#14120e), no shading / tints / gradients / dither / glow, and no
// baked shadow (the app projects its own). At most two details a piece.
//
// Build:  node <skill>/bin/pxl.js build art_src/pxl/buttons.px.js
// Export: node --disable-warning=ExperimentalWarning art_src/pxl/export_dart.mjs
pal({
  k: "#14120e",   // ink
  w: "#f2e3c6",   // wall cream
  c: "#c58c56",   // wood
  s: "#a8dcef",   // glass
  r: "#e98a7b",   // coral
  g: "#f0c24c",   // gold: the chick, the brass, the pennant (the meadow's flower gold)
  t: "#cdc3d9",   // stone: the lilac the cave floors use
})

// ------------------------------------------------------------------ toy chest
// A toy chest with the beach ball the game started with standing at the front
// of its left side. Every fill is fenced by ink (check_borders.mjs enforces it):
// blue lid and body, a wooden base band, brass straps and a clasp with a keyhole.
sprite("_ball", { w: 9, h: 9, outline: "k" },
  circ(4, 4, 4, "w"),
  clip([4, 4, 4], rect(0, 0, 3, 9, "s"), rect(6, 0, 3, 9, "r")))

// Blue, because the room's floor is the same wood a wooden chest would be.
sprite("_chest", { w: 26, h: 20, outline: "k" },
  poly([3, 0, 23, 0, 26, 3, 26, 9, 0, 9, 0, 3], "s"),     // domed lid, overhanging
  rect(1, 9, 24, 10, "s"),                                // body
  rect(1, 15, 24, 4, "c"), hline(1, 14, 24, "k"),         // wooden base band
  // two brass straps, a column of ink either side and an end of ink at the bottom
  rect(6, 0, 3, 19, "g"), vline(5, 0, 19, "k"), vline(9, 0, 19, "k"),
  rect(17, 0, 3, 19, "g"), vline(16, 0, 19, "k"), vline(20, 0, 19, "k"),
  hline(0, 9, 26, "k"),                                   // where the lid shuts
  hline(1, 19, 24, "k"),                                  // the foot of the body
  // the clasp across the seam, with its keyhole
  rect(10, 6, 6, 8, "g"), box(10, 6, 6, 8, "k"), rect(12, 8, 2, 3, "k"))

// The ball stands on the floor at the front of the chest's left side.
scene("toychest", { w: 34, h: 22 },
  stamp("_chest", 6, 0),
  stamp("_ball", 0, 11))

// ------------------------------------------------------------------ boss tower
// The tower the climb starts from: coral cone roof with a gold pennant, a
// narrower stone upper room with a glass window, and a wider base with a wood
// arched door.
sprite("_roof", { w: 15, h: 7, outline: "k" },
  poly([7, 0, 15, 7, 0, 7], "r"))

sprite("_flag", { w: 5, h: 3, outline: "k" },
  rect(0, 0, 5, 3, "g"))

sprite("_upper", { w: 13, h: 7, outline: "k" },
  rect(0, 0, 13, 7, "t"),
  rect(5, 2, 3, 3, "s"), box(4, 1, 5, 5, "k"))

sprite("_base", { w: 17, h: 9, outline: "k" },
  rect(0, 0, 17, 9, "t"),
  rect(6, 2, 5, 7, "c"), box(6, 2, 5, 7, "k"), px(6, 2, "t"), px(10, 2, "t"))

scene("tower", { w: 21, h: 32 },
  vline(10, 0, 6, "k"),
  stamp("_flag", 10, 0),
  stamp("_roof", 2, 5),
  stamp("_upper", 3, 13),
  stamp("_base", 1, 21))
