import { type Ref, computed, ref, watch } from 'vue';

/**
 * ประวัติ Undo/Redo แบบ snapshot ของสถานะที่ผู้ใช้แก้ (JSON ของสถานะทั้งก้อน)
 *
 * - เปลี่ยนต่อเนื่องภายใน [delay] มิลลิวินาที (เช่น ลากแถบสี พิมพ์ชื่อ) รวมเป็นขั้นเดียว
 * - [checkpoint] ปิดขั้นปัจจุบันทันที (ใช้ก่อน/หลังการกระทำใหญ่ เช่น นำเข้า ล้างทั้งหมด แก้อัตโนมัติ)
 * - undo/redo ปิดขั้นที่ค้างอยู่ก่อนเสมอ จึงไม่ต้องรอ
 * - ย้อนกลับแล้วทำอะไรใหม่ = ล้างรายการ redo ; ลึกสุด [limit] ขั้น (ทิ้งขั้นเก่าสุด)
 */
export interface History {
  canUndo: Ref<boolean>;
  canRedo: Ref<boolean>;
  undoCount: Ref<number>;
  redoCount: Ref<number>;
  undo: () => boolean;
  redo: () => boolean;
  checkpoint: () => void;
  /** ล้างประวัติ และใช้สถานะปัจจุบันเป็นจุดเริ่ม */
  reset: () => void;
  /** หยุดตัวจับเวลา (ตอน unmount) */
  dispose: () => void;
}

export function createHistory(opts: { current: () => string; restore: (snapshot: string) => void; delay?: number; limit?: number }): History {
  const delay = opts.delay ?? 500;
  const limit = opts.limit ?? 100;
  const state = computed(opts.current);
  let committed = state.value;
  const undoStack = ref<string[]>([]);
  const redoStack = ref<string[]>([]);
  let restoring = false;
  let timer: ReturnType<typeof setTimeout> | undefined;

  const clearTimer = () => {
    if (timer !== undefined) clearTimeout(timer);
    timer = undefined;
  };

  /** ปิดขั้นที่ค้าง : ถ้าสถานะต่างจากจุดที่บันทึกไว้ → เก็บจุดเดิมลง undo */
  function checkpoint() {
    clearTimer();
    const now = state.value;
    if (now === committed) return;
    undoStack.value.push(committed);
    if (undoStack.value.length > limit) undoStack.value.shift();
    redoStack.value = [];
    committed = now;
  }

  watch(
    state,
    () => {
      if (restoring) return;
      clearTimer();
      timer = setTimeout(checkpoint, delay);
    },
    { flush: 'sync' },
  );

  function apply(snapshot: string) {
    restoring = true;
    try {
      opts.restore(snapshot);
    } finally {
      restoring = false;
    }
    committed = state.value;
  }

  function undo(): boolean {
    checkpoint();
    const prev = undoStack.value.pop();
    if (prev === undefined) return false;
    redoStack.value.push(committed);
    apply(prev);
    return true;
  }

  function redo(): boolean {
    checkpoint();
    const next = redoStack.value.pop();
    if (next === undefined) return false;
    undoStack.value.push(committed);
    apply(next);
    return true;
  }

  function reset() {
    clearTimer();
    undoStack.value = [];
    redoStack.value = [];
    committed = state.value;
  }

  const undoCount = computed(() => undoStack.value.length + (state.value !== committed ? 1 : 0));
  return {
    canUndo: computed(() => undoCount.value > 0),
    canRedo: computed(() => redoStack.value.length > 0 && state.value === committed),
    undoCount,
    redoCount: computed(() => redoStack.value.length),
    undo,
    redo,
    checkpoint,
    reset,
    dispose: clearTimer,
  };
}
