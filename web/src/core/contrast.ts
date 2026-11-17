import { type Color, fromARGB32, lerp, luminance } from './color';

/** อัตราส่วน contrast ตาม WCAG (1.0 – 21.0) — ตรงกับ `contrastRatio` ฝั่ง Dart */
export function contrastRatio(a: Color, b: Color): number {
  const x = luminance(a);
  const y = luminance(b);
  return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05);
}

const BLACK = fromARGB32(0xff000000);
const WHITE = fromARGB32(0xffffffff);

/** ทำให้ accent เข้มขึ้น (ธีมสว่าง) หรืออ่อนลง (ธีมมืด) จนอ่านเป็นตัวอักษรบน surface ได้ (>= 4.5:1) */
export function inkFor(accent: Color, surface: Color, light: boolean): Color {
  const toward = light ? BLACK : WHITE;
  let ink = accent;
  for (let k = 1; contrastRatio(ink, surface) < 4.5 && k <= 20; k++) {
    ink = lerp(accent, toward, k / 20);
  }
  return ink;
}

/** สีตัวอักษรที่อ่านได้บนพื้น accent (เข้มหรือขาว แล้วแต่ตัวไหน contrast สูงกว่า) */
export function onAccentFor(accent: Color): Color {
  const dark = fromARGB32(0xff1a1204);
  return contrastRatio(accent, dark) >= contrastRatio(accent, WHITE) ? dark : WHITE;
}

/** ขยับ fg เข้าหาดำ (ธีมสว่าง) หรือขาว (ธีมมืด) จนได้ contrast >= min เทียบกับ bg */
export function ensureContrast(fg: Color, bg: Color, min: number, light: boolean): Color {
  if (contrastRatio(fg, bg) >= min) return fg;
  const toward = light ? BLACK : WHITE;
  for (let k = 1; k <= 20; k++) {
    const c = lerp(fg, toward, k / 20);
    if (contrastRatio(c, bg) >= min) return c;
  }
  return toward;
}
