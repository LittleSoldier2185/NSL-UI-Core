import { type Color, clamp, fromARGB32, hslFromColor, hslToColor } from './color';
import { contrastRatio, ensureContrast } from './contrast';

const WHITE = fromARGB32(0xffffffff);

/** (accent ที่ปรับให้อ่านได้, พื้นอ่อน, ตัวอักษรบนพื้นอ่อน) */
export type AccentSet = readonly [accent: Color, soft: Color, ink: Color];

const hsl = (alpha: number, hue: number, s: number, l: number) => hslToColor({ alpha, hue, saturation: s, lightness: l });

/** แปลงสีใด ๆ ที่ผู้ใช้เลือกเป็นชุดสี accent — พอร์ตจาก NSL Utility (accentTints) ผ่านฝั่ง Dart */
export function accentTints(base: Color, dark: boolean): AccentSet {
  const h = hslFromColor(base);
  const sat = clamp(h.saturation, 0.3, 0.95);
  let l = dark ? clamp(h.lightness, 0.42, 0.62) : clamp(h.lightness, 0.25, 0.45);
  let acc = hsl(1, h.hue, sat, l);
  while (contrastRatio(acc, WHITE) < (dark ? 3.6 : 4.5) && l > 0.1) {
    l -= 0.02;
    acc = hsl(1, h.hue, sat, l);
  }
  const soft = hsl(1, h.hue, dark ? sat * 0.45 : sat * 0.6, dark ? 0.18 : 0.92);
  const on0 = hsl(1, h.hue, dark ? sat * 0.8 : sat, dark ? 0.78 : 0.24);
  const on = ensureContrast(on0, soft, 4.5, !dark);
  return [acc, soft, on];
}

/** คู่ (พื้น, ตัวอักษร) ที่อ่านได้ (>= 4.5) สำหรับสีใด ๆ ตามโหมด */
export function tintFor(base: Color, dark: boolean): readonly [bg: Color, fg: Color] {
  const h = hslFromColor(base);
  const sat = clamp(h.saturation, 0.3, 0.95);
  const bg = hsl(1, h.hue, dark ? sat * 0.5 : sat * 0.6, dark ? 0.2 : 0.92);
  const fg = hsl(1, h.hue, sat, dark ? 0.78 : 0.26);
  return [bg, ensureContrast(fg, bg, 4.5, !dark)];
}
