import type { Appearance } from './appearance';
import type { Color } from './color';
import type { Density, ElevationMode } from './tokens';

/** เวอร์ชัน schema สูงสุดที่รุ่นนี้เข้าใจ (จำนวนเต็ม) */
export const kNsltSchema = 1;

/** เวอร์ชัน core ของ build นี้ — ต้องตรงกับ kNslCoreVersion ฝั่ง Dart (ตรวจใน tests/fixtures.test.ts) */
export const kNslCoreVersion = '1.1';

export interface ModeSpec {
  colors: Record<string, Color>;
  extensions: Record<string, Record<string, Color>>;
}

export const emptyMode = (): ModeSpec => ({ colors: {}, extensions: {} });

/** เนื้อหาของไฟล์ .nslt ตามที่เขียนไว้ (ยังไม่ resolve) */
export interface ThemeSpec {
  schema: number;
  core?: string;
  id: string;
  name: string;
  extendsId?: string;
  light: ModeSpec;
  dark: ModeSpec;
  radius: Record<string, number>;
  family?: string;
  content?: string;
  mono?: string;
  minSize?: number;
  scale?: number;
  density?: Density;
  elevationMode?: ElevationMode;
  elevationStrength?: number;
  /** คีย์ระดับบนสุดที่รุ่นนี้ไม่รู้จัก (เก็บไว้เขียนกลับ) */
  unknown: Record<string, unknown>;
  /** ค่า lite ของผู้ใช้ (ใช้ตอน resolve เท่านั้น ไม่เขียนลงไฟล์) */
  appearance?: Appearance;
}

export function newSpec(id: string, name: string, extra: Partial<ThemeSpec> = {}): ThemeSpec {
  return { schema: kNsltSchema, id, name, light: emptyMode(), dark: emptyMode(), radius: {}, unknown: {}, ...extra };
}

export const modeOf = (s: ThemeSpec, b: 'light' | 'dark'): ModeSpec => (b === 'light' ? s.light : s.dark);

export function withAppearance(s: ThemeSpec, a: Appearance | undefined): ThemeSpec {
  const hasAccent = a !== undefined && (a.presetId !== undefined || a.customAccent !== undefined);
  const { appearance: _drop, ...rest } = s;
  void _drop;
  return hasAccent ? { ...rest, appearance: a } : rest;
}
