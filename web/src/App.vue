<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue';
import { type AppId, allAppIds, appById, apps, areas } from './apps';
import { colorMatches, colorName } from './colorNames';
import ColorRow from './components/ColorRow.vue';
import ContrastPanel from './components/ContrastPanel.vue';
import PreviewPane from './components/PreviewPane.vue';
import { builtinSpecs, makeLookup } from './core/builtin';
import { parseHex, toHex6 } from './core/color';
import { accentPresets } from './core/presets';
import { resolveTokens } from './core/resolve';
import { kNslCoreVersion } from './core/spec';
import { type Brightness, schema } from './core/tokens';
import { useEditor } from './editor';
import { tokenElements } from './previewMap';
import { type Key, lang, setLang, t } from './i18n';
import { useToasts } from './toasts';
import { type UiTheme, setUiTheme, uiTheme, uiThemes } from './uiTheme';

/** ไอคอนจาก NSL Brand Pack (public/brand/<id>.svg) — path สัมพัทธ์ตาม base ของการ build */
const brand = (name: string) => `${import.meta.env.BASE_URL}brand/${name}`;

const ed = useEditor();
const { draft } = ed;

// ── ขั้นตอน (แถบซ้าย) ──
type Step = 'start' | 'colors' | 'ext' | 'shape' | 'style' | 'check' | 'file';
const mainSteps: Step[] = ['start', 'colors', 'ext', 'shape', 'style'];
const step = ref<Step>('start');
const stepTitle = (s: Step) => t(`step_${s}` as Key);
function go(s: Step) {
  step.value = s;
}
/** ลำดับทั้งหมดที่ปุ่ม "กลับ/ถัดไป" เดิน : 5 ขั้นแก้ → ตรวจความอ่านง่าย → ไฟล์ */
const flow: Step[] = [...mainSteps, 'check', 'file'];
const nextStep = computed<Step | null>(() => flow[flow.indexOf(step.value) + 1] ?? null);
const prevStep = computed<Step | null>(() => flow[flow.indexOf(step.value) - 1] ?? null);

const editMode = ref<Brightness>('light');
const copied = ref(false);
const quick = ref('#7B58D6');
const versions = ref<string[]>([]);
const modes: Brightness[] = ['light', 'dark'];
const densities = ['compact', 'normal', 'comfortable'] as const;

// ── พรีวิว ──
type PMode = 'both' | Brightness;
const previewMode = ref<PMode>('both');
const shownModes = computed<Brightness[]>(() => (previewMode.value === 'both' ? modes : [previewMode.value]));
const previewApp = ref<AppId | 'generic'>(ed.apps.value[0]!);
const previewTabs = computed<(AppId | 'generic')[]>(() => [...ed.apps.value, 'generic']);
watch(ed.apps, () => {
  if (!previewTabs.value.includes(previewApp.value)) previewApp.value = ed.apps.value[0]!;
});
const appName = (id: AppId | 'generic') => (id === 'generic' ? t('generic') : appById(id).name);
const extAppName = (ext: string) => apps.find((a) => a.extension === ext)?.name ?? ext;
const supportMark = { full: '✓', partial: '◐', none: '✕', unknown: '?' } as const;

// ── ขั้น 1 : ธีมฐาน ──
const baseDesc: Record<string, Key> = {
  'nsl.default': 'bd_default',
  'nsl.nebular': 'bd_nebular',
  'nsl.spectrum': 'bd_spectrum',
  'nsl.lyra.paper': 'bd_lyra',
  'nsl.orbit': 'bd_orbit',
};
const baseCards = computed(() => {
  const lookup = makeLookup(ed.library);
  return ed.baseChoices.value.map((b) => {
    const spec = b.builtin ? builtinSpecs[b.id] : ed.library[b.id];
    let strip: string[] = [];
    try {
      if (spec) {
        const c = resolveTokens(spec, 'light', lookup).colors;
        strip = [c.bg, c.text, c.accent].filter((x) => x !== undefined).map((x) => toHex6(x));
      }
    } catch {
      /* ธีมที่ resolve ไม่ได้ = ไม่มีแถบสี */
    }
    return { ...b, strip, desc: b.builtin && baseDesc[b.id] ? t(baseDesc[b.id]!) : t('base_user') };
  });
});

// ── ขั้น 1 : แอป ──
const allOn = computed(() => ed.apps.value.length === allAppIds.length);
const lastSpecific = ref<AppId[]>([]);
watch(
  ed.apps,
  (v) => {
    if (v.length < allAppIds.length) lastSpecific.value = [...v];
  },
  { immediate: true },
);
function toggleAll() {
  if (allOn.value) ed.setApps(lastSpecific.value.length > 0 ? lastSpecific.value : [allAppIds[0]!]);
  else ed.setApps(allAppIds);
}

// ── ขั้น 1 : สีหลัก ──
function applyQuick() {
  const c = parseHex(quick.value);
  if (c) {
    ed.setQuickAccent(c);
    ed.say('info', `${t('accentTitle')}: ${quick.value.toUpperCase()}`);
  }
}
function presetQuick(light: string) {
  quick.value = light;
  applyQuick();
}
const isPicked = (hex: string) => quick.value.toUpperCase() === hex.toUpperCase();

// ── ขั้น 2 : สี ──
const search = ref('');
const onlyOwn = ref(false);
const groupOrder = ['surfaces', 'borders', 'text', 'accent', 'status', 'other'];
const own = (key: string) => (editMode.value === 'light' ? draft.light : draft.dark)[key];
const resolvedColor = (key: string) => ed.views.value[editMode.value].tokens?.colors[key];
const ownExt = (ext: string, key: string) => (editMode.value === 'light' ? draft.extLight : draft.extDark)[ext]?.[key];
const resolvedExt = (ext: string, key: string) => ed.views.value[editMode.value].tokens?.extensions[ext]?.[key];
const groups = computed(() =>
  groupOrder
    .map((g) => ({
      id: g,
      label: t(`group_${g}` as Key),
      total: schema.colors.filter((c) => c.group === g).length,
      keys: schema.colors.filter((c) => c.group === g && colorMatches(c.key, search.value) && (!onlyOwn.value || own(c.key) !== undefined)),
    }))
    .filter((g) => g.keys.length > 0),
);
/** ผลตรวจที่แย่ที่สุดที่สีนี้เป็นตัวอักษร (ของโหมดที่กำลังแก้) */
function worstCheck(key: string) {
  const cs = ed.views.value[editMode.value].checks.filter((c) => c.fg === key);
  if (cs.length === 0) return undefined;
  const w = cs.reduce((a, b) => (b.passes === a.passes ? (b.ratio < a.ratio ? b : a) : b.passes ? a : b));
  return { ratio: w.ratio, min: w.min, passes: w.passes, against: w.bg };
}
const groupFails = (keys: { key: string }[]) => keys.filter((k) => worstCheck(k.key)?.passes === false).length;
const ownCount = computed(() => Object.keys(draft.light).length + Object.keys(draft.dark).length);

// ── ตรวจ / ไฟล์ ──
const failCount = computed(() => ed.views.value.light.failures.length + ed.views.value.dark.failures.length);
const problems = computed(() => ed.exportProblems.value);

function stepSub(s: Step): string {
  switch (s) {
    case 'start':
      return t('sub_start');
    case 'colors':
      return t('sub_colors', { n: schema.colors.length, m: ownCount.value });
    case 'ext':
      return ed.visibleExtensions.value.length > 0 ? ed.visibleExtensions.value.map((e) => extAppName(e.name)).join(' · ') : t('sub_extNone');
    case 'shape':
      return t('sub_shape');
    case 'style':
      return `${t(draft.density ?? 'normal')} · ${t(draft.elevationMode === 'flat' ? 'flat' : 'shadow')}`;
    case 'check':
      return failCount.value === 0 ? t('sub_checkPass') : t('sub_checkFail', { n: failCount.value });
    case 'file':
      return t('sub_file');
  }
}

// ── ค่าอื่น ๆ (เหมือนเดิม) ──
function num(e: Event): number | null {
  const v = (e.target as HTMLInputElement).value;
  if (v.trim() === '') return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}
function setText(field: 'family' | 'content' | 'mono', e: Event) {
  const v = (e.target as HTMLInputElement).value.trim();
  if (v === '') delete draft[field];
  else draft[field] = v;
}
function setScale(e: Event) {
  const n = num(e);
  if (n === null || Math.abs(n - schema.type.scale.default) < 1e-9) delete draft.scale;
  else draft.scale = n;
}
function setMinSize(e: Event) {
  const n = num(e);
  if (n === null) delete draft.minSize;
  else draft.minSize = Math.min(schema.type.minSize.max, Math.max(schema.type.minSize.min, n));
}
function setStrength(e: Event) {
  const n = num(e);
  if (n === null || Math.abs(n - schema.elevation.strength.default) < 1e-9) delete draft.elevationStrength;
  else draft.elevationStrength = n;
}
function setDensity(v: string) {
  if (v === 'normal') delete draft.density;
  else draft.density = v as 'compact' | 'comfortable';
}
function setElevation(v: string) {
  if (v === 'shadow') delete draft.elevationMode;
  else draft.elevationMode = v as 'flat';
}
function goVersion(e: Event) {
  const v = (e.target as HTMLSelectElement).value;
  if (/^\d{1,3}\.\d{1,3}$/.test(v)) window.location.href = `../v${v}/`;
}
function fix() {
  const n = ed.runAutoFix();
  ed.say('info', n > 0 ? t('autoFixed', { n }) : t('nothingToFix'));
}
async function readFiles(list: FileList | File[]) {
  const files = [...list].slice(0, 20);
  const read = await Promise.all(files.map(async (f) => ({ name: f.name, text: await f.text() })));
  ed.importFiles(read);
}
function onPick(e: Event) {
  const input = e.target as HTMLInputElement;
  if (input.files) void readFiles(input.files);
  input.value = '';
}
function onDrop(e: DragEvent) {
  e.preventDefault();
  if (e.dataTransfer?.files) void readFiles(e.dataTransfer.files);
}
function download() {
  const blob = new Blob([`${ed.exportText()}\n`], { type: 'application/json' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = `${ed.effectiveId.value}.nslt`;
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(a.href), 1000);
}
async function copy() {
  try {
    await navigator.clipboard.writeText(`${ed.exportText()}\n`);
    copied.value = true;
    setTimeout(() => (copied.value = false), 1500);
  } catch {
    ed.say('warn', 'Clipboard unavailable — use Download');
  }
}

// ── พรีวิวแสดงสีไหนบ้าง (อ่านจาก CSS จริงของพรีวิว) + ชี้ตำแหน่งเมื่อชี้/โฟกัสแถวสี ──
const previewsEl = ref<HTMLElement | null>(null);
const shown = ref<Set<string>>(new Set());
async function refreshShown() {
  await nextTick();
  const pv = previewsEl.value?.querySelector('section.pv');
  shown.value = pv ? new Set(tokenElements(pv).keys()) : new Set();
}
watch([previewApp, previewMode, lang, step], refreshShown);
/** ป้าย "ไม่มีในพรีวิวนี้" ของสี core : ดูได้ใน "ทั่วไป" (ครบทุกสีเสมอ) */
function missingCore(key: string) {
  if (shown.value.size === 0 || shown.value.has(key)) return undefined;
  return { in: appName(previewApp.value), seeIn: previewApp.value === 'generic' ? undefined : t('generic') };
}
/** ขั้นสีเฉพาะแอป : แสดงเฉพาะกลุ่มของแอปที่พรีวิวอยู่ (พรีวิวของแอปมีสีเฉพาะแอปครบเสมอ — มีเทสต์คุม จึงไม่ต้องมีป้าย "ไม่มีในพรีวิว") */
const extOfPreview = computed(() => {
  if (previewApp.value === 'generic') return undefined;
  const name = appById(previewApp.value).extension;
  return name ? schema.extensions.find((e) => e.name === name) : undefined;
});
/** แอปที่เลือกไว้และมีสีเฉพาะแอป — ปุ่มสลับพรีวิวไปแก้ */
const extApps = computed(() => ed.apps.value.filter((a) => appById(a).extension !== undefined));
let peeked: Element[] = [];
function peek(token: string | null) {
  for (const el of peeked) el.classList.remove('pv-peek');
  peeked = [];
  if (!token || !previewsEl.value) return;
  for (const pv of previewsEl.value.querySelectorAll('section.pv')) {
    for (const el of tokenElements(pv).get(token) ?? []) {
      el.classList.add('pv-peek');
      peeked.push(el);
    }
  }
}

onBeforeUnmount(() => {
  window.removeEventListener('keydown', onKey);
  ed.history.dispose();
});

// ── ข้อความแจ้ง (มุมบนขวา) : แสดง 3 อันล่าสุด ปิดทีละอันได้ ──
// หายเองใน 3 วินาที มีเส้นเวลา ; ชี้/โฟกัสอยู่ = หยุดนับ
const { toasts, paused, pause, resume, dismiss } = useToasts(ed.notices, { duration: 3000, max: 3 });

// ── Undo / Redo ──
function doUndo() {
  if (ed.history.undo()) ed.say('info', t('undone'));
}
function doRedo() {
  if (ed.history.redo()) ed.say('info', t('redone'));
}
/**
 * Ctrl/⌘+Z = ย้อน, Ctrl/⌘+Y หรือ Ctrl/⌘+Shift+Z = ทำซ้ำ — ใช้ได้ทุกที่ รวมตอนพิมพ์อยู่ในช่องที่เป็นส่วนของธีม (ชื่อ, hex, ตัวเลข)
 * เพราะสิ่งที่พิมพ์ก็อยู่ในประวัติเดียวกัน ; ยกเว้นช่องที่ไม่ใช่ส่วนของธีม (ค้นหาสี, hex สีหลักแบบเร็ว) = `data-native-undo` ใช้ undo ของช่องเอง
 */
function onKey(e: KeyboardEvent) {
  if (!(e.ctrlKey || e.metaKey) || e.altKey) return;
  // target อาจเป็น window/document (ไม่มี closest) เมื่อไม่มีอะไรโฟกัส
  const target = e.target instanceof HTMLElement ? e.target : null;
  const native = target?.closest('[data-native-undo]') != null;
  if (native || target instanceof HTMLTextAreaElement || target?.isContentEditable === true) return;
  const k = e.key.toLowerCase();
  if (k === 'z' && !e.shiftKey) {
    e.preventDefault();
    doUndo();
  } else if (k === 'y' || (k === 'z' && e.shiftKey)) {
    e.preventDefault();
    doRedo();
  }
}

onMounted(async () => {
  window.addEventListener('keydown', onKey);
  void refreshShown();
  // รายชื่อเวอร์ชันที่โฮสต์ไว้ (versions.json อยู่ระดับเหนือโฟลเดอร์ของเวอร์ชันนี้) — ไม่มี = ไม่แสดงตัวสลับ
  try {
    const r = await fetch('../versions.json', { cache: 'no-store' });
    if (r.ok) {
      const j = (await r.json()) as { versions?: unknown };
      if (Array.isArray(j.versions)) versions.value = j.versions.filter((v): v is string => typeof v === 'string' && /^\d{1,3}\.\d{1,3}$/.test(v));
    }
  } catch {
    /* ทำงานได้ปกติโดยไม่มีตัวสลับ */
  }
});
</script>

<template>
  <div class="shell" @dragover.prevent @drop="onDrop">
    <header class="top">
      <div class="brandline">
        <img class="brandicon" :src="brand('palette.svg')" alt="" width="30" height="30" />
        <span class="brandname">{{ t('title') }}</span>
      </div>
      <span class="divider" aria-hidden="true"></span>
      <label class="namefield">
        <span class="sr">{{ t('name') }}</span>
        <input v-model="draft.name" type="text" maxlength="80" :placeholder="t('name')" />
      </label>
      <button class="filechip" type="button" :title="t('id')" @click="go('file')">{{ ed.effectiveId.value }}.nslt</button>
      <span class="grow"></span>
      <label class="btn dk">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M12 15V3M7 8l5-5 5 5M4 15v4a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-4" /></svg>
        <span>{{ t('importShort') }}</span>
        <input type="file" accept=".nslt,.json,application/json" multiple hidden @change="onPick" />
      </label>
      <div class="uh" role="group" :aria-label="t('history')">
        <button type="button" class="btn dk icon undo" :disabled="!ed.history.canUndo.value" :aria-label="t('undo')" :title="t('undoHint', { n: ed.history.undoCount.value })" @click="doUndo">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M9 14 4 9l5-5" /><path d="M4 9h10.5a5.5 5.5 0 0 1 0 11H11" /></svg>
        </button>
        <button type="button" class="btn dk icon redo" :disabled="!ed.history.canRedo.value" :aria-label="t('redo')" :title="t('redoHint', { n: ed.history.redoCount.value })" @click="doRedo">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="m15 14 5-5-5-5" /><path d="M20 9H9.5a5.5 5.5 0 0 0 0 11H13" /></svg>
        </button>
      </div>
      <button class="btn primary" type="button" :disabled="problems.length > 0" :title="problems.length > 0 ? t('problemsN', { n: problems.length }) : undefined" @click="download">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M12 3v12M7 10l5 5 5-5M4 15v4a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-4" /></svg>
        <span>{{ t('download') }}</span>
        <span v-if="problems.length > 0" class="count">{{ problems.length }}</span>
      </button>
      <div class="seg uitheme" role="group" :aria-label="t('uiTheme')">
        <button v-for="m in uiThemes" :key="m" type="button" :class="{ on: uiTheme === m }" :aria-pressed="uiTheme === m" :aria-label="t(`ui_${m}` as Key)" :title="t(`ui_${m}` as Key)" @click="setUiTheme(m as UiTheme)">
          <svg v-if="m === 'system'" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><rect x="3" y="4" width="18" height="12" rx="2" /><path d="M8 20h8M12 16v4" /></svg>
          <svg v-else-if="m === 'light'" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="4" /><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4" /></svg>
          <svg v-else width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z" /></svg>
        </button>
      </div>
      <label class="lang">
        <span>{{ t('language') }}</span>
        <select :value="lang" @change="(e) => setLang((e.target as HTMLSelectElement).value as 'th' | 'en')">
          <option value="th">ไทย</option>
          <option value="en">English</option>
        </select>
      </label>
    </header>

    <div class="layout">
      <nav class="steps" :aria-label="t('steps')">
        <button
          v-for="(s, i) in mainSteps"
          :key="s"
          type="button"
          class="step"
          :data-step="s"
          :class="{ on: step === s }"
          :aria-current="step === s ? 'step' : undefined"
          @click="go(s)"
        >
          <span class="n" aria-hidden="true">{{ i + 1 }}</span>
          <span class="st"><b>{{ stepTitle(s) }}</b><span class="ss">{{ stepSub(s) }}</span></span>
        </button>
        <span class="sep" aria-hidden="true"></span>
        <button type="button" class="step" data-step="check" :class="{ on: step === 'check' }" :aria-current="step === 'check' ? 'step' : undefined" @click="go('check')">
          <svg v-if="failCount === 0" class="n ic" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="9" /><path d="m8 12 3 3 5-6" /></svg>
          <svg v-else class="n ic bad" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M12 3 2 20h20L12 3z" /><path d="M12 10v4M12 17h.01" /></svg>
          <span class="st"><b>{{ stepTitle('check') }}</b><span class="ss" :class="{ badtxt: failCount > 0 }">{{ stepSub('check') }}</span></span>
        </button>
        <button type="button" class="step" data-step="file" :class="{ on: step === 'file' }" :aria-current="step === 'file' ? 'step' : undefined" @click="go('file')">
          <svg class="n ic" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M8 4 3 12l5 8M16 4l5 8-5 8" /></svg>
          <span class="st"><b>{{ stepTitle('file') }}</b><span class="ss">{{ stepSub('file') }}</span></span>
        </button>
        <div class="navfoot">
          <span class="badge" :title="t('versionHint')">core v{{ kNslCoreVersion }}</span>
          <label v-if="versions.length > 1" class="ver">
            {{ t('versionLabel') }}
            <select @change="goVersion">
              <option v-for="v in versions" :key="v" :value="v" :selected="v === kNslCoreVersion">v{{ v }}</option>
            </select>
          </label>
          <p class="small">{{ t('footer') }}</p>
        </div>
      </nav>

      <main class="panel">
        <!-- ── 1 เริ่มต้น ── -->
        <template v-if="step === 'start'">
          <div class="phead">
            <h1>{{ stepTitle('start') }}</h1>
            <p class="small">{{ t('startHint') }}</p>
          </div>

          <section class="card">
            <h2>{{ t('baseTitle') }}</h2>
            <p class="small">{{ t('baseHint') }}</p>
            <div class="bases" role="radiogroup" :aria-label="t('baseTitle')">
              <button
                v-for="b in baseCards"
                :key="b.id"
                type="button"
                role="radio"
                class="base"
                :class="{ on: draft.baseId === b.id }"
                :aria-checked="draft.baseId === b.id"
                :title="b.id"
                @click="ed.setBase(b.id)"
              >
                <span class="strip" aria-hidden="true"><i v-for="(c, k) in b.strip" :key="k" :style="{ background: c }"></i></span>
                <b>{{ b.name }}</b>
                <span class="small">{{ b.desc }}</span>
              </button>
            </div>
          </section>

          <section class="card">
            <div class="chead">
              <div>
                <h2>{{ t('appsTitle') }}</h2>
                <p class="small">{{ t('appsHint') }}</p>
              </div>
              <label class="switch">
                <span>{{ t('allApps') }}</span>
                <input type="checkbox" role="switch" class="allapps" :checked="allOn" @change="toggleAll" />
                <span class="track" aria-hidden="true"><span class="knob"></span></span>
              </label>
            </div>
            <ul class="applist" :aria-label="t('appsTitle')">
              <li v-for="a in apps" :key="a.id">
                <label class="approw" :class="{ on: ed.apps.value.includes(a.id) }">
                  <img class="appicon" :src="brand(a.id + '.svg')" alt="" width="36" height="36" />
                  <span class="appname"><b>{{ a.name }}</b><span class="small">{{ t(`app_desc_${a.id}` as Key) }}</span></span>
                  <span class="pill" :class="a.status" :title="t(a.status === 'planned' ? 'status_planned' : 'status_experiment')">{{ t(a.status === 'planned' ? 'status_short_planned' : 'status_short_experiment') }}</span>
                  <input
                    type="checkbox"
                    class="appcheck"
                    :checked="ed.apps.value.includes(a.id)"
                    :disabled="ed.apps.value.length === 1 && ed.apps.value.includes(a.id)"
                    :title="ed.apps.value.length === 1 && ed.apps.value.includes(a.id) ? t('lastApp') : undefined"
                    @change="ed.toggleApp(a.id)"
                  />
                </label>
              </li>
            </ul>
            <ul v-if="ed.versionNotes.value.length > 0" class="small notes">
              <li v-for="e in ed.versionNotes.value" :key="e.name">{{ t('laterExt', { ext: e.name, app: extAppName(e.name), since: e.since }) }}</li>
            </ul>
          </section>

          <section class="card">
            <h2>{{ t('accentTitle') }}</h2>
            <p class="small">{{ t('accentHint') }}</p>
            <div class="swatches" role="group" :aria-label="t('presets')">
              <button
                v-for="p in accentPresets"
                :key="p.id"
                type="button"
                class="sw"
                :class="{ on: isPicked(toHex6(p.light[0])) }"
                :aria-label="lang === 'th' ? p.nameTh : p.nameEn"
                :aria-pressed="isPicked(toHex6(p.light[0]))"
                :title="lang === 'th' ? p.nameTh : p.nameEn"
                :style="{ background: toHex6(p.light[0]) }"
                @click="presetQuick(toHex6(p.light[0]))"
              ></button>
              <span class="vsep" aria-hidden="true"></span>
              <span class="custom">
                <input v-model="quick" type="color" :aria-label="t('customColour')" />
                <input v-model="quick" data-native-undo type="text" maxlength="7" class="mono" :aria-label="`${t('customColour')} hex`" />
                <button class="btn" type="button" @click="applyQuick">{{ t('applyAccent') }}</button>
              </span>
            </div>
          </section>
        </template>

        <!-- ── 2 สี ── -->
        <template v-else-if="step === 'colors'">
          <div class="phead row">
            <div>
              <h1>{{ stepTitle('colors') }}</h1>
              <p class="small">{{ t('colorsHint') }}</p>
            </div>
            <div class="seg" role="group" :aria-label="t('editing')">
              <button v-for="m in modes" :key="m" type="button" :class="{ on: editMode === m }" :aria-pressed="editMode === m" @click="editMode = m">{{ t(m) }}</button>
            </div>
          </div>
          <div class="searchbar">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="11" cy="11" r="7" /><path d="m20 20-3.5-3.5" /></svg>
            <input v-model="search" data-native-undo type="search" :placeholder="t('searchColors')" :aria-label="t('searchColors')" />
            <label class="chk"><input v-model="onlyOwn" type="checkbox" /> {{ t('onlyOwn') }}</label>
          </div>
          <p v-if="groups.length === 0" class="small">{{ t('noColorMatch') }}</p>
          <fieldset v-for="g in groups" :key="g.id" class="grp card" :class="{ warn: groupFails(g.keys) > 0 }">
            <legend class="sr">{{ g.label }}</legend>
            <div class="chead">
              <h2 aria-hidden="true">{{ g.label }}</h2>
              <span v-if="groupFails(g.keys) > 0" class="pill planned">⚠ {{ t('hardToRead', { n: groupFails(g.keys) }) }}</span>
              <span v-else class="small">{{ t('colorsInGroup', { n: g.total }) }}</span>
            </div>
            <ColorRow
              v-for="c in g.keys"
              :key="`${editMode}-${c.key}`"
              :label="c.key"
              :name="colorName(c.key, lang)"
              :check="worstCheck(c.key)"
              :missing="missingCore(c.key)"
              :resolved="resolvedColor(c.key)"
              :own="own(c.key)"
              @set="(col) => ed.setColor(editMode, c.key, col)"
              @clear="ed.setColor(editMode, c.key, null)"
              @peek="(on) => peek(on ? c.key : null)"
              @see="previewApp = 'generic'"
            />
          </fieldset>
        </template>

        <!-- ── 3 สีเฉพาะแอป ── -->
        <template v-else-if="step === 'ext'">
          <div class="phead row">
            <div>
              <h1>{{ stepTitle('ext') }}</h1>
              <p class="small">{{ t('extTitleHint') }}</p>
            </div>
            <div class="seg" role="group" :aria-label="t('editing')">
              <button v-for="m in modes" :key="m" type="button" :class="{ on: editMode === m }" :aria-pressed="editMode === m" @click="editMode = m">{{ t(m) }}</button>
            </div>
          </div>
          <section v-if="!extOfPreview" class="card noext">
            <p>{{ previewApp === 'generic' ? t('extPickApp') : t('extNoneFor', { app: appName(previewApp) }) }}</p>
            <div v-if="extApps.length > 0" class="btns">
              <button v-for="a in extApps" :key="a" class="btn" type="button" @click="previewApp = a">
                <img :src="brand(a + '.svg')" alt="" width="18" height="18" />{{ t('editAppColors', { app: appById(a).name }) }}
              </button>
            </div>
            <p v-else class="small">{{ t('extNoSelected') }}</p>
          </section>
          <fieldset v-for="e in extOfPreview ? [extOfPreview] : []" :key="e.name" class="grp card">
            <legend>{{ extAppName(e.name) }} · <code>{{ e.name }}</code> · core ≥ {{ e.since }}</legend>
            <ColorRow
              v-for="k in e.keys"
              :key="`${editMode}-${e.name}-${k}`"
              :label="k"
              :resolved="resolvedExt(e.name, k)"
              :own="ownExt(e.name, k)"
              @peek="(on) => peek(on ? e.name + '.' + k : null)"
              @set="(col) => ed.setExt(editMode, e.name, k, col)"
              @clear="ed.setExt(editMode, e.name, k, null)"
            />
          </fieldset>
          <details class="matrix card">
            <summary>{{ t('supportTitle') }}</summary>
            <div class="tblwrap">
              <table>
                <thead>
                  <tr>
                    <th></th>
                    <th v-for="a in apps" :key="a.id" :class="{ sel: ed.apps.value.includes(a.id) }">{{ a.name }}</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="ar in areas" :key="ar">
                    <th scope="row">{{ t(`area_${ar}` as Key) }}</th>
                    <td v-for="a in apps" :key="a.id" :class="[a.support[ar], { sel: ed.apps.value.includes(a.id) }]">
                      <span aria-hidden="true">{{ supportMark[a.support[ar]] }}</span>
                      <span class="sr">{{ t(`sup_${a.support[ar]}` as Key) }}</span>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
            <p class="small legend">✓ {{ t('sup_full') }} · ◐ {{ t('sup_partial') }} · ✕ {{ t('sup_none') }} · ? {{ t('sup_unknown') }}</p>
            <p class="small">{{ t('supportNote') }}</p>
          </details>
        </template>

        <!-- ── 4 รูปทรงและตัวอักษร ── -->
        <template v-else-if="step === 'shape'">
          <div class="phead"><h1>{{ stepTitle('shape') }}</h1></div>
          <fieldset class="grp card">
            <legend>{{ t('radius') }}</legend>
            <label v-for="k in schema.shape.radius.keys" :key="k" class="num">
              <span>{{ k }}</span>
              <input
                type="number"
                :min="schema.shape.radius.min"
                :max="schema.shape.radius.max"
                step="1"
                :placeholder="String(schema.shape.radius.default[k])"
                :value="draft.radius[k] ?? ''"
                @input="(e) => ed.setRadius(k, num(e))"
              />
            </label>
          </fieldset>
          <fieldset class="grp card">
            <legend>{{ t('fontFamily') }}</legend>
            <label class="f">{{ t('fontFamily') }}<input type="text" maxlength="64" :value="draft.family ?? ''" placeholder="Noto Sans Thai" @input="(e) => setText('family', e)" /></label>
            <label class="f">{{ t('fontContent') }}<input type="text" maxlength="64" :value="draft.content ?? ''" @input="(e) => setText('content', e)" /></label>
            <label class="f">{{ t('fontMono') }}<input type="text" maxlength="64" :value="draft.mono ?? ''" @input="(e) => setText('mono', e)" /></label>
            <p class="small">{{ t('fontHint') }}</p>
            <label class="num">
              <span>{{ t('scale') }} ({{ (draft.scale ?? schema.type.scale.default).toFixed(2) }})</span>
              <input type="range" :min="schema.type.scale.min" :max="schema.type.scale.max" step="0.05" :value="draft.scale ?? schema.type.scale.default" @input="setScale" />
            </label>
            <label class="num">
              <span>{{ t('minSize') }}</span>
              <input type="number" :min="schema.type.minSize.min" :max="schema.type.minSize.max" step="1" :value="draft.minSize ?? ''" placeholder="—" @input="setMinSize" />
            </label>
          </fieldset>
        </template>

        <!-- ── 5 ความหนาแน่นและเงา ── -->
        <template v-else-if="step === 'style'">
          <div class="phead"><h1>{{ stepTitle('style') }}</h1></div>
          <fieldset class="grp card">
            <legend>{{ t('density') }}</legend>
            <label v-for="d in densities" :key="d" class="chk">
              <input type="radio" name="density" :checked="(draft.density ?? 'normal') === d" @change="setDensity(d)" /> {{ t(d) }}
            </label>
            <p class="small">{{ t('densityHint') }}</p>
          </fieldset>
          <fieldset class="grp card">
            <legend>{{ t('elevationMode') }}</legend>
            <label class="chk"><input type="radio" name="elev" :checked="(draft.elevationMode ?? 'shadow') === 'shadow'" @change="setElevation('shadow')" /> {{ t('shadow') }}</label>
            <label class="chk"><input type="radio" name="elev" :checked="draft.elevationMode === 'flat'" @change="setElevation('flat')" /> {{ t('flat') }}</label>
            <label class="num">
              <span>{{ t('strength') }} ({{ (draft.elevationStrength ?? schema.elevation.strength.default).toFixed(2) }})</span>
              <input type="range" :min="schema.elevation.strength.min" :max="schema.elevation.strength.max" step="0.05" :value="draft.elevationStrength ?? schema.elevation.strength.default" @input="setStrength" />
            </label>
          </fieldset>
        </template>

        <!-- ── ตรวจความอ่านง่าย ── -->
        <template v-else-if="step === 'check'">
          <div class="phead row">
            <div>
              <h1>{{ t('contrast') }}</h1>
              <p class="small">{{ t('checkHint') }}</p>
            </div>
            <button class="btn primary" type="button" @click="fix">{{ t('autoFix') }}</button>
          </div>
          <div class="cps">
            <ContrastPanel v-for="m in modes" :key="m" class="card" :title="t(m)" :view="ed.views.value[m]" />
          </div>
        </template>

        <!-- ── ไฟล์ ── -->
        <template v-else>
          <div class="phead row">
            <div>
              <h1>{{ t('fileTitle') }}</h1>
              <p class="small">{{ t('fileHint') }}</p>
            </div>
            <div class="btns">
              <button class="btn" type="button" :disabled="problems.length > 0" @click="copy">{{ copied ? t('copied') : t('copy') }}</button>
            </div>
          </div>
          <section class="card">
            <label class="f">
              {{ t('id') }}
              <span class="inline">
                <input
                  :value="ed.effectiveId.value"
                  type="text"
                  maxlength="64"
                  spellcheck="false"
                  :disabled="ed.idAuto.value"
                  @input="(e) => (draft.id = (e.target as HTMLInputElement).value)"
                />
                <label class="chk"><input v-model="ed.idAuto.value" type="checkbox" /> {{ t('idAuto') }}</label>
              </span>
            </label>
            <ul v-if="problems.length > 0" class="problems">
              <li v-for="p in problems" :key="p">{{ p }}</li>
            </ul>
          </section>
          <pre class="code card" tabindex="0">{{ ed.exportText() }}</pre>
          <section class="card">
            <h3 class="how">{{ t('howToUse') }}</h3>
            <ul class="small">
              <li>{{ t('howWindows') }}</li>
              <li>{{ t('howAndroid') }}</li>
            </ul>
            <div class="btns">
              <button class="btn" type="button" @click="ed.resetAll()">{{ t('reset') }}</button>
            </div>
            <p class="small">{{ t('importHint') }}</p>
          </section>
        </template>

        <div v-if="prevStep || nextStep" class="nextrow">
          <button v-if="prevStep" class="btn back" type="button" @click="go(prevStep)">{{ t('back', { step: stepTitle(prevStep) }) }}</button>
          <span class="grow"></span>
          <button v-if="nextStep" class="btn" type="button" @click="go(nextStep)">{{ t('next', { step: stepTitle(nextStep) }) }}</button>
        </div>
      </main>

      <aside class="preview" :aria-label="t('preview')">
        <div class="pbar">
          <div class="ptabs seg" role="tablist" :aria-label="t('previewFor')">
            <button v-for="id in previewTabs" :key="id" type="button" role="tab" :aria-selected="previewApp === id" :class="{ on: previewApp === id }" @click="previewApp = id">
              <img v-if="id !== 'generic'" :src="brand(id + '.svg')" alt="" width="16" height="16" />{{ appName(id) }}
            </button>
          </div>
          <div class="seg" role="group" :aria-label="t('previewMode')">
            <button v-for="m in (['light', 'dark', 'both'] as PMode[])" :key="m" type="button" :class="{ on: previewMode === m }" :aria-pressed="previewMode === m" @click="previewMode = m">{{ t(m) }}</button>
          </div>
        </div>
        <div ref="previewsEl" class="previews">
          <template v-for="m in shownModes" :key="m">
            <PreviewPane v-if="ed.views.value[m].tokens" :tokens="ed.views.value[m].tokens!" :title="t(m)" :app="previewApp" />
            <p v-else class="err">{{ t(m) }}: {{ t('cannotResolve') }} {{ ed.views.value[m].error }}</p>
          </template>
        </div>
        <p class="small">{{ t('previewNote') }}</p>
        <button type="button" class="summary" :class="{ bad: failCount > 0 }" @click="go('check')">
          <span>{{ failCount === 0 ? '✓ ' + t('summaryPass') : '⚠ ' + t('summaryFail', { n: failCount }) }}</span>
          <span class="link">{{ t('details') }}</span>
        </button>
      </aside>
    </div>

    <div class="toasts" aria-live="polite">
      <div
        v-for="n in toasts"
        :key="n.id"
        class="toast"
        :class="[n.kind, { paused: paused.has(n.id) }]"
        @mouseenter="pause(n.id)"
        @mouseleave="resume(n.id)"
        @focusin="pause(n.id)"
        @focusout="resume(n.id)"
      >
        <span class="msg">{{ n.text }}</span>
        <button type="button" class="x" :aria-label="t('dismiss')" @click="dismiss(n.id)">×</button>
        <i class="life" :style="{ animationDuration: n.duration + 'ms' }" aria-hidden="true"></i>
      </div>
    </div>
  </div>
</template>
