<script setup lang="ts">
import type { ModeView } from '../editor';
import { t } from '../i18n';

defineProps<{ title: string; view: ModeView }>();
</script>

<template>
  <section class="cp">
    <h4>{{ title }}</h4>
    <p v-if="view.error" class="err">{{ t('cannotResolve') }} {{ view.error }}</p>
    <template v-else>
      <p v-if="view.unusable" class="err">{{ t('unusable') }}</p>
      <p v-else-if="view.failures.length === 0" class="ok">✓ {{ t('allPass') }}</p>
      <ul>
        <li v-for="c in view.checks" :key="c.name" :class="c.passes ? 'pass' : 'fail'">
          <span class="mark" aria-hidden="true">{{ c.passes ? '✓' : '✗' }}</span>
          <span class="nm">{{ c.name }}</span>
          <span class="rt">{{ c.ratio.toFixed(2) }} : 1</span>
          <span class="mn">≥ {{ c.min }}</span>
          <span class="sr">{{ c.passes ? t('pass') : t('failed') }}</span>
        </li>
      </ul>
    </template>
  </section>
</template>

<style scoped>
.cp h4 {
  margin: 0 0 6px;
  font-size: 13px;
}
ul {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  gap: 2px;
  font-size: 12px;
}
li {
  display: grid;
  grid-template-columns: 16px 1fr auto auto;
  gap: 8px;
}
.mn {
  color: var(--muted);
}
.sr {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip: rect(0 0 0 0);
}
.pass .mark {
  color: var(--ok);
}
.fail {
  color: var(--danger);
  font-weight: 600;
}
.ok {
  color: var(--ok);
  margin: 0 0 6px;
  font-size: 12px;
}
.err {
  color: var(--danger);
  margin: 0 0 6px;
  font-size: 12px;
}
</style>
