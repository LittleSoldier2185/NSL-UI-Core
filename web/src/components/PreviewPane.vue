<script setup lang="ts">
import { computed } from 'vue';
import type { AppId } from '../apps';
import { toHex } from '../core/color';
import { accentPresets } from '../core/presets';
import { tintFor } from '../core/tint';
import type { NslTokens } from '../core/tokens';
import { cssVars } from '../previewVars';
import { t } from '../i18n';
import LyraMock from './mocks/LyraMock.vue';
import NebularMock from './mocks/NebularMock.vue';
import OrbitMock from './mocks/OrbitMock.vue';
import SpectrumMock from './mocks/SpectrumMock.vue';
import { mockText } from './mocks/mockText';

/** app = หน้าตาโดยประมาณของแอปนั้น ; 'generic' = ตัวอย่างกลาง (widget มาตรฐานทั้งหมด) */
const props = withDefaults(defineProps<{ tokens: NslTokens; title: string; app?: AppId | 'generic' }>(), { app: 'generic' });

/** สีทั้งหมดเป็น CSS variables — พรีวิวเปลี่ยนสดตาม token (HTML/CSS ประมาณการ ไม่ใช่ widget จริง) */
const style = computed(() => cssVars(props.tokens));

const dark = computed(() => props.tokens.brightness === 'dark');
const chips = computed(() =>
  accentPresets.map((p) => {
    const base = dark.value ? p.dark[0] : p.light[0];
    const [bg, fg] = tintFor(base, dark.value);
    return { id: p.id, name: p.nameEn, bg: toHex(bg), fg: toHex(fg) };
  }),
);
</script>

<template>
  <section class="pv" :class="`ap-${app}`" :style="style" :aria-label="`${t('preview')} — ${title}`">
    <header class="pv-bar">
      <span class="pv-dot"></span>
      <strong>{{ title }}</strong>
      <span class="pv-spacer"></span>
      <span class="pv-muted">{{ t('preview') }}</span>
    </header>
    <NebularMock v-if="app === 'nebular'" :tokens="tokens" />
    <SpectrumMock v-else-if="app === 'spectrum'" :tokens="tokens" />
    <LyraMock v-else-if="app === 'lyra'" :tokens="tokens" />
    <OrbitMock v-else-if="app === 'orbit'" :tokens="tokens" />
    <div v-else class="pv-body">
      <nav class="pv-side">
        <div class="pv-row">{{ mockText.generic.normal }}</div>
        <div class="pv-row pv-hover">{{ mockText.generic.hover }}</div>
        <div class="pv-row pv-selected">{{ mockText.generic.selected }}</div>
        <div class="pv-row pv-faint">{{ mockText.generic.faint }}</div>
      </nav>
      <main class="pv-main">
        <h3>{{ mockText.generic.heading }}</h3>
        <p>{{ mockText.generic.body }}</p>
        <p class="pv-muted">{{ mockText.generic.muted }} <span class="pv-link">{{ mockText.generic.link }}</span></p>
        <p class="pv-content">{{ mockText.generic.content }}</p>
        <p class="pv-mono">const theme = "mono"; <kbd class="pv-kbd">Ctrl</kbd>+<kbd class="pv-kbd">S</kbd></p>
        <div class="pv-actions">
          <button class="pv-btn pv-primary" type="button">{{ mockText.generic.primary }}</button>
          <button class="pv-btn pv-tint" type="button">{{ mockText.generic.tint }}</button>
          <button class="pv-btn pv-outline" type="button">{{ mockText.generic.outline }}</button>
          <button class="pv-btn pv-border" type="button">{{ mockText.generic.accentBorder }}</button>
        </div>
        <input class="pv-input" type="text" :value="mockText.generic.input" readonly aria-label="sample input" />
        <div class="pv-alerts">
          <span class="pv-alert pv-danger">{{ mockText.generic.danger }}</span>
          <span class="pv-alert pv-warn">{{ mockText.generic.warn }}</span>
          <span class="pv-alert pv-info">{{ mockText.generic.info }}</span>
          <span class="pv-alert pv-success">{{ mockText.generic.success }}</span>
        </div>
        <div class="pv-solids">
          <span><i class="pv-sd pv-sd-danger"></i>{{ mockText.generic.dangerSolid }}</span>
          <span><i class="pv-sd pv-sd-success"></i>{{ mockText.generic.successSolid }}</span>
        </div>
        <div class="pv-chips" aria-label="categorical">
          <span v-for="c in chips" :key="c.id" class="pv-chip" :style="{ background: c.bg, color: c.fg }">{{ c.name }}</span>
        </div>
        <div class="pv-card">
          <strong>{{ mockText.generic.card }}</strong>
          <span class="pv-muted">{{ mockText.generic.cardNote }}</span>
        </div>
      </main>
    </div>
  </section>
</template>

<style scoped>
.pv {
  background: var(--c-bg);
  color: var(--c-text);
  font-family: var(--ff, system-ui, 'Noto Sans Thai', sans-serif);
  font-size: var(--fs);
  border-radius: var(--r-lg);
  border: 1px solid var(--c-border);
  overflow: hidden;
  min-width: 0;
}
.pv-bar {
  display: flex;
  align-items: center;
  gap: var(--pad);
  padding: var(--pad) var(--pad-lg);
  background: var(--c-chrome);
  border-bottom: 1px solid var(--c-borderSoft);
}
.pv-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: var(--c-accent);
}
.pv-spacer {
  flex: 1;
}
.pv-muted {
  color: var(--c-textMuted);
}
.pv-body {
  display: grid;
  grid-template-columns: minmax(120px, 34%) 1fr;
}
.pv-side {
  background: var(--c-surface);
  border-right: 1px solid var(--c-borderSoft);
  padding: var(--pad);
  display: grid;
  gap: 2px;
  align-content: start;
}
.pv-row {
  padding: var(--pad) var(--pad-lg);
  border-radius: var(--r-sm);
  font-size: var(--fs-sm);
  color: var(--c-text);
}
.pv-hover {
  background: var(--c-hover);
}
.pv-selected {
  background: var(--c-selected);
  border-left: 3px solid var(--c-accent);
}
.pv-faint {
  color: var(--c-textFaint);
}
.pv-main {
  padding: var(--pad-lg);
  display: grid;
  gap: var(--pad-lg);
  align-content: start;
  min-width: 0;
}
h3 {
  margin: 0;
  font-size: var(--fs-lg);
}
p {
  margin: 0;
}
.pv-link {
  color: var(--c-accentInk);
  text-decoration: underline;
}
.pv-content {
  font-family: var(--ff-content, inherit);
  color: var(--c-text);
}
.pv-mono {
  font-family: var(--ff-mono, ui-monospace, monospace);
  font-size: var(--fs-sm);
  color: var(--c-icon);
}
.pv-actions {
  display: flex;
  flex-wrap: wrap;
  gap: var(--pad);
}
.pv-btn {
  font: inherit;
  padding: var(--pad) var(--pad-lg);
  border-radius: var(--r-md);
  cursor: default;
  border: 1px solid transparent;
}
.pv-primary {
  background: var(--c-accent);
  color: var(--c-onAccent);
}
.pv-tint {
  background: var(--c-accentTint);
  color: var(--c-accentInk);
}
.pv-outline {
  background: transparent;
  color: var(--c-text);
  border-color: var(--c-borderStrong);
}
.pv-border {
  background: var(--c-surface);
  color: var(--c-accentInk);
  border-color: var(--c-accentBorder);
}
.pv-input {
  font: inherit;
  padding: var(--pad) var(--pad-lg);
  border-radius: var(--r-md);
  background: var(--c-surfaceSunken);
  color: var(--c-text);
  border: 1px solid var(--c-borderStrong);
}
.pv-alerts {
  display: flex;
  flex-wrap: wrap;
  gap: var(--pad);
}
.pv-alert {
  padding: calc(var(--pad) * 0.6) var(--pad-lg);
  border-radius: var(--r-sm);
  font-size: var(--fs-sm);
}
.pv-danger {
  background: var(--c-dangerBg);
  color: var(--c-dangerText);
}
.pv-warn {
  background: var(--c-warnBg);
  color: var(--c-warnText);
}
.pv-info {
  background: var(--c-infoBg);
  color: var(--c-infoText);
}
.pv-success {
  background: var(--c-successBg);
  color: var(--c-successText);
}
.pv-kbd {
  font: inherit;
  font-size: 0.9em;
  padding: 0 5px;
  border-radius: var(--r-xs);
  border: 1px solid var(--c-borderStrong);
  background: var(--c-surfaceSunken);
  color: var(--c-text);
}
.pv-solids {
  display: flex;
  flex-wrap: wrap;
  gap: var(--pad-lg);
  font-size: var(--fs-sm);
}
.pv-solids span {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}
.pv-sd {
  width: 12px;
  height: 12px;
  border-radius: 50%;
}
.pv-sd-danger {
  background: var(--c-danger);
}
.pv-sd-success {
  background: var(--c-success);
}
.pv-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}
.pv-chip {
  padding: 2px 10px;
  border-radius: var(--r-pill);
  font-size: var(--fs-sm);
}
.pv-card {
  background: var(--c-surfaceRaised);
  border-radius: var(--r-xl);
  padding: var(--pad-lg);
  box-shadow: var(--shadow);
  border: var(--flat-border);
}
</style>
