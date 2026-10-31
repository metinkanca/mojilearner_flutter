// The toy chest's picker, drawn with pxl: the open chest over the list, the
// five toys, the padlock for a shut one and the arrow for an open one.
//
// House style (docs/svg-style-reference.md, TOWN_ART.md section 7, buttons.px.js):
// the cozy room's flat colours, one flat fill per material, a one-cell ink
// outline, no shading / gradients / dither / glow, no baked shadow, at most two
// details a piece. Every fill is fenced by ink (check_borders.mjs toychest).
//
// Build:  node <skill>/bin/pxl.js build art_src/pxl/toychest.px.js
// Export: node --disable-warning=ExperimentalWarning art_src/pxl/export_dart.mjs
pal({
  k: "#14120e",   // ink
  w: "#f2e3c6",   // wall cream
  c: "#c58c56",   // wood
  s: "#a8dcef",   // glass
  r: "#e98a7b",   // coral
  g: "#f0c24c",   // gold
  t: "#cdc3d9",   // stone
  l: "#8cc56a",   // leaf
})

// ------------------------------------------------------------------ the toys
// Each toy is about 15 cells across and 13-15 tall with its outline, so the
// five sit alike in the list.

// Catch: the beach ball, a cream ball with a glass stripe and a coral one.
sprite("toy_catch", { w: 13, h: 13, outline: "k" },
  circ(6, 6, 6, "w"),
  clip([6, 6, 6], rect(0, 0, 4, 13, "s"), rect(9, 0, 4, 13, "r")))

// Bubble Bath: a rubber duck in profile facing right: a round head with its
// eye near the front, a coral beak, a body wider than the head, a small tail at the back.
sprite("toy_bath", { outline: "k" }, `
  .....ggggg......
  ....ggggggg.....
  ....ggggkgg.....
  ....gggggggkrrr.
  ....gggggggkrrr.
  .....ggggg......
  ..gggggggggggg..
  .gggggggggggggg.
  ggggggggggggggg.
  ggggggggggggggg.
  .gggggggggggggg.
  ..gggggggggggg..
  ...gggggggggg...`)

// Pounce: a mole in the shape of a tall egg, looking out of its hill: square
// eyes, a rectangular coral mouth, and its claws on the ground in front.
sprite("_mole", { outline: "k" }, `
  ....ttttt....
  ..ttttttttt..
  .ttttttttttt.
  .ttkktttkktt.
  .ttkktttkktt.
  .ttttttttttt.
  .tttkkkkkttt.
  .tttkrrrkttt.
  .tttkkkkkttt.
  .ttttttttttt.
  ..ttttttttt..`)

sprite("_mound", { outline: "k" }, `
  ...ccccccccccccc...
  .ccccccccccccccccc.
  ccccccccccccccccccc
  .ccccccccccccccccc.
  ...ccccccccccccc...`)

sprite("_claws", { outline: "k" }, `
  rrrrr
  rrrrr
  r.r.r`)

sprite("toy_pounce", { w: 21, h: 18 },
  stamp("_mole", 3, 0),
  stamp("_mound", 0, 11),
  stamp("_claws", 0, 9),
  stamp("_claws", 14, 9))

// Pond Hop: a lily pad seen from above, leaf green with the wedge cut out of
// it, and a coral lotus on it.
sprite("_pad", { outline: "k" }, `
  ....lllllll....
  ..lllllllllll..
  .lllllllllllll.
  lllllllllllll..
  lllllllllll....
  lllllllllllll..
  .lllllllllllll.
  ..lllllllllll..
  ....lllllll....`)

sprite("_flower", { outline: "k" }, `
  ...r...
  .r.r.r.
  .rrrrr.
  ..rrr..`)

sprite("toy_pond", { w: 17, h: 11 },
  stamp("_pad", 0, 0),
  stamp("_flower", 1, 2))

// Fetch the Words: a stick, wood, with a twig and a leaf on the twig.
sprite("_stick", { outline: "k" }, `
  ..........ccc
  .........cccc
  ........cccc.
  ..c....cccc..
  ..c...cccc...
  ..cc.cccc....
  ...ccccc.....
  ...cccc......
  ..cccc.......
  .cccc........
  cccc.........`)

sprite("_leaf", { outline: "k" }, `
  ...ll
  ..lll
  .lll.
  ll...`)

sprite("toy_fetch", { w: 15, h: 13 },
  stamp("_stick", 0, 0),
  stamp("_leaf", 2, 0))

// ------------------------------------------------------------------ small pieces
// The padlock on a shut toy: gold body, stone shackle, a keyhole.
sprite("padlock", { outline: "k" }, `
  ..ttttt..
  .tt...tt.
  .tt...tt.
  .tt...tt.
  kkkkkkkkk
  ggggggggg
  ggggkgggg
  ggggkgggg
  ggggkgggg
  ggggggggg`)

// The arrow on an open toy: coral, pointing at the game.
sprite("play_arrow", { outline: "k" }, `
  rr.....
  rrrr...
  rrrrrr.
  rrrrrrr
  rrrrrr.
  rrrr...
  rr.....`)

// The games' own buttons and bubble, drawn in ink on the button's colour: an X
// for close, a triangle for play (again), and the tail of a speech bubble
// that breaks the bubble's border (cream inside, ink along its edges).
sprite("icon_close", {}, `
  k.....k
  .k...k.
  ..k.k..
  ...k...
  ..k.k..
  .k...k.
  k.....k`)

sprite("icon_play", {}, `
  kk.....
  kkkk...
  kkkkkk.
  kkkkkkk
  kkkkkk.
  kkkk...
  kk.....`)

sprite("bubble_tail", {}, `
  kwwwwwwwk
  .kwwwwwk.
  ..kwwwk..
  ...kwk...
  ....k....`)

// Bubble Bath's bubble: a glass disc with a cream glint, a letter goes on it.
// The wrong one is the same bubble gone coral.
sprite("bubble", { w: 15, h: 15, outline: "k" },
  circ(7, 7, 7, "s"),
  rect(3, 3, 3, 1, "w"), rect(3, 4, 1, 2, "w"))

sprite("bubble_wrong", { base: "bubble", swap: { s: "r" } })

// The bathroom window over the tub, like the cozy room's: a wood frame round
// four glass panes, each fenced in ink, on a sill.
sprite("bath_window", { w: 25, h: 27, outline: "k" },
  rect(0, 0, 25, 25, "c"),
  rect(2, 2, 9, 9, "s"), box(1, 1, 11, 11, "k"),
  rect(14, 2, 9, 9, "s"), box(13, 1, 11, 11, "k"),
  rect(2, 14, 9, 9, "s"), box(1, 13, 11, 11, "k"),
  rect(14, 14, 9, 9, "s"), box(13, 13, 11, 11, "k"),
  rect(0, 25, 25, 2, "c"), hline(0, 25, 25, "k"))

// Pounce's molehill, in two halves so a mole can rise between them: the far
// side, a wood ring round the dark of the hole, and the near lip that covers
// the mole's feet (the lower half of the same ellipse).
sprite("mound_back", { w: 29, h: 9, outline: "k" },
  ellipse(14, 4, 14, 4, "c"),
  ellipse(14, 3, 8, 2, "k"))

sprite("mound_front", { w: 29, h: 4, outline: "k" },
  ellipse(14, -1, 14, 4, "c"))

// The mole that looks out of it, holding up a sign: the toy's egg head with
// square eyes and a rectangular mouth, smaller; eyes shut when it is bonked.
sprite("mole_head", { outline: "k" }, `
  ...ttttt...
  .ttttttttt.
  ttkktttkktt
  ttkktttkktt
  ttttttttttt
  tttkkkkkttt
  tttkrrrkttt
  tttkkkkkttt
  .ttttttttt.`)

sprite("mole_head_bonk", { outline: "k" }, `
  ...ttttt...
  .ttttttttt.
  ttttttttttt
  ttkkktkkktt
  ttttttttttt
  tttkkkkkttt
  tttkrrrkttt
  tttkkkkkttt
  .ttttttttt.`)

sprite("mole_claws", { outline: "k" }, `
  rrrrr
  rrrrr
  r.r.r`)

// Pond Hop's lily pad, big enough to write a word on: a leaf-green ellipse
// with a V cut out of its top edge. Gold lit for the right pad, coral
// for the one that went under.
sprite("lily_pad", { w: 23, h: 9, outline: "k" },
  ellipse(11, 4, 11, 4, "l"),
  poly([13, 0, 19, 0, 16, 3], "_"))

sprite("lily_pad_right", { base: "lily_pad", swap: { l: "g" } })
sprite("lily_pad_wrong", { base: "lily_pad", swap: { l: "r" } })

// Fetch the Words' park: a tree and a bush standing on the grass line, and the
// flowers that grow in it. Leaf-green crowns over a wood trunk, each fenced
// in ink.
sprite("_crown", { w: 30, h: 22, outline: "k" },
  circ(8, 13, 8, "l"), circ(20, 12, 9, "l"), circ(14, 8, 8, "l"))

sprite("_trunk", { w: 5, h: 10, outline: "k" }, rect(0, 0, 5, 10, "c"))

sprite("park_tree", { w: 32, h: 33 },
  stamp("_trunk", 13, 21),
  stamp("_crown", 0, 0))

sprite("park_bush", { w: 15, h: 9, outline: "k" }, ellipse(7, 4, 7, 4, "l"))

sprite("park_flower", { outline: "k" }, `
  .r.
  rkr
  .r.`)

// ------------------------------------------------------------------ the open chest
// The chest of the home button with its lid thrown back and the toys looking
// out of it: the lid's blue back and its two gold straps behind, the cream
// inside of the opening, the toys standing in it, then the body's front across
// their feet with the clasp hanging open.
sprite("_lid", { w: 26, h: 7, outline: "k" },
  rect(0, 0, 26, 7, "s"))

sprite("_mouth", { w: 34, h: 3, outline: "k" },
  rect(0, 0, 34, 3, "w"))

sprite("_body", { w: 34, h: 12, outline: "k" },
  rect(0, 0, 34, 12, "s"),
  rect(0, 8, 34, 4, "c"), hline(0, 7, 34, "k"),
  rect(5, 0, 3, 12, "g"), vline(4, 0, 12, "k"), vline(8, 0, 12, "k"),
  rect(26, 0, 3, 12, "g"), vline(25, 0, 12, "k"), vline(29, 0, 12, "k"),
  rect(14, 0, 6, 7, "g"), box(14, 0, 6, 7, "k"), rect(16, 2, 2, 3, "k"))

scene("chest_open", { w: 36, h: 26 },
  stamp("_lid", 5, 0),
  stamp("_mouth", 0, 8),
  stamp("toy_catch", 2, 5),
  stamp("toy_fetch", 21, 3),
  stamp("toy_bath", 11, 1),
  stamp("_body", 0, 12))

sheet("toys", ["toy_catch", "toy_bath", "toy_pounce", "toy_pond", "toy_fetch", "padlock", "play_arrow"], { pad: 2 })
