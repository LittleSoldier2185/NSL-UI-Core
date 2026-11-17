import { ref } from 'vue';

/**
 * ธีมของหน้าเว็บ NSL Palette เอง (ไม่เกี่ยวกับธีมที่กำลังแก้) : ตามระบบ / สว่าง / มืด
 * เก็บในเบราว์เซอร์นี้เท่านั้น — อ่าน/เขียนไม่ได้ (โหมดส่วนตัว ฯลฯ) ก็ยังทำงาน แค่ไม่จำ
 */
export type UiTheme = 'system' | 'light' | 'dark';
export const uiThemes: readonly UiTheme[] = ['system', 'light', 'dark'];

const KEY = 'nsl-palette-ui-theme';

function stored(): UiTheme {
  try {
    const v = localStorage.getItem(KEY);
    if (v === 'light' || v === 'dark' || v === 'system') return v;
  } catch {
    /* ไม่มี storage */
  }
  return 'system';
}

export const uiTheme = ref<UiTheme>(stored());

/** ใส่ `data-theme` ที่ <html> ("system" = ไม่ใส่ ให้ CSS ตาม prefers-color-scheme) */
export function applyUiTheme(v: UiTheme = uiTheme.value): void {
  if (typeof document === 'undefined') return;
  const root = document.documentElement;
  if (v === 'system') delete root.dataset.theme;
  else root.dataset.theme = v;
}

export function setUiTheme(v: UiTheme): void {
  uiTheme.value = v;
  applyUiTheme(v);
  try {
    if (v === 'system') localStorage.removeItem(KEY);
    else localStorage.setItem(KEY, v);
  } catch {
    /* ไม่จำก็ได้ */
  }
}
