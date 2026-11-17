import { type ComputedRef, type Ref, computed, reactive, ref } from 'vue';
import { type AppId, allAppIds, appById, appsOfSpec, baseForApps, extensionsFor, laterExtensions } from './apps';
import { builtinIds, builtinSpecs, kBuiltinNebularId, makeLookup } from './core/builtin';
import { type Color, parseHex, toHex } from './core/color';
import { type ContrastCheck, checkContrast, contrastFailures, isUnusable } from './core/contrastReport';
import { type Draft, autoFix, defaultBaseId, draftFromSpec, draftToSpec, resolveDraft, slugify } from './core/draft';
import { isReservedThemeId, isValidThemeId, kNsltMaxBytes, parseNslt, serializeNslt } from './core/nslt';
import { ResolveError } from './core/resolve';
import { type ThemeSpec, newSpec } from './core/spec';
import { accentTints } from './core/tint';
import type { Brightness, NslTokens } from './core/tokens';
import { type Key, t } from './i18n';

export interface ModeView {
  tokens: NslTokens | null;
  error: string | null;
  checks: ContrastCheck[];
  failures: ContrastCheck[];
  unusable: boolean;
}

export interface Editor {
  draft: Draft;
  library: Record<string, ThemeSpec>;
  idAuto: Ref<boolean>;
  notices: Ref<{ kind: 'error' | 'warn' | 'info'; text: string }[]>;
  /** แอปที่ธีมนี้ทำให้ (เลือกได้หลายแอป อย่างน้อยหนึ่ง) — เป็นตัวช่วยตอนแก้ไข ไม่ได้เขียนลงไฟล์ */
  apps: Ref<AppId[]>;
  showAllExt: Ref<boolean>;
  toggleApp: (id: AppId) => void;
  /** ตั้งแอปทั้งชุด (ว่าง = ไม่เปลี่ยน — ต้องเหลืออย่างน้อยหนึ่งแอป) */
  setApps: (ids: readonly AppId[]) => void;
  setBase: (id: string) => void;
  visibleExtensions: ComputedRef<ReturnType<typeof extensionsFor>>;
  versionNotes: ComputedRef<ReturnType<typeof laterExtensions>>;
  baseChoices: ComputedRef<{ id: string; name: string; builtin: boolean }[]>;
  views: ComputedRef<Record<Brightness, ModeView>>;
  effectiveId: ComputedRef<string>;
  exportProblems: ComputedRef<string[]>;
  exportText: () => string;
  setColor: (mode: Brightness, key: string, value: Color | null) => void;
  setExt: (mode: Brightness, ext: string, key: string, value: Color | null) => void;
  setQuickAccent: (c: Color) => void;
  setRadius: (key: string, v: number | null) => void;
  runAutoFix: () => number;
  resetAll: () => void;
  importFiles: (files: { name: string; text: string }[]) => void;
  say: (kind: 'error' | 'warn' | 'info', text: string) => void;
}

/** `?apps=lyra,orbit` เลือกแอปตั้งแต่เปิดหน้า (ลิงก์ที่แชร์ได้) — ค่าที่ไม่รู้จักถูกข้าม ; ไม่มี/ว่าง = ทุกแอป */
export function appsFromQuery(search: string): AppId[] {
  const raw = new URLSearchParams(search).get('apps');
  if (!raw) return [...allAppIds];
  const wanted = new Set(raw.split(',').map((x) => x.trim().toLowerCase()));
  const picked = allAppIds.filter((id) => wanted.has(id));
  return picked.length > 0 ? picked : [...allAppIds];
}

function freshDraft(): Draft {
  return draftFromSpec(newSpec('my-theme', 'My theme', { extendsId: baseForApps(allAppIds) }));
}

/** สถานะและตรรกะของหน้าแก้ไขธีม (แยกจาก UI เพื่อให้ทดสอบได้) */
export function useEditor(): Editor {
  const draft = reactive(freshDraft()) as Draft;
  const library = reactive<Record<string, ThemeSpec>>({});
  const idAuto = ref(true);
  const apps = ref<AppId[]>(appsFromQuery(typeof location === 'undefined' ? '' : location.search));
  if (apps.value.length !== allAppIds.length) draft.baseId = baseForApps(apps.value);
  const showAllExt = ref(false);
  // ผู้ใช้เลือกธีมฐานเองแล้ว (หรือนำเข้าไฟล์) = เลิกเปลี่ยนธีมฐานตามแอปที่เลือก
  const baseTouched = ref(false);
  // จัดหมวดจากการเดา (ไฟล์ไม่ได้ระบุ apps) และผู้ใช้ยังไม่แตะการเลือกแอป = ไม่เขียน apps ลงไฟล์ตอนส่งออก (ไป-กลับได้ข้อความเท่าเดิม)
  const appsGuessed = ref(false);
  const notices = ref<{ kind: 'error' | 'warn' | 'info'; text: string }[]>([]);

  const visibleExtensions = computed(() => extensionsFor(apps.value, showAllExt.value));
  const versionNotes = computed(() => laterExtensions(apps.value));

  function toggleApp(id: AppId) {
    appsGuessed.value = false;
    if (apps.value.includes(id)) {
      if (apps.value.length === 1) return; // ต้องเหลืออย่างน้อยหนึ่งแอป
      apps.value = apps.value.filter((a) => a !== id);
    } else {
      apps.value = allAppIds.filter((a) => a === id || apps.value.includes(a));
    }
    if (!baseTouched.value) draft.baseId = baseForApps(apps.value);
  }

  function setApps(ids: readonly AppId[]) {
    const next = allAppIds.filter((a) => ids.includes(a));
    if (next.length === 0) return;
    appsGuessed.value = false;
    apps.value = next;
    if (!baseTouched.value) draft.baseId = baseForApps(apps.value);
  }

  function setBase(id: string) {
    draft.baseId = id;
    baseTouched.value = true;
  }

  const lookup = computed(() => makeLookup(library));

  const effectiveId = computed(() => (idAuto.value || draft.id === '' ? slugify(draft.name) : draft.id));

  const baseChoices = computed(() => [
    ...builtinIds.map((id) => ({ id, name: builtinSpecs[id]!.name, builtin: true })),
    ...Object.values(library)
      .filter((s) => s.id !== effectiveId.value)
      .map((s) => ({ id: s.id, name: s.name, builtin: false })),
  ]);

  function viewOf(b: Brightness): ModeView {
    try {
      const tokens = resolveDraft({ ...draft, id: effectiveId.value }, b, lookup.value);
      const checks = checkContrast(tokens);
      return { tokens, error: null, checks, failures: contrastFailures(tokens), unusable: isUnusable(tokens) };
    } catch (e) {
      if (e instanceof ResolveError) return { tokens: null, error: e.message, checks: [], failures: [], unusable: false };
      throw e;
    }
  }

  const views = computed<Record<Brightness, ModeView>>(() => ({ light: viewOf('light'), dark: viewOf('dark') }));

  const say = (kind: 'error' | 'warn' | 'info', text: string) => {
    notices.value = [...notices.value.slice(-5), { kind, text }];
  };

  function setColor(mode: Brightness, key: string, value: Color | null) {
    const m = mode === 'light' ? draft.light : draft.dark;
    if (value === null) delete m[key];
    else m[key] = value;
  }

  function setExt(mode: Brightness, ext: string, key: string, value: Color | null) {
    const m = mode === 'light' ? draft.extLight : draft.extDark;
    if (value === null) {
      const e = m[ext];
      if (e) {
        delete e[key];
        if (Object.keys(e).length === 0) delete m[ext];
      }
    } else {
      (m[ext] ??= {})[key] = value;
    }
  }

  /** สีเดียว → ชุด accent ของทั้งสองโหมด (accent, accentTint, accentInk, onAccent) ด้วยสูตรเดียวกับ lite ในแอป */
  function setQuickAccent(c: Color) {
    for (const mode of ['light', 'dark'] as const) {
      const [acc, soft, ink] = accentTints(c, mode === 'dark');
      const m = mode === 'light' ? draft.light : draft.dark;
      m.accent = acc;
      m.accentTint = soft;
      m.accentInk = ink;
      delete m.onAccent; // ให้ระบบคำนวณใหม่จาก accent
      delete m.accentBorder;
    }
  }

  function setRadius(key: string, v: number | null) {
    if (v === null) delete draft.radius[key];
    else draft.radius[key] = v;
  }

  function runAutoFix(): number {
    try {
      return autoFix(draft, lookup.value);
    } catch (e) {
      if (e instanceof ResolveError) return 0;
      throw e;
    }
  }

  function resetAll() {
    const f = freshDraft();
    for (const k of Object.keys(draft) as (keyof Draft)[]) delete (draft as unknown as Record<string, unknown>)[k];
    Object.assign(draft, f);
    idAuto.value = true;
    apps.value = [...allAppIds];
    showAllExt.value = false;
    baseTouched.value = false;
    appsGuessed.value = false;
    notices.value = [];
  }

  function importFiles(files: { name: string; text: string }[]) {
    let first = true;
    for (const f of files) {
      const r = parseNslt(f.text);
      if (!r.spec) {
        say('error', `${t('errImport')} ${f.name} — ${r.errors.join('; ')}`);
        continue;
      }
      if (r.warnings.length > 0) say('warn', `${t('warnImport')} ${f.name} — ${r.warnings.join('; ')}`);
      const spec = r.spec;
      if (isReservedThemeId(spec.id)) {
        say('warn', `${f.name}: ${t('reservedId')}`);
      } else {
        library[spec.id] = spec;
      }
      if (first) {
        first = false;
        const d = draftFromSpec(spec);
        // ธีมฐานต้องหาเจอ — ไม่งั้นพรีวิว/แก้ไขไม่ได้ (ไฟล์อื่นที่นำเข้าพร้อมกันนับเป็นฐานได้)
        d.baseId = spec.extendsId ?? defaultBaseId;
        for (const k of Object.keys(draft) as (keyof Draft)[]) delete (draft as unknown as Record<string, unknown>)[k];
        Object.assign(draft, d);
        idAuto.value = false;
        // จัดหมวดตามไฟล์ : ใช้ apps ที่ระบุ ไม่มีก็ดูจากส่วนขยายที่มี ไม่พบ = ทุกแอป
        const cat = appsOfSpec(spec);
        apps.value = cat.apps;
        appsGuessed.value = cat.inferred;
        if (cat.inferred) say('info', t('appsInferred', { apps: cat.apps.map((a) => appById(a).name).join(', ') }));
        baseTouched.value = true;
      }
    }
    // ตรวจฐานหลังนำเข้าทั้งหมดแล้ว
    const have = (id: string) => id in builtinSpecs || id in library;
    if (!have(draft.baseId)) {
      const to = kBuiltinNebularId;
      say('warn', t('baseMissing', { id: draft.baseId, to }));
      draft.baseId = to;
    }
    // ธีมที่เพิ่งนำเข้าไม่ควรเป็นฐานของตัวเอง
    delete library[effectiveId.value];
  }

  /** apps ที่เขียนลงไฟล์ : เลือกครบทุกแอป = ไม่เขียน (ใช้ได้ทุกแอป) ; id ที่ editor ไม่รู้จักจากไฟล์ที่นำเข้าเก็บกลับไว้ */
  function exportApps(): string[] {
    const extras = (draft.apps ?? []).filter((a) => !(allAppIds as readonly string[]).includes(a));
    return [...(apps.value.length === allAppIds.length || appsGuessed.value ? [] : apps.value), ...extras];
  }

  const exportProblems = computed(() => {
    const out: Key[] = [];
    const id = effectiveId.value;
    if (!isValidThemeId(id)) out.push('badId');
    else if (isReservedThemeId(id)) out.push('reservedId');
    if (new TextEncoder().encode(serializeNslt(draftToSpec({ ...draft, id, apps: exportApps() }))).length > kNsltMaxBytes) out.push('tooBig');
    return out.map((k) => t(k));
  });

  const exportText = () => serializeNslt(draftToSpec({ ...draft, id: effectiveId.value, apps: exportApps() }));

  return { draft, library, idAuto, apps, showAllExt, toggleApp, setApps, setBase, visibleExtensions, versionNotes, notices, baseChoices, views, effectiveId, exportProblems, exportText, setColor, setExt, setQuickAccent, setRadius, runAutoFix, resetAll, importFiles, say };
}

export { parseHex, toHex };
