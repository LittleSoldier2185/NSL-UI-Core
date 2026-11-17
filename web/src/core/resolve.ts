import { accentSet } from './appearance';
import { onAccentFor } from './contrast';
import { deriveColors } from './derive';
import { knownExtensions } from './extensions';
import { type ThemeSpec, modeOf } from './spec';
import {
  type Brightness,
  type Colors,
  type Density,
  type ElevationMode,
  type NslShape,
  type NslTokens,
  kAccentDependents,
  kRootColorKeys,
  schema,
} from './tokens';

/** หาธีมฐานจาก id (undefined ถ้าไม่มี) */
export type ThemeLookup = (id: string) => ThemeSpec | undefined;

/** ความลึกสูงสุดของสายการสืบทอด (กันวนลูป) */
export const kMaxExtendsDepth = 8;

export class ResolveError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ResolveError';
  }
}

/** รวมสายการสืบทอดจากฐานสุดไปถึง spec เอง */
function chainOf(spec: ThemeSpec, lookup: ThemeLookup): ThemeSpec[] {
  const out: ThemeSpec[] = [spec];
  const seen = new Set<string>([spec.id]);
  let cur = spec;
  while (cur.extendsId !== undefined) {
    if (out.length > kMaxExtendsDepth) throw new ResolveError(`extends chain too deep (> ${kMaxExtendsDepth})`);
    const base = lookup(cur.extendsId);
    if (!base) throw new ResolveError(`base theme "${cur.extendsId}" not found`);
    if (seen.has(base.id)) throw new ResolveError(`extends cycle at "${base.id}"`);
    seen.add(base.id);
    out.unshift(base);
    cur = base;
  }
  return out;
}

const defaultShape = (): NslShape => ({ ...schema.shape.radius.default }) as unknown as NslShape;

/**
 * resolve ธีม spec ของโหมด brightness เป็น token ที่ครบทุกค่า — ตรงกับ resolveTokens ฝั่ง Dart
 * ลำดับ: ค่าจากธีมฐาน → ทับด้วยธีมลูก → ค่า lite ของผู้ใช้ → derive ค่าที่ยังขาด
 */
export function resolveTokens(spec: ThemeSpec, brightness: Brightness, lookup: ThemeLookup = () => undefined): NslTokens {
  const chain = chainOf(spec, lookup);

  const colors: Colors = {};
  const exts: Record<string, Colors> = {};
  const radius: Record<string, number> = {};
  let family: string | undefined;
  let content: string | undefined;
  let mono: string | undefined;
  let familyThai: string | undefined;
  let contentThai: string | undefined;
  let monoThai: string | undefined;
  let scale: number | undefined;
  let strength: number | undefined;
  let minSize: number | undefined;
  let density: Density | undefined;
  let mode: ElevationMode | undefined;

  for (const s of chain) {
    const m = modeOf(s, brightness);
    if ('accent' in m.colors && s !== chain[0]) {
      // ธีมลูกที่ไม่ใช่ฐานสุดเปลี่ยน accent → ล้างตัวที่คำนวณจาก accent ก่อนทับ
      for (const k of kAccentDependents) if (!(k in m.colors)) delete colors[k];
      for (const def of knownExtensions) {
        for (const k of def.accentDependents) {
          if (m.extensions[def.name]?.[k] === undefined) delete exts[def.name]?.[k];
        }
      }
    }
    Object.assign(colors, m.colors);
    for (const [name, vals] of Object.entries(m.extensions)) Object.assign((exts[name] ??= {}), vals);
    Object.assign(radius, s.radius);
    family = s.family ?? family;
    content = s.content ?? content;
    minSize = s.minSize ?? minSize;
    mono = s.mono ?? mono;
    familyThai = s.familyThai ?? familyThai;
    contentThai = s.contentThai ?? contentThai;
    monoThai = s.monoThai ?? monoThai;
    scale = s.scale ?? scale;
    density = s.density ?? density;
    mode = s.elevationMode ?? mode;
    strength = s.elevationStrength ?? strength;
  }

  // ค่า lite ของผู้ใช้ชนะทุกอย่าง (เฉพาะ accent)
  const lite = spec.appearance ? accentSet(spec.appearance, brightness === 'dark') : undefined;
  if (lite) {
    for (const k of kAccentDependents) delete colors[k];
    colors.accent = lite[0];
    colors.accentTint = lite[1];
    colors.accentInk = lite[2];
    colors.onAccent = onAccentFor(lite[0]);
    for (const def of knownExtensions) for (const k of def.accentDependents) delete exts[def.name]?.[k];
  }

  const missing = kRootColorKeys.filter((k) => !(k in colors));
  if (missing.length > 0) throw new ResolveError(`missing root colors: ${missing.join(', ')} (set them or use "extends")`);

  const core = deriveColors(colors, brightness);

  // ส่วนขยายที่รู้จัก: เติมค่า derive ; ส่วนขยายที่ไม่รู้จักผ่านไปตามเดิม
  const outExt: Record<string, Colors> = {};
  for (const def of knownExtensions) {
    const given = exts[def.name] ?? {};
    const derived = def.derive(core, brightness);
    outExt[def.name] = Object.fromEntries(def.keys.map((k) => [k, given[k] ?? derived[k]!]));
  }
  for (const [name, vals] of Object.entries(exts)) if (!(name in outExt)) outExt[name] = { ...vals };

  return {
    brightness,
    colors: core,
    shape: { ...defaultShape(), ...radius },
    type: {
      ...(family !== undefined ? { family } : {}),
      ...(content !== undefined ? { content } : {}),
      ...(mono !== undefined ? { mono } : {}),
      ...(familyThai !== undefined ? { familyThai } : {}),
      ...(contentThai !== undefined ? { contentThai } : {}),
      ...(monoThai !== undefined ? { monoThai } : {}),
      scale: scale ?? 1,
      ...(minSize !== undefined ? { minSize } : {}),
    },
    density: density ?? 'normal',
    elevation: { mode: mode ?? 'shadow', strength: strength ?? 1 },
    extensions: outExt,
  };
}
