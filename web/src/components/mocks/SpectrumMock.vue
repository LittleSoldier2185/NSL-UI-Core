<script setup lang="ts">
import type { NslTokens } from '../../core/tokens';

// หน้าตาโดยประมาณของ Spectrum (NSL Resonance): เครื่องเล่นมีเดีย — แผงไล่เฉด (panelBottom), แถบเลื่อน, ปุ่มเล่นสี accent
defineProps<{ tokens: NslTokens }>();
const tracks = ['Aurora Borealis', 'Midnight Signal', 'ท้องฟ้าหลังฝน', 'Low Orbit'];
</script>

<template>
  <div class="ap-spectrum">
    <div class="title"><span class="dot"></span> Spectrum <span class="sp"></span><span class="win">— □ ✕</span></div>
    <div class="body">
      <aside class="panel">
        <div class="cap">รายการเล่น</div>
        <div v-for="(t, i) in tracks" :key="t" class="row" :class="{ on: i === 1, hover: i === 2 }">
          <span class="n">{{ i + 1 }}</span>{{ t }}
        </div>
      </aside>
      <section class="now">
        <div class="art" aria-hidden="true"></div>
        <div class="meta">
          <strong>Midnight Signal</strong>
          <span class="muted">The Orbitals · Night Drive</span>
          <div class="bar" aria-hidden="true"><i></i></div>
          <div class="time muted"><span>1:42</span><span>4:08</span></div>
          <div class="ctrl">
            <span class="ic">⏮</span>
            <span class="play">▶</span>
            <span class="ic">⏭</span>
            <span class="sp"></span>
            <span class="vol" aria-hidden="true"><i></i></span>
          </div>
        </div>
      </section>
    </div>
  </div>
</template>

<style scoped>
.ap-spectrum {
  display: grid;
  min-width: 0;
}
.title {
  display: flex;
  align-items: center;
  gap: 8px;
  background: var(--c-chrome);
  padding: 6px var(--pad-lg);
  font-size: var(--fs-sm);
  border-bottom: 1px solid var(--c-borderSoft);
}
.dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--c-accent);
}
.sp {
  flex: 1;
}
.win {
  color: var(--c-icon);
  letter-spacing: 4px;
}
.body {
  display: grid;
  grid-template-columns: minmax(110px, 38%) 1fr;
}
.panel {
  background: linear-gradient(var(--c-surface), var(--e-spectrum-panelBottom));
  border-right: 1px solid var(--c-borderSoft);
  padding: var(--pad);
  display: grid;
  gap: 2px;
  align-content: start;
  font-size: var(--fs-sm);
}
.cap {
  color: var(--c-textMuted);
  padding: 2px var(--pad);
  text-transform: uppercase;
  font-size: 10px;
  letter-spacing: 0.08em;
}
.row {
  display: flex;
  gap: 8px;
  padding: calc(var(--pad) * 0.7) var(--pad);
  border-radius: var(--r-sm);
}
.row.on {
  background: var(--c-accentTint);
  color: var(--c-accentInk);
  font-weight: 600;
}
.row.hover {
  background: var(--c-hover);
}
.n {
  width: 14px;
  color: var(--c-textFaint);
}
.now {
  display: flex;
  flex-wrap: wrap;
  gap: var(--pad-lg);
  padding: var(--pad-lg);
  align-items: center;
  min-width: 0;
}
.art {
  flex: none;
  width: 64px;
  height: 64px;
  border-radius: var(--r-lg);
  background: linear-gradient(135deg, var(--c-accent), var(--c-accentInk));
  box-shadow: var(--shadow);
}
.meta {
  display: grid;
  gap: 4px;
  flex: 1 1 150px;
  min-width: 0;
}
.muted {
  color: var(--c-textMuted);
  font-size: var(--fs-sm);
}
.bar {
  height: 6px;
  background: var(--c-surfaceSunken);
  border-radius: var(--r-pill);
  overflow: hidden;
  margin-top: 4px;
}
.bar i {
  display: block;
  width: 42%;
  height: 100%;
  background: var(--c-accent);
}
.time {
  display: flex;
  justify-content: space-between;
}
.ctrl {
  display: flex;
  align-items: center;
  gap: 12px;
}
.ic {
  color: var(--c-icon);
}
.play {
  display: grid;
  place-items: center;
  width: 34px;
  height: 34px;
  border-radius: 50%;
  background: var(--c-accent);
  color: var(--c-onAccent);
}
.vol {
  width: 60px;
  height: 4px;
  border-radius: var(--r-pill);
  background: var(--c-surfaceSunken);
  overflow: hidden;
}
.vol i {
  display: block;
  width: 65%;
  height: 100%;
  background: var(--c-accent);
}
</style>
