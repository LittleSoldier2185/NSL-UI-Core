// คีย์ระดับบน apps : จัดหมวดธีมตามแอป — นำเข้าแล้วเลือกแอปให้อัตโนมัติ, ส่งออกเขียนกลับ, ไป-กลับ, id ที่ไม่รู้จัก, ผิดรูปแบบ
import { describe, expect, it } from 'vitest';
import { allAppIds, appsOfSpec } from '../src/apps';
import { builtinSpecs } from '../src/core/builtin';
import { parseNslt, serializeNslt } from '../src/core/nslt';
import { newSpec } from '../src/core/spec';
import { useEditor } from '../src/editor';

const theme = (extra: string) => `{"schema":1,"id":"t","name":"T","extends":"nsl.default"${extra}}`;

describe('apps ใน parser/serializer', () => {
  it('อ่านแบบไม่ซ้ำ เรียงตามที่เขียน และเขียนกลับครบ', () => {
    const r = parseNslt(theme(',"apps":["orbit","lyra","orbit"]'));
    expect(r.spec?.apps).toEqual(['orbit', 'lyra']);
    expect(r.warnings).toEqual([]);
    expect(JSON.parse(serializeNslt(r.spec!)).apps).toEqual(['orbit', 'lyra']);
  });

  it('ไม่มี/ว่าง = ไม่เขียนคีย์', () => {
    expect(parseNslt(theme('')).spec?.apps).toBeUndefined();
    expect('apps' in JSON.parse(serializeNslt(parseNslt(theme(',"apps":[]')).spec!))).toBe(false);
  });

  for (const bad of ['"orbit"', '[1,2]', '["Bad Id"]', '{"a":1}', `[${Array.from({ length: 17 }, (_, i) => `"a${i}"`).join(',')}]`]) {
    it(`ผิดรูปแบบ ${bad.slice(0, 24)} : เตือน ไม่ล้ม และเก็บค่าดิบกลับ`, () => {
      const r = parseNslt(theme(`,"apps":${bad}`));
      expect(r.ok).toBe(true);
      expect(r.spec?.apps).toBeUndefined();
      expect(r.warnings.some((w) => w.includes('apps'))).toBe(true);
      expect(JSON.parse(serializeNslt(r.spec!)).apps).toEqual(JSON.parse(bad));
    });
  }

  it('ธีมในตัวระบุแอปของตัวเอง', () => {
    expect(builtinSpecs['nsl.orbit']?.apps).toEqual(['orbit']);
    expect(builtinSpecs['nsl.lyra.paper']?.apps).toEqual(['lyra']);
    expect(builtinSpecs['nsl.default']?.apps).toBeUndefined();
  });
});

describe('appsOfSpec (จัดหมวดตอนนำเข้า)', () => {
  const base = newSpec('x', 'X');
  it('ใช้ apps ที่ระบุก่อน', () => {
    expect(appsOfSpec({ ...base, apps: ['lyra', 'orbit'] })).toEqual({ apps: ['lyra', 'orbit'], inferred: false });
  });
  it('ไม่ระบุ → เดาจากส่วนขยายที่มีค่าอยู่', () => {
    const s = { ...base, light: { colors: {}, extensions: { lyra: {} } }, dark: { colors: {}, extensions: { spectrum: {} } } };
    expect(appsOfSpec(s)).toEqual({ apps: ['spectrum', 'lyra'], inferred: true });
  });
  it('ไม่พบเลย = ทุกแอป', () => {
    expect(appsOfSpec(base)).toEqual({ apps: [...allAppIds], inferred: false });
  });
  it('ระบุแต่ id ที่ไม่รู้จัก = ไม่ทราบแอป → ทุกแอป', () => {
    expect(appsOfSpec({ ...base, apps: ['futureapp'] }).apps).toEqual([...allAppIds]);
  });
});

describe('ตัวแก้ไข : นำเข้า/ส่งออก apps', () => {
  it('นำเข้าไฟล์ที่ระบุ apps → เลือกแอปให้อัตโนมัติ และส่งออกเขียนกลับเท่าเดิม', () => {
    const ed = useEditor();
    const src = serializeNslt({ ...parseNslt(theme(',"apps":["orbit"]')).spec!, core: '1.1' });
    ed.importFiles([{ name: 't.nslt', text: src }]);
    expect(ed.apps.value).toEqual(['orbit']);
    expect(ed.exportText()).toBe(src);
  });

  it('ไม่ระบุ apps แต่มีส่วนขยาย → เดาแอปจากส่วนขยาย แจ้งผู้ใช้ และส่งออกไม่เติมเอง (ไป-กลับเท่าเดิม)', () => {
    const ed = useEditor();
    const src = theme(',"light":{"extensions":{"lyra":{"body":"#112233"}}}');
    ed.importFiles([{ name: 't.nslt', text: src }]);
    expect(ed.apps.value).toEqual(['lyra']);
    expect(ed.notices.value.some((n) => n.kind === 'info')).toBe(true);
    expect('apps' in JSON.parse(ed.exportText())).toBe(false);
  });

  it('ผู้ใช้ปรับการเลือกแอปหลังเดา → ส่งออกเขียน apps ตามที่เลือก', () => {
    const ed = useEditor();
    ed.importFiles([{ name: 't.nslt', text: theme(',"light":{"extensions":{"lyra":{"body":"#112233"}}}') }]);
    ed.toggleApp('orbit');
    expect(JSON.parse(ed.exportText()).apps).toEqual(['lyra', 'orbit']);
  });

  it('ธีมใหม่ เลือกแอปเดียว → ส่งออกมี apps ; เลือกครบทุกแอป = ไม่เขียน', () => {
    const ed = useEditor();
    expect('apps' in JSON.parse(ed.exportText())).toBe(false);
    for (const id of ['nebular', 'spectrum', 'lyra'] as const) ed.toggleApp(id);
    expect(JSON.parse(ed.exportText()).apps).toEqual(['orbit']);
  });

  it('id แอปที่ไม่รู้จักในไฟล์ ถูกเก็บกลับตอนส่งออก', () => {
    const ed = useEditor();
    ed.importFiles([{ name: 't.nslt', text: theme(',"apps":["orbit","futureapp"]') }]);
    expect(ed.apps.value).toEqual(['orbit']);
    expect(JSON.parse(ed.exportText()).apps).toEqual(['orbit', 'futureapp']);
  });
});
