// @vitest-environment jsdom
// เลือกไฟล์ฟอนต์จากเครื่องในหน้าเว็บจริง : รายการ, คำเตือนเมื่อฟอนต์ซ้อนสคริปต์, ลำดับฟอนต์ของพรีวิว, ไฟล์เสีย/ชื่อสงวน
import { type VueWrapper, flushPromises, mount } from '@vue/test-utils';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import App from '../src/App.vue';
import { setLang } from '../src/i18n';

type Range = [number, number];
function fakeFont(ranges: Range[], name: string): Uint8Array {
  const u16 = (b: number[], v: number) => b.push((v >> 8) & 255, v & 255);
  const u32 = (b: number[], v: number) => b.push((v >>> 24) & 255, (v >> 16) & 255, (v >> 8) & 255, v & 255);
  const cmap: number[] = [];
  u16(cmap, 0);
  u16(cmap, 1);
  u16(cmap, 3);
  u16(cmap, 10);
  u32(cmap, 12);
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
  const out: number[] = [];
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

/** jsdom ไม่มี File.arrayBuffer() จึงทำไฟล์จำลองที่มีเมธอดที่โค้ดใช้ */
const fileOf = (bytes: Uint8Array, name: string): File => {
  const f = new File([new Uint8Array(bytes)], name);
  Object.defineProperty(f, 'arrayBuffer', { value: async () => bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength) });
  return f;
};

let wrapper: VueWrapper;
let warn: ReturnType<typeof vi.spyOn>;
let err: ReturnType<typeof vi.spyOn>;
const loaded: string[] = [];
const removed: string[] = [];

beforeEach(() => {
  setLang('en');
  loaded.length = 0;
  removed.length = 0;
  class FakeFace {
    constructor(public family: string) {}
    async load() {
      loaded.push(this.family);
      return this;
    }
  }
  vi.stubGlobal('FontFace', FakeFace);
  Object.defineProperty(document, 'fonts', { configurable: true, value: { add: () => {}, delete: (f: FakeFace) => removed.push(f.family) } });
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
  vi.unstubAllGlobals();
});

const pick = async (...files: File[]) => {
  await wrapper.get('nav.steps button[data-step="shape"]').trigger('click');
  const input = wrapper.get('[data-testid="font-input"]');
  Object.defineProperty(input.element, 'files', { configurable: true, value: files });
  await input.trigger('change');
  await flushPromises();
};
const type = async (label: string, value: string) => {
  await wrapper.get('nav.steps button[data-step="shape"]').trigger('click');
  const lab = wrapper.findAll('label.f').find((l) => l.text().startsWith(label));
  expect(lab, label).toBeTruthy();
  await lab!.get('input').setValue(value);
};
const ffOfPreview = () => (wrapper.get('section.pv').element as HTMLElement).style.getPropertyValue('--ff');

describe('เลือกไฟล์ฟอนต์จากเครื่อง', () => {
  it('ไฟล์ที่ผ่านขึ้นรายการ + ลงทะเบียนกับเบราว์เซอร์ + เป็นตัวเลือกในช่องกรอก', async () => {
    await pick(fileOf(fakeFont(LATIN, 'My Latin'), 'a.ttf'), fileOf(fakeFont([...LATIN, ...THAI], 'My Both'), 'b.otf'));
    expect([...loaded].sort()).toEqual(['My Both', 'My Latin']);
    const items = wrapper.findAll('ul.font-list li');
    expect(items.map((i) => i.get('strong').text()).sort()).toEqual(['My Both', 'My Latin']);
    expect(
      wrapper
        .findAll('datalist#user-fonts option')
        .map((o) => o.attributes('value'))
        .sort(),
    ).toEqual(['My Both', 'My Latin']);
    expect(wrapper.find('.font-error').exists()).toBe(false);
  });

  it('เอาออกแล้วรายการและฟอนต์ในเบราว์เซอร์หายไป', async () => {
    await pick(fileOf(fakeFont(LATIN, 'My Latin'), 'a.ttf'));
    await wrapper.get('ul.font-list button').trigger('click');
    expect(wrapper.findAll('ul.font-list li').length).toBe(0);
    expect(removed).toEqual(['My Latin']);
  });

  it('ไฟล์เสีย/ชื่อสงวนถูกปฏิเสธพร้อมเหตุผล ไม่ขึ้นรายการ', async () => {
    await pick(fileOf(new Uint8Array(200).fill(7), 'bad.ttf'));
    expect(wrapper.get('.font-error').text()).toContain('bad.ttf');
    expect(wrapper.findAll('ul.font-list li').length).toBe(0);
    await pick(fileOf(fakeFont(LATIN, 'Tahoma'), 't.ttf'));
    expect(wrapper.get('.font-error').text()).toContain('reserved');
    expect(loaded).toEqual([]);
  });

  it('ฟอนต์ละตินที่มีไทยด้วย + ฟอนต์ไทยที่ไม่มีละติน : พรีวิววางฟอนต์ไทยก่อน', async () => {
    await pick(fileOf(fakeFont([...LATIN, ...THAI], 'Wide'), 'w.ttf'), fileOf(fakeFont(THAI, 'ThaiOnly'), 't.ttf'));
    await type('UI font (Latin', 'Wide');
    await type('UI font (Thai', 'ThaiOnly');
    expect(ffOfPreview().startsWith('"ThaiOnly", "Wide"')).toBe(true);
    expect(wrapper.find('.font-notes').exists()).toBe(false);
  });

  it('ละติน(ไม่มีไทย) + ไทย : ตามที่เลือก (ละตินก่อน)', async () => {
    await pick(fileOf(fakeFont(LATIN, 'LatinOnly'), 'l.ttf'), fileOf(fakeFont(THAI, 'ThaiOnly'), 't.ttf'));
    await type('UI font (Latin', 'LatinOnly');
    await type('UI font (Thai', 'ThaiOnly');
    expect(ffOfPreview().startsWith('"LatinOnly", "ThaiOnly"')).toBe(true);
  });

  it('ทั้งสองฟอนต์มีทั้งสองสคริปต์ : เตือนว่าบังคับไม่ได้', async () => {
    await pick(fileOf(fakeFont([...LATIN, ...THAI], 'A'), 'a.ttf'), fileOf(fakeFont([...LATIN, ...THAI], 'B'), 'b.ttf'));
    await type('UI font (Latin', 'A');
    await type('UI font (Thai', 'B');
    expect(wrapper.get('.font-notes').text()).toContain('cannot be forced');
  });

  it('ช่องไทยที่ไม่มีอักษรไทย : เตือน', async () => {
    await pick(fileOf(fakeFont(LATIN, 'NoThai'), 'n.ttf'));
    await type('UI font (Thai', 'NoThai');
    expect(wrapper.get('.font-notes').text()).toContain('no Thai letters');
  });

  it('มีแต่ช่องไทย : ฟอนต์ไทยมาก่อน Noto', async () => {
    await type('UI font (Thai', 'Sarabun');
    expect(ffOfPreview().startsWith('"Sarabun", "Noto Sans Thai"')).toBe(true);
  });

  it('ชื่อฟอนต์ที่พิมพ์เองและไม่ได้เลือกไฟล์ : ไม่เตือน (ไม่ตัดสินสิ่งที่ไม่รู้)', async () => {
    await type('UI font (Latin', 'Inter');
    await type('UI font (Thai', 'Sarabun');
    expect(wrapper.find('.font-notes').exists()).toBe(false);
    expect(ffOfPreview().startsWith('"Inter", "Sarabun"')).toBe(true);
  });
});
