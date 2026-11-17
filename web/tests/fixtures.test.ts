// พิสูจน์ว่า TS port ตรงกับ nsl_ui (Dart) โดยเทียบกับ fixture ที่เทสต์ฝั่ง Dart สร้าง (web/fixtures/core-fixtures.json)
// สีเทียบที่ระดับ 8 บิตต่อช่อง (ARGB32) เหมือนไฟล์ธีมจริง
import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { appearanceFromJson } from '../src/core/appearance';
import { builtinSpecs, makeLookup } from '../src/core/builtin';
import { type Color, fromARGB32, toARGB32 } from '../src/core/color';
import { checkContrast, isUnusable } from '../src/core/contrastReport';
import { autoFix, draftFromSpec } from '../src/core/draft';
import { parseNslt, serializeNslt } from '../src/core/nslt';
import { ResolveError, resolveTokens } from '../src/core/resolve';
import { kNslCoreVersion, kNsltSchema, withAppearance } from '../src/core/spec';
import { accentTints, tintFor } from '../src/core/tint';
import { kCoreColorKeys } from '../src/core/tokens';

type Json = Record<string, any>; // eslint-disable-line @typescript-eslint/no-explicit-any
const fx = JSON.parse(readFileSync(new URL('../fixtures/core-fixtures.json', import.meta.url), 'utf8')) as Json;

const userSpecs = Object.fromEntries(
  Object.entries(fx.userThemes as Record<string, string>).map(([id, text]) => {
    const r = parseNslt(text);
    if (!r.spec) throw new Error(`fixture theme ${id}: ${r.errors.join(';')}`);
    return [id, r.spec];
  }),
);
const lookup = makeLookup(userSpecs);
const specById = (id: string) => userSpecs[id] ?? builtinSpecs[id]!;
const ints = (m: Record<string, Color>) => Object.fromEntries(Object.entries(m).map(([k, c]) => [k, toARGB32(c)]));
// Dart พิมพ์ double จำนวนเต็มเป็น "5.0" ส่วน JS เป็น "5" — ปรับให้เหมือนกันก่อนเทียบข้อความเตือน
const normNum = (s: string) => s.replace(/(\d+)\.0\b/g, '$1');
const normErr = (s: string) => (s.startsWith('not valid JSON') ? 'not valid JSON' : s);

describe('เวอร์ชัน', () => {
  it('core และ schema ตรงกับ Dart', () => {
    expect(kNslCoreVersion).toBe(fx.core);
    expect(kNsltSchema).toBe(fx.schema);
  });
  it('รายชื่อสี core ตรงกับ schema และมี 30 ตัว', () => {
    expect(kCoreColorKeys.length).toBe(30);
  });
});

describe('tint: accentTints / tintFor ตรงกับ Dart ทุกบิต', () => {
  const rows = fx.tint as Json[];
  it(`${rows.length} กรณี`, () => {
    for (const r of rows) {
      const base = fromARGB32(r.base);
      const a = accentTints(base, r.dark);
      const t = tintFor(base, r.dark);
      const why = `${r.base.toString(16)} dark=${r.dark}`;
      expect([toARGB32(a[0]), toARGB32(a[1]), toARGB32(a[2])], why).toEqual([r.accent, r.soft, r.ink]);
      expect([toARGB32(t[0]), toARGB32(t[1])], why).toEqual([r.bg, r.fg]);
    }
  });
});

describe('resolveTokens ตรงกับ Dart', () => {
  const rows = fx.resolve as Json[];
  it(`${rows.length} กรณี (ธีมในตัว/ธีมผู้ใช้/ค่า lite/ธีมเสีย × 2 โหมด)`, () => {
    let ok = 0;
    let err = 0;
    for (const r of rows) {
      const why = `${r.label} ${r.spec} ${r.brightness} ${JSON.stringify(r.appearance ?? '')}`;
      const spec = r.appearance ? withAppearance(specById(r.spec), appearanceFromJson(r.appearance)) : specById(r.spec);
      if (r.error !== undefined) {
        err++;
        let msg = '';
        try {
          resolveTokens(spec, r.brightness, lookup);
        } catch (e) {
          expect(e, why).toBeInstanceOf(ResolveError);
          msg = (e as Error).message;
        }
        expect(msg, why).toBe(r.error);
        continue;
      }
      ok++;
      const t = resolveTokens(spec, r.brightness, lookup);
      const want = r.expected as Json;
      expect(ints(t.colors), why).toEqual(want.colors);
      expect(Object.fromEntries(Object.entries(t.extensions).map(([k, v]) => [k, ints(v)])), why).toEqual(want.ext);
      expect(t.shape, why).toEqual(want.shape);
      expect(t.type, why).toEqual(want.type);
      expect(t.density, why).toBe(want.density);
      expect(t.elevation, why).toEqual(want.elevation);
    }
    expect(ok).toBeGreaterThan(100);
    expect(err).toBeGreaterThanOrEqual(6);
  });
});

describe('parseNslt / serializeNslt ตรงกับ Dart', () => {
  const rows = fx.parse as Json[];
  it(`${rows.length} กรณี (ตัวอย่างเขียนมือ + สุ่มกลายพันธุ์) — ผล ok/ข้อผิดพลาด/คำเตือน/ข้อความที่เขียนกลับ`, () => {
    let okCount = 0;
    for (const r of rows) {
      const why = r.source.length > 120 ? `${r.source.slice(0, 120)}…` : r.source;
      const res = parseNslt(r.source);
      expect(res.spec !== undefined, why).toBe(r.ok);
      expect(res.errors.map(normErr), why).toEqual(r.errors);
      expect(res.warnings.map(normNum), why).toEqual((r.warnings as string[]).map(normNum));
      if (res.spec) {
        okCount++;
        expect(serializeNslt(res.spec), why).toBe(r.serialized);
      }
    }
    expect(okCount).toBeGreaterThan(40);
  });

  it('ไม่โยน exception กับข้อมูลเสียแบบใด ๆ (รวมซ้อนลึก 5,000 ชั้น)', () => {
    for (const s of ['', '[', '{"a":', 'null', '"x"', '['.repeat(5000), '{"schema":1,"id":"a","name":"a","light":' + '{"a":'.repeat(3000)]) {
      expect(() => parseNslt(s)).not.toThrow();
    }
  });
});

describe('contrast report ตรงกับ Dart', () => {
  const rows = fx.contrast as Json[];
  it(`${rows.length} ธีม/โหมด`, () => {
    for (const r of rows) {
      const t = resolveTokens(specById(r.spec), r.brightness, lookup);
      const got = checkContrast(t);
      expect(got.map((c) => c.name)).toEqual(r.checks.map((c: Json) => c.name));
      got.forEach((c, i) => {
        const w = r.checks[i] as Json;
        expect(c.ratio, `${r.spec} ${r.brightness} ${c.name}`).toBeCloseTo(w.ratio, 9);
        expect(c.passes, `${r.spec} ${r.brightness} ${c.name}`).toBe(w.passes);
      });
      expect(isUnusable(t)).toBe(r.unusable);
    }
  });
});

describe('autoFix ตรงกับ Dart', () => {
  for (const r of fx.autofix as Json[]) {
    it(r.label, () => {
      const d = draftFromSpec(parseNslt(r.source).spec!);
      const changed = autoFix(d, lookup);
      expect(changed).toBe(r.changed);
      expect(ints(d.light)).toEqual(r.light);
      expect(ints(d.dark)).toEqual(r.dark);
    });
  }
});
