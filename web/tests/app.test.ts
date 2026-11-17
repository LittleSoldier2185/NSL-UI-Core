// @vitest-environment jsdom
// ทดสอบหน้าเว็บจริง (App.vue) ใน jsdom: ผู้ใช้พิมพ์/คลิกแล้วไฟล์ที่ส่งออกเปลี่ยนตาม และไม่มีคำเตือนจาก Vue
// โครงหน้า (2026-11-17) : แถบบน · ขั้นตอนซ้าย (เริ่มต้น/สี/สีเฉพาะแอป/รูปทรง/ความหนาแน่น + ตรวจ + ไฟล์) · แผงกลาง · พรีวิวขวา
import { type VueWrapper, flushPromises, mount } from '@vue/test-utils';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import App from '../src/App.vue';
import { parseNslt } from '../src/core/nslt';
import { accentPresets } from '../src/core/presets';
import { setLang } from '../src/i18n';

let wrapper: VueWrapper;
let warn: ReturnType<typeof vi.spyOn>;
let err: ReturnType<typeof vi.spyOn>;

beforeEach(() => {
  setLang('th');
  warn = vi.spyOn(console, 'warn').mockImplementation(() => {});
  err = vi.spyOn(console, 'error').mockImplementation(() => {});
  wrapper = mount(App, { attachTo: document.body });
});

afterEach(() => {
  wrapper.unmount();
  expect(warn, 'Vue warn').not.toHaveBeenCalled();
  expect(err, 'console.error').not.toHaveBeenCalled();
  warn.mockRestore();
  err.mockRestore();
});

type Step = 'start' | 'colors' | 'ext' | 'shape' | 'style' | 'check' | 'file';
const go = async (s: Step) => {
  await wrapper.get(`nav.steps button[data-step="${s}"]`).trigger('click');
};
const current = () => wrapper.get('nav.steps [aria-current="step"]').attributes('data-step') as Step;
/** อ่านไฟล์ที่จะส่งออก (ไปขั้น "ไฟล์" แล้วกลับขั้นเดิม) */
const code = async () => {
  const back = current();
  await go('file');
  const text = wrapper.get('pre.code').text();
  await go(back);
  return text;
};
const exported = async () => parseNslt(await code()).spec!;
const downloadBtn = () => wrapper.findAll('header.top button.btn').find((b) => b.text().includes('ดาวน์โหลด'))!;
const langSelect = () => wrapper.findAll('select').find((s) => s.text().includes('English'))!;

describe('หน้าแก้ไขธีม', () => {
  it('แสดงชื่อ เวอร์ชัน core พรีวิวสว่าง/มืด และรายงาน contrast ของทั้งสองโหมด (ขั้นตรวจ)', async () => {
    expect(wrapper.text()).toContain('NSL Palette');
    expect(wrapper.get('.badge').text()).toBe('core v1.1');
    expect(wrapper.findAll('section.pv').length).toBe(2);
    expect(current()).toBe('start');
    await go('check');
    expect(wrapper.findAll('section.cp').length).toBe(2);
    expect((await exported()).extendsId).toBe('nsl.default');
  });

  it('พิมพ์ชื่อธีมที่แถบบน → รหัส/ชื่อไฟล์เปลี่ยนตาม (ทั้งในไฟล์และป้ายชื่อไฟล์)', async () => {
    await wrapper.get('input[maxlength="80"]').setValue('Ocean Blue');
    expect((await exported()).id).toBe('ocean-blue');
    expect((await exported()).name).toBe('Ocean Blue');
    expect(wrapper.get('.filechip').text()).toBe('ocean-blue.nslt');
  });

  it('ป้ายชื่อไฟล์ที่แถบบน → ไปขั้น "ไฟล์"', async () => {
    await wrapper.get('.filechip').trigger('click');
    expect(current()).toBe('file');
    expect(wrapper.find('pre.code').exists()).toBe(true);
  });

  it('คลิกสีสำเร็จรูป → accent ของทั้งสองโหมดถูกเขียนลงไฟล์, พรีวิวเปลี่ยนสี และสีนั้นถูกทำเครื่องหมาย', async () => {
    const before = wrapper.get('section.pv').attributes('style');
    expect(accentPresets[1]!.id).toBe('blue');
    await wrapper.findAll('button.sw')[1]!.trigger('click'); // ลำดับที่ 2 = น้ำเงิน
    const s = await exported();
    expect(s.light.colors.accent).toBeDefined();
    expect(s.dark.colors.accent).toBeDefined();
    expect(s.light.colors.accentTint).toBeDefined();
    expect(wrapper.get('section.pv').attributes('style')).not.toBe(before);
    expect(wrapper.findAll('button.sw')[1]!.attributes('aria-pressed')).toBe('true');
    expect(wrapper.findAll('button.sw')[0]!.attributes('aria-pressed')).toBe('false');
  });

  it('ขั้นสี : พิมพ์ hex → ส่งออกมีค่านั้น ; ปุ่มย้อนกลับ → ใช้ค่าเดิม ; hex ผิดไม่เปลี่ยนค่า ; มีชื่อที่คนอ่านเข้าใจ', async () => {
    await go('colors');
    expect(wrapper.text()).toContain('พื้นหลัง');
    const input = wrapper.get('input[aria-label="bg hex"]');
    await input.setValue('#123456');
    expect(await code()).toContain('"bg": "#123456"');
    expect(wrapper.find('button.clr').exists()).toBe(true);
    await wrapper.get('input[aria-label="bg hex"]').setValue('#12G');
    expect(wrapper.get('input[aria-label="bg hex"]').attributes('aria-invalid')).toBe('true');
    expect(await code()).toContain('"bg": "#123456"'); // ค่าล่าสุดที่ถูกต้องยังอยู่
    await wrapper.get('button.clr').trigger('click');
    expect(await code()).not.toContain('"bg"');
  });

  it('ขั้นสี : ค้นหาด้วยชื่อไทย/ชื่อ token และ "แสดงเฉพาะที่ปรับ"', async () => {
    await go('colors');
    await wrapper.get('input[type="search"]').setValue('ตัวอักษรรอง');
    expect(wrapper.findAll('input.hex').map((i) => i.attributes('aria-label'))).toEqual(['textMuted hex']);
    await wrapper.get('input[type="search"]').setValue('border');
    expect(wrapper.findAll('input.hex').length).toBe(4); // borderSoft, border, borderStrong, accentBorder
    await wrapper.get('input[type="search"]').setValue('ไม่มีสีชื่อนี้');
    expect(wrapper.text()).toContain('ไม่พบสีที่ตรงกับคำค้น');
    await wrapper.get('input[type="search"]').setValue('');
    await wrapper.get('input[aria-label="bg hex"]').setValue('#123456');
    const only = wrapper.findAll('.searchbar label.chk input')[0]!;
    await only.setValue(true);
    expect(wrapper.findAll('input.hex').map((i) => i.attributes('aria-label'))).toEqual(['bg hex']);
  });

  it('ขั้นสี : สีตัวอักษรที่อ่านยาก → แถวบอกค่าไม่ผ่าน, กลุ่มขึ้นป้ายเตือน, ขั้นตรวจบอกจำนวน, สรุปใต้พรีวิวเปลี่ยน', async () => {
    // nsl.default โหมดมืดตกเกณฑ์อยู่แล้ว 1 ข้อ (เส้นขอบ) — นับก่อน/หลังแทน
    const failsNow = () => Number(/(\d+)/.exec(wrapper.get('button.summary').text())?.[1] ?? 0);
    const before = failsNow();
    await go('colors');
    const row = () => wrapper.findAll('.row').find((r) => r.find('input[aria-label="textMuted hex"]').exists())!;
    expect(row().get('.ratio').classes()).toContain('ok');
    await wrapper.get('input[aria-label="textMuted hex"]').setValue('#EEEEEE');
    expect(row().get('.ratio').classes()).toContain('fail');
    expect(wrapper.text()).toContain('อ่านยาก');
    expect(wrapper.get('nav.steps button[data-step="check"]').text()).toContain('คู่สีอ่านยาก');
    expect(wrapper.get('button.summary').classes()).toContain('bad');
    expect(failsNow()).toBeGreaterThan(before);
    await wrapper.get('button.summary').trigger('click');
    expect(current()).toBe('check');
  });

  it('เข้าได้ทุกขั้นโดยไม่มี error และแต่ละขั้นมีเนื้อหา ; ปุ่ม "ถัดไป" พาไปขั้นต่อไป', async () => {
    expect(wrapper.findAll('.base').length).toBe(5);
    for (const s of ['colors', 'ext', 'shape', 'style'] as const) {
      await go(s);
      expect(wrapper.findAll('fieldset.grp').length, s).toBeGreaterThan(0);
    }
    await go('ext');
    expect(wrapper.text()).toContain('Lyra');
    expect(wrapper.text()).toContain('Nebular');
    expect(wrapper.text()).toContain('Spectrum');
    await go('start');
    await wrapper.get('.nextrow button').trigger('click');
    expect(current()).toBe('colors');
    await go('style');
    expect(wrapper.find('.nextrow').exists()).toBe(false); // ขั้นสุดท้ายไม่มี "ถัดไป"
  });

  it('รูปทรง/ตัวอักษร/ความหนาแน่น/เงา: ค่าที่ตั้งถูกเขียนลงไฟล์ ; ค่าเริ่มต้นไม่ถูกเขียน', async () => {
    await go('shape');
    const nums = wrapper.findAll('input[type="number"]');
    await nums[2]!.setValue('12'); // md
    expect((await exported()).radius.md).toBe(12);
    await wrapper.get('input[type="range"]').setValue('1.1');
    expect((await exported()).scale).toBeCloseTo(1.1);
    await wrapper.get('input[type="range"]').setValue('1');
    expect((await exported()).scale).toBeUndefined();
    await go('style');
    await wrapper.findAll('input[name="density"]')[0]!.setValue(true);
    expect((await exported()).density).toBe('compact');
    await wrapper.findAll('input[name="elev"]')[1]!.setValue(true);
    expect((await exported()).elevationMode).toBe('flat');
    expect(wrapper.get('nav.steps button[data-step="style"]').text()).toContain('แน่น');
  });

  it('ภาษา: สลับเป็นอังกฤษแล้วข้อความเปลี่ยน', async () => {
    await langSelect().setValue('en');
    expect(wrapper.text()).toContain('Download .nslt');
    await go('check');
    expect(wrapper.text()).toContain('Readability (contrast)');
    await langSelect().setValue('th');
    expect(wrapper.text()).toContain('ดาวน์โหลด .nslt');
  });

  it('รหัสสงวน (nsl.*) → ปุ่มดาวน์โหลดถูกปิดพร้อมจำนวนปัญหา และขั้นไฟล์มีข้อความอธิบาย', async () => {
    expect(downloadBtn().attributes('disabled')).toBeUndefined();
    await go('file');
    await wrapper.get('label.chk input[type="checkbox"]').setValue(false);
    await wrapper.get('input[maxlength="64"]').setValue('nsl.hack');
    expect(downloadBtn().attributes('disabled')).toBeDefined();
    expect(downloadBtn().get('.count').text()).toBe('1');
    expect(wrapper.get('ul.problems').text()).toContain('nsl.');
  });

  it('autoFix (ขั้นตรวจ): ปุ่มทำงานและมีข้อความแจ้งผล', async () => {
    await go('colors');
    await wrapper.get('input[aria-label="text hex"]').setValue('#CCCCCC');
    await wrapper.get('input[aria-label="surface hex"]').setValue('#FFFFFF');
    await wrapper.get('input[aria-label="bg hex"]').setValue('#FFFFFF');
    await go('check');
    expect(wrapper.find('li.fail').exists()).toBe(true);
    await wrapper.findAll('button.btn').find((b) => b.text().includes('แก้ให้ผ่านอัตโนมัติ'))!.trigger('click');
    await flushPromises();
    expect(wrapper.get('.toasts').text()).toContain('ปรับแล้ว');
  });

  it('ข้อความแจ้งขึ้นมุมบนขวาและปิดได้', async () => {
    await wrapper.findAll('button.sw')[0]!.trigger('click');
    expect(wrapper.findAll('.toast').length).toBe(1);
    await wrapper.get('.toast button.x').trigger('click');
    expect(wrapper.findAll('.toast').length).toBe(0);
  });

  it('ไม่มี v-html และข้อความที่ผู้ใช้พิมพ์ถูก escape (ชื่อธีมที่มี HTML)', async () => {
    await wrapper.get('input[maxlength="80"]').setValue('<img src=x onerror=alert(1)>');
    // รูปที่มีในหน้าต้องเป็นไอคอนแบรนด์ของเราเท่านั้น (ไม่มี img ที่มาจากข้อความที่พิมพ์)
    const imgs = wrapper.findAll('img');
    expect(imgs.length).toBeGreaterThan(0);
    expect(imgs.every((i) => (i.attributes('src') ?? '').includes('brand/') && i.attributes('onerror') === undefined && i.attributes('alt') === '')).toBe(true);
    expect((await exported()).name).toBe('<img src=x onerror=alert(1)>');
  });

  it('ธีมฐาน: การ์ดเลือกได้ (radio) และเขียนลงไฟล์', async () => {
    const orbit = wrapper.findAll('.base').find((b) => b.attributes('title') === 'nsl.orbit')!;
    await orbit.trigger('click');
    expect(orbit.attributes('aria-checked')).toBe('true');
    expect((await exported()).extendsId).toBe('nsl.orbit');
  });

  it('พรีวิว: เลือกดูโหมดเดียวได้', async () => {
    const seg = wrapper.findAll('.pbar .seg')[1]!;
    await seg.findAll('button')[0]!.trigger('click'); // สว่าง
    expect(wrapper.findAll('section.pv').length).toBe(1);
    await seg.findAll('button')[2]!.trigger('click'); // คู่กัน
    expect(wrapper.findAll('section.pv').length).toBe(2);
  });
});

describe('เลือกแอป + พรีวิวเฉพาะแอป', () => {
  const rows = () => wrapper.findAll('.approw');
  const box = (i: number) => rows()[i]!.get('input.appcheck');
  const checked = () => rows().map((r) => (r.get('input.appcheck').element as HTMLInputElement).checked);
  const tabs = () => wrapper.findAll('.ptabs button');
  const allSwitch = () => wrapper.get('input.allapps');

  it('มี 4 แอปเป็นแถว (ไอคอน ชื่อ คำอธิบาย ป้ายสถานะ ช่องติ๊ก) เริ่มต้นเลือกครบ ; ตัวสุดท้ายเอาออกไม่ได้', async () => {
    expect(rows().map((r) => r.get('b').text())).toEqual(['Nebular', 'Spectrum', 'Lyra', 'Orbit']);
    expect(checked()).toEqual([true, true, true, true]);
    expect((allSwitch().element as HTMLInputElement).checked).toBe(true);
    await box(3).setValue(false);
    await box(2).setValue(false);
    await box(1).setValue(false);
    expect(checked()).toEqual([true, false, false, false]);
    expect(box(0).attributes('disabled')).toBeDefined();
    expect((allSwitch().element as HTMLInputElement).checked).toBe(false);
  });

  it('สวิตช์ "ทุกแอป": เปิด = เลือกครบ ; ปิด = กลับไปชุดที่เลือกไว้ล่าสุด', async () => {
    await box(0).setValue(false);
    await box(1).setValue(false); // เหลือ Lyra, Orbit
    expect(checked()).toEqual([false, false, true, true]);
    await allSwitch().setValue(true);
    expect(checked()).toEqual([true, true, true, true]);
    await allSwitch().setValue(false);
    expect(checked()).toEqual([false, false, true, true]);
  });

  it('สวิตช์ "ทุกแอป" ปิดตอนยังไม่เคยเลือกเฉพาะ = เหลือแอปแรก', async () => {
    await allSwitch().setValue(false);
    expect(checked()).toEqual([true, false, false, false]);
  });

  it('เลือกแอปเดียว (Lyra) → ธีมฐานเป็นกระดาษอุ่น, พรีวิวเป็นหน้าตา Lyra, สีเฉพาะแอปเหลือของ Lyra', async () => {
    await box(0).setValue(false);
    await box(1).setValue(false);
    await box(3).setValue(false);
    expect((await exported()).extendsId).toBe('nsl.lyra.paper');
    expect(wrapper.findAll('.ap-lyra').length).toBeGreaterThan(0);
    expect(wrapper.text()).toContain('ไลรา วาเลน');
    await go('ext');
    const legends = wrapper.findAll('fieldset.grp legend').map((l) => l.text());
    expect(legends.length).toBe(1);
    expect(legends[0]).toContain('Lyra');
  });

  it('แท็บพรีวิว: ทุกแอปมีหน้าตาของตัวเอง และแท็บ "ทั่วไป" อยู่ท้ายเสมอ', async () => {
    expect(tabs().map((b) => b.text())).toEqual(['Nebular', 'Spectrum', 'Lyra', 'Orbit', 'ทั่วไป']);
    const marks: [number, string][] = [
      [0, 'users'],
      [1, 'Midnight Signal'],
      [2, 'ไลรา วาเลน'],
      [3, '฿ 482'],
      [4, 'หัวข้อตัวอย่าง'],
    ];
    for (const [i, mark] of marks) {
      await tabs()[i]!.trigger('click');
      expect(tabs()[i]!.attributes('aria-selected'), mark).toBe('true');
      expect(wrapper.findAll('section.pv').length).toBe(2);
      expect(wrapper.get('section.pv').text(), mark).toContain(mark);
    }
  });

  it('พรีวิวเฉพาะแอปเปลี่ยนสดตามสีที่แก้ (ตาราง ER ของ Nebular ใช้ส่วนขยาย nebular)', async () => {
    await tabs()[0]!.trigger('click');
    await go('colors');
    await wrapper.get('input[aria-label="bg hex"]').setValue('#123456');
    expect(wrapper.get('section.pv').attributes('style')).toContain('--c-bg: #123456');
    await go('ext');
    await wrapper.get('input[aria-label="tableHead hex"]').setValue('#AA0000');
    expect(wrapper.get('section.pv').attributes('style')).toContain('--e-nebular-tableHead: #AA0000');
  });

  it('ถ้าแอปที่ดูอยู่ถูกเอาออก แท็บจะย้ายไปแอปแรกที่เหลือ', async () => {
    await tabs()[3]!.trigger('click'); // Orbit
    await box(3).setValue(false); // เอา Orbit ออก
    expect(tabs().map((b) => b.text())).toEqual(['Nebular', 'Spectrum', 'Lyra', 'ทั่วไป']);
    expect(tabs()[0]!.attributes('aria-selected')).toBe('true');
  });

  it('ตารางความรองรับ (ขั้นสีเฉพาะแอป): แสดงทุกหมวด Orbit ✕ ทั้งคอลัมน์ และมีข้อความอ่านได้สำหรับ screen reader', async () => {
    await go('ext');
    const trs = wrapper.findAll('.matrix tbody tr');
    expect(trs.length).toBe(8);
    const orbitCol = trs.map((r) => r.findAll('td')[3]!);
    expect(orbitCol.every((c) => c.classes().includes('none'))).toBe(true);
    expect(orbitCol.every((c) => c.find('.sr').text().length > 0)).toBe(true);
    expect(wrapper.get('.matrix').text()).toContain('ไม่ได้อ่านจากแอปจริง');
  });

  it('สถานะอยู่ในแถวของแอป: Orbit "ยังไม่อ่านธีม" (คำอธิบายเต็มใน title) ; คำเตือนเวอร์ชันของ Lyra แสดงเมื่อเลือกแอปนั้นเท่านั้น', async () => {
    const orbitPill = rows()[3]!.get('.pill');
    expect(orbitPill.classes()).toContain('planned');
    expect(orbitPill.text()).toContain('ยังไม่อ่านธีม');
    expect(orbitPill.attributes('title')).toContain('ยังไม่ได้ย้าย');
    expect(rows()[0]!.get('.pill').text()).toBe('ทดลอง');
    expect(wrapper.get('.notes').text()).toContain('core 1.1');
    await box(2).setValue(false); // เอา Lyra ออก
    expect(wrapper.find('.notes').exists()).toBe(false);
  });

  it('เลือกแค่ Orbit: ขั้นสีเฉพาะแอปบอกว่ายังไม่มี แต่ติ๊ก "แสดงส่วนขยายของแอปอื่น" แล้วเห็นทั้งหมด', async () => {
    for (const i of [0, 1, 2]) await box(i).setValue(false);
    expect(wrapper.get('nav.steps button[data-step="ext"]').text()).toContain('ไม่มีสำหรับแอปที่เลือก');
    await go('ext');
    expect(wrapper.text()).toContain('Orbit ยังไม่มีค่าเฉพาะแอป');
    expect(wrapper.findAll('fieldset.grp').length).toBe(0);
    const showAll = wrapper.findAll('label.chk').find((l) => l.text().includes('แสดงส่วนขยายของแอปอื่น'))!;
    await showAll.get('input').setValue(true);
    expect(wrapper.findAll('fieldset.grp').length).toBe(3); // nebular, spectrum, lyra
    expect(wrapper.text()).not.toContain('Orbit ยังไม่มีค่าเฉพาะแอป');
  });

  it('สลับภาษาเป็นอังกฤษ: การ์ดเลือกแอปและตารางแปลครบ', async () => {
    await langSelect().setValue('en');
    expect(wrapper.text()).toContain('Which apps is it for?');
    expect(wrapper.text()).toContain('All apps');
    await go('ext');
    expect(wrapper.text()).toContain('What each app takes from a theme');
    expect(wrapper.get('.matrix').text()).toContain('Corner radius');
    await langSelect().setValue('th');
  });
});

describe('วิธีใช้ไฟล์ (ตำแหน่งที่เก็บ)', () => {
  it('บอกโฟลเดอร์ Documents\\NSL\\Themes (ไม่ใช่ APPDATA) และบอกว่า Android ไม่มี Launcher', async () => {
    await go('file');
    const how = () => wrapper.get('h3.how').element.nextElementSibling!.textContent!;
    expect(how()).toContain('Documents\\NSL\\Themes');
    expect(how()).not.toContain('APPDATA');
    expect(how()).toContain('Launcher');
    await langSelect().setValue('en');
    expect(how()).toContain('Documents\\NSL\\Themes');
    expect(how()).toContain('no Launcher on Android');
    await langSelect().setValue('th');
  });
});

describe('ไอคอนแบรนด์ (NSL Brand Pack)', () => {
  it('ทุกแอปมีไฟล์ไอคอนใน public/brand และแถวเลือกแอป/แท็บพรีวิวแสดงไอคอนของแอปนั้น', async () => {
    const { existsSync } = await import('node:fs');
    const { resolve } = await import('node:path');
    for (const id of ['nebular', 'spectrum', 'lyra', 'orbit', 'palette']) {
      expect(existsSync(resolve(__dirname, `../public/brand/${id}.svg`)), id).toBe(true);
    }
    expect(existsSync(resolve(__dirname, '../public/brand/favicon.ico'))).toBe(true);
    const icons = (sel: string) => wrapper.findAll(sel).map((i) => (i.attributes('src') ?? '').split('brand/').pop());
    expect(icons('.approw img')).toEqual(['nebular.svg', 'spectrum.svg', 'lyra.svg', 'orbit.svg']);
    expect(icons('.ptabs img')).toEqual(['nebular.svg', 'spectrum.svg', 'lyra.svg', 'orbit.svg']);
  });

  it('ไอคอนเป็นภาพประกอบ (alt ว่าง) — ชื่อแอปเป็นข้อความอยู่แล้ว ไม่อ่านซ้ำ', () => {
    expect(wrapper.findAll('img').every((i) => i.attributes('alt') === '')).toBe(true);
  });

  it('ไฟล์ SVG ไม่มีสคริปต์/ลิงก์ภายนอก', async () => {
    const { readFileSync, readdirSync } = await import('node:fs');
    const { resolve } = await import('node:path');
    const dir = resolve(__dirname, '../public/brand');
    for (const f of readdirSync(dir).filter((n) => n.endsWith('.svg'))) {
      const s = readFileSync(resolve(dir, f), 'utf8');
      expect(/<script|<foreignObject|onload=|onclick=|javascript:|href=|<image/i.test(s), f).toBe(false);
    }
  });
});

describe('ธีมของหน้าเว็บ (สว่าง/มืด/ตามระบบ)', () => {
  const btns = () => wrapper.findAll('header.top .uitheme button');
  const attr = () => document.documentElement.dataset.theme;
  // jsdom ในเครื่องนี้ไม่มี localStorage ที่ใช้ได้ — ใช้ที่เก็บในหน่วยความจำแทน
  let mem: Map<string, string>;
  let blocked = false;
  beforeEach(() => {
    mem = new Map();
    blocked = false;
    vi.stubGlobal('localStorage', {
      getItem: (k: string) => mem.get(k) ?? null,
      setItem: (k: string, v: string) => {
        if (blocked) throw new Error('blocked');
        mem.set(k, v);
      },
      removeItem: (k: string) => {
        if (blocked) throw new Error('blocked');
        mem.delete(k);
      },
    });
  });
  afterEach(() => {
    vi.unstubAllGlobals();
    delete document.documentElement.dataset.theme;
  });

  it('มี 3 ปุ่ม (ตามระบบ/สว่าง/มืด) เริ่มต้น = ตามระบบ (ไม่มี data-theme)', () => {
    expect(btns().map((b) => b.attributes('aria-label'))).toEqual(['ตามระบบ', 'สว่าง', 'มืด']);
    expect(btns()[0]!.attributes('aria-pressed')).toBe('true');
    expect(attr()).toBeUndefined();
  });

  it('กดมืด → <html data-theme="dark"> และจำไว้ ; กดสว่าง → light ; กลับตามระบบ → ลบ attribute และลบค่าที่จำ', async () => {
    await btns()[2]!.trigger('click');
    expect(attr()).toBe('dark');
    expect(btns()[2]!.attributes('aria-pressed')).toBe('true');
    expect(localStorage.getItem('nsl-palette-ui-theme')).toBe('dark');
    await btns()[1]!.trigger('click');
    expect(attr()).toBe('light');
    expect(localStorage.getItem('nsl-palette-ui-theme')).toBe('light');
    await btns()[0]!.trigger('click');
    expect(attr()).toBeUndefined();
    expect(localStorage.getItem('nsl-palette-ui-theme')).toBeNull();
  });

  it('เปลี่ยนธีมของหน้าเว็บ ไม่เปลี่ยนไฟล์ธีมที่กำลังแก้', async () => {
    const before = await code();
    await btns()[2]!.trigger('click');
    expect(await code()).toBe(before);
    await btns()[0]!.trigger('click');
  });

  it('localStorage ใช้ไม่ได้ (โหมดส่วนตัว) ก็ยังสลับได้ ไม่ล้ม', async () => {
    blocked = true;
    await btns()[2]!.trigger('click');
    expect(attr()).toBe('dark');
    blocked = false;
    await btns()[0]!.trigger('click');
  });

  it('CSS : บังคับมืดมีตัวแปรครบเท่าโหมดมืดตามระบบ และกำหนด color-scheme', async () => {
    const { readFileSync } = await import('node:fs');
    const { resolve } = await import('node:path');
    const css = readFileSync(resolve(__dirname, '../src/style.css'), 'utf8');
    const vars = (block: string) => [...block.matchAll(/(--[a-z-]+):/g)].map((m) => m[1]).sort();
    const media = /@media \(prefers-color-scheme: dark\) \{\s*:root:not\(\[data-theme='light'\]\) \{([\s\S]*?)\}/.exec(css)![1]!;
    const forced = /:root\[data-theme='dark'\] \{([\s\S]*?)\}/.exec(css)![1]!;
    expect(vars(forced)).toEqual(vars(media));
    expect(forced).toContain('color-scheme: dark');
    expect(css).toMatch(/:root\[data-theme='light'\] \{\s*color-scheme: light;/);
  });
});

describe('พรีวิวตามภาษาของหน้าเว็บ + เส้นความสัมพันธ์ของ Nebular', () => {
  const tabs = () => wrapper.findAll('.ptabs button');
  // อักษรไทย (ยกเว้น ฿ ซึ่งเป็นสกุลเงินที่ Orbit ใช้จริง)
  const thai = /[\u0E00-\u0E3E\u0E40-\u0E7F]/;

  it('ภาษาอังกฤษ: พรีวิวทุกแอป (รวม "ทั่วไป") ไม่มีอักษรไทยค้าง', async () => {
    await langSelect().setValue('en');
    for (let i = 0; i < tabs().length; i++) {
      await tabs()[i]!.trigger('click');
      for (const pv of wrapper.findAll('section.pv')) {
        const leftover = [...pv.text()].filter((ch) => thai.test(ch)).join('');
        expect(leftover, tabs()[i]!.text()).toBe('');
      }
    }
    await langSelect().setValue('th');
  });

  it('สลับภาษาแล้วข้อความในพรีวิวเปลี่ยนตาม (Nebular, Lyra, Orbit, Spectrum, ทั่วไป)', async () => {
    const marks: [number, string, string][] = [
      [0, 'ความสัมพันธ์', 'Relation'],
      [1, 'รายการเล่น', 'Playlist'],
      [2, 'ไลรา วาเลน', 'Lyra Valen'],
      [3, 'ตารางวันนี้', "Today's schedule"],
      [4, 'หัวข้อตัวอย่าง', 'Sample heading'],
    ];
    for (const [i, th, en] of marks) {
      await tabs()[i]!.trigger('click');
      expect(wrapper.get('section.pv').text(), th).toContain(th);
      await langSelect().setValue('en');
      expect(wrapper.get('section.pv').text(), en).toContain(en);
      expect(wrapper.get('section.pv').text(), en).not.toContain(th);
      await langSelect().setValue('th');
    }
  });

  it('Nebular: ปลายเส้นอยู่ที่ขอบตารางและตรงกลางแถว users.id / orders.user_id (คำนวณจากขนาดใน CSS)', async () => {
    const { readFileSync } = await import('node:fs');
    const { resolve } = await import('node:path');
    const src = readFileSync(resolve(__dirname, '../src/components/mocks/NebularMock.vue'), 'utf8');
    const px = (re: RegExp) => Number(re.exec(src)![1]);
    const head = px(/\.th \{[^}]*?height: (\d+)px/);
    const row = px(/\.tr \{[^}]*?height: (\d+)px/);
    const t1Left = px(/\.t1 \{[^}]*?left: (\d+)px/);
    const t1Top = px(/\.t1 \{[^}]*?top: (\d+)px/);
    const t2Top = px(/\.t2 \{[^}]*?top: (\d+)px/);
    const t2Right = px(/\.t2 \{[^}]*?right: (\d+)px/);
    const width = px(/\.tbl \{[^}]*?width: (\d+)px/);
    const border = 1;
    const usersId = t1Top + border + head + row / 2; // แถวแรกของ users
    const ordersFk = t2Top + border + head + row + row / 2; // แถวที่สองของ orders
    const d = /<path d="M0 ([\d.]+) C [^,]+, [^,]+, 100 ([\d.]+)"/.exec(src)!;
    expect(Number(d[1])).toBe(usersId);
    expect(Number(d[2])).toBe(ordersFk);
    // เส้นวาดเฉพาะช่องว่างระหว่างตาราง : ซ้าย = ขอบขวาของ users, ขวา = ขอบซ้ายของ orders
    expect(px(/\.links \{[^}]*?left: (\d+)px/)).toBe(t1Left + width);
    expect(px(/\.links \{[^}]*?right: (\d+)px/)).toBe(t2Right + width);
    expect(src).toContain('vector-effect="non-scaling-stroke"');
  });
});
