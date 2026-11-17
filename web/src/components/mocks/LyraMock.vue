<script setup lang="ts">
import { computed } from 'vue';
import type { NslTokens } from '../../core/tokens';
import { mockText } from './mockText';

// หน้าตาโดยประมาณของ Lyra (NSL Writer Tools): รายการโลกนิยาย — ป้ายประเภท 7 แบบ, ป้ายสถานะ, ข้อความเนื้อหา, กราฟความสัมพันธ์
defineProps<{ tokens: NslTokens }>();
const entries = computed(() => mockText.value.lyra.entries.map((e, i) => ({ ...e, on: i === 0 })));
</script>

<template>
  <div class="ap-lyra">
    <div class="bar"><strong>{{ mockText.lyra.world }}</strong><span class="sp"></span><span class="pill">{{ mockText.lyra.newEntry }}</span></div>
    <div class="body">
      <nav class="list">
        <div v-for="e in entries" :key="e.name" class="row" :class="{ on: e.on }">
          <span class="glyph" :class="`t-${e.type}`">{{ e.glyph }}</span>
          <span class="nm">{{ e.name }}</span>
          <span class="st" :class="`s-${e.status}`">{{ e.status }}</span>
        </div>
      </nav>
      <article class="detail">
        <h3>{{ entries[0]!.name }}</h3>
        <p class="sum">{{ mockText.lyra.summary }}</p>
        <p class="txt">{{ mockText.lyra.body }}</p>
        <div class="back">
          <span class="muted">{{ mockText.lyra.backlinks }}</span>
          <span class="snip">{{ mockText.lyra.snippet }}</span>
        </div>
        <svg class="graph" viewBox="0 0 200 70" aria-hidden="true">
          <line x1="40" y1="35" x2="100" y2="18" stroke="var(--e-lyra-edge)" stroke-width="1.5" />
          <line x1="100" y1="18" x2="160" y2="40" stroke="var(--e-lyra-edge)" stroke-width="1.5" />
          <line x1="40" y1="35" x2="140" y2="58" stroke="var(--e-lyra-dash)" stroke-width="1.5" stroke-dasharray="4 3" />
          <circle cx="40" cy="35" r="9" fill="var(--e-lyra-typeCharacter)" />
          <circle cx="100" cy="18" r="9" fill="var(--e-lyra-typePlace)" />
          <circle cx="160" cy="40" r="9" fill="var(--e-lyra-typeOrg)" />
          <circle cx="140" cy="58" r="7" fill="var(--e-lyra-typeItem)" />
        </svg>
      </article>
    </div>
  </div>
</template>

<style scoped>
.ap-lyra {
  display: grid;
  min-width: 0;
}
.bar {
  display: flex;
  align-items: center;
  padding: var(--pad) var(--pad-lg);
  background: var(--c-chrome);
  border-bottom: 1px solid var(--c-borderSoft);
  font-size: var(--fs-sm);
}
.sp {
  flex: 1;
}
.pill {
  background: var(--c-accent);
  color: var(--c-onAccent);
  padding: 2px 10px;
  border-radius: var(--r-pill);
}
.body {
  display: grid;
  grid-template-columns: minmax(150px, 46%) 1fr;
}
.list {
  background: var(--c-surface);
  border-right: 1px solid var(--c-borderSoft);
  padding: var(--pad);
  display: grid;
  gap: 2px;
  align-content: start;
}
.row {
  display: grid;
  grid-template-columns: 20px 1fr auto;
  gap: 8px;
  align-items: center;
  padding: calc(var(--pad) * 0.6) var(--pad);
  border-radius: var(--r-sm);
  font-size: var(--fs-sm);
}
.row.on {
  background: var(--e-lyra-navIndicator);
  box-shadow: inset 3px 0 0 var(--c-accent);
}
.glyph {
  display: grid;
  place-items: center;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  color: var(--c-bg);
  font-size: 11px;
  font-weight: 600;
}
.t-Character { background: var(--e-lyra-typeCharacter); }
.t-Place { background: var(--e-lyra-typePlace); }
.t-Org { background: var(--e-lyra-typeOrg); }
.t-Event { background: var(--e-lyra-typeEvent); }
.t-Item { background: var(--e-lyra-typeItem); }
.t-Rule { background: var(--e-lyra-typeRule); }
.t-Species { background: var(--e-lyra-typeSpecies); }
.nm {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.st {
  font-size: 10px;
  padding: 0 6px;
  border-radius: var(--r-pill);
}
.s-Idea { background: var(--e-lyra-statusIdeaBg); color: var(--e-lyra-statusIdeaFg); }
.s-Draft { background: var(--e-lyra-statusDraftBg); color: var(--e-lyra-statusDraftFg); }
.s-Canon { background: var(--e-lyra-statusCanonBg); color: var(--e-lyra-statusCanonFg); }
.detail {
  padding: var(--pad-lg);
  display: grid;
  gap: var(--pad);
  align-content: start;
  min-width: 0;
}
h3 {
  margin: 0;
  font-family: var(--ff-content, Georgia, serif);
  font-size: var(--fs-lg);
}
p {
  margin: 0;
  font-family: var(--ff-content, Georgia, serif);
}
.sum {
  color: var(--e-lyra-summary);
}
.txt {
  color: var(--e-lyra-body);
}
.back {
  border: 1px solid var(--e-lyra-border);
  border-radius: var(--r-md);
  padding: var(--pad);
  background: var(--c-surface);
  display: grid;
  gap: 2px;
  font-size: var(--fs-sm);
}
.muted {
  color: var(--c-textFaint);
}
.snip {
  color: var(--e-lyra-snippet);
  font-family: var(--ff-content, Georgia, serif);
}
.graph {
  width: 100%;
  height: 60px;
}
</style>
