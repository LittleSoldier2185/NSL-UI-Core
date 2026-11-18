import { type Color, alphaBlend, fromARGB32, lerp, withAlpha } from './color';
import { accentPresets } from './presets';
import { type Brightness, type Colors, schema } from './tokens';

type Derive = (core: Colors, b: Brightness) => Colors;

export interface ExtensionDef {
  name: string;
  keys: readonly string[];
  derive: Derive;
  accentDependents: readonly string[];
}

const mix = lerp;
const col = fromARGB32;

/** สีประจำชนิดเอกสารของ Nebular (ตรงกับ `_docLight`/`_deriveDocColors` ฝั่ง Dart): ชนิด → [หลัก, ตัวอักษรบนพื้นอ่อน, พื้นอ่อน] */
const docLight: Record<string, readonly [number, number, number]> = {
  Er: [0xff0f766e, 0xff0b5a54, 0xffe2f3f1],
  Dfd: [0xff2f6fb5, 0xff1e4f8a, 0xffe8eef8],
  Flow: [0xff6d4fc2, 0xff553ba0, 0xfff3f0fc],
  Wire: [0xffb7791f, 0xff8a5a12, 0xfffff4d6],
  Screen: [0xffb83b6b, 0xff8f2a52, 0xfffce8f0],
  Api: [0xff0e7490, 0xff155e75, 0xffe0f2f7],
};

function deriveDocColors(c: Colors, light: boolean): Colors {
  const white = col(0xffffffff);
  const out: Colors = {};
  for (const [name, [main, ink, tint]] of Object.entries(docLight)) {
    const m = col(main);
    if (light) {
      out[`doc${name}`] = m;
      out[`doc${name}Ink`] = col(ink);
      out[`doc${name}Tint`] = col(tint);
    } else {
      out[`doc${name}`] = mix(m, white, 0.2);
      out[`doc${name}Ink`] = mix(m, white, 0.55);
      out[`doc${name}Tint`] = alphaBlend(withAlpha(m, 0.2), c.surface!);
    }
  }
  return out;
}

const deriveDev: Derive = (c, b) => {
  const light = b === 'light';
  return {
    ...deriveDocColors(c, light),
    canvas: mix(c.bg!, c.surface!, 0.5),
    dot: c.border!,
    tableHead: light ? c.text! : mix(c.surface!, c.text!, 0.12),
    pkBg: col(light ? 0xfffdebd3 : 0xff4a3213),
    pkText: col(light ? 0xff8a4b08 : 0xfff5b66b),
    uqBg: col(light ? 0xffede9fe : 0xff2e2552),
    uqText: col(light ? 0xff5b21b6 : 0xffc4b0fa),
    nnBg: mix(c.surface!, c.text!, 0.1),
    nnText: mix(c.text!, c.surface!, 0.15),
    boardOutside: mix(c.bg!, col(0xff000000), light ? 0.05 : 0.3),
    boardEdge: mix(c.surface!, c.text!, 0.3),
    fkSource: col(light ? 0xffffe9a8 : 0xff5a4a12),
    fkChip: alphaBlend(withAlpha(c.accent!, 0.2), c.surface!),
  };
};

const deriveSpectrum: Derive = (c) => ({ panelBottom: mix(c.surface!, c.bg!, 0.7) });

const deriveLyra: Derive = (c, b) => {
  const dark = b === 'dark';
  const cat = (i: number): Color => (dark ? accentPresets[i]!.dark[0] : accentPresets[i]!.light[0]);
  return {
    body: c.text!,
    accentDark: mix(c.accent!, col(0xff000000), 0.15),
    summary: mix(c.text!, c.surface!, 0.12),
    snippet: mix(c.text!, c.surface!, 0.25),
    chipText: mix(c.text!, c.surface!, 0.18),
    border: mix(c.border!, c.borderStrong!, 0.5),
    dash: c.textFaint!,
    edge: c.textFaint!,
    navIndicator: c.selected!,
    typeCharacter: cat(6),
    typePlace: cat(5),
    typeOrg: cat(1),
    typeEvent: cat(4),
    typeItem: cat(2),
    typeRule: cat(0),
    typeSpecies: cat(3),
    statusIdeaBg: c.surfaceSunken!,
    statusIdeaFg: c.textMuted!,
    statusDraftBg: c.warnBg!,
    statusDraftFg: c.warnText!,
    statusCanonBg: c.successBg!,
    statusCanonFg: c.successText!,
  };
};

const derivers: Record<string, Derive> = { nebular: deriveDev, spectrum: deriveSpectrum, lyra: deriveLyra };

/** ส่วนขยายที่รู้จัก — รายชื่อคีย์และคีย์ที่ขึ้นกับ accent มาจาก schema, สูตร derive เขียนไว้ที่นี่ (ตรวจกับ fixture) */
export const knownExtensions: readonly ExtensionDef[] = schema.extensions.map((e) => {
  const derive = derivers[e.name];
  if (!derive) throw new Error(`no derive function for extension "${e.name}" — add it to extensions.ts`);
  return { name: e.name, keys: e.keys, derive, accentDependents: e.accentDependents };
});
