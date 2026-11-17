// ฟอนต์ที่ผู้ใช้เลือกจากเครื่องเพื่อดูพรีวิว — อยู่ในหน่วยความจำของหน้านี้เท่านั้น (ไม่อัปโหลด ไม่บันทึก ปิดหน้าแล้วหาย)
// ไฟล์ธีม .nslt เก็บแค่ "ชื่อ family" ; ผู้ใช้ต้องนำไฟล์ฟอนต์เข้าแอปเองด้วย
import { type Ref, ref } from 'vue';
import { type FontInfo, inspectFontBytes, isReservedFamily, kMaxFontBytes } from './core/fontInfo';

export interface UserFont {
  family: string;
  info: FontInfo;
}

export type AddResult = { ok: true; family: string } | { ok: false; error: string };

/** จำนวนฟอนต์สูงสุดที่เปิดพรีวิวพร้อมกัน */
export const kMaxPreviewFonts = 12;

export interface FontLibrary {
  fonts: Ref<UserFont[]>;
  add: (file: File) => Promise<AddResult>;
  remove: (family: string) => void;
  infoOf: (family: string | undefined) => FontInfo | undefined;
  dispose: () => void;
}

export function useFontLibrary(): FontLibrary {
  const fonts = ref<UserFont[]>([]);
  const faces = new Map<string, FontFace>();

  const dropFace = (family: string) => {
    const f = faces.get(family);
    if (f && typeof document !== 'undefined' && document.fonts) document.fonts.delete(f);
    faces.delete(family);
  };

  const add = async (file: File): Promise<AddResult> => {
    if (file.size > kMaxFontBytes) return { ok: false, error: 'font file too large' };
    const buf = await file.arrayBuffer();
    const r = inspectFontBytes(new Uint8Array(buf));
    if (!r.ok) return { ok: false, error: r.error };
    const family = r.info.familyName;
    if (family === undefined) return { ok: false, error: 'font has no readable family name' };
    if (isReservedFamily(family)) return { ok: false, error: `"${family}" is reserved (built-in fallback font)` };
    const replacing = fonts.value.some((f) => f.family === family);
    if (!replacing && fonts.value.length >= kMaxPreviewFonts) return { ok: false, error: 'too many fonts — remove one first' };
    if (typeof FontFace !== 'undefined' && typeof document !== 'undefined' && document.fonts) {
      try {
        const face = new FontFace(family, buf.slice(0));
        await face.load();
        dropFace(family);
        document.fonts.add(face);
        faces.set(family, face);
      } catch {
        return { ok: false, error: 'cannot be loaded as a font' };
      }
    }
    fonts.value = [...fonts.value.filter((f) => f.family !== family), { family, info: r.info }];
    return { ok: true, family };
  };

  const remove = (family: string) => {
    dropFace(family);
    fonts.value = fonts.value.filter((f) => f.family !== family);
  };

  const infoOf = (family: string | undefined) => (family === undefined ? undefined : fonts.value.find((f) => f.family === family)?.info);

  const dispose = () => {
    for (const f of [...faces.keys()]) dropFace(f);
    fonts.value = [];
  };

  return { fonts, add, remove, infoOf, dispose };
}
