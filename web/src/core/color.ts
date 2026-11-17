// สีแบบเดียวกับ dart:ui Color (ช่องเป็นทศนิยม 0..1) — พอร์ตสูตรจาก Flutter ตรง ๆ เพื่อให้ผลลัพธ์ตรงกับแอปที่ระดับ 8 บิต
// (ตรวจด้วย fixture ที่เทสต์ฝั่ง Dart สร้าง — ดู tests/fixtures.test.ts)

export interface Color {
  readonly a: number;
  readonly r: number;
  readonly g: number;
  readonly b: number;
}

/** เหมือน Color(0xAARRGGBB) */
export function fromARGB32(v: number): Color {
  return { a: ((v >>> 24) & 0xff) / 255, r: ((v >>> 16) & 0xff) / 255, g: ((v >>> 8) & 0xff) / 255, b: (v & 0xff) / 255 };
}

export function rgb(r: number, g: number, b: number, a = 255): Color {
  return { a: a / 255, r: r / 255, g: g / 255, b: b / 255 };
}

export function clamp(x: number, lo: number, hi: number): number {
  return x < lo ? lo : x > hi ? hi : x;
}

/** (x*255).round().clamp(0,255) — เหมือน dart:ui `_floatToInt8` */
export function f8(x: number): number {
  return clamp(Math.round(x * 255), 0, 255);
}

/** เหมือน Color.toARGB32() (ค่าไม่ติดลบ) */
export function toARGB32(c: Color): number {
  return (f8(c.a) * 0x1000000 + (f8(c.r) << 16) + (f8(c.g) << 8) + f8(c.b)) >>> 0;
}

export const alpha8 = (c: Color): number => f8(c.a);
export const red8 = (c: Color): number => f8(c.r);
export const green8 = (c: Color): number => f8(c.g);
export const blue8 = (c: Color): number => f8(c.b);

export function colorEquals(x: Color, y: Color): boolean {
  return toARGB32(x) === toARGB32(y);
}

const hexRe = /^#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/;

/** อ่าน `#RRGGBB` / `#RRGGBBAA` (รูปแบบเดียวกับไฟล์ธีม) ; อย่างอื่น = null */
export function parseHex(v: unknown): Color | null {
  if (typeof v !== 'string' || !hexRe.test(v)) return null;
  const h = v.slice(1);
  const rgbv = parseInt(h.slice(0, 6), 16);
  const a = h.length === 8 ? parseInt(h.slice(6, 8), 16) : 0xff;
  return fromARGB32(((a << 24) | rgbv) >>> 0);
}

/** `#RRGGBB` (ทึบ) หรือ `#RRGGBBAA` (โปร่ง) — ตัวพิมพ์ใหญ่ เหมือนฝั่ง Dart */
export function toHex(c: Color): string {
  const v = toARGB32(c);
  const a = (v >>> 24) & 0xff;
  const rgbs = (v & 0xffffff).toString(16).padStart(6, '0').toUpperCase();
  return a === 0xff ? `#${rgbs}` : `#${rgbs}${a.toString(16).padStart(2, '0').toUpperCase()}`;
}

/** `#RRGGBB` เสมอ (ทิ้ง alpha) — สำหรับ input type=color */
export function toHex6(c: Color): string {
  return `#${(toARGB32(c) & 0xffffff).toString(16).padStart(6, '0').toUpperCase()}`;
}

/** Color.lerp (sRGB เดียวกัน): a*(1-t) + b*t แล้ว clamp */
export function lerp(x: Color, y: Color, t: number): Color {
  const l = (p: number, q: number) => clamp(p * (1 - t) + q * t, 0, 1);
  return { a: l(x.a, y.a), r: l(x.r, y.r), g: l(x.g, y.g), b: l(x.b, y.b) };
}

/** Color.withValues(alpha: a) — alpha เป็นทศนิยม ไม่ปัดเป็น 8 บิต */
export function withAlpha(c: Color, alpha: number): Color {
  return { a: alpha, r: c.r, g: c.g, b: c.b };
}

/** Color.alphaBlend(foreground, background) (สูตรทศนิยมของ Flutter รุ่นนี้) */
export function alphaBlend(fg: Color, bg: Color): Color {
  const alpha = fg.a;
  if (alpha === 0) return bg;
  const inv = 1 - alpha;
  let backAlpha = bg.a;
  if (backAlpha === 1) {
    return { a: 1, r: alpha * fg.r + inv * bg.r, g: alpha * fg.g + inv * bg.g, b: alpha * fg.b + inv * bg.b };
  }
  backAlpha = backAlpha * inv;
  const out = alpha + backAlpha;
  return {
    a: out,
    r: (fg.r * alpha + bg.r * backAlpha) / out,
    g: (fg.g * alpha + bg.g * backAlpha) / out,
    b: (fg.b * alpha + bg.b * backAlpha) / out,
  };
}

function linearize(c: number): number {
  return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
}

/** Color.computeLuminance() */
export function luminance(c: Color): number {
  return 0.2126 * linearize(c.r) + 0.7152 * linearize(c.g) + 0.0722 * linearize(c.b);
}

// ---------------------------------------------------------------------------
// HSL — พอร์ตจาก HSLColor ของ Flutter (fromColor ใช้ช่อง 8 บิต, toColor ปัดเป็น 8 บิต)

export interface HSL {
  readonly alpha: number;
  readonly hue: number;
  readonly saturation: number;
  readonly lightness: number;
}

const mod = (a: number, b: number): number => ((a % b) + b) % b;

export function hslFromColor(c: Color): HSL {
  const red = red8(c) / 0xff;
  const green = green8(c) / 0xff;
  const blue = blue8(c) / 0xff;
  const max = Math.max(red, green, blue);
  const min = Math.min(red, green, blue);
  const delta = max - min;
  const alpha = alpha8(c) / 0xff;
  let hue: number;
  if (max === 0) hue = 0;
  else if (max === red) hue = 60 * mod((green - blue) / delta, 6);
  else if (max === green) hue = 60 * ((blue - red) / delta + 2);
  else hue = 60 * ((red - green) / delta + 4);
  if (Number.isNaN(hue)) hue = 0;
  const lightness = (max + min) / 2;
  const saturation = min === max ? 0 : clamp(delta / (1 - Math.abs(2 * lightness - 1)), 0, 1);
  return { alpha, hue, saturation, lightness };
}

export function hslToColor(h: HSL): Color {
  const chroma = (1 - Math.abs(2 * h.lightness - 1)) * h.saturation;
  const secondary = chroma * (1 - Math.abs(mod(h.hue / 60, 2) - 1));
  const match = h.lightness - chroma / 2;
  let r: number, g: number, b: number;
  if (h.hue < 60) [r, g, b] = [chroma, secondary, 0];
  else if (h.hue < 120) [r, g, b] = [secondary, chroma, 0];
  else if (h.hue < 180) [r, g, b] = [0, chroma, secondary];
  else if (h.hue < 240) [r, g, b] = [0, secondary, chroma];
  else if (h.hue < 300) [r, g, b] = [secondary, 0, chroma];
  else [r, g, b] = [chroma, 0, secondary];
  return rgb(f8Round((r + match) * 0xff), f8Round((g + match) * 0xff), f8Round((b + match) * 0xff), f8Round(h.alpha * 0xff));
}

// Color.fromARGB รับจำนวนเต็มและใช้ modulo 255 กับค่านอกช่วง — HSL ให้ค่าในช่วงอยู่แล้ว จึงแค่ปัด
function f8Round(x: number): number {
  return Math.round(x) & 0xff;
}
