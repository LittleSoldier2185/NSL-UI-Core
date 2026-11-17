// ตัวตรวจไฟล์ฟอนต์ + การจัดลำดับฟอนต์ละติน/ไทย — พอร์ตจาก lib/src/fonts/font_info.dart (ผลต้องตรงกัน ดู tests/fontInfo.test.ts)
// ไฟล์ฟอนต์ถือเป็นข้อมูลไม่น่าเชื่อถือ : ไม่โยน exception และไม่อ่านเกินขอบเขตไฟล์

/** ขนาดไฟล์ฟอนต์ที่รับได้สูงสุด (ตรงกับ kMaxFontBytes ฝั่ง Dart) */
export const kMaxFontBytes = 16 * 1024 * 1024;

export interface FontInfo {
  /** ชื่อ family จากตาราง name (undefined = อ่านไม่ได้) */
  familyName?: string;
  /** มีอักษรไทยพอใช้งาน (≥ 90% ของชุดทดสอบ) */
  coversThai: boolean;
  /** มี A–Z a–z 0–9 ครบ (≥ 95%) */
  coversLatin: boolean;
}

export type FontInspection = { ok: true; info: FontInfo } | { ok: false; error: string };

const TAG_TRUETYPE = 0x00010000;
const TAG_OTTO = 0x4f54544f;
const TAG_TRUE = 0x74727565;
const TAG_TTCF = 0x74746366;
const TAG_WOFF = 0x774f4646;
const TAG_WOFF2 = 0x774f4632;
const MAX_TABLES = 64;
const MAX_SEGMENTS = 20000;

const range = (a: number, b: number): number[] => Array.from({ length: b - a + 1 }, (_, i) => a + i);
const THAI_PROBE = [...range(0x0e01, 0x0e2e), ...range(0x0e30, 0x0e3a), ...range(0x0e40, 0x0e4e)];
const LATIN_PROBE = [...range(0x41, 0x5a), ...range(0x61, 0x7a), ...range(0x30, 0x39)];

const fail = (error: string): FontInspection => ({ ok: false, error });

export function inspectFontBytes(bytes: Uint8Array): FontInspection {
  if (bytes.length < 12) return fail('too small to be a font');
  if (bytes.length > kMaxFontBytes) return fail('font file too large');
  try {
    const d = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
    const tag = d.getUint32(0);
    if (tag === TAG_TTCF) return fail('font collections (.ttc) are not supported');
    if (tag === TAG_WOFF || tag === TAG_WOFF2) return fail('WOFF fonts are not supported — use .ttf or .otf');
    if (tag !== TAG_TRUETYPE && tag !== TAG_OTTO && tag !== TAG_TRUE) return fail('not a TrueType/OpenType font');
    const numTables = d.getUint16(4);
    if (numTables === 0 || numTables > MAX_TABLES) return fail('invalid table count');
    if (12 + numTables * 16 > bytes.length) return fail('table directory is cut off');

    const tables = new Map<number, [number, number]>();
    for (let i = 0; i < numTables; i++) {
      const r = 12 + i * 16;
      const t = d.getUint32(r);
      const off = d.getUint32(r + 8);
      const len = d.getUint32(r + 12);
      if (off > bytes.length || len > bytes.length - off) return fail('a table points outside the file');
      tables.set(t, [off, len]);
    }
    const cmap = tables.get(0x636d6170); // 'cmap'
    if (!cmap) return fail('no character map (cmap)');
    const covers = cmapReader(d, cmap[0], cmap[1]);
    if (!covers) return fail('unsupported or invalid character map');
    const share = (probe: number[], need: number) => probe.filter(covers).length >= probe.length * need;

    const name = tables.get(0x6e616d65); // 'name'
    const info: FontInfo = { coversThai: share(THAI_PROBE, 0.9), coversLatin: share(LATIN_PROBE, 0.95) };
    const fam = name ? familyName(d, name[0], name[1]) : undefined;
    if (fam !== undefined) info.familyName = fam;
    return { ok: true, info };
  } catch (e) {
    if (e instanceof RangeError) return fail('font file is corrupt');
    throw e;
  }
}

function cmapReader(d: DataView, base: number, len: number): ((cp: number) => boolean) | null {
  if (len < 4) return null;
  const n = d.getUint16(base + 2);
  if (n === 0 || n > 64 || 4 + n * 8 > len) return null;
  let best4: number | null = null;
  let best12: number | null = null;
  for (let i = 0; i < n; i++) {
    const r = base + 4 + i * 8;
    const plat = d.getUint16(r);
    const enc = d.getUint16(r + 2);
    const off = d.getUint32(r + 4);
    if (off >= len - 2) continue;
    const fmt = d.getUint16(base + off);
    const unicode = plat === 0 || (plat === 3 && (enc === 1 || enc === 10));
    if (!unicode) continue;
    if (fmt === 12) best12 = base + off;
    if (fmt === 4) best4 = base + off;
  }
  if (best12 !== null) {
    const o = best12;
    const groups = d.getUint32(o + 12);
    if (groups > MAX_SEGMENTS || o + 16 + groups * 12 > base + len) return null;
    return (cp) => {
      for (let g = 0; g < groups; g++) {
        const p = o + 16 + g * 12;
        if (cp >= d.getUint32(p) && cp <= d.getUint32(p + 4)) return true;
      }
      return false;
    };
  }
  if (best4 !== null) {
    const o = best4;
    const segX2 = d.getUint16(o + 6);
    const seg = segX2 >> 1;
    if (seg === 0 || seg > MAX_SEGMENTS || o + 16 + segX2 * 4 > base + len) return null;
    const endO = o + 14;
    const startO = endO + segX2 + 2;
    const deltaO = startO + segX2;
    const rangeO = deltaO + segX2;
    return (cp) => {
      if (cp > 0xffff) return false;
      for (let s = 0; s < seg; s++) {
        const end = d.getUint16(endO + s * 2);
        if (cp > end) continue;
        const start = d.getUint16(startO + s * 2);
        if (cp < start) return false;
        const ro = d.getUint16(rangeO + s * 2);
        if (ro === 0) return ((cp + d.getInt16(deltaO + s * 2)) & 0xffff) !== 0;
        const gp = rangeO + s * 2 + ro + (cp - start) * 2;
        if (gp + 2 > base + len) return false;
        return d.getUint16(gp) !== 0;
      }
      return false;
    };
  }
  return null;
}

const NAME_BAD = /[\x00-\x1f\\/:]/g;

function familyName(d: DataView, base: number, len: number): string | undefined {
  if (len < 6) return undefined;
  const count = d.getUint16(base + 2);
  const strOff = d.getUint16(base + 4);
  if (count > 2000 || 6 + count * 12 > len) return undefined;
  let found: string | undefined;
  let foundId = 0;
  for (let i = 0; i < count; i++) {
    const r = base + 6 + i * 12;
    const plat = d.getUint16(r);
    const id = d.getUint16(r + 6);
    const l = d.getUint16(r + 8);
    const o = d.getUint16(r + 10);
    if ((id !== 1 && id !== 16) || (found !== undefined && id < foundId)) continue;
    const start = base + strOff + o;
    if (start + l > base + len || l === 0 || l > 256) continue;
    let s: string | undefined;
    if (plat === 3 || plat === 0) {
      const cu: number[] = [];
      for (let k = 0; k + 1 < l; k += 2) cu.push(d.getUint16(start + k));
      s = String.fromCharCode(...cu);
    } else if (plat === 1) {
      const cu: number[] = [];
      for (let k = 0; k < l; k++) cu.push(d.getUint8(start + k));
      s = String.fromCharCode(...cu);
    }
    if (s === undefined) continue;
    s = s.replace(NAME_BAD, '').trim();
    if (s === '' || s.length > 64) continue;
    found = s;
    foundId = id;
  }
  return found;
}

// ---------------------------------------------------------------------------

/** ฟอนต์สำรองของ nsl_ui — ผู้ใช้นำเข้าฟอนต์ที่ชื่อชนกันไม่ได้ (ตรงกับ NslFontStore.isReservedFamily) */
const RESERVED = new Set(['noto sans thai', 'leelawadee ui', 'segoe ui symbol', 'segoe ui', 'tahoma']);
export const isReservedFamily = (family: string): boolean => RESERVED.has(family.toLowerCase());

export type FontIssue = 'thaiFontLacksThai' | 'latinFontLacksLatin' | 'bothCoverBoth';

export interface FontPlan {
  /** ต้องวางฟอนต์ไทยไว้ก่อนฟอนต์ละติน */
  thaiFirst: boolean;
  issues: FontIssue[];
}

/** จัดลำดับฟอนต์ละติน/ไทยให้อักษรแต่ละสคริปต์ได้ฟอนต์ที่ผู้ใช้เลือกมากที่สุด (undefined = ไม่ใช่ไฟล์ของผู้ใช้/ยังไม่รู้ ไม่เอามาตัดสิน) */
export function planFontOrder(latin?: FontInfo, thai?: FontInfo): FontPlan {
  const issues: FontIssue[] = [];
  if (thai && !thai.coversThai) issues.push('thaiFontLacksThai');
  if (latin && !latin.coversLatin) issues.push('latinFontLacksLatin');
  if (!latin || !thai || !thai.coversThai) return { thaiFirst: false, issues };
  if (!latin.coversThai) return { thaiFirst: false, issues };
  if (!thai.coversLatin) return { thaiFirst: true, issues };
  return { thaiFirst: false, issues: [...issues, 'bothCoverBoth'] };
}
