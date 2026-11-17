/**
 * อ่านจาก CSS จริงว่าชิ้นไหนในพรีวิวแสดง token อะไร — ไม่ต้องติดป้ายด้วยมือ จึงตรงกับพรีวิวเสมอ
 *
 * token id : สี core = ชื่อคีย์ (`accent`) ; ส่วนขยาย = `แอป.คีย์` (`nebular.tableHead`)
 * แหล่งที่อ่าน : กฎ CSS ทุกกฎในหน้า (`var(--c-…)`, `var(--e-แอป-…)`, `var(--shadow)` = สี shadow, `var(--flat-border)` = border)
 * และค่าในแอตทริบิวต์ของ element เอง (เช่น `stroke="var(--e-lyra-edge)"` ใน SVG, style แบบ inline)
 */

const VAR_RE = /var\(--(c|e)-([A-Za-z0-9]+)(?:-([A-Za-z0-9]+))?\)|var\(--(shadow|flat-border)\)/g;

/** token ทั้งหมดที่ข้อความ CSS นี้อ้างถึง */
export function tokensIn(css: string): string[] {
  const out = new Set<string>();
  for (const m of css.matchAll(VAR_RE)) {
    if (m[1] === 'c') out.add(m[2]!);
    else if (m[1] === 'e' && m[3]) out.add(`${m[2]}.${m[3]}`);
    else if (m[4] === 'shadow') out.add('shadow');
    else if (m[4] === 'flat-border') out.add('border');
  }
  return [...out];
}

/** กฎ CSS (selector, เนื้อกฎ) จากข้อความ — เอาเฉพาะกฎชั้นในสุด (กฎใน @media ก็ได้) */
function rulesFromText(css: string): [string, string][] {
  const out: [string, string][] = [];
  const clean = css.replace(/\/\*[\s\S]*?\*\//g, '');
  for (const m of clean.matchAll(/([^{}]+)\{([^{}]*)\}/g)) out.push([m[1]!.trim(), m[2]!]);
  return out;
}

/** กฎทั้งหมดในหน้า : <style> อ่านจากข้อความ (dev/เทสต์) ; ไฟล์ CSS แยก อ่านจาก cssRules (build จริง) */
function allRules(doc: Document): [string, string][] {
  const out: [string, string][] = [];
  for (const sheet of [...doc.styleSheets]) {
    const owner = sheet.ownerNode;
    if (owner instanceof HTMLStyleElement && owner.textContent) {
      out.push(...rulesFromText(owner.textContent));
      continue;
    }
    let rules: CSSRuleList;
    try {
      rules = sheet.cssRules;
    } catch {
      continue; // stylesheet ต่างโดเมน อ่านไม่ได้
    }
    const walk = (list: CSSRuleList) => {
      for (const r of [...list]) {
        if ('selectorText' in r && 'style' in r) out.push([(r as CSSStyleRule).selectorText, (r as CSSStyleRule).style.cssText]);
        else if ('cssRules' in r) walk((r as CSSGroupingRule).cssRules);
      }
    };
    walk(rules);
  }
  return out;
}

/** token → element ใน [root] ที่แสดง token นั้น */
export function tokenElements(root: Element): Map<string, Element[]> {
  const map = new Map<string, Element[]>();
  const add = (tok: string, el: Element) => {
    const list = map.get(tok);
    if (!list) map.set(tok, [el]);
    else if (!list.includes(el)) list.push(el);
  };
  for (const [selector, body] of allRules(root.ownerDocument)) {
    const toks = tokensIn(body);
    if (toks.length === 0) continue;
    let els: Element[];
    try {
      // :hover / :focus ฯลฯ ไม่ตรงตอนนี้ — ตัดออกเพื่อชี้ element ที่ "จะ" แสดงสีนั้น
      const sel = selector.replace(/:(hover|focus|focus-visible|active)\b/g, '');
      els = [...root.querySelectorAll(sel)];
      if (root.matches(sel)) els.push(root);
    } catch {
      continue; // selector ที่ querySelectorAll ไม่รับ (เช่น ::before)
    }
    for (const el of els) for (const t of toks) add(t, el);
  }
  for (const el of [root, ...root.querySelectorAll('*')]) {
    for (const a of [...el.attributes]) {
      if (!a.value.includes('var(--')) continue;
      for (const t of tokensIn(a.value)) add(t, el);
    }
  }
  return map;
}
