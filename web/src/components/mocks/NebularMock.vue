<script setup lang="ts">
import { computed } from 'vue';
import { toHex } from '../../core/color';
import { onAccentFor } from '../../core/contrast';
import type { NslTokens } from '../../core/tokens';

// หน้าตาโดยประมาณของ Nebular (NSL Dev): แคนวาส ER — พื้นกระดาน, หัวตาราง, ป้าย PK/UQ/NN, แถว FK ที่ไฮไลต์
const props = defineProps<{ tokens: NslTokens }>();
const headInk = computed(() => toHex(onAccentFor(props.tokens.extensions.nebular!.tableHead!)));
</script>

<template>
  <div class="ap-nebular" :style="{ '--head-ink': headInk }">
    <div class="tools">
      <span class="tool on">เลือก</span><span class="tool">ตาราง</span><span class="tool">ความสัมพันธ์</span>
      <span class="sp"></span><span class="muted">ER · schema.sql</span>
    </div>
    <div class="outside">
      <div class="canvas">
        <svg class="links" viewBox="0 0 300 150" preserveAspectRatio="none" aria-hidden="true">
          <path d="M118 70 C 160 70, 150 40, 190 40" fill="none" stroke="var(--e-nebular-boardEdge)" stroke-width="2" />
        </svg>
        <div class="tbl t1">
          <div class="th">users</div>
          <div class="tr"><span>id</span><i class="b pk">PK</i></div>
          <div class="tr"><span>email</span><i class="b uq">UQ</i></div>
          <div class="tr"><span>name</span><i class="b nn">NN</i></div>
        </div>
        <div class="tbl t2">
          <div class="th">orders</div>
          <div class="tr"><span>id</span><i class="b pk">PK</i></div>
          <div class="tr fk"><span>user_id</span><i class="chip">FK → users</i></div>
          <div class="tr"><span>total</span><i class="b nn">NN</i></div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.ap-nebular {
  display: grid;
  min-width: 0;
}
.tools {
  display: flex;
  gap: 6px;
  align-items: center;
  padding: var(--pad) var(--pad-lg);
  background: var(--c-surface);
  border-bottom: 1px solid var(--c-borderSoft);
  font-size: var(--fs-sm);
}
.tool {
  padding: 2px 10px;
  border-radius: var(--r-sm);
  border: 1px solid var(--c-border);
}
.tool.on {
  background: var(--c-accentTint);
  color: var(--c-accentInk);
  border-color: var(--c-accentBorder);
}
.sp {
  flex: 1;
}
.muted {
  color: var(--c-textMuted);
}
.outside {
  background: var(--e-nebular-boardOutside);
  padding: var(--pad-lg);
}
.canvas {
  position: relative;
  height: 190px;
  background-color: var(--e-nebular-canvas);
  background-image: radial-gradient(var(--e-nebular-dot) 1px, transparent 1px);
  background-size: 16px 16px;
  border: 1px solid var(--e-nebular-boardEdge);
  border-radius: var(--r-md);
  overflow: hidden;
}
.links {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
}
.tbl {
  position: absolute;
  width: 124px;
  background: var(--c-surface);
  border-radius: var(--r-md);
  box-shadow: var(--shadow);
  border: 1px solid var(--c-border);
  overflow: hidden;
  font-size: var(--fs-sm);
}
.t1 {
  left: 12px;
  top: 14px;
}
.t2 {
  right: 12px;
  top: 40px;
}
.th {
  background: var(--e-nebular-tableHead);
  color: var(--head-ink);
  padding: 5px 8px;
  font-weight: 600;
}
.tr {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 4px 8px;
  border-top: 1px solid var(--c-borderSoft);
}
.tr.fk {
  background: var(--e-nebular-fkSource);
  color: var(--c-text);
}
.b,
.chip {
  font-style: normal;
  font-size: 10px;
  padding: 0 5px;
  border-radius: var(--r-xs);
}
.pk {
  background: var(--e-nebular-pkBg);
  color: var(--e-nebular-pkText);
}
.uq {
  background: var(--e-nebular-uqBg);
  color: var(--e-nebular-uqText);
}
.nn {
  background: var(--e-nebular-nnBg);
  color: var(--e-nebular-nnText);
}
.chip {
  background: var(--e-nebular-fkChip);
  color: var(--c-accentInk);
}
</style>
