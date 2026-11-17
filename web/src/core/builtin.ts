import builtinTexts from '../generated/builtin-themes.json';
import { parseNslt } from './nslt';
import type { ThemeLookup } from './resolve';
import type { ThemeSpec } from './spec';

// ธีมในตัวถูกสร้างโดยฝั่ง Dart (test/web_fixtures_test.dart เขียน src/generated/builtin-themes.json) แล้วอ่านผ่าน parser เดียวกับไฟล์ผู้ใช้
// จึงไม่มีสำเนาค่าสีของธีมในตัวในโค้ดฝั่งเว็บ

export const kBuiltinDefaultId = 'nsl.default';
export const kBuiltinNebularId = 'nsl.nebular';
export const kBuiltinSpectrumId = 'nsl.spectrum';
export const kBuiltinLyraPaperId = 'nsl.lyra.paper';
export const kBuiltinOrbitId = 'nsl.orbit';

export const builtinSpecs: Readonly<Record<string, ThemeSpec>> = Object.fromEntries(
  Object.entries(builtinTexts as Record<string, string>).map(([id, text]) => {
    const r = parseNslt(text);
    if (!r.spec) throw new Error(`built-in theme "${id}" is unreadable: ${r.errors.join('; ')}`);
    return [id, r.spec];
  }),
);

export const builtinIds: readonly string[] = Object.keys(builtinSpecs);

export const builtinById = (id: string): ThemeSpec | undefined => builtinSpecs[id];

/** หาธีมจากธีมของผู้ใช้ก่อน แล้วค่อยธีมในตัว */
export function makeLookup(user: Readonly<Record<string, ThemeSpec>> = {}): ThemeLookup {
  return (id) => user[id] ?? builtinSpecs[id];
}
