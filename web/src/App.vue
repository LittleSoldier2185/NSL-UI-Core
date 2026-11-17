<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue';
import { type AppId, appById, apps, areas } from './apps';
import ColorRow from './components/ColorRow.vue';
import ContrastPanel from './components/ContrastPanel.vue';
import PreviewPane from './components/PreviewPane.vue';
import { fromARGB32, parseHex, toHex6 } from './core/color';
import { accentPresets } from './core/presets';
import { kNslCoreVersion } from './core/spec';
import { type Brightness, schema } from './core/tokens';
import { useEditor } from './editor';
import { type Key, lang, setLang, t } from './i18n';

/** ไอคอนจาก NSL Brand Pack (public/brand/<id>.svg) — path สัมพัทธ์ตาม base ของการ build */
const brand = (name: string) => `${import.meta.env.BASE_URL}brand/${name}`;

const ed = useEditor();
const { draft } = ed;

type Tab = 'colors' | 'ext' | 'shape' | 'style';
const tab = ref<Tab>('colors');
const editMode = ref<Brightness>('light');
const copied = ref(false);
const quick = ref('#7B58D6');
const versions = ref<string[]>([]);
const previewApp = ref<AppId | 'generic'>(ed.apps.value[0]!);
const previewTabs = computed<(AppId | 'generic')[]>(() => [...ed.apps.value, 'generic']);
watch(ed.apps, () => {
  if (!previewTabs.value.includes(previewApp.value)) previewApp.value = ed.apps.value[0]!;
});
const appName = (id: AppId | 'generic') => (id === 'generic' ? t('generic') : appById(id).name);
const extAppName = (ext: string) => apps.find((a) => a.extension === ext)?.name ?? ext;
const supportMark = { full: '✓', partial: '◐', none: '✕', unknown: '?' } as const;

const groupOrder = ['surfaces', 'borders', 'text', 'accent', 'status', 'other'];
const groups = computed(() =>
  groupOrder
    .map((g) => ({ id: g, label: t(`group_${g}` as Key), keys: schema.colors.filter((c) => c.group === g) }))
    .filter((g) => g.keys.length > 0),
);

const own = (key: string) => (editMode.value === 'light' ? draft.light : draft.dark)[key];
const resolvedColor = (key: string) => ed.views.value[editMode.value].tokens?.colors[key];
const ownExt = (ext: string, key: string) => (editMode.value === 'light' ? draft.extLight : draft.extDark)[ext]?.[key];
const resolvedExt = (ext: string, key: string) => ed.views.value[editMode.value].tokens?.extensions[ext]?.[key];

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

function applyQuick() {
  const c = parseHex(quick.value);
  if (c) {
    ed.setQuickAccent(c);
    ed.say('info', `${t('quickAccent')}: ${quick.value.toUpperCase()}`);
  }
}

function presetQuick(light: string) {
  quick.value = light;
  applyQuick();
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

onMounted(async () => {
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

const modes: Brightness[] = ['light', 'dark'];
const densities = ['compact', 'normal', 'comfortable'] as const;
</script>

<template>
  <div class="app" @dragover.prevent @drop="onDrop">
    <header class="top">
      <div>
        <h1 class="brandline"><img class="brandicon" :src="brand('palette.svg')" alt="" width="32" height="32" />{{ t('title') }}</h1>
        <p class="sub">{{ t('subtitle') }}</p>
      </div>
      <div class="top-right">
        <span class="badge" :title="t('coreVersion')">core v{{ kNslCoreVersion }}</span>
        <label v-if="versions.length > 1" class="ver">
          {{ t('otherVersions') }}
          <select @change="goVersion">
            <option v-for="v in versions" :key="v" :value="v" :selected="v === kNslCoreVersion">v{{ v }}</option>
          </select>
        </label>
        <label class="lang">
          {{ t('language') }}
          <select :value="lang" @change="(e) => setLang((e.target as HTMLSelectElement).value as 'th' | 'en')">
            <option value="th">ไทย</option>
            <option value="en">English</option>
          </select>
        </label>
      </div>
    </header>
    <p class="hint">{{ t('versionHint') }}</p>

    <div class="layout">
      <aside class="controls">
        <section class="card">
          <h2>{{ t('theme') }}</h2>
          <label class="f">
            {{ t('name') }}
            <input v-model="draft.name" type="text" maxlength="80" />
          </label>
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
          <label class="f">
            {{ t('base') }}
            <select :value="draft.baseId" @change="(e) => ed.setBase((e.target as HTMLSelectElement).value)">
              <option v-for="b in ed.baseChoices.value" :key="b.id" :value="b.id">{{ b.name }} ({{ b.id }})</option>
            </select>
          </label>
          <div class="btns">
            <label class="btn">
              {{ t('importFiles') }}
              <input type="file" accept=".nslt,.json,application/json" multiple hidden @change="onPick" />
            </label>
            <button class="btn" type="button" @click="ed.resetAll()">{{ t('reset') }}</button>
          </div>
          <p class="small">{{ t('importHint') }}</p>
        </section>

        <section class="card">
          <h2>{{ t('forApps') }}</h2>
          <p class="small">{{ t('forAppsHint') }}</p>
          <div class="appchips" role="group" :aria-label="t('forApps')">
            <button
              v-for="a in apps"
              :key="a.id"
              type="button"
              class="appchip"
              :class="{ on: ed.apps.value.includes(a.id) }"
              :aria-pressed="ed.apps.value.includes(a.id)"
              @click="ed.toggleApp(a.id)"
            >
              <img class="appicon" :src="brand(a.id + '.svg')" alt="" width="28" height="28" />
              <strong>{{ a.name }}</strong>
              <span>{{ a.product }}</span>
            </button>
          </div>
          <ul class="statuses">
            <li v-for="id in ed.apps.value" :key="id" :class="appById(id).status">
              <strong>{{ appById(id).name }}</strong> — {{ t(appById(id).status === 'planned' ? 'status_planned' : 'status_experiment') }}
            </li>
          </ul>
          <ul v-if="ed.versionNotes.value.length > 0" class="small notes">
            <li v-for="e in ed.versionNotes.value" :key="e.name">{{ t('laterExt', { ext: e.name, app: extAppName(e.name), since: e.since }) }}</li>
          </ul>
          <details class="matrix">
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
        </section>

        <section class="card">
          <h2>{{ t('quickAccent') }}</h2>
          <p class="small">{{ t('quickAccentHint') }}</p>
          <div class="swatches" role="group" :aria-label="t('presets')">
            <button
              v-for="p in accentPresets"
              :key="p.id"
              type="button"
              class="sw"
              :title="lang === 'th' ? p.nameTh : p.nameEn"
              :style="{ background: toHex6(p.light[0]) }"
              @click="presetQuick(toHex6(p.light[0]))"
            ></button>
          </div>
          <div class="inline">
            <input v-model="quick" type="color" :aria-label="t('customColour')" />
            <input v-model="quick" type="text" maxlength="7" class="mono" :aria-label="t('customColour')" />
            <button class="btn" type="button" @click="applyQuick">{{ t('applyAccent') }}</button>
          </div>
        </section>

        <section class="card">
          <div class="tabs" role="tablist">
            <button v-for="k in (['colors', 'ext', 'shape', 'style'] as Tab[])" :key="k" role="tab" :aria-selected="tab === k" :class="{ on: tab === k }" type="button" @click="tab = k">
              {{ t(({ colors: 'tabColors', ext: 'tabExt', shape: 'tabShape', style: 'tabStyle' } as Record<Tab, Key>)[k]) }}
            </button>
          </div>

          <div v-if="tab === 'colors' || tab === 'ext'" class="modebar">
            <span>{{ t('editing') }}</span>
            <button v-for="m in modes" :key="m" type="button" :class="{ on: editMode === m }" @click="editMode = m">{{ t(m) }}</button>
          </div>

          <div v-if="tab === 'colors'">
            <fieldset v-for="g in groups" :key="g.id" class="grp">
              <legend>{{ g.label }}</legend>
              <ColorRow
                v-for="c in g.keys"
                :key="`${editMode}-${c.key}`"
                :label="c.key"
                :resolved="resolvedColor(c.key)"
                :own="own(c.key)"
                @set="(col) => ed.setColor(editMode, c.key, col)"
                @clear="ed.setColor(editMode, c.key, null)"
              />
            </fieldset>
          </div>

          <div v-else-if="tab === 'ext'">
            <p class="small">{{ t('extHint') }}</p>
            <label class="chk"><input v-model="ed.showAllExt.value" type="checkbox" /> {{ t('showOtherExt') }}</label>
            <p v-if="ed.visibleExtensions.value.length === 0" class="small">{{ t('extOrbit') }}</p>
            <fieldset v-for="e in ed.visibleExtensions.value" :key="e.name" class="grp">
              <legend>{{ e.app }} · <code>{{ e.name }}</code> · core ≥ {{ e.since }}</legend>
              <ColorRow
                v-for="k in e.keys"
                :key="`${editMode}-${e.name}-${k}`"
                :label="k"
                :resolved="resolvedExt(e.name, k)"
                :own="ownExt(e.name, k)"
                @set="(col) => ed.setExt(editMode, e.name, k, col)"
                @clear="ed.setExt(editMode, e.name, k, null)"
              />
            </fieldset>
          </div>

          <div v-else-if="tab === 'shape'">
            <fieldset class="grp">
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
            <fieldset class="grp">
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
          </div>

          <div v-else>
            <fieldset class="grp">
              <legend>{{ t('density') }}</legend>
              <label v-for="d in densities" :key="d" class="chk">
                <input type="radio" name="density" :checked="(draft.density ?? 'normal') === d" @change="setDensity(d)" /> {{ t(d) }}
              </label>
              <p class="small">{{ t('densityHint') }}</p>
            </fieldset>
            <fieldset class="grp">
              <legend>{{ t('elevationMode') }}</legend>
              <label class="chk"><input type="radio" name="elev" :checked="(draft.elevationMode ?? 'shadow') === 'shadow'" @change="setElevation('shadow')" /> {{ t('shadow') }}</label>
              <label class="chk"><input type="radio" name="elev" :checked="draft.elevationMode === 'flat'" @change="setElevation('flat')" /> {{ t('flat') }}</label>
              <label class="num">
                <span>{{ t('strength') }} ({{ (draft.elevationStrength ?? schema.elevation.strength.default).toFixed(2) }})</span>
                <input type="range" :min="schema.elevation.strength.min" :max="schema.elevation.strength.max" step="0.05" :value="draft.elevationStrength ?? schema.elevation.strength.default" @input="setStrength" />
              </label>
            </fieldset>
          </div>
        </section>
      </aside>

      <main class="output">
        <section class="card">
          <h2>{{ t('preview') }}</h2>
          <p class="small">{{ t('previewNote') }}</p>
          <div class="ptabs" role="tablist" :aria-label="t('previewFor')">
            <span class="small">{{ t('previewFor') }}</span>
            <button v-for="id in previewTabs" :key="id" type="button" role="tab" :aria-selected="previewApp === id" :class="{ on: previewApp === id }" @click="previewApp = id">
              {{ appName(id) }}
            </button>
          </div>
          <div class="previews">
            <template v-for="m in modes" :key="m">
              <PreviewPane v-if="ed.views.value[m].tokens" :tokens="ed.views.value[m].tokens!" :title="t(m)" :app="previewApp" />
              <p v-else class="err">{{ t(m) }}: {{ t('cannotResolve') }} {{ ed.views.value[m].error }}</p>
            </template>
          </div>
        </section>

        <section class="card">
          <div class="head">
            <h2>{{ t('contrast') }}</h2>
            <button class="btn" type="button" @click="fix">{{ t('autoFix') }}</button>
          </div>
          <div class="cps">
            <ContrastPanel v-for="m in modes" :key="m" :title="t(m)" :view="ed.views.value[m]" />
          </div>
        </section>

        <section class="card">
          <div class="head">
            <h2>.nslt</h2>
            <div class="btns">
              <button class="btn primary" type="button" :disabled="ed.exportProblems.value.length > 0" @click="download">{{ t('download') }}</button>
              <button class="btn" type="button" :disabled="ed.exportProblems.value.length > 0" @click="copy">{{ copied ? t('copied') : t('copy') }}</button>
            </div>
          </div>
          <ul v-if="ed.exportProblems.value.length > 0" class="problems">
            <li v-for="p in ed.exportProblems.value" :key="p">{{ p }}</li>
          </ul>
          <pre class="code" tabindex="0">{{ ed.exportText() }}</pre>
          <h3 class="how">{{ t('howToUse') }}</h3>
          <ul class="small">
            <li>{{ t('howWindows') }}</li>
            <li>{{ t('howAndroid') }}</li>
          </ul>
        </section>

        <section v-if="ed.notices.value.length > 0" class="card" aria-live="polite">
          <h2>{{ t('notices') }}</h2>
          <ul class="notices">
            <li v-for="(n, i) in ed.notices.value" :key="i" :class="n.kind">{{ n.text }}</li>
          </ul>
        </section>
      </main>
    </div>
    <footer class="foot">{{ t('footer') }}</footer>
  </div>
</template>
