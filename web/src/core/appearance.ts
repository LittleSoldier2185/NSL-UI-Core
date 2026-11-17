import type { Color } from './color';
import { parseHex, toHex6 } from './color';
import { type AccentPreset, accentPresetById, accentPresets } from './presets';
import { type AccentSet, accentTints } from './tint';

export type ModeChoice = 'system' | 'light' | 'dark';

/** การปรับแต่งแบบ lite (โหมด + accent) — ตรงกับ NslAppearance ฝั่ง Dart */
export interface Appearance {
  mode: ModeChoice;
  presetId?: string;
  customAccent?: Color;
}

export const noAppearance = (): Appearance => ({ mode: 'system' });

/** ชุดสี accent ของโหมดที่ต้องการ (undefined = ไม่ได้ตั้ง accent หรือ preset ที่อ้างไม่มีและไม่มีสีเอง) */
export function accentSet(a: Appearance, dark: boolean, presets: readonly AccentPreset[] = accentPresets): AccentSet | undefined {
  if (a.presetId !== undefined) {
    const p = accentPresetById(a.presetId, presets);
    if (p) return dark ? p.dark : p.light;
  }
  return a.customAccent === undefined ? undefined : accentTints(a.customAccent, dark);
}

const presetIdRe = /^[a-z0-9][a-z0-9._-]{0,31}$/;

/** อ่านแบบไม่โยน: ค่าที่ไม่รู้จัก/รูปแบบผิด = ข้าม */
export function appearanceFromJson(j: unknown): Appearance {
  if (typeof j !== 'object' || j === null || Array.isArray(j)) return noAppearance();
  const o = j as Record<string, unknown>;
  const mode: ModeChoice = o.mode === 'light' || o.mode === 'dark' || o.mode === 'system' ? o.mode : 'system';
  const out: Appearance = { mode };
  if (typeof o.preset === 'string' && presetIdRe.test(o.preset)) out.presetId = o.preset;
  if (typeof o.customAccent === 'string' && /^#[0-9a-fA-F]{6}$/.test(o.customAccent)) {
    const c = parseHex(o.customAccent);
    if (c) out.customAccent = c;
  }
  return out;
}

export function appearanceToJson(a: Appearance): Record<string, unknown> {
  return {
    mode: a.mode,
    ...(a.presetId !== undefined ? { preset: a.presetId } : {}),
    ...(a.presetId === undefined && a.customAccent !== undefined ? { customAccent: toHex6(a.customAccent) } : {}),
  };
}
