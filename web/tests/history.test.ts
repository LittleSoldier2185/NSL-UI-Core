// Undo/Redo : ประวัติแบบ snapshot — รวมการเปลี่ยนต่อเนื่อง, ปิดขั้นด้วย checkpoint, ลึกสุด, redo ถูกล้างเมื่อแก้ใหม่
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { reactive } from 'vue';
import { createHistory } from '../src/history';

beforeEach(() => vi.useFakeTimers());
afterEach(() => vi.useRealTimers());

function make(limit?: number) {
  const s = reactive({ n: 0, tag: 'a' });
  const h = createHistory({
    current: () => JSON.stringify(s),
    restore: (snap) => Object.assign(s, JSON.parse(snap)),
    delay: 500,
    limit,
  });
  return { s, h };
}
const settle = () => vi.advanceTimersByTime(600);

describe('createHistory', () => {
  it('เริ่มต้นย้อน/ทำซ้ำไม่ได้', () => {
    const { h } = make();
    expect(h.canUndo.value).toBe(false);
    expect(h.canRedo.value).toBe(false);
    expect(h.undo()).toBe(false);
    expect(h.redo()).toBe(false);
  });

  it('แก้แล้วย้อนได้ทันที (ไม่ต้องรอจับเวลา) และทำซ้ำได้', () => {
    const { s, h } = make();
    s.n = 1;
    expect(h.canUndo.value).toBe(true);
    expect(h.undo()).toBe(true);
    expect(s.n).toBe(0);
    expect(h.canRedo.value).toBe(true);
    expect(h.redo()).toBe(true);
    expect(s.n).toBe(1);
    expect(h.canRedo.value).toBe(false);
  });

  it('การแก้ต่อเนื่องภายใน 500ms รวมเป็นขั้นเดียว ; เว้นช่วงแล้วเป็นคนละขั้น', () => {
    const { s, h } = make();
    s.n = 1;
    vi.advanceTimersByTime(200);
    s.n = 2;
    vi.advanceTimersByTime(200);
    s.n = 3;
    settle();
    s.n = 10;
    settle();
    expect(h.undoCount.value).toBe(2);
    h.undo();
    expect(s.n).toBe(3);
    h.undo();
    expect(s.n).toBe(0);
    expect(h.canUndo.value).toBe(false);
  });

  it('checkpoint ปิดขั้นทันที : สองการกระทำติดกันแยกเป็นสองขั้น', () => {
    const { s, h } = make();
    s.n = 1;
    h.checkpoint();
    s.n = 2;
    h.checkpoint();
    expect(h.undoCount.value).toBe(2);
    h.undo();
    expect(s.n).toBe(1);
  });

  it('แก้ใหม่หลังย้อนกลับ = ล้างรายการ redo', () => {
    const { s, h } = make();
    s.n = 1;
    settle();
    s.n = 2;
    settle();
    h.undo();
    expect(h.canRedo.value).toBe(true);
    s.n = 99;
    expect(h.canRedo.value).toBe(false); // มีการแก้ค้างอยู่ → ทำซ้ำไม่ได้ทันที
    settle();
    expect(h.redoCount.value).toBe(0);
    expect(h.redo()).toBe(false);
    h.undo();
    expect(s.n).toBe(1);
  });

  it('ย้อนกลับไม่สร้างขั้นใหม่ (ไม่วนซ้ำ) แม้ผ่านตัวจับเวลา', () => {
    const { s, h } = make();
    s.n = 1;
    settle();
    h.undo();
    settle();
    expect(s.n).toBe(0);
    expect(h.undoCount.value).toBe(0);
    expect(h.redoCount.value).toBe(1);
  });

  it('ค่ากลับมาเท่าเดิมก่อนครบเวลา = ไม่เกิดขั้น', () => {
    const { s, h } = make();
    s.n = 5;
    s.n = 0;
    settle();
    expect(h.canUndo.value).toBe(false);
  });

  it('ลึกสุดตามที่กำหนด : ทิ้งขั้นเก่าสุด', () => {
    const { s, h } = make(3);
    for (let i = 1; i <= 5; i++) {
      s.n = i;
      h.checkpoint();
    }
    expect(h.undoCount.value).toBe(3);
    h.undo();
    h.undo();
    h.undo();
    expect(s.n).toBe(2); // เก่าสุดที่ย้อนได้ = 2 (ขั้น 0, 1 ถูกทิ้ง)
    expect(h.undo()).toBe(false);
  });

  it('reset ล้างประวัติและใช้สถานะปัจจุบันเป็นจุดเริ่ม', () => {
    const { s, h } = make();
    s.n = 1;
    h.checkpoint();
    s.n = 2;
    h.reset();
    expect(h.canUndo.value).toBe(false);
    s.n = 3;
    h.undo();
    expect(s.n).toBe(2);
  });

  it('dispose หยุดตัวจับเวลา', () => {
    const { s, h } = make();
    s.n = 1;
    h.dispose();
    settle();
    expect(h.undoCount.value).toBe(1); // ยังนับขั้นที่ค้างอยู่ แต่ไม่ถูก commit ด้วยตัวจับเวลา
    h.undo();
    expect(s.n).toBe(0);
  });
});
