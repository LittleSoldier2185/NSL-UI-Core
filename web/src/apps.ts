import { kBuiltinDefaultId, kBuiltinLyraPaperId, kBuiltinNebularId, kBuiltinSpectrumId } from './core/builtin';
import { schema } from './core/tokens';

export type AppId = 'nebular' | 'spectrum' | 'lyra' | 'orbit';

/** ระดับที่แอปรับค่าหมวดนั้นจากธีมได้ : full = ครบ, partial = เฉพาะ widget มาตรฐาน/บางส่วน, none = ยังไม่มีผล, unknown = ยังไม่ได้ตรวจ */
export type Support = 'full' | 'partial' | 'none' | 'unknown';

export type Area = 'colors' | 'accent' | 'ext' | 'shape' | 'type' | 'fonts' | 'density' | 'elevation';
export const areas: readonly Area[] = ['colors', 'accent', 'ext', 'shape', 'type', 'fonts', 'density', 'elevation'];

export interface AppInfo {
  id: AppId;
  name: string;
  product: string;
  /** ชื่อส่วนขยายใน schema (undefined = แอปนี้ยังไม่มีส่วนขยาย) */
  extension?: string;
  baseId: string;
  /** สถานะการย้ายมาใช้ core — เขียนเองตามบันทึกใน progress.md (ตรวจล่าสุด 2026-11-16) */
  status: 'experiment' | 'planned';
  support: Record<Area, Support>;
}

/**
 * ตารางความรองรับ — **เขียนมือ** ตามผลเฟส 3/5/9 ใน progress.md (ไม่ได้มาจาก Dart) ต้องอัปเดตเมื่อย้ายแอปเพิ่ม
 * หมายเหตุสำคัญ: ตอนนี้ยังเป็นสำเนาทดลอง แอปจริงยังไม่อ่านไฟล์ธีม
 */
export const apps: readonly AppInfo[] = [
  {
    id: 'nebular',
    name: 'Nebular',
    product: 'NSL Dev',
    extension: 'nebular',
    baseId: kBuiltinNebularId,
    status: 'experiment',
    support: { colors: 'full', accent: 'full', ext: 'full', shape: 'partial', type: 'partial', fonts: 'unknown', density: 'partial', elevation: 'full' },
  },
  {
    id: 'spectrum',
    name: 'Spectrum',
    product: 'NSL Resonance',
    extension: 'spectrum',
    baseId: kBuiltinSpectrumId,
    status: 'experiment',
    support: { colors: 'full', accent: 'full', ext: 'full', shape: 'none', type: 'partial', fonts: 'none', density: 'partial', elevation: 'none' },
  },
  {
    id: 'lyra',
    name: 'Lyra',
    product: 'NSL Writer Tools',
    extension: 'lyra',
    baseId: kBuiltinLyraPaperId,
    status: 'experiment',
    support: { colors: 'full', accent: 'full', ext: 'full', shape: 'none', type: 'none', fonts: 'none', density: 'none', elevation: 'none' },
  },
  {
    id: 'orbit',
    name: 'Orbit',
    product: 'NSL Utility',
    baseId: kBuiltinDefaultId,
    status: 'planned',
    support: { colors: 'none', accent: 'none', ext: 'none', shape: 'none', type: 'none', fonts: 'none', density: 'none', elevation: 'none' },
  },
];

export const allAppIds: readonly AppId[] = apps.map((a) => a.id);

export const appById = (id: AppId): AppInfo => apps.find((a) => a.id === id)!;

/** ธีมฐานเริ่มต้น : แอปเดียว = ธีมในตัวของแอปนั้น ; หลายแอป = ธีมกลาง nsl.default */
export function baseForApps(selected: readonly AppId[]): string {
  return selected.length === 1 ? appById(selected[0]!).baseId : kBuiltinDefaultId;
}

/** ส่วนขยายที่ต้องแสดงสำหรับแอปที่เลือก (ตามลำดับใน schema) */
export function extensionsFor(selected: readonly AppId[], showAll: boolean) {
  const names = new Set(selected.map((id) => appById(id).extension).filter((n): n is string => n !== undefined));
  return schema.extensions.filter((e) => showAll || names.has(e.name));
}

/** เวอร์ชัน core แบบตัวเลขสำหรับเทียบ */
export function coreNum(v: string): number {
  const [a, b] = v.split('.').map(Number);
  return (a ?? 0) * 1000 + (b ?? 0);
}

/** ส่วนขยายของแอปที่เลือกที่เริ่มหลัง core 1.0 → แอปรุ่นเก่าจะข้ามค่าเหล่านั้น (ไม่พัง) */
export function laterExtensions(selected: readonly AppId[]) {
  return extensionsFor(selected, false).filter((e) => coreNum(e.since) > coreNum('1.0'));
}
