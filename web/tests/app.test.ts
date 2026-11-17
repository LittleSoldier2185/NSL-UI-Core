// @vitest-environment jsdom
// ทดสอบหน้าเว็บจริง (App.vue) ใน jsdom: ผู้ใช้พิมพ์/คลิกแล้วไฟล์ที่ส่งออกเปลี่ยนตาม และไม่มีคำเตือนจาก Vue
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

const code = () => wrapper.get('pre.code').text();
const exported = () => parseNslt(code()).spec!;
const clickTab = async (i: number) => {
  await wrapper.findAll('[role="tab"]')[i]!.trigger('click');
};

describe('หน้าแก้ไขธีม', () => {
  it('แสดงชื่อ เวอร์ชัน core พรีวิวสว่าง/มืด และรายงาน contrast ของทั้งสองโหมด', () => {
    expect(wrapper.text()).toContain('NSL Palette');
    expect(wrapper.get('.badge').text()).toBe('core v1.1');
    expect(wrapper.findAll('section.pv').length).toBe(2);
    expect(wrapper.findAll('section.cp').length).toBe(2);
    expect(exported().extendsId).toBe('nsl.default');
  });

  it('พิมพ์ชื่อธีม → รหัส/ชื่อไฟล์ในไฟล์ส่งออกเปลี่ยนตาม', async () => {
    await wrapper.get('input[maxlength="80"]').setValue('Ocean Blue');
    expect(exported().id).toBe('ocean-blue');
    expect(exported().name).toBe('Ocean Blue');
  });

  it('คลิกสี preset → accent ของทั้งสองโหมดถูกเขียนลงไฟล์ และพรีวิวเปลี่ยนสี', async () => {
    const before = wrapper.get('section.pv').attributes('style');
    expect(accentPresets[1]!.id).toBe('blue');
    await wrapper.findAll('button.sw')[1]!.trigger('click'); // ลำดับที่ 2 = น้ำเงิน
    const s = exported();
    expect(s.light.colors.accent).toBeDefined();
    expect(s.dark.colors.accent).toBeDefined();
    expect(s.light.colors.accentTint).toBeDefined();
    expect(wrapper.get('section.pv').attributes('style')).not.toBe(before);
  });

  it('แก้สีในแท็บสี: พิมพ์ hex → ส่งออกมีค่านั้น ; ปุ่มย้อนกลับ → ใช้ค่าเดิม ; hex ผิดไม่เปลี่ยนค่า', async () => {
    const input = wrapper.get('input[aria-label="bg hex"]');
    await input.setValue('#123456');
    expect(code()).toContain('"bg": "#123456"');
    expect(wrapper.find('button.clr').exists()).toBe(true);
    await input.setValue('#12G');
    expect(input.attributes('aria-invalid')).toBe('true');
    expect(code()).toContain('"bg": "#123456"'); // ค่าล่าสุดที่ถูกต้องยังอยู่
    await wrapper.get('button.clr').trigger('click');
    expect(code()).not.toContain('"bg"');
  });

  it('สลับแท็บทั้งสี่ได้โดยไม่มี error และแต่ละแท็บมีเนื้อหา', async () => {
    for (let i = 0; i < 4; i++) {
      await clickTab(i);
      expect(wrapper.findAll('fieldset.grp').length).toBeGreaterThan(0);
    }
    await clickTab(1);
    expect(wrapper.text()).toContain('Lyra');
    expect(wrapper.text()).toContain('Nebular');
    expect(wrapper.text()).toContain('Spectrum');
  });

  it('รูปทรง/ตัวอักษร/ความหนาแน่น/เงา: ค่าที่ตั้งถูกเขียนลงไฟล์ ; ค่าเริ่มต้นไม่ถูกเขียน', async () => {
    await clickTab(2);
    const nums = wrapper.findAll('input[type="number"]');
    await nums[2]!.setValue('12'); // md
    expect(exported().radius.md).toBe(12);
    await wrapper.get('input[type="range"]').setValue('1.1');
    expect(exported().scale).toBeCloseTo(1.1);
    await wrapper.get('input[type="range"]').setValue('1');
    expect(exported().scale).toBeUndefined();
    await clickTab(3);
    await wrapper.findAll('input[name="density"]')[0]!.setValue(true);
    expect(exported().density).toBe('compact');
    await wrapper.findAll('input[name="elev"]')[1]!.setValue(true);
    expect(exported().elevationMode).toBe('flat');
  });

  it('ภาษา: สลับเป็นอังกฤษแล้วข้อความเปลี่ยน', async () => {
    const select = wrapper.findAll('select').find((s) => s.text().includes('English'))!;
    await select.setValue('en');
    expect(wrapper.text()).toContain('Download .nslt');
    expect(wrapper.text()).toContain('Readability (contrast)');
    await select.setValue('th');
    expect(wrapper.text()).toContain('ดาวน์โหลด .nslt');
  });

  it('รหัสสงวน (nsl.*) → ปุ่มดาวน์โหลดและคัดลอกถูกปิด และมีข้อความอธิบาย', async () => {
    const dl = wrapper.findAll('button.btn').find((b) => b.text().includes('ดาวน์โหลด'))!;
    expect(dl.attributes('disabled')).toBeUndefined();
    await wrapper.get('label.chk input[type="checkbox"]').setValue(false);
    await wrapper.get('input[maxlength="64"]').setValue('nsl.hack');
    expect(dl.attributes('disabled')).toBeDefined();
    expect(wrapper.get('ul.problems').text()).toContain('nsl.');
  });

  it('autoFix: ปุ่มทำงานและมีข้อความแจ้งผล', async () => {
    await wrapper.get('input[aria-label="text hex"]').setValue('#CCCCCC');
    await wrapper.get('input[aria-label="surface hex"]').setValue('#FFFFFF');
    await wrapper.get('input[aria-label="bg hex"]').setValue('#FFFFFF');
    expect(wrapper.find('li.fail').exists()).toBe(true);
    await wrapper.findAll('button.btn').find((b) => b.text().includes('แก้ให้ผ่านอัตโนมัติ'))!.trigger('click');
    await flushPromises();
    expect(wrapper.text()).toContain('ปรับแล้ว');
  });

  it('ไม่มี v-html และข้อความที่ผู้ใช้พิมพ์ถูก escape (ชื่อธีมที่มี HTML)', async () => {
    await wrapper.get('input[maxlength="80"]').setValue('<img src=x onerror=alert(1)>');
    expect(wrapper.find('img').exists()).toBe(false);
    expect(exported().name).toBe('<img src=x onerror=alert(1)>');
  });
});


describe('เลือกแอป + พรีวิวเฉพาะแอป', () => {
  const chips = () => wrapper.findAll('button.appchip');
  const tabs = () => wrapper.findAll('.ptabs button');

  it('มี 4 แอปให้เลือก เริ่มต้นเลือกครบ ; ตัวสุดท้ายเอาออกไม่ได้', async () => {
    expect(chips().map((c) => c.find('strong').text())).toEqual(['Nebular', 'Spectrum', 'Lyra', 'Orbit']);
    expect(chips().every((c) => c.attributes('aria-pressed') === 'true')).toBe(true);
    await chips()[3]!.trigger('click');
    await chips()[2]!.trigger('click');
    await chips()[1]!.trigger('click');
    expect(chips().map((c) => c.attributes('aria-pressed'))).toEqual(['true', 'false', 'false', 'false']);
    await chips()[0]!.trigger('click');
    expect(chips()[0]!.attributes('aria-pressed')).toBe('true');
  });

  it('เลือกแอปเดียว (Lyra) → ธีมฐานเป็นกระดาษอุ่น, พรีวิวเป็นหน้าตา Lyra, ส่วนขยายเหลือของ Lyra', async () => {
    await chips()[0]!.trigger('click');
    await chips()[1]!.trigger('click');
    await chips()[3]!.trigger('click');
    expect(exported().extendsId).toBe('nsl.lyra.paper');
    expect(wrapper.findAll('.ap-lyra').length).toBeGreaterThan(0);
    expect(wrapper.text()).toContain('ไลรา วาเลน');
    await clickTab(1);
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
      [4, 'Sample heading'],
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
    await wrapper.get('input[aria-label="bg hex"]').setValue('#123456');
    expect(wrapper.get('section.pv').attributes('style')).toContain('--c-bg: #123456');
    await clickTab(1);
    await wrapper.get('input[aria-label="tableHead hex"]').setValue('#AA0000');
    expect(wrapper.get('section.pv').attributes('style')).toContain('--e-nebular-tableHead: #AA0000');
  });

  it('ถ้าแอปที่ดูอยู่ถูกเอาออก แท็บจะย้ายไปแอปแรกที่เหลือ', async () => {
    await tabs()[3]!.trigger('click'); // Orbit
    await chips()[3]!.trigger('click'); // เอา Orbit ออก
    expect(tabs().map((b) => b.text())).toEqual(['Nebular', 'Spectrum', 'Lyra', 'ทั่วไป']);
    expect(tabs()[0]!.attributes('aria-selected')).toBe('true');
  });

  it('ตารางความรองรับ: แสดงทุกหมวด Orbit ✕ ทั้งคอลัมน์ และมีข้อความอ่านได้สำหรับ screen reader', () => {
    const rows = wrapper.findAll('.matrix tbody tr');
    expect(rows.length).toBe(8);
    const orbitCol = rows.map((r) => r.findAll('td')[3]!);
    expect(orbitCol.every((c) => c.classes().includes('none'))).toBe(true);
    expect(orbitCol.every((c) => c.find('.sr').text().length > 0)).toBe(true);
    expect(wrapper.get('.matrix').text()).toContain('ไม่ได้อ่านจากแอปจริง');
  });

  it('สถานะ: Orbit เตือนว่ายังไม่ได้ย้าย ; คำเตือนเวอร์ชันของ Lyra แสดงเมื่อเลือกแอปนั้นเท่านั้น', async () => {
    expect(wrapper.get('.statuses li.planned').text()).toContain('ยังไม่ได้ย้าย');
    expect(wrapper.get('.notes').text()).toContain('core 1.1');
    await chips()[2]!.trigger('click'); // เอา Lyra ออก
    expect(wrapper.find('.notes').exists()).toBe(false);
  });

  it('เลือกแค่ Orbit: แท็บส่วนขยายบอกว่ายังไม่มี แต่ติ๊ก "แสดงส่วนขยายของแอปอื่น" แล้วเห็นทั้งหมด', async () => {
    for (const i of [0, 1, 2]) await chips()[i]!.trigger('click');
    await clickTab(1);
    expect(wrapper.text()).toContain('Orbit ยังไม่มีค่าเฉพาะแอป');
    expect(wrapper.findAll('fieldset.grp').length).toBe(0);
    const showAll = wrapper.findAll('label.chk').find((l) => l.text().includes('แสดงส่วนขยายของแอปอื่น'))!;
    await showAll.get('input').setValue(true);
    expect(wrapper.findAll('fieldset.grp').length).toBe(3); // nebular, spectrum, lyra
    expect(wrapper.text()).not.toContain('Orbit ยังไม่มีค่าเฉพาะแอป');
  });

  it('สลับภาษาเป็นอังกฤษ: การ์ดเลือกแอปและตารางแปลครบ', async () => {
    const select = wrapper.findAll('select').find((s) => s.text().includes('English'))!;
    await select.setValue('en');
    expect(wrapper.text()).toContain('Which apps is this theme for?');
    expect(wrapper.text()).toContain('What each app takes from a theme');
    expect(wrapper.get('.matrix').text()).toContain('Corner radius');
    await select.setValue('th');
  });
});


describe('วิธีใช้ไฟล์ (ตำแหน่งที่เก็บ)', () => {
  it('บอกโฟลเดอร์ Documents\\NSL\\Themes (ไม่ใช่ APPDATA) และบอกว่า Android ไม่มี Launcher', async () => {
    const how = () => wrapper.get('h3.how').element.nextElementSibling!.textContent!;
    expect(how()).toContain('Documents\\NSL\\Themes');
    expect(how()).not.toContain('APPDATA');
    expect(how()).toContain('Launcher');
    const select = wrapper.findAll('select').find((s) => s.text().includes('English'))!;
    await select.setValue('en');
    expect(how()).toContain('Documents\\NSL\\Themes');
    expect(how()).toContain('no Launcher on Android');
    await select.setValue('th');
  });
});
