# NSL Palette (เว็บสร้างไฟล์ธีม `.nslt`)

เว็บ Vue 3 + TypeScript ที่ทำงานในเบราว์เซอร์ล้วน ๆ (ไม่ส่งข้อมูลไปที่ใด) — แอป NSL ทุกตัวมีชุดปรับแต่ง lite (accent + โหมด) ในตัวอยู่แล้ว
ส่วนการปรับลึก (สีรายตัว, มุมโค้ง, เงา, ฟอนต์, ส่วนขยายต่อแอป) ทำที่นี่แล้วดาวน์โหลดเป็นไฟล์ `.nslt`

## คำสั่ง
```
npm install
npm run dev        # เปิดทดลอง
npm test           # เทสต์ทั้งหมด (parity กับ Dart + ตรรกะ editor + หน้าเว็บใน jsdom)
npm run typecheck
npm run build      # -> dist/v<core>/  (ไม่เขียนทับเวอร์ชันเก่า ; ใส่ --force ถ้าตั้งใจ)
```

## ความสัมพันธ์กับ `nsl_ui` (Dart)
- **Dart คือแหล่งความจริง** — เว็บไม่มีสำเนาค่าสีของธีมในตัวหรือ preset
  - `../schema/tokens.schema.json` (รายชื่อ token, ช่วงค่า, preset, ธีมในตัว) สร้างจาก `buildTokensSchema()`
  - `src/generated/builtin-themes.json` (ธีมในตัวเป็นข้อความ `.nslt`) และ `fixtures/core-fixtures.json` สร้างโดย `../test/web_fixtures_test.dart`
- แก้ core ฝั่ง Dart แล้วต้องรีเจนเนอเรต: `NSL_UPDATE_SCHEMA=1 flutter test test/phase8_test.dart` และ `NSL_UPDATE_FIXTURES=1 flutter test test/web_fixtures_test.dart` (ที่โฟลเดอร์ `NSL-UI`) แล้วรัน `npm test` —
  ถ้า TS ไม่ตรง เทสต์ใน `tests/fixtures.test.ts` จะล้มและบอกว่ากรณีไหนต่าง
- `src/core/` คือ TS port ของ parser/serializer `.nslt`, resolve, derive, contrast, tint, autoFix — เทียบกับ Dart ที่ระดับ 8 บิตต่อช่อง
  (tint 824 กรณี, resolve 158 กรณี, parse 349 กรณีรวมสุ่มกลายพันธุ์, contrast, autoFix)

## เวอร์ชัน
- แต่ละ build อยู่ใต้ `dist/v<core>/` (เช่น `v1.1/`) พร้อม `dist/versions.json` ที่หน้าเว็บอ่านไปทำตัวสลับเวอร์ชัน และ `dist/index.html` ที่ส่งต่อไปเวอร์ชันล่าสุด
- ใช้ `base: './'` จึงวางใต้ path ไหนก็ได้โดยไม่ต้อง build ใหม่
- **ห้ามเขียนทับ build เก่า** — ผู้ใช้แอปรุ่นเก่าต้องเปิดเว็บรุ่นเดิมได้
- ฟังก์ชัน `parseNslt` ใน TS ใช้ `JSON.parse` ซึ่งอ่าน `1.0` เป็นจำนวนเต็ม ต่างจาก Dart ที่ถือเป็น double — ถ้า `"schema": 1.0` Dart ปฏิเสธ แต่ TS รับ (ไม่มีไฟล์ที่ editor สร้างเองเป็นแบบนี้)

## เลือกแอป (`src/apps.ts`)
- ผู้ใช้เลือกได้ว่าทำธีมให้แอปไหน (หลายแอปได้) : เปลี่ยนธีมฐานเริ่มต้น, กรองแท็บส่วนขยาย, เปลี่ยนพรีวิวเป็นหน้าตาของแอป, แสดงตารางความรองรับและคำเตือนเวอร์ชัน — **ไม่เขียนลงไฟล์ธีม**
- `apps.ts` มีตารางความรองรับที่ **เขียนมือ** (ไม่ได้มาจาก Dart) — อัปเดตทุกครั้งที่ย้ายแอปเพิ่มหรือแอปรับค่าใหม่ ; เทสต์ตรวจแค่ความครบและชื่อส่วนขยาย ไม่ได้ตรวจความจริง
- ถ้าเพิ่มส่วนขยายใหม่ใน core: ต้องมีแอปเจ้าของใน `apps.ts`, ฟังก์ชัน derive ใน `src/core/extensions.ts`, และพรีวิวใน `src/components/mocks/` (ถ้าต้องการ)
- ลิงก์: `?apps=lyra,orbit`

## ที่เก็บไฟล์ธีม (บอกผู้ใช้ในหน้าเว็บ)
ไฟล์ธีมอยู่ที่ `Documents\NSL\Themes` (Windows) ; ค่าตั้งภายในอยู่ที่ AppData ผู้ใช้ไม่ต้องยุ่ง ; Android ไม่มี NSL Launcher และแอปแชร์ธีมกันไม่ได้ ต้องนำเข้าทีละแอป — ดู `../Plan.md` 9.7

## ไอคอนแบรนด์

ไอคอนใน `public/brand/` (ปุ่มเลือกแอป, หัวหน้าเว็บ, favicon) คัดลอกมาจาก **NSL Brand Pack** (`D:\NSL Product\NSL-Brand-Pack`) — `apps/nsl-<แอป>/<แอป>_icon_rounded.svg` → `brand/<id>.svg` (id ตรงกับ `AppId` ; Nebula ของ Brand Pack = `nebular`), `nsl-palette` → `palette.svg`, `apps/nsl-palette/palette_windows.ico` → `favicon.ico` (แท็บเบราว์เซอร์ใช้ไอคอน Palette ไม่ใช่โลโก้ NSL ; เบราว์เซอร์ที่รองรับใช้ `palette.svg`)
อัปเดตไอคอนให้คัดลอกทับไฟล์เหล่านี้ใหม่ ; เทสต์ตรวจว่ามีครบทุกแอปและ SVG ไม่มีสคริปต์/ลิงก์ภายนอก
