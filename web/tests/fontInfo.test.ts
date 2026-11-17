// ตัวตรวจไฟล์ฟอนต์ (พอร์ตจาก Dart) — ผลต้องตรงกับ test/fonts_test.dart และ test/font_real_files_test.dart
import { existsSync, readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { type FontInfo, inspectFontBytes, isReservedFamily, kMaxFontBytes, planFontOrder } from '../src/core/fontInfo';

type Range = [number, number];

/** ฟอนต์จำลองขั้นต่ำ (เหมือน fakeFont ฝั่ง Dart) : cmap format 12 หรือ 4 + name */
function fakeFont(ranges: Range[], name = 'Fake Sans', format4 = false): Uint8Array {
  const out: number[] = [];
  const u16 = (b: number[], v: number) => b.push((v >> 8) & 255, v & 255);
  const u32 = (b: number[], v: number) => b.push((v >>> 24) & 255, (v >> 16) & 255, (v >> 8) & 255, v & 255);
  const cmap: number[] = [];
  u16(cmap, 0);
  u16(cmap, 1);
  u16(cmap, 3);
  u16(cmap, format4 ? 1 : 10);
  u32(cmap, 12);
  if (format4) {
    const segs: Range[] = [...ranges, [0xffff, 0xffff]];
    const n = segs.length;
    u16(cmap, 4);
    u16(cmap, 16 + n * 8);
    u16(cmap, 0);
    u16(cmap, n * 2);
    u16(cmap, 0);
    u16(cmap, 0);
    u16(cmap, 0);
    for (const s of segs) u16(cmap, s[1]);
    u16(cmap, 0);
    for (const s of segs) u16(cmap, s[0]);
    for (let i = 0; i < n; i++) u16(cmap, 1);
    for (let i = 0; i < n; i++) u16(cmap, 0);
  } else {
    u16(cmap, 12);
    u16(cmap, 0);
    u32(cmap, 16 + ranges.length * 12);
    u32(cmap, 0);
    u32(cmap, ranges.length);
    let g = 1;
    for (const r of ranges) {
      u32(cmap, r[0]);
      u32(cmap, r[1]);
      u32(cmap, g);
      g += r[1] - r[0] + 1;
    }
  }
  const nm: number[] = [];
  const utf16: number[] = [];
  for (const c of name) utf16.push(c.charCodeAt(0) >> 8, c.charCodeAt(0) & 255);
  u16(nm, 0);
  u16(nm, 1);
  u16(nm, 18);
  u16(nm, 3);
  u16(nm, 1);
  u16(nm, 0x409);
  u16(nm, 1);
  u16(nm, utf16.length);
  u16(nm, 0);
  nm.push(...utf16);
  const tables: [number, number[]][] = [
    [0x636d6170, cmap],
    [0x6e616d65, nm],
  ];
  u32(out, 0x00010000);
  u16(out, tables.length);
  u16(out, 0);
  u16(out, 0);
  u16(out, 0);
  let off = 12 + tables.length * 16;
  for (const [t, b] of tables) {
    u32(out, t);
    u32(out, 0);
    u32(out, off);
    u32(out, b.length);
    off += b.length;
  }
  for (const [, b] of tables) out.push(...b);
  return Uint8Array.from(out);
}

const LATIN: Range[] = [[0x20, 0x7e]];
const THAI: Range[] = [[0x0e01, 0x0e5b]];
const info = (b: Uint8Array): FontInfo => {
  const r = inspectFontBytes(b);
  if (!r.ok) throw new Error(r.error);
  return r.info;
};

describe('inspectFontBytes (พอร์ตจาก Dart)', () => {
  it('ฟอนต์ละตินอย่างเดียว (format 12)', () => {
    const i = info(fakeFont(LATIN, 'My Latin'));
    expect([i.coversLatin, i.coversThai, i.familyName]).toEqual([true, false, 'My Latin']);
  });
  it('ไทย + ละติน (format 12 และ 4)', () => {
    expect(info(fakeFont([...LATIN, ...THAI])).coversThai).toBe(true);
    const a = info(fakeFont(LATIN, 'F4', true));
    expect([a.coversLatin, a.coversThai]).toEqual([true, false]);
    expect(info(fakeFont([...LATIN, ...THAI], 'F4', true)).coversThai).toBe(true);
  });
  it('ไทยไม่กี่ตัวไม่นับว่ามีไทย', () => {
    expect(info(fakeFont([...LATIN, [0x0e01, 0x0e05]])).coversThai).toBe(false);
  });
  it('ชื่อ family ตัดอักขระควบคุมและตัวคั่น path', () => {
    expect(info(fakeFont(LATIN, 'A/B:C\D')).familyName).toBe('ABCD');
  });
  it('ปฏิเสธไฟล์ที่ใช้ไม่ได้', () => {
    expect(inspectFontBytes(new Uint8Array(0)).ok).toBe(false);
    expect(inspectFontBytes(new Uint8Array(100).fill(65)).ok).toBe(false);
    const withTag = (t: number) => {
      const b = fakeFont(LATIN);
      new DataView(b.buffer).setUint32(0, t);
      return inspectFontBytes(b);
    };
    expect((withTag(0x74746366) as { error: string }).error).toContain('.ttc');
    expect((withTag(0x774f4646) as { error: string }).error).toContain('WOFF');
    const b = fakeFont(LATIN);
    new DataView(b.buffer).setUint32(12 + 12, 0x7fffffff);
    expect(inspectFontBytes(b).ok).toBe(false);
    expect(inspectFontBytes(fakeFont(LATIN).slice(0, 20)).ok).toBe(false);
    expect((inspectFontBytes(new Uint8Array(kMaxFontBytes + 1)) as { error: string }).error).toContain('too large');
  });
  it('fuzz : ไฟล์ที่ถูกกลายพันธุ์ไม่โยน exception', () => {
    let seed = 7;
    const rnd = (n: number) => {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return seed % n;
    };
    const seeds = [fakeFont([...LATIN, ...THAI]), fakeFont([...LATIN, ...THAI], 'F4', true)];
    for (let i = 0; i < 4000; i++) {
      const b = Uint8Array.from(seeds[i % 2]!);
      for (let k = 0; k < 1 + rnd(6); k++) b[rnd(b.length)] = rnd(256);
      inspectFontBytes(rnd(4) === 0 ? b.slice(0, rnd(b.length)) : b);
    }
  });
});

describe('ฟอนต์จริง (ผลต้องเท่า Dart)', () => {
  const cases: [string, boolean, boolean][] = [
    ['../assets/fonts/NotoSansThai-Regular.ttf', true, true],
    ['C:/Windows/Fonts/LeelawUI.ttf', true, true],
    ['C:/Windows/Fonts/arial.ttf', false, true],
    ['C:/Windows/Fonts/consola.ttf', false, true],
  ];
  for (const [p, thai, latin] of cases) {
    it(p, () => {
      if (!existsSync(p)) return; // ไม่มีบนเครื่องนี้
      const i = info(new Uint8Array(readFileSync(p)));
      expect([i.coversThai, i.coversLatin]).toEqual([thai, latin]);
      expect(i.familyName).toBeTruthy();
    });
  }
  it('Noto Sans Thai ของ nsl_ui อยู่ในรายการสงวน', () => {
    expect(isReservedFamily('Noto Sans Thai')).toBe(true);
    expect(isReservedFamily('tahoma')).toBe(true);
    expect(isReservedFamily('Sarabun')).toBe(false);
  });
});

describe('planFontOrder', () => {
  const latinOnly: FontInfo = { coversThai: false, coversLatin: true };
  const thaiOnly: FontInfo = { coversThai: true, coversLatin: false };
  const both: FontInfo = { coversThai: true, coversLatin: true };
  it('ละติน(ไม่มีไทย) + ไทย : ตามที่เลือก ไม่มีปัญหา', () => {
    expect(planFontOrder(latinOnly, thaiOnly)).toEqual({ thaiFirst: false, issues: [] });
  });
  it('ละติน(มีไทยด้วย) + ไทย(ไม่มีละติน) : ไทยก่อน', () => {
    expect(planFontOrder(both, thaiOnly)).toEqual({ thaiFirst: true, issues: [] });
  });
  it('ทั้งคู่ครอบคลุมทั้งสอง : บังคับไม่ได้ แจ้งผู้ใช้', () => {
    expect(planFontOrder(both, both)).toEqual({ thaiFirst: false, issues: ['bothCoverBoth'] });
  });
  it('ช่องไทยที่ไม่มีไทย / ช่องละตินที่ไม่มีละติน', () => {
    expect(planFontOrder(latinOnly, latinOnly).issues).toContain('thaiFontLacksThai');
    expect(planFontOrder(thaiOnly, thaiOnly).issues).toContain('latinFontLacksLatin');
  });
  it('ไม่รู้จักฟอนต์ (undefined) ไม่ตัดสิน', () => {
    expect(planFontOrder()).toEqual({ thaiFirst: false, issues: [] });
    expect(planFontOrder(both).thaiFirst).toBe(false);
  });
});
