<script setup lang="ts">
import { computed } from 'vue';
import { toHex } from '../../core/color';
import { onAccentFor } from '../../core/contrast';
import type { NslTokens } from '../../core/tokens';
import { mockText } from './mockText';

// หน้าตาโดยประมาณของ Nebular (NSL Dev): แคนวาส ER — พื้นกระดาน, หัวตาราง, ป้าย PK/UQ/NN, แถว FK ที่ไฮไลต์
const props = defineProps<{ tokens: NslTokens }>();
const headInk = computed(() => toHex(onAccentFor(props.tokens.extensions.nebular!.tableHead!)));
</script>

<template>
  <div class="ap-nebular" :style="{ '--head-ink': headInk }">
    <div class="tools">
      <span class="tool on">{{ mockText.nebular.select }}</span><span class="tool">{{ mockText.nebular.table }}</span><span class="tool">{{ mockText.nebular.relation }}</span>
      <span class="sp"></span><span class="muted">ER · schema.sql</span>
    </div>
    <div class="outside">
      <div class="canvas">
        <!-- เส้น FK : orders.user_id → users.id — วาดเฉพาะช่องว่างระหว่างสองตาราง แกนตั้งเป็นพิกเซลจริง (viewBox สูง = ผืนผ้าใบ 190)
             แกนนอนยืดได้เพราะปลายอยู่ที่ขอบซ้าย/ขวาพอดี ; ความหนาเส้นไม่ยืดตาม (non-scaling-stroke) -->
        <svg class="links" viewBox="0 0 100 190" preserveAspectRatio="none" aria-hidden="true">
          <path d="M0 56 C 50 56, 50 108, 100 108" fill="none" stroke="var(--e-nebular-boardEdge)" stroke-width="2" vector-effect="non-scaling-stroke" />
        </svg>
        <span class="end e1" aria-hidden="true"></span>
        <span class="end e2" aria-hidden="true"></span>
        <div class="tbl t1">
          <div class="th">users</div>
          <div class="tr"><span>id</span><i class="b pk">PK</i></div>
          <div class="tr hover"><span>email</span><i class="b uq">UQ</i></div>
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
/* ตำแหน่งตาราง/แถวตายตัว (px) เพื่อให้ปลายเส้นตรงแถว : หัว 28 + แถว 26 + เส้นขอบ 1
   users.id กลางแถว = 14 + 1 + 28 + 13 = 56 ; orders.user_id = 40 + 1 + 28 + 26 + 13 = 108 */
/* svg เป็น replaced element : left+right อย่างเดียวไม่ยืด (width:auto = ตามสัดส่วน viewBox) จึงต้องกำหนดกว้างเอง
   = ผืนผ้าใบ − (ขอบขวาของ users 136) − (ขอบซ้ายของ orders 136) */
.links {
  position: absolute;
  top: 0;
  left: 136px;
  width: calc(100% - 272px);
  height: 190px;
  overflow: visible;
}
.end {
  position: absolute;
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--e-nebular-boardEdge);
}
.e1 {
  left: 133px;
  top: 52.5px;
}
.e2 {
  right: 133px;
  top: 104.5px;
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
  height: 28px;
  display: flex;
  align-items: center;
  padding: 0 8px;
  box-sizing: border-box;
  overflow: hidden;
  font-weight: 600;
}
.tr {
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 26px;
  padding: 0 8px;
  box-sizing: border-box;
  overflow: hidden;
  border-top: 1px solid var(--c-borderSoft);
}
.tr.hover {
  background: var(--c-hover);
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
