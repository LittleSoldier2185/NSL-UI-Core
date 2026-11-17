// build เว็บ NSL Palette ลง dist/v<core>/ ตามเวอร์ชัน core (อ่านจาก ../schema/tokens.schema.json)
// - build เก่าไม่ถูกเขียนทับ (ผู้ใช้แอปรุ่นเก่าต้องเปิดเว็บรุ่นเดิมได้) — ถ้าเวอร์ชันนี้มีอยู่แล้วต้องใส่ --force
// - dist/versions.json รวมรายชื่อเวอร์ชันที่โฮสต์ไว้ (หน้าเว็บอ่านไปทำตัวสลับเวอร์ชัน)
// - dist/index.html ส่งต่อไปเวอร์ชันล่าสุด
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { build } from 'vite';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const schema = JSON.parse(readFileSync(resolve(root, '../schema/tokens.schema.json'), 'utf8'));
const core = String(schema.core);
if (!/^\d{1,3}\.\d{1,3}$/.test(core)) throw new Error(`bad core version in schema: ${core}`);

const dist = resolve(root, 'dist');
const out = resolve(dist, `v${core}`);
if (existsSync(out) && !process.argv.includes('--force')) {
  console.error(`dist/v${core} มีอยู่แล้ว — build เก่าไม่ถูกเขียนทับ (ใส่ --force ถ้าตั้งใจ)`);
  process.exit(1);
}

await build({ root, base: './', logLevel: 'info', build: { outDir: out, emptyOutDir: true } });

const vfile = resolve(dist, 'versions.json');
let versions = [];
try {
  versions = JSON.parse(readFileSync(vfile, 'utf8')).versions ?? [];
} catch {
  /* ยังไม่มี */
}
if (!versions.includes(core)) versions.push(core);
const num = (v) => v.split('.').map(Number);
versions.sort((a, b) => num(a)[0] - num(b)[0] || num(a)[1] - num(b)[1]);
const latest = versions[versions.length - 1];
mkdirSync(dist, { recursive: true });
writeFileSync(vfile, `${JSON.stringify({ versions, latest }, null, 2)}\n`);
writeFileSync(
  resolve(dist, 'index.html'),
  `<!doctype html><meta charset="utf-8"><title>NSL Palette</title><meta http-equiv="refresh" content="0; url=./v${latest}/"><a href="./v${latest}/">NSL Palette v${latest}</a>\n`,
);
console.log(`built dist/v${core} (versions: ${versions.join(', ')}; latest: ${latest})`);
