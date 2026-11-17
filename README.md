# NSL UI Core

แกน UI ร่วมของแอป NSL — design token, ไฟล์ธีม `.nslt`, เครื่องมือตรวจ contrast และเว็บ editor สำหรับสร้างธีม

| ส่วน | ที่อยู่ | คืออะไร |
|---|---|---|
| **`nsl_ui`** (Dart/Flutter) | `lib/`, `test/` | แพ็กเกจที่แอป NSL เรียกใช้: tokens, derive, contrast, parser/serializer `.nslt`, ที่เก็บธีม, widget ปรับแต่ง |
| **NSL Palette** (Vue 3 + TS) | `web/` | เว็บที่ทำงานในเบราว์เซอร์ล้วน ๆ สำหรับปรับธีมแบบลึกแล้วดาวน์โหลดเป็น `.nslt` |
| **Schema** | `schema/tokens.schema.json` | รายชื่อ token, ช่วงค่า, preset และธีมในตัว สร้างจาก Dart |

เวอร์ชันปัจจุบัน: **1.1.0** — ดูประวัติใน [`CHANGELOG.md`](CHANGELOG.md), แผนทั้งหมดใน [`Plan.md`](Plan.md), ความคืบหน้าใน [`progress.md`](progress.md)

## แนวคิด

- **Dart คือแหล่งความจริง** — เว็บไม่เก็บสำเนาค่าสีของธีมในตัว แต่อ่านจาก schema และ fixture ที่สร้างจาก Dart และมีเทสต์ parity คอยตรวจว่า TS ตรงกับ Dart
- **พึ่งแค่ Flutter SDK** — ไม่มี dependency อื่น เพื่อไม่ให้ชนเวอร์ชันกับแอปต่าง ๆ
- **เพิ่มได้ ห้ามลบ** — เวอร์ชัน core เพิ่มได้เฉพาะ token ใหม่ ห้ามลบหรือเปลี่ยนความหมายคีย์เดิม แอปและ editor รุ่นเก่าจึงอ่านไฟล์จากรุ่นใหม่ได้ (ข้ามคีย์ที่ไม่รู้จักและเก็บกลับตอนบันทึก)
- **ลำดับความสำคัญของค่า:** ธีมในตัว < ไฟล์ธีม `.nslt` < ค่าปรับแบบ lite (accent + โหมด ในแอป)

## `nsl_ui` (Dart)

### ติดตั้ง

แพ็กเกจนี้ตั้ง `publish_to: none` ใช้ผ่าน path หรือ git dependency:

```yaml
dependencies:
  nsl_ui:
    git:
      url: https://github.com/LittleSoldier2185/NSL-UI-Core.git
```

ต้องใช้ Dart SDK `^3.13.5` ขึ้นไป

### สิ่งที่มีให้

- **Tokens** — สี core 30 ตัว, shape, type, density, elevation และส่วนขยายเฉพาะแอป (`nebular`, `spectrum`, `lyra`)
- **Derive / Tint** — คำนวณสีที่เกี่ยวเนื่องจาก accent และชุด `categorical` 8 สี
- **Contrast** — ตรวจและรายงาน contrast รวมถึงสี `#RRGGBBAA` ที่มีความโปร่งใส
- **รูปแบบ `.nslt`** — parse / serialize / resolve (สืบทอดธีม, ตรวจวนลูป, clamp ค่า) ทนไฟล์ผิดรูปแบบโดยไม่โยน exception
- **ที่เก็บธีม** — `NslThemeStore`, `NslThemeController`, `NslMemoryThemeStorage` พร้อม watcher และ safe mode
- **ธีมในตัว** — `nsl.default`, `nsl.nebular`, `nsl.spectrum`, `nsl.lyra.paper` (id เหล่านี้ห้ามเปลี่ยน)
- **Widget** — `NslAppearancePanel` (ชุดปรับแต่ง lite) และ `NslGallery`
- **ThemeData กลาง** — `buildNslThemeData(tokens)` สร้าง `ThemeData` จาก token (ColorScheme + ตัวควบคุมของ Material ทั้งหมด + แนบ `NslTheme`) : `MaterialApp(theme: buildNslThemeData(resolveTokens(spec, Brightness.light)), darkTheme: buildNslThemeData(resolveTokens(spec, Brightness.dark)))`
- **Component กลาง** — `NslButton`, `NslIconButton`, `NslPanel`, `NslBadge`, `NslProgressBar`, `NslEmptyState`, `NslListRow`, `NslNavItem`, `NslColorPicker` ; อ่านค่าทั้งหมดจาก token ผ่าน `context.nsl` (ไม่ได้แนบ `NslTheme` ก็ใช้ได้ — ถอยไปธีมในตัว) ; ใส่ธีมให้ทั้งต้นไม้ด้วย `ThemeData(extensions: [NslTheme(tokens)])` หรือเฉพาะบางส่วนด้วย `NslThemeScope(tokens:, child:)` ; ดูหน้าตาทั้งหมดได้ใน `NslGallery`
  ```dart
  NslPanel(
    child: Column(children: [
      NslBadge('พร้อมใช้', tone: NslBadgeTone.success),
      NslButton(label: 'บันทึก', kind: NslButtonKind.primary, onPressed: save),
    ]),
  )
  ```
- **ฟอนต์** — Noto Sans Thai (SIL OFL, ดู `assets/fonts/OFL.txt`) อ้างด้วยชื่อ `packages/nsl_ui/Noto Sans Thai`

### เทสต์

```
flutter test
flutter analyze
```

## NSL Palette (เว็บ)

เว็บ Vue 3 + TypeScript ไม่ส่งข้อมูลออกนอกเบราว์เซอร์ ใช้ปรับสีรายตัว มุมโค้ง เงา ฟอนต์ และส่วนขยายต่อแอป แล้วดาวน์โหลดเป็นไฟล์ `.nslt`

```
cd web
npm install
npm run dev          # เปิดทดลอง
npm test             # parity กับ Dart + ตรรกะ editor + หน้าเว็บใน jsdom
npm run typecheck
npm run build        # -> dist/v<core>/ (ไม่เขียนทับเวอร์ชันเก่า, ใส่ --force ถ้าตั้งใจ)
```

รายละเอียดเรื่องการ build แยกเวอร์ชัน การเลือกแอป (`?apps=lyra,orbit`) และการรีเจนเนอเรต fixture อยู่ใน [`web/README.md`](web/README.md)

### เมื่อแก้ core ฝั่ง Dart

ต้องรีเจนเนอเรตไฟล์ที่เว็บอ่านก่อนรัน `npm test`:

```
NSL_UPDATE_SCHEMA=1 flutter test test/phase8_test.dart
NSL_UPDATE_FIXTURES=1 flutter test test/web_fixtures_test.dart
```

## โครงสร้างโฟลเดอร์

```
lib/src/        tokens, derive, contrast, format, store, widgets, builtin, ...
test/           เทสต์ของ nsl_ui (รวม parity กับธีมของแอปจริงแบบอ่านอย่างเดียว)
assets/fonts/   Noto Sans Thai
schema/         tokens.schema.json (สร้างอัตโนมัติ)
web/            NSL Palette
```

> โฟลเดอร์ `experiments/` (สำเนาแอปที่ใช้ทดลอง `nsl_ui`) อยู่ในเครื่องผู้พัฒนาเท่านั้น และไม่ถูกเก็บใน repo นี้

## สัญญาอนุญาต

ฟอนต์ Noto Sans Thai อยู่ภายใต้ SIL Open Font License (`assets/fonts/OFL.txt`) — ยังไม่ได้กำหนดสัญญาอนุญาตของโค้ดในแพ็กเกจนี้
