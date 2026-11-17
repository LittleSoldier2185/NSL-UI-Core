// @vitest-environment jsdom
// Undo / Redo + ปุ่มกลับขั้นตอน ทดสอบผ่านหน้าเว็บจริง (App.vue)
import { type VueWrapper, flushPromises, mount } from '@vue/test-utils';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import App from '../src/App.vue';
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
const code = async () => {
  const back = current();
  await go('file');
  const text = wrapper.get('pre.code').text();
  await go(back);
  return text;
};
const undoBtn = () => wrapper.get('header.top button.undo');
const redoBtn = () => wrapper.get('header.top button.redo');
const nameInput = () => wrapper.get('input[maxlength="80"]');
const langSelect = () => wrapper.findAll('select').find((s) => s.text().includes('English'))!;
const key = (k: string, init: KeyboardEventInit = {}) => {
  window.dispatchEvent(new KeyboardEvent('keydown', { key: k, ctrlKey: true, bubbles: true, cancelable: true, ...init }));
};

describe('Undo / Redo', () => {
  it('เริ่มต้นกดไม่ได้ ; แก้แล้วย้อนได้ ; ย้อนแล้วทำซ้ำได้ และมีข้อความแจ้ง', async () => {
    expect(undoBtn().attributes('disabled')).toBeDefined();
    expect(redoBtn().attributes('disabled')).toBeDefined();
    const before = await code();
    await wrapper.findAll('button.sw')[2]!.trigger('click'); // ม่วง
    expect(undoBtn().attributes('disabled')).toBeUndefined();
    const withAccent = await code();
    expect(withAccent).not.toBe(before);
    await undoBtn().trigger('click');
    expect(await code()).toBe(before);
    expect(redoBtn().attributes('disabled')).toBeUndefined();
    expect(wrapper.get('.toasts').text()).toContain('ย้อนกลับแล้ว');
    await redoBtn().trigger('click');
    expect(await code()).toBe(withAccent);
    expect(redoBtn().attributes('disabled')).toBeDefined();
    expect(wrapper.get('.toasts').text()).toContain('ทำซ้ำแล้ว');
  });

  it('ย้อนกลับครอบคลุมชื่อธีม สีรายตัว มุมโค้ง ความหนาแน่น และแอปที่เลือก — ย้อนสุดแล้วเท่าเดิม ทำซ้ำสุดแล้วเท่าที่แก้', async () => {
    const start = await code();
    await nameInput().setValue('Ocean');
    await go('colors');
    await wrapper.get('input[aria-label="bg hex"]').setValue('#123456');
    await go('shape');
    await wrapper.findAll('input[type="number"]')[2]!.setValue('14');
    await go('style');
    await wrapper.findAll('input[name="density"]')[0]!.setValue(true);
    await go('start');
    await wrapper.findAll('.approw input.appcheck')[3]!.setValue(false); // เอา Orbit ออก
    const edited = await code();
    expect(edited).not.toBe(start);

    for (let i = 0; i < 30 && undoBtn().attributes('disabled') === undefined; i++) await undoBtn().trigger('click');
    expect(await code()).toBe(start);
    expect((nameInput().element as HTMLInputElement).value).toBe('My theme');
    expect(wrapper.findAll('.approw input.appcheck').every((c) => (c.element as HTMLInputElement).checked)).toBe(true);

    for (let i = 0; i < 30 && redoBtn().attributes('disabled') === undefined; i++) await redoBtn().trigger('click');
    expect(await code()).toBe(edited);
    expect((nameInput().element as HTMLInputElement).value).toBe('Ocean');
    expect(wrapper.findAll('.approw input.appcheck').map((c) => (c.element as HTMLInputElement).checked)).toEqual([true, true, true, false]);
  });

  it('ล้างทั้งหมดย้อนได้ (กลับมาเป็นสิ่งที่แก้ไว้) ; การแก้ก่อนหน้าย้อนได้ต่อ', async () => {
    const base = await code();
    await nameInput().setValue('Keep');
    await wrapper.findAll('button.sw')[1]!.trigger('click');
    const edited = await code();
    await go('file');
    await wrapper
      .findAll('button.btn')
      .find((b) => b.text().includes('ล้างการแก้ไขทั้งหมด'))!
      .trigger('click');
    expect(await code()).toBe(base);
    await undoBtn().trigger('click');
    expect(await code()).toBe(edited);
  });

  it('ล้างทั้งหมดทันทีหลังพิมพ์ (ยังไม่ครบ 500ms) ก็ย้อนกลับมาเป็นสิ่งที่พิมพ์ไว้ได้', async () => {
    await nameInput().setValue('JustTyped');
    await go('file');
    await wrapper
      .findAll('button.btn')
      .find((b) => b.text().includes('ล้างการแก้ไขทั้งหมด'))!
      .trigger('click');
    expect((nameInput().element as HTMLInputElement).value).toBe('My theme');
    await undoBtn().trigger('click');
    expect((nameInput().element as HTMLInputElement).value).toBe('JustTyped');
  });

  it('นำเข้าไฟล์ย้อนได้ในขั้นเดียว : กลับมาเป็นธีมที่แก้อยู่', async () => {
    await nameInput().setValue('Mine');
    const input = wrapper.get('header.top input[type="file"]');
    const body = '{"schema":1,"id":"imp","name":"Imported","extends":"nsl.nebular"}';
    const file = new File([body], 'imp.nslt', { type: 'application/json' });
    // jsdom ยังไม่มี File.text() — เบราว์เซอร์จริงมี
    Object.defineProperty(file, 'text', { value: async () => body });
    Object.defineProperty(input.element, 'files', { value: [file], configurable: true });
    await input.trigger('change');
    await flushPromises();
    expect((nameInput().element as HTMLInputElement).value).toBe('Imported');
    await undoBtn().trigger('click');
    expect((nameInput().element as HTMLInputElement).value).toBe('Mine');
    await redoBtn().trigger('click');
    expect((nameInput().element as HTMLInputElement).value).toBe('Imported');
  });

  it('คีย์ลัดใช้ได้ทุกที่ รวมตอนโฟกัสอยู่ในช่องของธีม (ชื่อ) ; ช่องที่ไม่ใช่ส่วนของธีม (ค้นหา, สีหลักแบบเร็ว) ใช้ undo ของช่องเอง ; Alt+Ctrl+Z ไม่ถูกจับ', async () => {
    const fire = (el: Element, init: KeyboardEventInit = {}) => {
      const ev = new KeyboardEvent('keydown', { key: 'z', ctrlKey: true, bubbles: true, cancelable: true, ...init });
      el.dispatchEvent(ev);
      return ev;
    };
    await wrapper.findAll('button.sw')[3]!.trigger('click');
    const edited = await code();

    // ช่องที่ไม่ใช่ส่วนของธีม → ปล่อยให้ช่องย้อนข้อความของตัวเอง (ไม่ preventDefault ไม่ย้อนธีม)
    await go('colors');
    const search = wrapper.get('input[type="search"]').element;
    expect(fire(search).defaultPrevented).toBe(false);
    await go('start');
    const quick = wrapper.get('input.mono').element;
    expect(fire(quick).defaultPrevented).toBe(false);
    expect(await code()).toBe(edited);

    // Alt+Ctrl+Z ไม่ถูกจับ
    key('z', { altKey: true });
    await flushPromises();
    expect(await code()).toBe(edited);

    // ช่องของธีม (ชื่อธีม) โฟกัสอยู่ → ย้อนธีมได้ (ไม่ใช่แค่ข้อความในช่อง)
    (nameInput().element as HTMLInputElement).focus();
    const ev = fire(nameInput().element);
    expect(ev.defaultPrevented).toBe(true);
    await flushPromises();
    expect(await code()).not.toBe(edited);
    (nameInput().element as HTMLInputElement).focus();
    fire(nameInput().element, { key: 'y' });
    await flushPromises();
    expect(await code()).toBe(edited);

    (document.activeElement as HTMLElement | null)?.blur();
    key('z');
    await flushPromises();
    expect(await code()).not.toBe(edited);
    key('y');
    await flushPromises();
    expect(await code()).toBe(edited);
    key('z');
    await flushPromises();
    expect(await code()).not.toBe(edited);
    key('z', { shiftKey: true });
    await flushPromises();
    expect(await code()).toBe(edited);
  });

  it('พิมพ์ชื่อธีมแล้วกด Ctrl+Z ทั้งที่ยังอยู่ในช่อง → ชื่อกลับไปก่อนพิมพ์ ; Ctrl+Shift+Z → กลับมา', async () => {
    const el = nameInput().element as HTMLInputElement;
    el.focus();
    await nameInput().setValue('Typed in field');
    const fire = (init: KeyboardEventInit) => el.dispatchEvent(new KeyboardEvent('keydown', { ctrlKey: true, bubbles: true, cancelable: true, ...init }));
    fire({ key: 'z' });
    await flushPromises();
    expect(el.value).toBe('My theme');
    fire({ key: 'Z', shiftKey: true });
    await flushPromises();
    expect(el.value).toBe('Typed in field');
  });

  it('คำใบ้บนปุ่มบอกคีย์ลัดและจำนวนขั้น ; มี aria-label สองภาษา', async () => {
    await wrapper.findAll('button.sw')[1]!.trigger('click');
    expect(undoBtn().attributes('aria-label')).toBe('ย้อนกลับ');
    expect(undoBtn().attributes('title')).toContain('Ctrl+Z');
    expect(undoBtn().attributes('title')).toMatch(/เหลือ \d+ ขั้น/);
    await langSelect().setValue('en');
    expect(undoBtn().attributes('aria-label')).toBe('Undo');
    expect(redoBtn().attributes('aria-label')).toBe('Redo');
    await langSelect().setValue('th');
  });

  it('เปลี่ยนขั้น / ภาษา / แท็บพรีวิว ไม่เป็นขั้นใน Undo (ไม่ใช่การแก้ธีม)', async () => {
    await go('colors');
    await go('ext');
    await langSelect().setValue('en');
    await langSelect().setValue('th');
    await wrapper.findAll('.ptabs button')[1]!.trigger('click');
    expect(undoBtn().attributes('disabled')).toBeDefined();
  });
});

describe('ปุ่มกลับ/ถัดไป', () => {
  const order: Step[] = ['start', 'colors', 'ext', 'shape', 'style', 'check', 'file'];

  it('"กลับ" พาถอยทีละขั้นจากไฟล์ถึงเริ่มต้น ; ขั้นแรกไม่มีปุ่มกลับ', async () => {
    await go('file');
    for (let i = order.length - 1; i > 0; i--) {
      expect(current()).toBe(order[i]);
      const back = wrapper.get('.nextrow .back');
      expect(back.text()).toContain('กลับ');
      expect(back.text()).toContain(wrapper.get(`nav.steps button[data-step="${order[i - 1]}"] b`).text());
      await back.trigger('click');
    }
    expect(current()).toBe('start');
    expect(wrapper.find('.nextrow .back').exists()).toBe(false);
  });

  it('"ถัดไป" เดินครบเจ็ดขั้น ; ขั้นสุดท้ายมีแต่ "กลับ"', async () => {
    for (let i = 1; i < order.length; i++) {
      await wrapper.findAll('.nextrow button').at(-1)!.trigger('click');
      expect(current()).toBe(order[i]);
    }
    expect(wrapper.findAll('.nextrow button').length).toBe(1);
    expect(wrapper.get('.nextrow button').classes()).toContain('back');
  });

  it('ขั้นกลางมีทั้ง "กลับ" และ "ถัดไป" ซึ่งบอกชื่อขั้นปลายทาง', async () => {
    await go('ext');
    const [back, next] = wrapper.findAll('.nextrow button');
    expect(back!.text()).toContain('สี');
    expect(next!.text()).toContain('รูปทรงและตัวอักษร');
  });

  it('กลับ/ถัดไปไม่ทำให้ค่าที่แก้หาย', async () => {
    await go('colors');
    await wrapper.get('input[aria-label="bg hex"]').setValue('#123456');
    await wrapper.findAll('.nextrow button').at(-1)!.trigger('click');
    await wrapper.get('.nextrow .back').trigger('click');
    expect((wrapper.get('input[aria-label="bg hex"]').element as HTMLInputElement).value.toUpperCase()).toBe('#123456');
  });
});
