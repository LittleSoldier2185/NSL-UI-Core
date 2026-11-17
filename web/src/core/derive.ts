import { type Color, alphaBlend, fromARGB32, lerp, withAlpha } from './color';
import { inkFor, onAccentFor } from './contrast';
import { type Brightness, type Colors, kCoreColorKeys, kRootColorKeys } from './tokens';

const mix = lerp;
const c = fromARGB32;

/** เติมสีที่ไม่ได้ระบุให้ครบทุก token ของ brightness — ลำดับและสูตรตรงกับ deriveColors ฝั่ง Dart */
export function deriveColors(given: Colors, brightness: Brightness): Colors {
  for (const k of kRootColorKeys) {
    if (!(k in given)) throw new Error(`deriveColors: missing root color "${k}"`);
  }
  const light = brightness === 'light';
  const v: Record<string, Color> = { ...given };
  const set = (k: string, f: () => Color) => {
    if (!(k in v)) v[k] = f();
  };
  const bg = v.bg!;
  const surface = v.surface!;
  const text = v.text!;
  const accent = v.accent!;

  set('chrome', () => bg);
  set('surfaceRaised', () => surface);
  set('surfaceSunken', () => mix(surface, text, 0.05));
  set('borderSoft', () => mix(surface, text, 0.08));
  set('border', () => mix(surface, text, 0.14));
  set('borderStrong', () => mix(surface, text, 0.22));
  set('textMuted', () => mix(text, surface, 0.38));
  set('textFaint', () => mix(text, surface, 0.58));
  set('icon', () => mix(text, v.textMuted!, 0.3));
  set('accentInk', () => inkFor(accent, surface, light));
  set('accentTint', () => alphaBlend(withAlpha(accent, 0.14), surface));
  set('onAccent', () => onAccentFor(accent));
  set('hover', () => mix(surface, text, 0.06));
  set('selected', () => alphaBlend(withAlpha(accent, 0.2), surface));
  set('accentBorder', () => alphaBlend(withAlpha(accent, 0.45), surface));

  // สีสถานะ: ค่าเริ่มต้นคงที่ตามโหมด
  const pick = (l: number, d: number) => () => c(light ? l : d);
  set('danger', pick(0xffb42318, 0xfff97066));
  set('dangerBg', pick(0xfffde8e8, 0xff3f1b1b));
  set('dangerText', pick(0xff7a1f1f, 0xfffca5a5));
  set('warnBg', pick(0xfffff4d6, 0xff3a2e10));
  set('warnText', pick(0xff5c3d00, 0xfff4d58a));
  set('infoBg', pick(0xffe8eef8, 0xff1b2a44));
  set('infoText', pick(0xff1e3a6b, 0xff9dbbea));
  set('success', pick(0xff1a7f4b, 0xff4ade80));
  set('successBg', pick(0xffe6f4ea, 0xff12301f));
  set('successText', pick(0xff14532d, 0xff86efac));
  set('shadow', pick(0xff0f172a, 0xff000000));

  return Object.fromEntries(kCoreColorKeys.map((k) => [k, v[k]!]));
}
