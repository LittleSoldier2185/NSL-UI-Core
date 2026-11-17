import { type Color, parseHex } from './color';
import type { AccentSet } from './tint';
import { schema } from './tokens';

export interface AccentPreset {
  id: string;
  nameTh: string;
  nameEn: string;
  light: AccentSet;
  dark: AccentSet;
}

const hex = (s: string): Color => parseHex(s)!;

/** accent สำเร็จรูป (ค่าอ่านจาก schema ที่ฝั่ง Dart สร้าง — ไม่มีสำเนาค่าสีในโค้ดฝั่งเว็บ) */
export const accentPresets: readonly AccentPreset[] = schema.appearance.presets.map((p) => ({
  id: p.id,
  nameTh: p.nameTh,
  nameEn: p.nameEn,
  light: [hex(p.light.accent), hex(p.light.soft), hex(p.light.ink)] as const,
  dark: [hex(p.dark.accent), hex(p.dark.soft), hex(p.dark.ink)] as const,
}));

export function accentPresetById(id: string, presets: readonly AccentPreset[] = accentPresets): AccentPreset | undefined {
  return presets.find((p) => p.id === id);
}
