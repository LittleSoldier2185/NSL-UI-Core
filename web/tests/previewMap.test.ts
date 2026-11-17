// @vitest-environment jsdom
// ตัวอ่าน "ชิ้นไหนในพรีวิวแสดง token อะไร" จาก CSS จริง
import { afterEach, describe, expect, it } from 'vitest';
import { tokenElements, tokensIn } from '../src/previewMap';

afterEach(() => {
  document.head.innerHTML = '';
  document.body.innerHTML = '';
});

describe('tokensIn', () => {
  it('อ่านสี core, ส่วนขยาย, เงา และขอบแบบแบน', () => {
    expect(tokensIn('color: var(--c-accent); background: linear-gradient(var(--c-surface), var(--e-spectrum-panelBottom))').sort()).toEqual(
      ['accent', 'spectrum.panelBottom', 'surface'].sort(),
    );
    expect(tokensIn('box-shadow: var(--shadow); border: var(--flat-border)').sort()).toEqual(['border', 'shadow']);
    expect(tokensIn('padding: var(--pad); border-radius: var(--r-md)')).toEqual([]);
  });
});

describe('tokenElements', () => {
  it('จับคู่ selector ของกฎ CSS กับ element, รวมแอตทริบิวต์ inline/SVG, ตัด :hover ออก', () => {
    document.head.innerHTML = `<style>
      .a { color: var(--c-text); }
      /* ความเห็น { ไม่ใช่กฎ } */
      @media (min-width: 1px) { .b { background: var(--c-accent); } }
      .c:hover { background: var(--c-hover); }
      .none { padding: 4px; }
    </style>`;
    document.body.innerHTML = `<section class="root a">
      <span class="b">x</span><span class="c">y</span><span class="none">z</span>
      <svg><line stroke="var(--e-lyra-edge)" /></svg>
      <i style="background: var(--c-danger)"></i>
    </section>`;
    const root = document.querySelector('section')!;
    const m = tokenElements(root);
    expect(m.get('text')).toEqual([root]);
    expect(m.get('accent')!.map((e) => e.className)).toEqual(['b']);
    expect(m.get('hover')!.map((e) => e.className)).toEqual(['c']);
    expect(m.get('lyra.edge')!.map((e) => e.tagName.toLowerCase())).toEqual(['line']);
    expect(m.get('danger')!.map((e) => e.tagName.toLowerCase())).toEqual(['i']);
    expect(m.has('padding')).toBe(false);
  });

  it('selector ที่ querySelectorAll ไม่รับ (::before) ถูกข้าม ไม่โยน', () => {
    document.head.innerHTML = '<style>.a::before { color: var(--c-text); } .a { color: var(--c-icon); }</style>';
    document.body.innerHTML = '<div class="a"></div>';
    expect([...tokenElements(document.querySelector('div')!).keys()]).toEqual(['icon']);
  });
});
