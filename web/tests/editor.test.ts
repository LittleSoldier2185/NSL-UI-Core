// ตรรกะของหน้าแก้ไขธีม (แยกจาก UI) — นำเข้า/ส่งออก, accent เร็ว, autoFix, ปัญหาก่อนส่งออก
import { describe, expect, it } from 'vitest';
import { builtinSpecs } from '../src/core/builtin';
import { fromARGB32, toARGB32 } from '../src/core/color';
import { contrastRatio } from '../src/core/contrast';
import { isReservedThemeId, parseNslt, serializeNslt } from '../src/core/nslt';
import { accentPresets } from '../src/core/presets';
import { newSpec } from '../src/core/spec';
import { apps, areas, allAppIds } from '../src/apps';
import { schema } from '../src/core/tokens';
import { appsFromQuery, useEditor } from '../src/editor';
import { lang, setLang } from '../src/i18n';

const text = (id: string, extra = '') => `{"schema":1,"id":"${id}","name":"${id}","extends":"nsl.nebular"${extra}}`;

describe('ค่าเริ่มต้น', () => {
  it('ธีมใหม่ resolve ได้ทั้งสองโหมดและส่งออกเป็นไฟล์ที่แอปอ่านได้', () => {
    const ed = useEditor();
    expect(ed.views.value.light.tokens).not.toBeNull();
    expect(ed.views.value.dark.tokens).not.toBeNull();
    const r = parseNslt(ed.exportText());
    expect(r.ok).toBe(true);
    expect(r.spec!.id).toBe('my-theme');
    expect(r.spec!.core).toBe('1.1');
    expect(r.spec!.extendsId).toBe('nsl.default'); // เริ่มต้น = ทุกแอป → ธีมกลาง
    expect(ed.exportProblems.value).toEqual([]);
  });

  it('ธีมที่ไม่ได้แก้อะไรไม่เขียนสีลงไฟล์ (สืบทอดล้วน)', () => {
    const ed = useEditor();
    const s = parseNslt(ed.exportText()).spec!;
    expect(Object.keys(s.light.colors)).toEqual([]);
    expect(Object.keys(s.dark.colors)).toEqual([]);
  });
});

describe('ชื่อและรหัส', () => {
  it('รหัสตามชื่ออัตโนมัติ ; ชื่อไทยล้วนได้ "theme" ; รหัสสงวน/ผิดรูปแบบถูกบล็อกส่งออก', () => {
    const ed = useEditor();
    ed.draft.name = 'Ocean Blue';
    expect(ed.effectiveId.value).toBe('ocean-blue');
    ed.draft.name = 'ทะเลสีฟ้า';
    expect(ed.effectiveId.value).toBe('theme');
    ed.idAuto.value = false;
    ed.draft.id = 'nsl.hack';
    expect(isReservedThemeId(ed.effectiveId.value)).toBe(true);
    expect(ed.exportProblems.value.length).toBe(1);
    ed.draft.id = 'Bad Id!';
    expect(ed.exportProblems.value.length).toBe(1);
    ed.draft.id = 'good-id';
    expect(ed.exportProblems.value).toEqual([]);
  });
});

describe('accent เร็ว (ชุดเดียวกับ lite ในแอป)', () => {
  it('สีเดียว → accent/accentTint/accentInk ของทั้งสองโหมดอ่านได้ และ onAccent ถูกคำนวณใหม่', () => {
    const ed = useEditor();
    for (const c of [0x7b58d6, 0xf4b860, 0x00ff00, 0xffffff, 0x000000, 0x14958b]) {
      ed.setQuickAccent(fromARGB32((0xff000000 | c) >>> 0));
      for (const m of ['light', 'dark'] as const) {
        const t = ed.views.value[m].tokens!;
        expect(contrastRatio(t.colors.accentInk!, t.colors.accentTint!), `${c.toString(16)} ${m}`).toBeGreaterThanOrEqual(4.5);
        expect('onAccent' in (m === 'light' ? ed.draft.light : ed.draft.dark)).toBe(false);
      }
    }
  });

  it('ตรงกับ preset: preset น้ำเงิน → accent ของ light = ค่า preset (ผ่านสูตร tint ไม่ใช่ค่า preset ตรง ๆ แต่ต้องใกล้เคียงและอ่านได้)', () => {
    const ed = useEditor();
    const blue = accentPresets.find((p) => p.id === 'blue')!;
    ed.setQuickAccent(blue.light[0]);
    const acc = ed.draft.light.accent!;
    expect(contrastRatio(acc, fromARGB32(0xffffffff))).toBeGreaterThanOrEqual(4.5);
  });
});

describe('autoFix และ contrast', () => {
  it('สีตัวอักษรจางเกินถูกแก้ให้ผ่าน และรายงานหลังแก้ไม่มีรายการที่ไม่ผ่านของ text', () => {
    const ed = useEditor();
    ed.setColor('light', 'bg', fromARGB32(0xffffffff));
    ed.setColor('light', 'surface', fromARGB32(0xffffffff));
    ed.setColor('light', 'text', fromARGB32(0xffcccccc));
    expect(ed.views.value.light.failures.some((f) => f.name === 'text/surface')).toBe(true);
    const n = ed.runAutoFix();
    expect(n).toBeGreaterThan(0);
    expect(ed.views.value.light.failures.some((f) => f.name.startsWith('text/'))).toBe(false);
  });

  it('ธีมที่อ่านไม่ออกจริงถูกรายงานว่า unusable', () => {
    const ed = useEditor();
    ed.setColor('light', 'bg', fromARGB32(0xffffffff));
    ed.setColor('light', 'surface', fromARGB32(0xffffffff));
    ed.setColor('light', 'text', fromARGB32(0xfff8f8f8));
    expect(ed.views.value.light.unusable).toBe(true);
  });
});

describe('นำเข้าไฟล์', () => {
  it('นำเข้าไฟล์เดียว → กลายเป็นธีมที่แก้ ; ส่งออกกลับได้ข้อความเท่าเดิม (ไป-กลับ)', () => {
    const ed = useEditor();
    const src = serializeNslt({
      ...newSpec('sea', 'Sea', { core: '1.1', extendsId: 'nsl.nebular' }),
      light: { colors: { accent: fromARGB32(0xff0369a1) }, extensions: { nebular: { tableHead: fromARGB32(0xff334455) } } },
      radius: { md: 10 },
      scale: 1.1,
    });
    ed.importFiles([{ name: 'sea.nslt', text: src }]);
    expect(ed.draft.name).toBe('Sea');
    expect(ed.effectiveId.value).toBe('sea');
    expect(ed.draft.radius.md).toBe(10);
    expect(ed.exportText()).toBe(src);
  });

  it('ไฟล์เสียถูกปฏิเสธพร้อมข้อความ ไม่เปลี่ยนธีมที่แก้อยู่ ไม่โยน', () => {
    const ed = useEditor();
    ed.draft.name = 'Keep me';
    ed.importFiles([{ name: 'bad.nslt', text: 'not json' }, { name: 'big.nslt', text: 'x'.repeat(70000) }]);
    expect(ed.draft.name).toBe('Keep me');
    expect(ed.notices.value.filter((n) => n.kind === 'error').length).toBe(2);
  });

  it('คีย์ที่ editor ไม่รู้จักถูกเก็บกลับตอนส่งออก (ไฟล์จาก core ใหม่กว่า)', () => {
    const ed = useEditor();
    ed.importFiles([{ name: 'n.nslt', text: text('n', ',"core":"1.7","futureThing":{"a":1}') }]);
    const out = ed.exportText();
    expect(out).toContain('futureThing');
    expect(parseNslt(out).spec!.unknown.futureThing).toEqual({ a: 1 });
  });

  it('หลายไฟล์: ไฟล์แรกแก้ไข ไฟล์ที่เหลือใช้เป็นธีมฐานได้ ; ธีมฐานที่หาไม่เจอถูกสลับเป็น nsl.nebular พร้อมเตือน', () => {
    const ed = useEditor();
    ed.importFiles([
      { name: 'child.nslt', text: `{"schema":1,"id":"child","name":"Child","extends":"base-theme"}` },
      { name: 'base.nslt', text: `{"schema":1,"id":"base-theme","name":"Base","extends":"nsl.default","light":{"colors":{"accent":"#aa3355"}}}` },
    ]);
    expect(ed.draft.baseId).toBe('base-theme');
    expect(ed.views.value.light.tokens).not.toBeNull();
    expect(ed.baseChoices.value.some((b) => b.id === 'base-theme')).toBe(true);

    const ed2 = useEditor();
    ed2.importFiles([{ name: 'orphan.nslt', text: `{"schema":1,"id":"orphan","name":"O","extends":"missing-base"}` }]);
    expect(ed2.draft.baseId).toBe('nsl.nebular');
    expect(ed2.notices.value.some((n) => n.kind === 'warn' && n.text.includes('missing-base'))).toBe(true);
    expect(ed2.views.value.light.tokens).not.toBeNull();
  });

  it('ไฟล์ที่ใช้ id สงวน (nsl.*) ถูกเตือนและไม่เข้าไปเป็นธีมฐานของผู้ใช้', () => {
    const ed = useEditor();
    ed.importFiles([{ name: 'x.nslt', text: `{"schema":1,"id":"nsl.fake","name":"F","extends":"nsl.default"}` }]);
    expect(ed.library['nsl.fake']).toBeUndefined();
    expect(ed.notices.value.some((n) => n.kind === 'warn')).toBe(true);
    expect(ed.exportProblems.value.length).toBeGreaterThan(0); // id สงวนส่งออกไม่ได้
  });

  it('นำเข้าสิ่งที่ไม่ใช่ธีมใด ๆ ไม่ทำให้พัง (ข้อมูลไม่น่าเชื่อถือ)', () => {
    const ed = useEditor();
    for (const s of ['', '[]', 'null', '{"schema":1}', '{"schema":99,"id":"a","name":"a"}', '{"schema":1,"id":"a","name":"a","light":{"colors":{"bg":{"x":1}}}}']) {
      expect(() => ed.importFiles([{ name: 'z', text: s }])).not.toThrow();
    }
    expect(ed.views.value.light.tokens).not.toBeNull();
  });
});

describe('อื่น ๆ', () => {
  it('resetAll ล้างทุกอย่างกลับเป็นธีมใหม่', () => {
    const ed = useEditor();
    ed.draft.name = 'X';
    ed.setColor('dark', 'bg', fromARGB32(0xff000000));
    ed.setRadius('md', 20);
    ed.resetAll();
    expect(ed.draft.name).toBe('My theme');
    expect(Object.keys(ed.draft.dark)).toEqual([]);
    expect(Object.keys(ed.draft.radius)).toEqual([]);
  });

  it('setColor(null) = กลับไปใช้ค่าสืบทอด ; ค่าที่ตั้งเองถูกเขียนลงไฟล์เรียงคีย์คงที่', () => {
    const ed = useEditor();
    ed.setColor('light', 'accent', fromARGB32(0xff112233));
    ed.setColor('light', 'bg', fromARGB32(0xffeeeeee));
    const out = ed.exportText();
    expect(out.indexOf('"accent"')).toBeLessThan(out.indexOf('"bg"')); // เรียง a→z
    ed.setColor('light', 'accent', null);
    expect(ed.exportText()).not.toContain('"accent"');
  });

  it('ส่วนขยายของแอป: ตั้ง/ล้างได้ และค่าที่ตั้งชนะค่า derive', () => {
    const ed = useEditor();
    const before = toARGB32(ed.views.value.light.tokens!.extensions.nebular!.tableHead!);
    ed.setExt('light', 'nebular', 'tableHead', fromARGB32(0xff102030));
    expect(toARGB32(ed.views.value.light.tokens!.extensions.nebular!.tableHead!)).toBe(0xff102030);
    ed.setExt('light', 'nebular', 'tableHead', null);
    expect(toARGB32(ed.views.value.light.tokens!.extensions.nebular!.tableHead!)).toBe(before);
    expect(ed.draft.extLight.nebular).toBeUndefined();
  });

  it('ธีมฐานทุกตัวในตัว resolve ได้ในหน้าแก้ไข', () => {
    const ed = useEditor();
    for (const id of Object.keys(builtinSpecs)) {
      ed.draft.baseId = id;
      expect(ed.views.value.light.tokens, id).not.toBeNull();
      expect(ed.views.value.dark.tokens, id).not.toBeNull();
    }
  });

  it('ภาษา: สลับ th/en ได้', () => {
    setLang('en');
    expect(lang.value).toBe('en');
    setLang('th');
    expect(lang.value).toBe('th');
  });
});


describe('เลือกแอปที่ธีมนี้ทำให้', () => {
  it('เริ่มต้นเลือกทุกแอป ; เอาออกได้แต่ต้องเหลืออย่างน้อยหนึ่ง', () => {
    const ed = useEditor();
    expect(ed.apps.value).toEqual(['nebular', 'spectrum', 'lyra', 'orbit']);
    ed.toggleApp('orbit');
    ed.toggleApp('lyra');
    ed.toggleApp('spectrum');
    expect(ed.apps.value).toEqual(['nebular']);
    ed.toggleApp('nebular'); // ตัวสุดท้าย เอาออกไม่ได้
    expect(ed.apps.value).toEqual(['nebular']);
    ed.toggleApp('orbit');
    expect(ed.apps.value).toEqual(['nebular', 'orbit']); // ลำดับคงที่ตามรายการแอป
  });

  it('ธีมฐานตามแอป: แอปเดียว = ธีมในตัวของแอปนั้น, หลายแอป = nsl.default', () => {
    const ed = useEditor();
    for (const id of ['spectrum', 'lyra', 'orbit'] as const) ed.toggleApp(id);
    expect(ed.draft.baseId).toBe('nsl.nebular');
    expect(ed.apps.value).toEqual(['nebular']);
    ed.toggleApp('lyra');
    expect(ed.draft.baseId).toBe('nsl.default');
    ed.toggleApp('nebular');
    expect(ed.apps.value).toEqual(['lyra']);
    expect(ed.draft.baseId).toBe('nsl.lyra.paper');
    expect(ed.views.value.light.tokens).not.toBeNull();
  });

  it('ผู้ใช้เลือกธีมฐานเองแล้ว → การสลับแอปไม่ทับอีก ; resetAll กลับค่าเริ่มต้น', () => {
    const ed = useEditor();
    ed.setBase('nsl.spectrum');
    ed.toggleApp('nebular');
    ed.toggleApp('spectrum');
    ed.toggleApp('lyra');
    expect(ed.draft.baseId).toBe('nsl.spectrum');
    ed.resetAll();
    expect(ed.apps.value.length).toBe(4);
    expect(ed.draft.baseId).toBe('nsl.default');
    ed.toggleApp('orbit');
    ed.toggleApp('spectrum');
    ed.toggleApp('lyra');
    expect(ed.draft.baseId).toBe('nsl.nebular'); // ยังตามแอปได้อีกหลังรีเซ็ต
  });

  it('นำเข้าไฟล์ = ถือว่าเลือกธีมฐานแล้ว (ไม่เปลี่ยนตามแอป)', () => {
    const ed = useEditor();
    ed.importFiles([{ name: 'a.nslt', text: text('imp') }]);
    expect(ed.draft.baseId).toBe('nsl.nebular');
    ed.toggleApp('nebular');
    ed.toggleApp('spectrum');
    ed.toggleApp('lyra');
    expect(ed.draft.baseId).toBe('nsl.nebular');
  });

  it('ส่วนขยายที่แสดงกรองตามแอป: orbit ไม่มี ; showAllExt แสดงทั้งหมด', () => {
    const ed = useEditor();
    expect(ed.visibleExtensions.value.map((e) => e.name)).toEqual(['nebular', 'spectrum', 'lyra']);
    for (const id of ['nebular', 'spectrum', 'lyra'] as const) ed.toggleApp(id);
    expect(ed.apps.value).toEqual(['orbit']);
    expect(ed.visibleExtensions.value).toEqual([]);
    ed.showAllExt.value = true;
    expect(ed.visibleExtensions.value.length).toBe(schema.extensions.length);
    ed.showAllExt.value = false;
    ed.toggleApp('lyra');
    ed.toggleApp('orbit');
    expect(ed.visibleExtensions.value.map((e) => e.name)).toEqual(['lyra']);
  });

  it('คำเตือนเวอร์ชัน: ส่วนขยายที่เริ่มหลัง core 1.0 (lyra 1.1) เตือนเมื่อเลือกแอปนั้น', () => {
    const ed = useEditor();
    expect(ed.versionNotes.value.map((e) => [e.name, e.since])).toEqual([['lyra', '1.1']]);
    ed.toggleApp('lyra');
    expect(ed.versionNotes.value).toEqual([]);
    ed.toggleApp('lyra');
    expect(ed.versionNotes.value.length).toBe(1);
  });

  it('ตารางความรองรับ: ครบทุกแอปและทุกหมวด, ชื่อส่วนขยายมีอยู่ใน schema จริง, Orbit ยังไม่รองรับอะไรเลย', () => {
    expect(apps.map((a) => a.id)).toEqual([...allAppIds]);
    expect(new Set(apps.map((a) => a.id)).size).toBe(apps.length);
    const names = new Set(schema.extensions.map((e) => e.name));
    for (const a of apps) {
      expect(Object.keys(a.support).sort()).toEqual([...areas].sort());
      if (a.extension) expect(names.has(a.extension), a.id).toBe(true);
      else expect(a.support.ext).toBe('none');
    }
    const orbit = apps.find((a) => a.id === 'orbit')!;
    expect(orbit.status).toBe('planned');
    expect(Object.values(orbit.support).every((v) => v === 'none')).toBe(true);
    // ส่วนขยายทุกตัวใน schema ต้องมีแอปเจ้าของ (ไม่งั้นจะไม่มีทางโผล่ในหน้าแก้ไข)
    for (const n of names) expect(apps.some((a) => a.extension === n), n).toBe(true);
  });
});


describe('ลิงก์เลือกแอป (?apps=)', () => {
  it('อ่านรายชื่อแอปจาก query อย่างปลอดภัย: ไม่รู้จัก/ว่าง/ซ้ำ/ตัวพิมพ์ใหญ่', () => {
    expect(appsFromQuery('')).toEqual([...allAppIds]);
    expect(appsFromQuery('?apps=')).toEqual([...allAppIds]);
    expect(appsFromQuery('?apps=lyra')).toEqual(['lyra']);
    expect(appsFromQuery('?apps=ORBIT,Nebular,nebular')).toEqual(['nebular', 'orbit']);
    expect(appsFromQuery('?apps=nope,<script>')).toEqual([...allAppIds]);
    expect(appsFromQuery('?apps=lyra,nope')).toEqual(['lyra']);
    expect(appsFromQuery('?other=1')).toEqual([...allAppIds]);
  });
});
