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

const deriveDev: Derive = (c, b) => {
  const light = b === 'light';
  return {
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
