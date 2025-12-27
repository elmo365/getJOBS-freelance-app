const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

function toHex(r, g, b) {
  return (
    '#' +
    [r, g, b]
      .map((v) => v.toString(16).padStart(2, '0'))
      .join('')
      .toUpperCase()
  );
}

function dist(a, b) {
  const dr = a[0] - b[0];
  const dg = a[1] - b[1];
  const db = a[2] - b[2];
  return Math.sqrt(dr * dr + dg * dg + db * db);
}

function isNearWhite(r, g, b) {
  return r > 245 && g > 245 && b > 245;
}

function isNearTransparent(a) {
  return a < 200;
}

function isNearGray(r, g, b) {
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  return max - min < 12 && max > 120 && max < 235;
}

function sampleColors(png, sampleStep = 3) {
  const colors = new Map();

  for (let y = 0; y < png.height; y += sampleStep) {
    for (let x = 0; x < png.width; x += sampleStep) {
      const idx = (png.width * y + x) << 2;
      const r = png.data[idx];
      const g = png.data[idx + 1];
      const b = png.data[idx + 2];
      const a = png.data[idx + 3];

      if (isNearTransparent(a)) continue;
      if (isNearWhite(r, g, b)) continue;
      // The logo contains silver/gray; we skip most gray to better surface brand colors.
      if (isNearGray(r, g, b)) continue;

      // Quantize to reduce noise and cluster similar pixels.
      const q = (v) => Math.round(v / 24) * 24;
      const qr = q(r);
      const qg = q(g);
      const qb = q(b);
      const key = (qr << 16) | (qg << 8) | qb;

      colors.set(key, (colors.get(key) || 0) + 1);
    }
  }

  return [...colors.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, 25)
    .map(([key, count]) => {
      const rgb = [(key >> 16) & 255, (key >> 8) & 255, key & 255];
      return { rgb, hex: toHex(rgb[0], rgb[1], rgb[2]), count };
    });
}

function pickRepresentative(top) {
  // We want representative blue/green/yellow/red-ish colors.
  const targets = {
    blue: [60, 100, 190],
    green: [40, 170, 90],
    yellow: [240, 200, 50],
    red: [220, 60, 60],
  };

  const picked = {};
  for (const [name, t] of Object.entries(targets)) {
    let best = null;
    for (const c of top) {
      const d = dist(c.rgb, t);
      if (!best || d < best.d) {
        best = { ...c, d };
      }
    }
    picked[name] = best;
  }
  return picked;
}

const files = [
  'assets/images/BOTSJOBSCONNECT logo.png',
  'assets/images/BOTSJOBSCONNECT logo icon.png',
  'assets/images/logo.png',
].map((p) => path.resolve(process.cwd(), p));

for (const file of files) {
  if (!fs.existsSync(file)) continue;
  const png = PNG.sync.read(fs.readFileSync(file));
  const top = sampleColors(png, 3);
  const picked = pickRepresentative(top);

  console.log(`\n== ${path.relative(process.cwd(), file)} ==`);
  console.log('Top colors (filtered):');
  for (const c of top.slice(0, 10)) {
    console.log(`  ${c.hex}  count ${c.count}`);
  }
  console.log('Picked (closest representative):');
  for (const k of Object.keys(picked)) {
    const c = picked[k];
    if (!c) continue;
    console.log(`  ${k}: ${c.hex} (rgb ${c.rgb.join(',')})`);
  }
}
