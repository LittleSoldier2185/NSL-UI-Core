import vue from '@vitejs/plugin-vue';
import { defineConfig } from 'vitest/config';

// base './' = วางไว้ใต้ path ไหนก็ได้ (เช่น /v1.1/) โดยไม่ต้อง build ใหม่
export default defineConfig({
  base: './',
  plugins: [vue()],
  server: { fs: { allow: ['..'] } }, // อ่าน ../schema/tokens.schema.json (แหล่งความจริงจากฝั่ง Dart)
  test: { environment: 'node', include: ['tests/**/*.test.ts'] },
});
