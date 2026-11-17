import { type Color, alphaBlend, fromARGB32 } from './color';
import { contrastRatio } from './contrast';
import type { NslTokens } from './tokens';

/** หนึ่งการตรวจ contrast ระหว่างสีตัวอักษร/ไอคอนกับพื้น */
export interface ContrastCheck {
  name: string;
  fg: string;
  bg: string;
  ratio: number;
  min: number;
  passes: boolean;
}

/** ตรวจ contrast ตามกติกาในแผน (ข้อ 9) — รายการและเกณฑ์ตรงกับ checkContrast ฝั่ง Dart */
export function checkContrast(t: NslTokens): ContrastCheck[] {
  const c = t.colors;
  const backdrop = flatten(c.surface!, c.bg!);
  const chk = (fg: string, bg: string, min: number): ContrastCheck => {
    // สีโปร่งใส (#RRGGBBAA) วัดตามที่ตาเห็นจริง : พื้นโปร่งผสมบนพื้นด้านหลัง แล้วตัวอักษรโปร่งผสมบนพื้นนั้น
    const b = bg === 'surface' ? backdrop : flatten(c[bg]!, backdrop);
    const f = flatten(c[fg]!, b);
    const ratio = contrastRatio(f, b);
    return { name: `${fg}/${bg}`, fg, bg, ratio, min, passes: ratio >= min };
  };
  return [
    chk('text', 'surface', 4.5),
    chk('text', 'bg', 4.5),
    chk('textMuted', 'surface', 4.5),
    chk('accentInk', 'surface', 4.5),
    chk('onAccent', 'accent', 4.5),
    chk('dangerText', 'dangerBg', 4.5),
    chk('warnText', 'warnBg', 4.5),
    chk('infoText', 'infoBg', 4.5),
    chk('successText', 'successBg', 4.5),
    chk('border', 'surface', 1.3),
  ];
}

export const contrastFailures = (t: NslTokens): ContrastCheck[] => checkContrast(t).filter((k) => !k.passes);

/** ธีมที่ใช้ไม่ได้จริง (ตัวอักษรหลักเทียบพื้นต่ำกว่า 3:1) — แอปจะถอยไปธีมในตัว */
export function isUnusable(t: NslTokens): boolean {
  const c = t.colors;
  const surface = flatten(c.surface!, c.bg!);
  const bg = flatten(c.bg!, surface);
  return contrastRatio(flatten(c.text!, bg), bg) < 3 || contrastRatio(flatten(c.text!, surface), surface) < 3;
}

/** ผสมสีโปร่งใส x บนพื้นด้านหลัง back (ถ้าด้านหลังก็โปร่งใส ใช้ดำเป็นฐาน) ; สีทึบคืนค่าเดิม */
function flatten(x: Color, back: Color): Color {
  return x.a >= 1 ? x : alphaBlend(x, back.a >= 1 ? back : fromARGB32(0xff000000));
}
