// Lints the button sprites for the house rule that every fill is fenced by ink:
// a coloured pixel may only touch (4-neighbours) its own colour or ink, and may
// not touch transparency.
//   node --disable-warning=ExperimentalWarning art_src/pxl/check_borders.mjs [file.px.js] [sprite ...]
// Exits 1 and prints the coordinates of every breach.
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { loadProject } from "../../.claude/skills/pxl-pixel-art/src/index.ts";

const here = dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const file = args[0] && args[0].endsWith(".px.js") ? args.shift() : "buttons.px.js";
const project = loadProject(join(here, file));
const INK = 0x14120eff;

// Sprites checked by default: the pieces whose borders matter. The ball's
// stripes are one painted object and are left alone.
const names = args.length > 0
  ? args
  : file === "toychest.px.js"
    ? ["toy_bath", "toy_pounce", "toy_pond", "toy_fetch", "padlock", "play_arrow", "_lid", "_mouth", "_body"]
    : ["_chest", "_roof", "_flag", "_upper", "_base"];

let bad = 0;
for (const name of names) {
  const img = project.image(name);
  const at = (x, y) => (x < 0 || y < 0 || x >= img.w || y >= img.h) ? 0 : img.data[y * img.w + x] >>> 0;
  const opaque = (c) => (c & 0xff) !== 0;
  const hex = (c) => "#" + c.toString(16).padStart(8, "0").slice(0, 6);
  for (let y = 0; y < img.h; y++) {
    for (let x = 0; x < img.w; x++) {
      const c = at(x, y);
      if (!opaque(c) || c === INK) continue;
      for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
        const n = at(x + dx, y + dy);
        if (!opaque(n)) { bad++; console.log(`${name} (${x},${y}) ${hex(c)} touches the outside`); break; }
        if (n !== INK && n !== c) { bad++; console.log(`${name} (${x},${y}) ${hex(c)} touches ${hex(n)} with no ink`); break; }
      }
    }
  }
}
console.log(bad ? `${bad} breach(es)` : "every fill is fenced by ink");
process.exit(bad ? 1 : 0);
