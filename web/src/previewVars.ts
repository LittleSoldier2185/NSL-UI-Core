import { toHex } from './core/color';
import type { NslTokens } from './core/tokens';

/**
 * token → CSS variables ของพรีวิว (HTML/CSS ประมาณการ ไม่ใช่ widget จริง)
 * `--c-<สี core>` · `--e-<ส่วนขยาย>-<คีย์>` · `--r-*` มุมโค้ง · `--fs*` ขนาดตัวอักษร · `--pad*` ระยะ · `--shadow` · `--flat-border`
 */
export function cssVars(tk: NslTokens): Record<string, string> {
  const v: Record<string, string> = {};
  for (const [k, c] of Object.entries(tk.colors)) v[`--c-${k}`] = toHex(c);
  for (const [name, vals] of Object.entries(tk.extensions)) {
    for (const [k, c] of Object.entries(vals)) v[`--e-${name}-${k}`] = toHex(c);
  }
  const r = tk.shape;
  v['--r-xs'] = `${r.xs}px`;
  v['--r-sm'] = `${r.sm}px`;
  v['--r-md'] = `${r.md}px`;
  v['--r-lg'] = `${r.lg}px`;
  v['--r-xl'] = `${r.xl}px`;
  v['--r-pill'] = `${Math.min(r.pill, 999)}px`;
  const size = (px: number) => `${Math.max(px * tk.type.scale, tk.type.minSize ?? 0)}px`;
  v['--fs'] = size(14);
  v['--fs-sm'] = size(12);
  v['--fs-lg'] = size(18);
  const pad = tk.density === 'compact' ? 0.6 : tk.density === 'comfortable' ? 1.4 : 1;
  v['--pad'] = `${8 * pad}px`;
  v['--pad-lg'] = `${14 * pad}px`;
  const sh = tk.elevation;
  v['--shadow'] = sh.mode === 'flat' ? 'none' : `0 ${2 * sh.strength}px ${12 * sh.strength}px ${toHex({ ...tk.colors.shadow!, a: Math.min(1, 0.18 * sh.strength) })}`;
  v['--flat-border'] = sh.mode === 'flat' ? `1px solid ${toHex(tk.colors.border!)}` : '1px solid transparent';
  if (tk.type.family) v['--ff'] = `"${tk.type.family}", "Noto Sans Thai", system-ui, sans-serif`;
  if (tk.type.mono) v['--ff-mono'] = `"${tk.type.mono}", ui-monospace, monospace`;
  if (tk.type.content) v['--ff-content'] = `"${tk.type.content}", "Noto Serif Thai", Georgia, serif`;
  return v;
}
