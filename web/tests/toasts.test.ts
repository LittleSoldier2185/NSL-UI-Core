// @vitest-environment jsdom
// ข้อความแจ้งที่หายเองใน 3 วินาที : ตัวนับเวลา, หยุดเมื่อชี้/โฟกัส, ลบออกจากรายการจริง, สูงสุด 3 อันที่แสดง
import { type VueWrapper, mount } from '@vue/test-utils';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { defineComponent, h, ref } from 'vue';
import { type Notice, useToasts } from '../src/toasts';

let wrapper: VueWrapper | undefined;
beforeEach(() => vi.useFakeTimers());
afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
  vi.useRealTimers();
});

function setup(initial: Notice[] = [], opts?: { duration?: number; max?: number }) {
  const notices = ref<Notice[]>(initial);
  let api!: ReturnType<typeof useToasts>;
  wrapper = mount(
    defineComponent({
      setup() {
        api = useToasts(notices, opts);
        return () => h('div');
      },
    }),
  );
  const say = (text: string, kind: Notice['kind'] = 'info') => {
    notices.value = [...notices.value, { kind, text }];
  };
  return { notices, api, say };
}

describe('useToasts', () => {
  it('ข้อความหายเองหลัง 3 วินาที และถูกลบออกจากรายการจริง', async () => {
    const { notices, api, say } = setup();
    say('hello');
    await Promise.resolve();
    expect(api.toasts.value.map((t) => t.text)).toEqual(['hello']);
    expect(api.toasts.value[0]!.duration).toBe(3000);
    vi.advanceTimersByTime(2999);
    expect(notices.value.length).toBe(1);
    vi.advanceTimersByTime(2);
    expect(notices.value.length).toBe(0);
    expect(api.toasts.value).toEqual([]);
  });

  it('ข้อความที่มีอยู่แล้วตอนเริ่มก็หายเองเช่นกัน ; ทุกชนิด (error/warn/info) ใช้ 3 วินาทีเท่ากัน', async () => {
    const { notices } = setup([
      { kind: 'error', text: 'e' },
      { kind: 'warn', text: 'w' },
      { kind: 'info', text: 'i' },
    ]);
    vi.advanceTimersByTime(3001);
    expect(notices.value).toEqual([]);
  });

  it('แต่ละข้อความนับเวลาของตัวเอง (มาทีหลังก็หายทีหลัง)', async () => {
    const { notices, say } = setup();
    say('a');
    await Promise.resolve();
    vi.advanceTimersByTime(2000);
    say('b');
    await Promise.resolve();
    vi.advanceTimersByTime(1500); // a ครบ 3.5s, b ได้ 1.5s
    expect(notices.value.map((n) => n.text)).toEqual(['b']);
    vi.advanceTimersByTime(1600);
    expect(notices.value).toEqual([]);
  });

  it('ชี้/โฟกัสอยู่ = หยุดนับ ; ออกแล้วนับต่อจากเวลาที่เหลือ (ไม่เริ่ม 3 วินาทีใหม่)', async () => {
    const { notices, api, say } = setup();
    say('hold');
    await Promise.resolve();
    const id = api.toasts.value[0]!.id;
    vi.advanceTimersByTime(1000); // เหลือ 2000
    api.pause(id);
    expect(api.paused.value.has(id)).toBe(true);
    vi.advanceTimersByTime(60_000); // ค้างไว้นานแค่ไหนก็ไม่หาย
    expect(notices.value.length).toBe(1);
    api.resume(id);
    expect(api.paused.value.has(id)).toBe(false);
    vi.advanceTimersByTime(1999);
    expect(notices.value.length).toBe(1);
    vi.advanceTimersByTime(2);
    expect(notices.value.length).toBe(0);
  });

  it('pause/resume ซ้ำ ๆ รักษาเวลาที่เหลือรวมถูกต้อง', async () => {
    const { notices, api, say } = setup();
    say('x');
    await Promise.resolve();
    const id = api.toasts.value[0]!.id;
    vi.advanceTimersByTime(500);
    api.pause(id);
    api.pause(id); // ซ้ำ = ไม่นับซ้อน
    vi.advanceTimersByTime(5000);
    api.resume(id);
    api.resume(id); // ซ้ำ = ไม่ตั้งตัวจับเวลาซ้อน
    vi.advanceTimersByTime(1000);
    api.pause(id);
    api.resume(id);
    vi.advanceTimersByTime(1499); // ใช้ไป 500 + 1000 + 1499 = 2999
    expect(notices.value.length).toBe(1);
    vi.advanceTimersByTime(2);
    expect(notices.value.length).toBe(0);
  });

  it('dismiss ลบทันที และตัวจับเวลาไม่ทำงานซ้ำ', async () => {
    const { notices, api, say } = setup();
    say('a');
    say('b');
    await Promise.resolve();
    api.dismiss(api.toasts.value[0]!.id);
    expect(notices.value.map((n) => n.text)).toEqual(['b']);
    vi.advanceTimersByTime(3001);
    expect(notices.value).toEqual([]);
  });

  it('แสดงพร้อมกันสูงสุด 3 อัน (ใหม่สุด) ; อันที่เกินยังนับเวลาและหายตามเวลา', async () => {
    const { notices, api, say } = setup();
    for (const t of ['1', '2', '3', '4', '5']) say(t);
    await Promise.resolve();
    expect(api.toasts.value.map((t) => t.text)).toEqual(['3', '4', '5']);
    vi.advanceTimersByTime(3001);
    expect(notices.value).toEqual([]);
  });

  it('ข้อความถูกล้างจากข้างนอก (ล้างทั้งหมด) → เลิกนับ ไม่ลบข้อความใหม่ที่เข้ามาแทน', async () => {
    const { notices, api, say } = setup();
    say('old');
    await Promise.resolve();
    vi.advanceTimersByTime(2000);
    notices.value = [];
    await Promise.resolve();
    say('new');
    await Promise.resolve();
    vi.advanceTimersByTime(1500); // ตัวจับเวลาของ old จะครบตอนนี้ แต่ต้องไม่กระทบ new
    expect(notices.value.map((n) => n.text)).toEqual(['new']);
    expect(api.toasts.value.length).toBe(1);
  });

  it('กำหนดระยะเวลาเองได้', async () => {
    const { notices, say } = setup([], { duration: 1000 });
    say('short');
    await Promise.resolve();
    vi.advanceTimersByTime(1001);
    expect(notices.value).toEqual([]);
  });

  it('ถอด component = เลิกตัวจับเวลา (ไม่มีอะไรทำงานหลังถอด)', async () => {
    const { notices, say } = setup();
    say('x');
    await Promise.resolve();
    wrapper!.unmount();
    wrapper = undefined;
    vi.advanceTimersByTime(5000);
    expect(notices.value.length).toBe(1); // ไม่ถูกลบ เพราะตัวจับเวลาถูกยกเลิกแล้ว
  });
});

// ── ผ่านหน้าเว็บจริง : เส้นเวลา, หายเอง, หยุดเมื่อชี้/โฟกัส ──
import { flushPromises } from '@vue/test-utils';
import App from '../src/App.vue';
import { setLang } from '../src/i18n';

describe('ข้อความแจ้งในหน้าเว็บ', () => {
  let page: VueWrapper;
  beforeEach(() => {
    setLang('th');
    vi.spyOn(console, 'warn').mockImplementation(() => {});
    vi.spyOn(console, 'error').mockImplementation(() => {});
    page = mount(App, { attachTo: document.body });
  });
  afterEach(() => {
    page.unmount();
    vi.restoreAllMocks();
  });
  const fire = async () => {
    await page.findAll('button.sw')[0]!.trigger('click'); // ตั้งสีหลัก → มีข้อความแจ้ง
    await flushPromises();
  };

  it('ข้อความมีเส้นเวลา (ยาว 3000ms, ซ่อนจาก screen reader) และหายเองใน 3 วินาที', async () => {
    await fire();
    expect(page.findAll('.toast').length).toBe(1);
    const life = page.get('.toast .life');
    expect(life.attributes('aria-hidden')).toBe('true');
    expect(life.attributes('style')).toContain('animation-duration: 3000ms');
    vi.advanceTimersByTime(2900);
    await flushPromises();
    expect(page.findAll('.toast').length).toBe(1);
    vi.advanceTimersByTime(200);
    await flushPromises();
    expect(page.findAll('.toast').length).toBe(0);
  });

  it('เอาเมาส์ชี้ = เส้นเวลาหยุด (class paused) และไม่หาย ; ออก = นับต่อ', async () => {
    await fire();
    vi.advanceTimersByTime(1000);
    await page.get('.toast').trigger('mouseenter');
    expect(page.get('.toast').classes()).toContain('paused');
    vi.advanceTimersByTime(30_000);
    await flushPromises();
    expect(page.findAll('.toast').length).toBe(1);
    await page.get('.toast').trigger('mouseleave');
    expect(page.get('.toast').classes()).not.toContain('paused');
    vi.advanceTimersByTime(2100); // เหลือ ~2000ms
    await flushPromises();
    expect(page.findAll('.toast').length).toBe(0);
  });

  it('โฟกัสคีย์บอร์ดที่ปุ่มปิด = หยุดนับเช่นกัน ; กดปิดเองได้', async () => {
    await fire();
    await page.get('.toast').trigger('focusin');
    vi.advanceTimersByTime(10_000);
    await flushPromises();
    expect(page.findAll('.toast').length).toBe(1);
    await page.get('.toast button.x').trigger('click');
    expect(page.findAll('.toast').length).toBe(0);
  });

  it('CSS : เส้นเวลาหดจากเต็มเป็น 0 ด้วย linear, หยุดตาม .paused, ไม่ทับข้อความ (อยู่ขอบล่าง)', async () => {
    const { readFileSync } = await import('node:fs');
    const { resolve } = await import('node:path');
    const css = readFileSync(resolve(__dirname, '../src/style.css'), 'utf8');
    const life = /\.toast \.life \{([^}]*)\}/.exec(css)![1]!;
    expect(life).toContain('animation-timing-function: linear');
    expect(life).toContain('animation-fill-mode: forwards');
    expect(life).toContain('bottom: 0');
    expect(css).toMatch(/\.toast\.paused \.life \{\s*animation-play-state: paused;/);
    expect(css).toMatch(/@keyframes toast-life \{\s*from \{\s*transform: scaleX\(1\);\s*\}\s*to \{\s*transform: scaleX\(0\);/);
  });
});
