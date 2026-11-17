import { type Ref, computed, onBeforeUnmount, ref, watch } from 'vue';

export interface Notice {
  kind: 'error' | 'warn' | 'info';
  text: string;
}

export interface Toast extends Notice {
  id: number;
  /** ระยะเวลาทั้งหมด (ms) — ใช้กำหนดความยาวของเส้นเวลา */
  duration: number;
}

/**
 * ข้อความแจ้งที่หายเองหลัง [duration] ms (ค่าเริ่มต้น 3 วินาที) พร้อมข้อมูลให้วาดเส้นเวลา
 *
 * - เอาเมาส์ชี้หรือโฟกัสคีย์บอร์ดอยู่ที่ข้อความ = หยุดนับ (อ่านไม่ทัน/กำลังจะกดปุ่มปิด) ; ออกแล้วนับต่อจากเวลาที่เหลือ
 * - แสดงพร้อมกันได้สูงสุด [max] อัน (ใหม่สุด) ; อันเก่ากว่านั้นไม่แสดงแต่ยังนับเวลาต่อ
 * - ข้อความที่หายแล้วถูกลบออกจากรายการ [notices] จริง
 */
export function useToasts(notices: Ref<Notice[]>, opts: { duration?: number; max?: number } = {}) {
  const duration = opts.duration ?? 3000;
  const max = opts.max ?? 3;

  interface Life {
    id: number;
    start: number; // เวลาที่เริ่ม/เริ่มนับต่อล่าสุด
    left: number; // เวลาที่เหลือ ณ [start]
    timer: ReturnType<typeof setTimeout> | undefined;
  }
  const lives = new WeakMap<Notice, Life>();
  const tracked = new Set<Notice>();
  const paused = ref<Set<number>>(new Set());
  let nextId = 1;

  function remove(n: Notice) {
    const life = lives.get(n);
    if (life?.timer !== undefined) clearTimeout(life.timer);
    lives.delete(n);
    tracked.delete(n);
    const i = notices.value.indexOf(n);
    if (i >= 0) notices.value = notices.value.filter((x) => x !== n);
  }

  function run(n: Notice, life: Life) {
    life.start = Date.now();
    life.timer = setTimeout(() => remove(n), life.left);
  }

  // ข้อความใหม่ที่เพิ่งเข้ามา → เริ่มนับ ; ข้อความที่ถูกลบจากข้างนอก (ล้างทั้งหมด) → เลิกนับ
  watch(
    notices,
    (list) => {
      for (const n of list) {
        if (lives.has(n)) continue;
        const life: Life = { id: nextId++, start: 0, left: duration, timer: undefined };
        lives.set(n, life);
        tracked.add(n);
        run(n, life);
      }
      for (const n of [...tracked]) {
        if (!list.includes(n)) {
          const life = lives.get(n);
          if (life?.timer !== undefined) clearTimeout(life.timer);
          lives.delete(n);
          tracked.delete(n);
        }
      }
    },
    { immediate: true, deep: false },
  );

  const toasts = computed<Toast[]>(() =>
    notices.value
      .map((n) => ({ ...n, id: lives.get(n)?.id ?? 0, duration }))
      .filter((n) => n.id !== 0)
      .slice(-max),
  );

  function find(id: number): [Notice, Life] | undefined {
    for (const n of tracked) {
      const life = lives.get(n);
      if (life?.id === id) return [n, life];
    }
    return undefined;
  }

  /** หยุดนับ (เมาส์ชี้/โฟกัส) */
  function pause(id: number) {
    const f = find(id);
    if (!f || paused.value.has(id)) return;
    const [, life] = f;
    if (life.timer !== undefined) clearTimeout(life.timer);
    life.timer = undefined;
    life.left = Math.max(0, life.left - (Date.now() - life.start));
    paused.value = new Set(paused.value).add(id);
  }

  /** นับต่อจากเวลาที่เหลือ */
  function resume(id: number) {
    const f = find(id);
    if (!f || !paused.value.has(id)) return;
    const next = new Set(paused.value);
    next.delete(id);
    paused.value = next;
    run(f[0], f[1]);
  }

  function dismiss(id: number) {
    const f = find(id);
    if (f) remove(f[0]);
  }

  onBeforeUnmount(() => {
    for (const n of tracked) {
      const life = lives.get(n);
      if (life?.timer !== undefined) clearTimeout(life.timer);
    }
  });

  return { toasts, paused, pause, resume, dismiss };
}
