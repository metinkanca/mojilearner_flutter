// Cap for the cat, drawn with pxl: one pixel = one 3-unit cell of cat2's grid,
// border three cells (9 units) like the finished pets, flat colours, no shading.
// See tophat.px.js for why the border is a chain of three outlines.
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/cap.px.js
// Export: python art_src/gen_cat_hats.py cap
//
pal({
  k: "#1f2223",   // pet ink
  r: "#e3664f",   // the cap, as before
  g: "#f0c24c",   // the button
})

// 50 x 23 cells of fill. The dome is 40 wide (cols 0..39, centre line at 20) and
// 20 rows tall; the button sits on its top, the peak sticks out of the front.
// At a three-cell border a detail needs 5+ cells to show any fill at all, hence
// the 6x3 button and the six-row peak.
//
// The peak is a straight rectangle: flush with the dome's bottom, square at the
// end, no taper and no droop (owner: "going down on a certain part" was the
// earlier version; "I wanted it to be straight instead"). It is the same coral
// as the dome, as in the original cap, so it needs a line where it joins: a
// 3-row ink seam (cap-line weight, like the whiskers) running from the peak's
// top edge back into the dome. Past the dome the peak's own border is that
// line, so the seam stops at col 39.
sprite("_cap_fill", { w: 50, h: 23 },
  rect(17, 0, 6, 3, "g"),     // button
  rect(12, 3, 16, 1, "r"),    // dome, widths 16 24 28 32 34 36 38 38 then 40
  rect(8, 4, 24, 1, "r"),
  rect(6, 5, 28, 1, "r"),
  rect(4, 6, 32, 1, "r"),
  rect(3, 7, 34, 1, "r"),
  rect(2, 8, 36, 1, "r"),
  rect(1, 9, 38, 2, "r"),
  rect(0, 11, 40, 12, "r"),
  rect(40, 17, 10, 6, "r"),   // peak
  rect(28, 14, 12, 3, "k"))   // the seam, drawn last so it sits over the dome

sprite("_cap_1", { base: "_cap_fill", outline8: "k" })
sprite("_cap_2", { base: "_cap_1", outline8: "k" })
sprite("cap", { base: "_cap_2", outline8: "k" })
