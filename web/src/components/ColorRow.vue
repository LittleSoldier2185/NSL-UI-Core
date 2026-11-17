<script setup lang="ts">
import { computed, ref, watch } from 'vue';
import { type Color, parseHex, toHex, toHex6 } from '../core/color';
import { t } from '../i18n';

const props = defineProps<{
  label: string;
  /** ค่าที่ resolve แล้ว (ใช้แสดงเมื่อสืบทอด) */
  resolved: Color | undefined;
  /** ค่าที่ผู้ใช้ตั้งไว้เอง (undefined = สืบทอด/คำนวณ) */
  own: Color | undefined;
  /** ชื่อที่คนอ่านเข้าใจ (ไม่มี = ใช้ label) */
  name?: string;
  /** ผลตรวจ contrast ที่แย่ที่สุดที่สีนี้เป็นตัวอักษร (ไม่มี = ไม่แสดง) */
  check?: { ratio: number; min: number; passes: boolean; against: string };
  /** สีนี้ไม่มีในพรีวิวที่ดูอยู่ : ชื่อพรีวิวนั้น + ชื่อพรีวิวที่มีสีนี้ (ไม่มี = ไม่แสดงป้าย ; seeIn ว่าง = ไม่มีปุ่มสลับ) */
  missing?: { in: string; seeIn?: string };
}>();
const emit = defineEmits<{ set: [Color]; clear: []; peek: [boolean]; see: [] }>();

const shown = computed(() => props.own ?? props.resolved);
const text = ref(shown.value ? toHex(shown.value) : '');
const bad = ref(false);

watch(shown, (c) => {
  if (c && parseHex(text.value) && toHex(parseHex(text.value)!) === toHex(c)) return; // กำลังพิมพ์ค่าที่ตรงกันอยู่ ไม่ทับ
  text.value = c ? toHex(c) : '';
  bad.value = false;
});

function onText(e: Event) {
  const v = (e.target as HTMLInputElement).value.trim();
  text.value = v;
  const c = parseHex(v.startsWith('#') ? v : `#${v}`);
  bad.value = c === null;
  if (c) emit('set', c);
}

function onPicker(e: Event) {
  const c = parseHex((e.target as HTMLInputElement).value);
  if (c) emit('set', c);
}
</script>

<template>
  <div class="row" :class="{ own: own !== undefined }" @mouseenter="emit('peek', true)" @mouseleave="emit('peek', false)" @focusin="emit('peek', true)" @focusout="emit('peek', false)">
    <span class="lbl"><b v-if="name && name !== label">{{ name }}</b> <span :class="{ key: name && name !== label }">{{ label }}</span>
      <span v-if="missing" class="miss">{{ t('notInPreview', { app: missing.in }) }}<button v-if="missing.seeIn" type="button" class="see" @click="emit('see')">{{ t('seeIn', { app: missing.seeIn }) }}</button></span>
    </span>
    <input
      class="pick"
      type="color"
      :value="shown ? toHex6(shown) : '#000000'"
      :aria-label="label"
      @input="onPicker"
    />
    <input
      class="hex"
      :class="{ bad }"
      type="text"
      :value="text"
      maxlength="9"
      spellcheck="false"
      :aria-label="`${label} hex`"
      :aria-invalid="bad"
      @input="onText"
    />
    <span v-if="check" class="ratio" :class="check.passes ? 'ok' : 'fail'" :title="`${check.ratio.toFixed(2)} : 1 / ${check.against} (≥ ${check.min})`">{{ check.ratio.toFixed(1) }} <span aria-hidden="true">{{ check.passes ? '✓' : '✕' }}</span><span class="sr">{{ check.passes ? t('pass') : t('failed') }}</span></span>
    <span v-else></span>
    <button v-if="own !== undefined" class="clr" type="button" :title="t('clear')" @click="emit('clear')">↺</button>
    <span v-else class="inh" :title="t('inherited')">·</span>
  </div>
</template>

<style scoped>
.row {
  display: grid;
  grid-template-columns: minmax(96px, 1fr) 34px 92px 54px 26px;
  align-items: center;
  gap: 8px;
  padding: 3px 0;
}
.lbl {
  font-size: 13px;
  overflow-wrap: anywhere;
}
.own .lbl {
  font-weight: 600;
}
.pick {
  width: 34px;
  height: 28px;
  padding: 0;
  border: 1px solid var(--line);
  border-radius: 6px;
  background: none;
  cursor: pointer;
}
.hex {
  font: 12px ui-monospace, Consolas, monospace;
  padding: 4px 6px;
  border: 1px solid var(--line);
  border-radius: 6px;
  background: var(--field);
  color: var(--ink);
  width: 100%;
}
.hex.bad {
  border-color: var(--danger);
}
.clr,
.inh {
  width: 26px;
  height: 26px;
  display: grid;
  place-items: center;
  color: var(--muted);
}
.clr {
  border: 1px solid var(--line);
  border-radius: 6px;
  background: var(--panel);
  color: var(--ink);
  cursor: pointer;
}


.key {
  font: 11px ui-monospace, Consolas, monospace;
  color: var(--muted);
}
.ratio {
  font-size: 12px;
  font-weight: 700;
  text-align: right;
  white-space: nowrap;
}
.ratio.ok {
  color: var(--ok);
}
.ratio.fail {
  color: var(--danger);
}
.sr {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip: rect(0 0 0 0);
}
</style>
<style scoped>
.miss {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  color: var(--muted);
  margin-top: 2px;
}
.see {
  font: inherit;
  font-weight: 600;
  border: 0;
  padding: 0;
  background: none;
  color: var(--brand-ink);
  text-decoration: underline;
  cursor: pointer;
}
</style>
