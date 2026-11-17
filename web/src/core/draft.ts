import { type Color, colorEquals } from './color';
import { contrastRatio, ensureContrast } from './contrast';
import { contrastFailures } from './contrastReport';
import { type ThemeLookup, resolveTokens } from './resolve';
import { type ThemeSpec, kNslCoreVersion, kNsltSchema } from './spec';
import type { Brightness, Density, ElevationMode, NslTokens } from './tokens';

/** โมเดลแก้ไขธีมของ NSL Palette (ไม่มี UI) — ตรงกับ NslThemeDraft ฝั่ง Dart */
export interface Draft {
  id: string;
  name: string;
  baseId: string;
  light: Record<string, Color>;
  dark: Record<string, Color>;
  extLight: Record<string, Record<string, Color>>;
  extDark: Record<string, Record<string, Color>>;
  radius: Record<string, number>;
  scale?: number;
  minSize?: number;
  family?: string;
  content?: string;
  mono?: string;
  density?: Density;
  elevationMode?: ElevationMode;
  elevationStrength?: number;
  /** คีย์ที่ editor ไม่รู้จัก — เก็บกลับตอนบันทึก (ไม่ทำของรุ่นใหม่หาย) */
  unknown: Record<string, unknown>;
}

export const defaultBaseId = 'nsl.nebular';

export function draftFromSpec(s: ThemeSpec): Draft {
  const d: Draft = {
    id: s.id,
    name: s.name,
    baseId: s.extendsId ?? defaultBaseId,
    light: { ...s.light.colors },
    dark: { ...s.dark.colors },
    extLight: cloneExt(s.light.extensions),
    extDark: cloneExt(s.dark.extensions),
    radius: { ...s.radius },
    unknown: { ...s.unknown },
  };
  if (s.scale !== undefined) d.scale = s.scale;
  if (s.minSize !== undefined) d.minSize = s.minSize;
  if (s.family !== undefined) d.family = s.family;
  if (s.content !== undefined) d.content = s.content;
  if (s.mono !== undefined) d.mono = s.mono;
  if (s.density !== undefined) d.density = s.density;
  if (s.elevationMode !== undefined) d.elevationMode = s.elevationMode;
  if (s.elevationStrength !== undefined) d.elevationStrength = s.elevationStrength;
  return d;
}

function cloneExt(e: Record<string, Record<string, Color>>): Record<string, Record<string, Color>> {
  return Object.fromEntries(Object.entries(e).map(([k, v]) => [k, { ...v }]));
}

/** ชื่อ → id ที่ใช้เป็นชื่อไฟล์ได้ (a-z 0-9 . _ -) ; ชื่อไทยล้วนได้ "theme" */
export function slugify(name: string): string {
  let s = name.toLowerCase().replace(/[^a-z0-9._-]+/g, '-').replace(/^[^a-z0-9]+|-+$/g, '');
  if (s === '') s = 'theme';
  return s.length > 64 ? s.slice(0, 64) : s;
}

export function draftToSpec(d: Draft): ThemeSpec {
  const spec: ThemeSpec = {
    schema: kNsltSchema,
    core: kNslCoreVersion,
    id: d.id === '' ? slugify(d.name) : d.id,
    name: d.name === '' ? 'Theme' : d.name,
    extendsId: d.baseId,
    light: { colors: { ...d.light }, extensions: cloneExt(d.extLight) },
    dark: { colors: { ...d.dark }, extensions: cloneExt(d.extDark) },
    radius: { ...d.radius },
    unknown: { ...d.unknown },
  };
  if (d.family !== undefined) spec.family = d.family;
  if (d.content !== undefined) spec.content = d.content;
  if (d.mono !== undefined) spec.mono = d.mono;
  if (d.minSize !== undefined) spec.minSize = d.minSize;
  if (d.scale !== undefined) spec.scale = d.scale;
  if (d.density !== undefined) spec.density = d.density;
  if (d.elevationMode !== undefined) spec.elevationMode = d.elevationMode;
  if (d.elevationStrength !== undefined) spec.elevationStrength = d.elevationStrength;
  return spec;
}

export const resolveDraft = (d: Draft, b: Brightness, lookup: ThemeLookup): NslTokens => resolveTokens(draftToSpec(d), b, lookup);

export const colorsOf = (d: Draft, b: Brightness): Record<string, Color> => (b === 'light' ? d.light : d.dark);

/**
 * แก้รายการที่ contrast ไม่ผ่านโดยขยับสีตัวอักษร/เส้นขอบ (ไม่แตะพื้น/accent ที่ผู้ใช้เลือก)
 * คืนจำนวนค่าที่ปรับ ; ทำสูงสุด 3 รอบเพราะบางสีคำนวณต่อจากกัน
 */
export function autoFix(d: Draft, lookup: ThemeLookup): number {
  let changed = 0;
  for (const b of ['light', 'dark'] as const) {
    for (let pass = 0; pass < 3; pass++) {
      const t = resolveDraft(d, b, lookup);
      const fails = contrastFailures(t);
      if (fails.length === 0) break;
      for (const f of fails) {
        const fg = t.colors[f.fg]!;
        const bg = t.colors[f.bg]!;
        const isLight = t.brightness === 'light';
        // ขยับตามทิศปกติของโหมดก่อน ; ถ้ายังไม่ถึงเกณฑ์ (เช่น ขาวบน accent สว่าง) ลองอีกทิศ
        let fixed = ensureContrast(fg, bg, f.min, isLight);
        if (contrastRatio(fixed, bg) < f.min) {
          const other = ensureContrast(fg, bg, f.min, !isLight);
          if (contrastRatio(other, bg) > contrastRatio(fixed, bg)) fixed = other;
        }
        if (!colorEquals(fixed, fg)) {
          colorsOf(d, b)[f.fg] = fixed;
          changed++;
        }
      }
    }
  }
  return changed;
}
