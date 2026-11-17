import { computed, ref } from 'vue';

export type Lang = 'th' | 'en';

const dict = {
  title: { th: 'NSL Palette', en: 'NSL Palette' },
  subtitle: { th: 'สร้างไฟล์ธีม .nslt สำหรับแอป NSL', en: 'Make .nslt theme files for NSL apps' },
  coreVersion: { th: 'เวอร์ชัน core', en: 'Core version' },
  otherVersions: { th: 'เวอร์ชันอื่น (ใช้ให้ตรงกับแอปของคุณ)', en: 'Other versions (match your app)' },
  versionHint: {
    th: 'ดูเวอร์ชัน core ที่แอปใช้ได้ที่ Settings ของแอป ถ้าแอปเก่ากว่า ให้เลือกเวอร์ชันเว็บให้ตรง',
    en: 'Your app shows its core version in Settings. If it is older, pick the matching web version.',
  },
  language: { th: 'ภาษา', en: 'Language' },
  theme: { th: 'ธีม', en: 'Theme' },
  name: { th: 'ชื่อธีม', en: 'Theme name' },
  id: { th: 'รหัส (ชื่อไฟล์)', en: 'ID (file name)' },
  idAuto: { th: 'ตั้งอัตโนมัติจากชื่อ', en: 'Auto from name' },
  base: { th: 'ธีมฐาน (สืบทอดค่า)', en: 'Base theme (inherits)' },
  importFiles: { th: 'นำเข้าไฟล์ .nslt', en: 'Import .nslt' },
  importHint: { th: 'เลือกได้หลายไฟล์ — ไฟล์แรกเป็นธีมที่แก้ไข ที่เหลือใช้เป็นธีมฐานได้', en: 'Pick several — the first is edited, others can be used as bases' },
  download: { th: 'ดาวน์โหลด .nslt', en: 'Download .nslt' },
  copy: { th: 'คัดลอกข้อความ', en: 'Copy text' },
  copied: { th: 'คัดลอกแล้ว', en: 'Copied' },
  reset: { th: 'ล้างการแก้ไขทั้งหมด', en: 'Reset all edits' },
  quickAccent: { th: 'ตั้งสี accent แบบเร็ว', en: 'Quick accent' },
  quickAccentHint: { th: 'เลือกสีเดียว ระบบคำนวณชุดสี accent ของทั้งสองโหมดให้อ่านได้', en: 'Pick one colour; accent sets for both modes are derived to stay readable' },
  presets: { th: 'สีสำเร็จรูป', en: 'Presets' },
  customColour: { th: 'สีกำหนดเอง', en: 'Custom colour' },
  applyAccent: { th: 'ใช้กับธีม', en: 'Apply' },
  tabColors: { th: 'สี', en: 'Colours' },
  tabExt: { th: 'ส่วนขยายต่อแอป', en: 'Per-app' },
  tabShape: { th: 'รูปทรง/ตัวอักษร', en: 'Shape & type' },
  tabStyle: { th: 'ความหนาแน่น/เงา', en: 'Density & shadow' },
  editing: { th: 'กำลังแก้โหมด', en: 'Editing mode' },
  light: { th: 'สว่าง', en: 'Light' },
  dark: { th: 'มืด', en: 'Dark' },
  inherited: { th: 'สืบทอดจากธีมฐาน/คำนวณ', en: 'Inherited / derived' },
  overridden: { th: 'กำหนดเอง', en: 'Overridden' },
  clear: { th: 'ใช้ค่าเดิม', en: 'Use inherited' },
  radius: { th: 'มุมโค้ง (px)', en: 'Corner radius (px)' },
  fontFamily: { th: 'ฟอนต์ UI', en: 'UI font' },
  fontContent: { th: 'ฟอนต์เนื้อหา', en: 'Content font' },
  fontMono: { th: 'ฟอนต์ mono', en: 'Mono font' },
  fontHint: { th: 'ใส่ชื่อฟอนต์ที่แอปมี — ไม่มีในเครื่อง = ตกไปฟอนต์สำรอง (Noto Sans Thai ปิดท้ายเสมอ)', en: 'Use a font name the app has; missing fonts fall back (Noto Sans Thai is always last)' },
  scale: { th: 'สัดส่วนตัวอักษร', en: 'Font scale' },
  minSize: { th: 'ขนาดตัวอักษรขั้นต่ำ', en: 'Minimum font size' },
  density: { th: 'ความหนาแน่น', en: 'Density' },
  densityHint: { th: 'มีผลกับ widget มาตรฐานของแอปเท่านั้น ไม่รวมแคนวาสและเลย์เอาต์ที่แอปกำหนดตายตัว', en: 'Affects standard widgets only — not canvases or layouts fixed by the app' },
  elevationMode: { th: 'การแสดงเงา', en: 'Elevation' },
  shadow: { th: 'เงา', en: 'Shadow' },
  flat: { th: 'แบน (ใช้เส้นขอบแทน)', en: 'Flat (borders instead)' },
  strength: { th: 'ความเข้มเงา', en: 'Shadow strength' },
  compact: { th: 'แน่น', en: 'Compact' },
  normal: { th: 'ปกติ', en: 'Normal' },
  comfortable: { th: 'โปร่ง', en: 'Comfortable' },
  default: { th: 'ค่าเริ่มต้น', en: 'Default' },
  preview: { th: 'ตัวอย่าง', en: 'Preview' },
  previewNote: {
    th: 'เป็นตัวอย่างโดยประมาณด้วย HTML/CSS — รูปทรงปุ่ม เงา และขนาดตัวอักษรอาจต่างจาก widget จริงของแอปเล็กน้อย แต่สีคำนวณด้วยสูตรเดียวกับแอป',
    en: 'Approximate HTML/CSS preview — shapes, shadows and sizes may differ slightly from the real app widgets, but colours use the same formulas.',
  },
  contrast: { th: 'ความอ่านออก (contrast)', en: 'Readability (contrast)' },
  autoFix: { th: 'แก้ให้ผ่านอัตโนมัติ', en: 'Auto-fix' },
  autoFixed: { th: 'ปรับแล้ว {n} ค่า', en: 'Adjusted {n} value(s)' },
  nothingToFix: { th: 'ไม่มีรายการที่ต้องแก้', en: 'Nothing to fix' },
  allPass: { th: 'ผ่านทุกข้อ', en: 'All checks pass' },
  pass: { th: 'ผ่าน', en: 'Pass' },
  failed: { th: 'ไม่ผ่าน', en: 'Fail' },
  unusable: { th: 'ธีมนี้อ่านไม่ออกจริง (ตัวอักษรหลักต่ำกว่า 3:1) แอปจะถอยไปใช้ธีมในตัว', en: 'Unreadable theme (main text below 3:1) — apps fall back to the built-in theme' },
  cannotResolve: { th: 'ใช้ธีมนี้ไม่ได้:', en: 'Cannot use this theme:' },
  notices: { th: 'ข้อความจากระบบ', en: 'Messages' },
  errImport: { th: 'นำเข้าไม่ได้:', en: 'Cannot import:' },
  warnImport: { th: 'คำเตือนตอนอ่านไฟล์:', en: 'Warnings while reading:' },
  appsInferred: { th: 'จัดหมวดอัตโนมัติจากส่วนขยายในไฟล์ : {apps} (ไฟล์นี้ไม่ได้ระบุ apps — ส่งออกจะไม่เขียนเพิ่มจนกว่าจะปรับการเลือกแอป)', en: 'Categorised automatically from the extensions in the file: {apps} (no "apps" in the file — not added on export until you change the app selection)' },
  baseMissing: { th: 'ไม่พบธีมฐาน "{id}" — เปลี่ยนเป็น "{to}" (เลือกใหม่ได้)', en: 'Base "{id}" not found — switched to "{to}" (change it if needed)' },
  reservedId: { th: 'รหัสที่ขึ้นต้นด้วย nsl. สงวนไว้สำหรับธีมในตัว — แอปจะไม่รับไฟล์นี้', en: 'IDs starting with nsl. are reserved for built-in themes — apps reject this file' },
  badId: { th: 'รหัสต้องเป็น a-z 0-9 . _ - (ขึ้นต้นด้วยตัวอักษรหรือตัวเลข ไม่เกิน 64 ตัว)', en: 'ID must be a-z 0-9 . _ - (start with a letter or digit, max 64)' },
  tooBig: { th: 'ไฟล์ใหญ่เกิน 64 KB แอปจะไม่รับ', en: 'File over 64 KB — apps reject it' },
  howToUse: { th: 'วิธีใช้ไฟล์', en: 'How to use the file' },
  howWindows: {
    th: 'Windows: วางไฟล์ในโฟลเดอร์ Documents\\NSL\\Themes แล้วทุกแอปจะเห็นทันที (หรือนำเข้าผ่านปุ่มในแอปหรือ NSL Launcher)',
    en: 'Windows: put the file in Documents\\NSL\\Themes — every app sees it live (or import it from the app or NSL Launcher)',
  },
  howAndroid: {
    th: 'Android: ใช้ปุ่มนำเข้าธีมใน Settings ของแต่ละแอป (ไม่มี Launcher บน Android และแอปแชร์ธีมกันไม่ได้ ต้องนำเข้าทีละแอป)',
    en: 'Android: use the theme import in each app’s Settings (no Launcher on Android and apps cannot share themes — import per app)',
  },
  forApps: { th: 'ทำธีมนี้ให้แอปไหน', en: 'Which apps is this theme for?' },
  forAppsHint: {
    th: 'เลือกได้หลายแอป (อย่างน้อยหนึ่ง) — ใช้เป็นตัวช่วยตอนแก้ไขเท่านั้น ไฟล์ธีมเดียวกันใช้ได้กับทุกแอป',
    en: 'Pick one or more — this only guides editing; the same file works in every app.',
  },
  status_experiment: { th: 'รองรับในสำเนาทดลอง (แอปจริงยังไม่อ่านไฟล์ธีม)', en: 'Supported in the experimental copy (the real app does not read theme files yet)' },
  status_planned: { th: 'ยังไม่ได้ย้ายมาใช้ core — ค่าที่ตั้งยังไม่มีผลกับแอปนี้', en: 'Not migrated to the core yet — settings have no effect here' },
  supportTitle: { th: 'แอปรับค่าอะไรจากธีมได้บ้าง', en: 'What each app takes from a theme' },
  supportNote: {
    th: 'ตารางนี้เขียนตามผลการย้ายในสำเนาทดลอง (ตรวจล่าสุด 2026-11-16) ไม่ได้อ่านจากแอปจริง',
    en: 'Hand-written from the experimental migrations (checked 2026-11-16); not read from the real apps.',
  },
  sup_full: { th: 'ครบ', en: 'Full' },
  sup_partial: { th: 'บางส่วน (เฉพาะ widget มาตรฐาน)', en: 'Partial (standard widgets only)' },
  sup_none: { th: 'ยังไม่มีผล', en: 'No effect yet' },
  sup_unknown: { th: 'ยังไม่ได้ตรวจ', en: 'Not checked' },
  area_colors: { th: 'สี core', en: 'Core colours' },
  area_accent: { th: 'accent / โหมด (lite)', en: 'Accent / mode (lite)' },
  area_ext: { th: 'ส่วนขยายของแอป', en: 'App extension' },
  area_shape: { th: 'มุมโค้ง', en: 'Corner radius' },
  area_type: { th: 'สัดส่วนตัวอักษร', en: 'Font scale' },
  area_fonts: { th: 'ชื่อฟอนต์', en: 'Font names' },
  area_density: { th: 'ความหนาแน่น', en: 'Density' },
  area_elevation: { th: 'เงา', en: 'Shadow' },
  previewFor: { th: 'ดูหน้าตาของ', en: 'Preview as' },
  generic: { th: 'ทั่วไป', en: 'Generic' },
  showOtherExt: { th: 'แสดงส่วนขยายของแอปอื่นด้วย', en: 'Show other apps extensions too' },
  laterExt: {
    th: 'ส่วนขยาย "{ext}" ({app}) เริ่มใน core {since} — ถ้าแอปของคุณใช้ core เก่ากว่านั้นจะข้ามค่าเหล่านี้ (ไม่พัง)',
    en: 'Extension "{ext}" ({app}) starts in core {since} — apps on an older core skip these values (nothing breaks).',
  },
  extOrbit: { th: 'Orbit ยังไม่มีค่าเฉพาะแอป', en: 'Orbit has no app-specific values yet' },
  group_surfaces: { th: 'พื้นผิว', en: 'Surfaces' },
  group_borders: { th: 'เส้นขอบ', en: 'Borders' },
  group_text: { th: 'ตัวอักษรและไอคอน', en: 'Text & icons' },
  group_accent: { th: 'สีเน้น (accent)', en: 'Accent' },
  group_status: { th: 'สถานะ', en: 'Status' },
  group_other: { th: 'อื่น ๆ', en: 'Other' },
  extNone: { th: 'ไม่มีค่าที่ต้องปรับ', en: 'Nothing to adjust' },
  extHint: { th: 'ค่าเหล่านี้ใช้เฉพาะแอปที่ระบุ — ถ้าไม่ระบุ ระบบคำนวณจากสี core ให้', en: 'Only used by the named app; if unset they are derived from core colours' },
  footer: { th: 'NSL Palette ทำงานในเบราว์เซอร์ทั้งหมด ไม่ส่งข้อมูลธีมของคุณไปที่ใด', en: 'NSL Palette runs entirely in your browser; your theme is never uploaded' },
} as const;

export type Key = keyof typeof dict;

const KEY = 'nsl-palette-lang';
function initial(): Lang {
  try {
    const v = localStorage.getItem(KEY);
    if (v === 'th' || v === 'en') return v;
  } catch {
    /* ไม่มี storage ก็ไม่เป็นไร */
  }
  return typeof navigator !== 'undefined' && navigator.language.toLowerCase().startsWith('en') ? 'en' : 'th';
}

export const lang = ref<Lang>(initial());

export function setLang(l: Lang): void {
  lang.value = l;
  try {
    localStorage.setItem(KEY, l);
  } catch {
    /* ignore */
  }
}

/** แปลข้อความ ({name} แทนค่าจาก params) */
export function t(key: Key, params: Record<string, string | number> = {}): string {
  let s: string = dict[key][lang.value];
  for (const [k, v] of Object.entries(params)) s = s.replaceAll(`{${k}}`, String(v));
  return s;
}

export const tr = computed(() => (key: Key, params: Record<string, string | number> = {}) => {
  void lang.value;
  return t(key, params);
});
