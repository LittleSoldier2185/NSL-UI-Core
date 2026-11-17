import { toHex } from './core/color';
import type { NslTokens } from './core/tokens';

/**
 * token → CSS variables ของพรีวิว (HTML/CSS ประมาณการ ไม่ใช่ widget จริง)
 * `--c-<สี core>` · `--e-<ส่วนขยาย>-<คีย์>` · `--r-*` มุมโค้ง · `--fs*` ขนาดตัวอักษร · `--pad*` ระยะ · `--shadow` · `--flat-border`
 */
export function cssVars(tk: NslTokens, thaiFirst: readonly string[] = []): Record<string, string> {
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
  const names = (...f: (string | undefined)[]) => f.filter((x): x is string => !!x).map((x) => `"${x}"`);
  /** ลำดับ ละติน → ไทย (ไทยก่อนเมื่อแผนสั่ง หรือเมื่อมีแต่ช่องไทย) ให้ตรงกับ NslType.fallback ฝั่งแอป */
  const order = (role: string, latin?: string, thai?: string) => (thai && (!latin || thaiFirst.includes(role)) ? [thai, latin] : [latin, thai]);
  if (tk.type.family || tk.type.familyThai) v['--ff'] = [...names(...order('family', tk.type.family, tk.type.familyThai), 'Noto Sans Thai'), 'system-ui', 'sans-serif'].join(', ');
  if (tk.type.mono || tk.type.monoThai) v['--ff-mono'] = [...names(...order('mono', tk.type.mono, tk.type.monoThai)), 'ui-monospace', 'monospace'].join(', ');
  if (tk.type.content || tk.type.contentThai) v['--ff-content'] = [...names(...order('content', tk.type.content, tk.type.contentThai), 'Noto Serif Thai'), 'Georgia', 'serif'].join(', ');
  return v;
}
