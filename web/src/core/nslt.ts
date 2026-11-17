import { type Color, parseHex, toHex } from './color';
import { type ModeSpec, type ThemeSpec, emptyMode, kNslCoreVersion, kNsltSchema } from './spec';
import type { Density, ElevationMode } from './tokens';
import { schema } from './tokens';

/** ขนาดไฟล์ .nslt สูงสุด (ไบต์) */
export const kNsltMaxBytes = schema.limits.maxFileBytes;

const maxNameLen = 80;
const maxFamilyLen = schema.type.fontNameMaxLength;
const idRe = new RegExp(schema.limits.idPattern);
const coreRe = /^\d{1,3}\.\d{1,3}$/;
const radiusKeys = schema.shape.radius.keys;
const { min: minRadius, max: maxRadius } = schema.shape.radius;
const { min: minScale, max: maxScale } = schema.type.scale;
const { min: minMinSize, max: maxMinSize } = schema.type.minSize;
const { min: minStrength, max: maxStrength } = schema.elevation.strength;

export const isValidThemeId = (id: string): boolean => idRe.test(id);
export const isReservedThemeId = (id: string): boolean => id.startsWith(schema.limits.reservedIdPrefix);

/** ผลการอ่านไฟล์ธีม: spec เป็น undefined = อ่านไม่ได้ (ดู errors) ; warnings = ค่าที่ถูกข้าม/ปรับ */
export interface ParseResult {
  /** อ่านสำเร็จ = มี spec */
  ok: boolean;
  spec?: ThemeSpec;
  errors: string[];
  warnings: string[];
}

const fail = (...errors: string[]): ParseResult => ({ ok: false, errors, warnings: [] });

/** อ่านไฟล์ธีมจากข้อความ — ไม่โยน exception ไม่ว่าอินพุตจะเสียอย่างไร (ข้อมูลไม่น่าเชื่อถือ) */
export function parseNslt(source: string): ParseResult {
  try {
    return parseInner(source);
  } catch (e) {
    return fail(`unexpected error while reading theme: ${e instanceof Error ? e.name : typeof e}`);
  }
}

type Obj = Record<string, unknown>;
const isObj = (v: unknown): v is Obj => typeof v === 'object' && v !== null && !Array.isArray(v);

function parseInner(source: string): ParseResult {
  if (new TextEncoder().encode(source).length > kNsltMaxBytes) return fail('file too large (> 64 KB)');
  let root: unknown;
  try {
    root = JSON.parse(source);
  } catch (e) {
    return fail(`not valid JSON: ${e instanceof Error ? e.message : ''}`);
  }
  if (!isObj(root)) return fail('top level must be a JSON object');

  const warnings: string[] = [];

  const sch = root.schema;
  if (typeof sch !== 'number' || !Number.isInteger(sch) || sch < 1) return fail('"schema" must be an integer >= 1');
  if (sch > kNsltSchema) return fail(`theme schema ${sch} is newer than supported (${kNsltSchema}) — update the app`);

  const id = root.id;
  if (typeof id !== 'string' || !idRe.test(id)) return fail('"id" must match [a-z0-9][a-z0-9._-]{0,63}');
  let name: unknown = root.name;
  if (typeof name !== 'string' || name.trim() === '') {
    warnings.push('"name" missing — using id');
    name = id;
  } else if (name.length > maxNameLen) {
    warnings.push('"name" too long — truncated');
    name = name.slice(0, maxNameLen);
  }

  let core: string | undefined;
  if (root.core !== undefined && root.core !== null) {
    if (typeof root.core === 'string' && coreRe.test(root.core)) {
      core = root.core;
      if (coreNewer(core)) {
        warnings.push(`theme made with newer core ${core} (this is ${kNslCoreVersion}) — unknown values are kept but not applied`);
      }
    } else {
      warnings.push('"core" must look like "1.0" — ignored');
    }
  }

  let extendsId: string | undefined;
  if (root.extends !== undefined && root.extends !== null) {
    if (typeof root.extends === 'string' && idRe.test(root.extends)) extendsId = root.extends;
    else warnings.push('"extends" ignored (not a valid id)');
  }

  const light = parseMode(root.light, 'light', warnings);
  const dark = parseMode(root.dark, 'dark', warnings);

  const radius: Record<string, number> = {};
  if (isObj(root.shape)) {
    const r = root.shape.radius;
    if (isObj(r)) {
      for (const [k, val] of Object.entries(r)) {
        if (!radiusKeys.includes(k)) {
          warnings.push(`shape.radius.${k} unknown — ignored`);
          continue;
        }
        const n = num(val);
        if (n === undefined) {
          warnings.push(`shape.radius.${k} is not a finite number — ignored`);
          continue;
        }
        radius[k] = clampWarn(n, minRadius, maxRadius, `shape.radius.${k}`, warnings);
      }
    }
  }

  let family: string | undefined;
  let content: string | undefined;
  let mono: string | undefined;
  let familyThai: string | undefined;
  let contentThai: string | undefined;
  let monoThai: string | undefined;
  let scale: number | undefined;
  let minSize: number | undefined;
  if (isObj(root.type)) {
    const t = root.type;
    family = fontName(t.family, 'type.family', warnings);
    content = fontName(t.content, 'type.content', warnings);
    mono = fontName(t.mono, 'type.mono', warnings);
    familyThai = fontName(t.familyThai, 'type.familyThai', warnings);
    contentThai = fontName(t.contentThai, 'type.contentThai', warnings);
    monoThai = fontName(t.monoThai, 'type.monoThai', warnings);
    if ('minSize' in t) {
      const n = num(t.minSize);
      if (n === undefined) warnings.push('type.minSize is not a finite number — ignored');
      else minSize = clampWarn(n, minMinSize, maxMinSize, 'type.minSize', warnings);
    }
    if ('scale' in t) {
      const n = num(t.scale);
      if (n === undefined) warnings.push('type.scale is not a finite number — ignored');
      else scale = clampWarn(n, minScale, maxScale, 'type.scale', warnings);
    }
  }

  let density: Density | undefined;
  if ('density' in root) {
    if (root.density === 'compact' || root.density === 'normal' || root.density === 'comfortable') density = root.density;
    else warnings.push('"density" must be compact|normal|comfortable — ignored');
  }

  let elevationMode: ElevationMode | undefined;
  let elevationStrength: number | undefined;
  if (isObj(root.elevation)) {
    const el = root.elevation;
    if ('mode' in el) {
      if (el.mode === 'shadow' || el.mode === 'flat') elevationMode = el.mode;
      else warnings.push('elevation.mode must be shadow|flat — ignored');
    }
    if ('strength' in el) {
      const n = num(el.strength);
      if (n === undefined) warnings.push('elevation.strength is not a finite number — ignored');
      else elevationStrength = clampWarn(n, minStrength, maxStrength, 'elevation.strength', warnings);
    }
  }

  // apps : รายชื่อ id ไม่ซ้ำ ≤ 16 — ผิดรูปแบบ = เตือนและเก็บค่าดิบไว้ใน unknown (ไม่ให้ข้อมูลหาย)
  let apps: string[] = [];
  let appsRaw = false;
  if (root.apps !== undefined && root.apps !== null) {
    const a = root.apps;
    if (Array.isArray(a) && a.length <= 16 && a.every((e) => typeof e === 'string' && idRe.test(e))) apps = [...new Set(a as string[])];
    else {
      warnings.push('"apps" must be a list of up to 16 app ids — ignored');
      appsRaw = true;
    }
  }

  const known = new Set(['schema', 'core', 'id', 'name', 'extends', 'light', 'dark', 'shape', 'type', 'density', 'elevation', 'apps']);
  const unknown: Record<string, unknown> = {};
  for (const [k, val] of Object.entries(root)) if (!known.has(k)) unknown[k] = val;
  if (appsRaw) unknown.apps = root.apps;

  const spec: ThemeSpec = { schema: sch, id, name: name as string, light, dark, radius, unknown };
  if (core !== undefined) spec.core = core;
  if (extendsId !== undefined) spec.extendsId = extendsId;
  if (apps.length > 0) spec.apps = apps;
  if (family !== undefined) spec.family = family;
  if (content !== undefined) spec.content = content;
  if (mono !== undefined) spec.mono = mono;
  if (familyThai !== undefined) spec.familyThai = familyThai;
  if (contentThai !== undefined) spec.contentThai = contentThai;
  if (monoThai !== undefined) spec.monoThai = monoThai;
  if (minSize !== undefined) spec.minSize = minSize;
  if (scale !== undefined) spec.scale = scale;
  if (density !== undefined) spec.density = density;
  if (elevationMode !== undefined) spec.elevationMode = elevationMode;
  if (elevationStrength !== undefined) spec.elevationStrength = elevationStrength;
  return { ok: true, spec, errors: [], warnings };
}

function parseMode(v: unknown, path: string, warnings: string[]): ModeSpec {
  if (v === undefined || v === null) return emptyMode();
  if (!isObj(v)) {
    warnings.push(`"${path}" must be an object — ignored`);
    return emptyMode();
  }
  const colors: Record<string, Color> = {};
  const c = v.colors;
  if (isObj(c)) {
    for (const [k, val] of Object.entries(c)) {
      const col = parseHex(val);
      if (col === null) warnings.push(`${path}.colors.${k}: invalid color — ignored`);
      else colors[k] = col;
    }
  } else if (c !== undefined && c !== null) {
    warnings.push(`${path}.colors must be an object — ignored`);
  }
  const extensions: Record<string, Record<string, Color>> = {};
  const x = v.extensions;
  if (isObj(x)) {
    for (const [name, m] of Object.entries(x)) {
      if (!isObj(m)) {
        warnings.push(`${path}.extensions.${name} must be an object — ignored`);
        continue;
      }
      const cm: Record<string, Color> = {};
      for (const [k, val] of Object.entries(m)) {
        const col = parseHex(val);
        if (col === null) warnings.push(`${path}.extensions.${name}.${k}: invalid color — ignored`);
        else cm[k] = col;
      }
      extensions[name] = cm;
    }
  } else if (x !== undefined && x !== null) {
    warnings.push(`${path}.extensions must be an object — ignored`);
  }
  return { colors, extensions };
}

/** เวอร์ชัน core v ใหม่กว่ารุ่นนี้หรือไม่ (เทียบ major.minor เป็นตัวเลข) */
function coreNewer(v: string): boolean {
  const a = v.split('.').map(Number);
  const b = kNslCoreVersion.split('.').map(Number);
  return a[0] !== b[0] ? a[0]! > b[0]! : a[1]! > b[1]!;
}

function num(v: unknown): number | undefined {
  return typeof v === 'number' && Number.isFinite(v) ? v : undefined;
}

function clampWarn(v: number, lo: number, hi: number, path: string, warnings: string[]): number {
  if (v < lo || v > hi) {
    const c = v < lo ? lo : hi;
    warnings.push(`${path} = ${v} out of range [${lo}, ${hi}] — using ${c}`);
    return c;
  }
  return v;
}

function fontName(v: unknown, path: string, warnings: string[]): string | undefined {
  if (v === undefined || v === null) return undefined;
  // eslint-disable-next-line no-control-regex
  if (typeof v !== 'string' || v.trim() === '' || v.length > maxFamilyLen || /[\\/:\x00-\x1f]/.test(v)) {
    warnings.push(`${path}: invalid font name — ignored`);
    return undefined;
  }
  return v.trim();
}

// ---------------------------------------------------------------------------
// เขียนไฟล์ (เรียงคีย์คงที่ เทียบ/diff ได้ — ตรงกับ serializeNslt ฝั่ง Dart)

const sorted = (o: Record<string, unknown>): string[] => Object.keys(o).sort();

function modeJson(m: ModeSpec): Obj {
  const out: Obj = {};
  if (Object.keys(m.colors).length > 0) {
    out.colors = Object.fromEntries(sorted(m.colors).map((k) => [k, toHex(m.colors[k]!)]));
  }
  if (Object.keys(m.extensions).length > 0) {
    out.extensions = Object.fromEntries(
      sorted(m.extensions).map((e) => [e, Object.fromEntries(sorted(m.extensions[e]!).map((k) => [k, toHex(m.extensions[e]![k]!)]))]),
    );
  }
  return out;
}

export function serializeNslt(s: ThemeSpec): string {
  const out: Obj = { schema: s.schema };
  if (s.core !== undefined) out.core = s.core;
  out.id = s.id;
  out.name = s.name;
  if (s.extendsId !== undefined) out.extends = s.extendsId;
  if (s.apps !== undefined && s.apps.length > 0) out.apps = s.apps;
  const light = modeJson(s.light);
  const dark = modeJson(s.dark);
  if (Object.keys(light).length > 0) out.light = light;
  if (Object.keys(dark).length > 0) out.dark = dark;
  if (Object.keys(s.radius).length > 0) {
    out.shape = { radius: Object.fromEntries(radiusKeys.filter((k) => k in s.radius).map((k) => [k, s.radius[k]])) };
  }
  const type: Obj = {};
  if (s.family !== undefined) type.family = s.family;
  if (s.content !== undefined) type.content = s.content;
  if (s.mono !== undefined) type.mono = s.mono;
  if (s.familyThai !== undefined) type.familyThai = s.familyThai;
  if (s.contentThai !== undefined) type.contentThai = s.contentThai;
  if (s.monoThai !== undefined) type.monoThai = s.monoThai;
  if (s.minSize !== undefined) type.minSize = s.minSize;
  if (s.scale !== undefined) type.scale = s.scale;
  if (Object.keys(type).length > 0) out.type = type;
  if (s.density !== undefined) out.density = s.density;
  const el: Obj = {};
  if (s.elevationMode !== undefined) el.mode = s.elevationMode;
  if (s.elevationStrength !== undefined) el.strength = s.elevationStrength;
  if (Object.keys(el).length > 0) out.elevation = el;
  for (const [k, v] of Object.entries(s.unknown)) if (!(k in out)) out[k] = v;
  return JSON.stringify(out, null, 2);
}
