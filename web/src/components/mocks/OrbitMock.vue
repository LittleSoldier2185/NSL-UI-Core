<script setup lang="ts">
import { computed } from 'vue';
import { toHex } from '../../core/color';
import { accentPresets } from '../../core/presets';
import { tintFor } from '../../core/tint';
import type { NslTokens } from '../../core/tokens';

// หน้าตาโดยประมาณของ Orbit (NSL Utility): การ์ดการเงิน + โดนัทตามหมวด + ตารางวันนี้ + แถบเมนูล่าง
// ใช้เฉพาะสี core และชุด categorical (Orbit ยังไม่ได้ย้ายมาใช้ core — นี่คือหน้าตาที่คาดว่าจะเป็น)
const props = defineProps<{ tokens: NslTokens }>();
const dark = computed(() => props.tokens.brightness === 'dark');
const cats = computed(() => accentPresets.slice(0, 5).map((p) => (dark.value ? p.dark[0] : p.light[0])));
const shares = [38, 24, 18, 12, 8];
const arcs = computed(() => {
  let acc = 0;
  const r = 15.9155; // เส้นรอบวง = 100
  return shares.map((s, i) => {
    const a = { dash: `${s - 1} ${100 - s + 1}`, off: -acc, color: toHex(cats.value[i]!) };
    acc += s;
    return { ...a, r };
  });
});
const chips = computed(() =>
  [cats.value[1]!, cats.value[4]!].map((c) => {
    const [bg, fg] = tintFor(c, dark.value);
    return { bg: toHex(bg), fg: toHex(fg) };
  }),
);
</script>

<template>
  <div class="ap-orbit">
    <div class="hero">
      <div class="hi">วันนี้ · 16 พ.ย.</div>
      <div class="muted">ใช้ไปวันนี้</div>
      <div class="big">฿ 482</div>
    </div>
    <div class="cards">
      <div class="oc">
        <div class="cap">เดือนนี้</div>
        <div class="split">
          <svg viewBox="0 0 36 36" class="donut" aria-hidden="true">
            <circle cx="18" cy="18" r="15.9155" fill="none" stroke="var(--c-surfaceSunken)" stroke-width="4" />
            <circle
              v-for="(a, i) in arcs"
              :key="i"
              cx="18"
              cy="18"
              r="15.9155"
              fill="none"
              :stroke="a.color"
              stroke-width="4"
              :stroke-dasharray="a.dash"
              :stroke-dashoffset="a.off"
              transform="rotate(-90 18 18)"
            />
          </svg>
          <div class="nums">
            <span class="inc">+ ฿ 18,000</span>
            <span class="exp">− ฿ 9,640</span>
            <div class="budget" aria-hidden="true"><i></i></div>
            <span class="muted">งบ 54%</span>
          </div>
        </div>
      </div>
      <div class="oc">
        <div class="cap">ตารางวันนี้</div>
        <div class="ev"><span class="t" :style="{ background: chips[0]!.bg, color: chips[0]!.fg }">09:00</span> ฟิสิกส์ 2</div>
        <div class="ev"><span class="t" :style="{ background: chips[1]!.bg, color: chips[1]!.fg }">13:30</span> ส่งรายงาน</div>
      </div>
    </div>
    <nav class="nav">
      <span class="tab on"><i></i>หน้าหลัก</span><span class="tab"><i></i>การเงิน</span><span class="tab"><i></i>ตาราง</span><span class="tab"><i></i>เครื่องมือ</span>
    </nav>
  </div>
</template>

<style scoped>
.ap-orbit {
  display: grid;
  gap: var(--pad-lg);
  padding: var(--pad-lg);
  min-width: 0;
}
.hero {
  display: grid;
  gap: 2px;
}
.hi {
  font-size: var(--fs-sm);
  color: var(--c-textMuted);
}
.muted {
  color: var(--c-textMuted);
  font-size: var(--fs-sm);
}
.big {
  font-size: calc(var(--fs-lg) * 1.6);
  font-weight: 700;
}
.cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: var(--pad-lg);
}
.oc {
  background: var(--c-surfaceRaised);
  border-radius: var(--r-lg);
  padding: var(--pad-lg);
  box-shadow: var(--shadow);
  border: var(--flat-border);
  display: grid;
  gap: var(--pad);
  align-content: start;
}
.cap {
  font-size: var(--fs-sm);
  font-weight: 600;
}
.split {
  display: flex;
  gap: var(--pad-lg);
  align-items: center;
}
.donut {
  width: 70px;
  height: 70px;
  flex: none;
}
.nums {
  display: grid;
  gap: 2px;
  font-size: var(--fs-sm);
  min-width: 0;
}
.inc {
  color: var(--c-success);
}
.exp {
  color: var(--c-danger);
}
.budget {
  height: 6px;
  border-radius: var(--r-pill);
  background: var(--c-surfaceSunken);
  overflow: hidden;
}
.budget i {
  display: block;
  width: 54%;
  height: 100%;
  background: var(--c-accent);
}
.ev {
  display: flex;
  gap: 8px;
  align-items: center;
  font-size: var(--fs-sm);
}
.t {
  padding: 1px 8px;
  border-radius: var(--r-pill);
  font-size: 11px;
}
.nav {
  display: flex;
  justify-content: space-around;
  background: var(--c-surface);
  border-top: 1px solid var(--c-borderSoft);
  border-radius: var(--r-lg);
  padding: var(--pad);
  font-size: 11px;
  color: var(--c-textMuted);
}
.tab {
  display: grid;
  justify-items: center;
  gap: 2px;
}
.tab i {
  width: 36px;
  height: 18px;
  border-radius: var(--r-pill);
  background: transparent;
}
.tab.on i {
  background: var(--c-accentTint);
}
.tab.on {
  color: var(--c-accentInk);
  font-weight: 600;
}
</style>
