// ฟอนต์สองสคริปต์ (ละติน + ไทย) — ต้องตรงกับฝั่ง Dart : อ่าน/เขียน/สืบทอด/draft ไม่ทำค่าหาย
import { describe, expect, it } from 'vitest';
import { parseNslt, serializeNslt } from '../src/core/nslt';
import { resolveTokens } from '../src/core/resolve';
import { draftFromSpec, draftToSpec } from '../src/core/draft';
import { builtinById } from '../src/core/builtin';

const theme = (type: string) => `{"schema":1,"id":"t","name":"t","extends":"nsl.nebular","type":${type}}`;

describe('ฟอนต์อักษรไทยแยกช่อง', () => {
  it('อ่านแล้วเขียนกลับได้ครบ', () => {
    const r = parseNslt(theme('{"family":"Inter","familyThai":"Sarabun","contentThai":"Mali","monoThai":"Noto Sans Mono"}'));
    const s = r.spec!;
    expect([s.family, s.familyThai, s.contentThai, s.monoThai]).toEqual(['Inter', 'Sarabun', 'Mali', 'Noto Sans Mono']);
    const again = parseNslt(serializeNslt(s)).spec!;
    expect([again.familyThai, again.contentThai, again.monoThai]).toEqual(['Sarabun', 'Mali', 'Noto Sans Mono']);
  });

  it('ธีมที่ไม่มีคีย์ไทยไม่เขียนคีย์ไทยออกมา', () => {
    const s = parseNslt(theme('{"family":"Inter"}')).spec!;
    expect(serializeNslt(s)).not.toContain('Thai');
  });

  it('ชื่อฟอนต์ไทยที่ผิดถูกทิ้งพร้อมคำเตือน', () => {
    const r = parseNslt(theme('{"familyThai":"../evil","contentThai":"","monoThai":5}'));
    const s = r.spec!;
    expect([s.familyThai, s.contentThai, s.monoThai]).toEqual([undefined, undefined, undefined]);
    expect(r.warnings.filter((w) => w.includes('Thai')).length).toBe(3);
  });

  it('ธีมลูกสืบทอดและทับช่องไทยได้', () => {
    const base = parseNslt('{"schema":1,"id":"base","name":"b","extends":"nsl.nebular","type":{"familyThai":"Sarabun","contentThai":"Mali"}}').spec!;
    const child = parseNslt('{"schema":1,"id":"child","name":"c","extends":"base","type":{"familyThai":"Prompt"}}').spec!;
    const lookup = (id: string) => (id === 'base' ? base : builtinById(id));
    const t = resolveTokens(child, 'light', lookup).type;
    expect(t.familyThai).toBe('Prompt');
    expect(t.contentThai).toBe('Mali');
  });

  it('draft ไป-กลับไม่ทำช่องไทยหาย', () => {
    const s = parseNslt(theme('{"familyThai":"Sarabun","monoThai":"Mali"}')).spec!;
    const back = draftToSpec(draftFromSpec(s));
    expect([back.familyThai, back.monoThai]).toEqual(['Sarabun', 'Mali']);
  });
});

describe('คีย์ที่ไม่รู้จักใน type (ตรงกับ Dart)', () => {
  it('ถูกเก็บและเขียนกลับ ไม่หายเมื่อบันทึกทับ', async () => {
    const { parseNslt, serializeNslt } = await import('../src/core/nslt');
    const r = parseNslt('{"schema":1,"core":"9.9","id":"f","name":"F","extends":"nsl.nebular","type":{"familyThai":"Sarabun","futureKey":{"a":[1,2]}}}');
    const out = serializeNslt(r.spec!);
    expect(out).toContain('futureKey');
    expect(out).toContain('Sarabun');
  });
});
