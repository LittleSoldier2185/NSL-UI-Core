import type { Lang } from './i18n';

/**
 * ชื่อสีที่คนอ่านเข้าใจ (แสดงคู่กับชื่อ token) — token ที่ไม่มีในตารางใช้ชื่อ token ตรง ๆ
 * เป็นข้อความหน้าเว็บเท่านั้น ไม่เกี่ยวกับไฟล์ .nslt
 */
const names: Record<string, Record<Lang, string>> = {
  bg: { th: 'พื้นหลัง', en: 'Background' },
  chrome: { th: 'แถบหน้าต่าง', en: 'Window chrome' },
  surface: { th: 'พื้นการ์ด', en: 'Card surface' },
  surfaceRaised: { th: 'พื้นยก (เมนู/ไดอะล็อก)', en: 'Raised (menus/dialogs)' },
  surfaceSunken: { th: 'พื้นจม (ช่อง/ราง)', en: 'Sunken (wells/tracks)' },
  hover: { th: 'พื้นตอนชี้', en: 'Hover' },
  selected: { th: 'พื้นที่เลือก', en: 'Selected' },
  borderSoft: { th: 'เส้นแบ่งอ่อน', en: 'Soft divider' },
  border: { th: 'เส้นขอบ', en: 'Border' },
  borderStrong: { th: 'เส้นขอบชัด', en: 'Strong border' },
  text: { th: 'ตัวอักษรหลัก', en: 'Main text' },
  textMuted: { th: 'ตัวอักษรรอง', en: 'Secondary text' },
  textFaint: { th: 'ตัวอักษรจาง', en: 'Faint text' },
  icon: { th: 'ไอคอน', en: 'Icons' },
  accent: { th: 'สีหลัก', en: 'Accent' },
  accentInk: { th: 'ตัวอักษรสีหลัก (ลิงก์)', en: 'Accent text (links)' },
  accentTint: { th: 'พื้นสีหลักอ่อน', en: 'Accent tint' },
  onAccent: { th: 'ตัวอักษรบนปุ่มหลัก', en: 'Text on accent' },
  accentBorder: { th: 'เส้นขอบสีหลัก', en: 'Accent border' },
  danger: { th: 'อันตราย', en: 'Danger' },
  dangerBg: { th: 'พื้นอันตราย', en: 'Danger background' },
  dangerText: { th: 'ตัวอักษรอันตราย', en: 'Danger text' },
  warnBg: { th: 'พื้นเตือน', en: 'Warning background' },
  warnText: { th: 'ตัวอักษรเตือน', en: 'Warning text' },
  infoBg: { th: 'พื้นข้อมูล', en: 'Info background' },
  infoText: { th: 'ตัวอักษรข้อมูล', en: 'Info text' },
  success: { th: 'สำเร็จ', en: 'Success' },
  successBg: { th: 'พื้นสำเร็จ', en: 'Success background' },
  successText: { th: 'ตัวอักษรสำเร็จ', en: 'Success text' },
  shadow: { th: 'เงา', en: 'Shadow' },
};

export const colorName = (key: string, lang: Lang): string => names[key]?.[lang] ?? key;

/** ข้อความค้นหาตรงกับสีนี้ไหม (ชื่อ token, ชื่อไทย, ชื่ออังกฤษ ; ไม่สนตัวพิมพ์) */
export function colorMatches(key: string, query: string): boolean {
  const q = query.trim().toLowerCase();
  if (q === '') return true;
  const n = names[key];
  return [key, n?.th ?? '', n?.en ?? ''].some((s) => s.toLowerCase().includes(q));
}
