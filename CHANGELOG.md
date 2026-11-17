# Changelog — nsl_ui (UI Core)

กติกาเวอร์ชัน: `schema` ของไฟล์ `.nslt` เป็นจำนวนเต็ม เปลี่ยนเฉพาะเมื่อโครงสร้างแตกหัก ; เวอร์ชัน core (`major.minor`) เพิ่มได้เฉพาะ token ใหม่
**ห้ามลบหรือเปลี่ยนความหมายของคีย์เดิม** (แอป/editor รุ่นเก่าต้องอ่านไฟล์จากรุ่นใหม่ได้ โดยข้ามคีย์ที่ไม่รู้จักและเก็บกลับตอนบันทึก)

## 1.2.0 — 2026-11-17

เพิ่มอย่างเดียว — **ชุด component กลาง** (Dart เท่านั้น) ; **ไม่แตะ token / schema / รูปแบบไฟล์ `.nslt`** จึง **`kNslCoreVersion` ยังเป็น `1.1`** (เว็บ NSL Palette, fixture, ตราในไฟล์ธีม และแอปที่ใช้ core 1.1 ไม่ต้องเปลี่ยนอะไร) — เลขเวอร์ชันแพ็กเกจ `pubspec.yaml` เพิ่มเป็น 1.2.0 เพราะมี API ใหม่

- การเข้าถึง token : `NslTheme` (ThemeExtension), `NslThemeScope`, `context.nsl` (ไม่มี extension = ใช้ `nsl.default` ตามโหมดของ Theme), `context.nslTouch`
- ตัวช่วยกลาง : `NslTokens.controlHeight({touch})`, `gap`, `textStyle(...)`, `legibleOn(fg, bg)` (ปรับสีตัวอักษรให้ผ่าน 4.5:1 เฉพาะเมื่อไม่ผ่าน)
- component : `NslButton` (primary/secondary/danger/ghost), `NslIconButton`, `NslPanel` (surface/raised/sunken), `NslBadge` (6 โทน), `NslProgressBar`, `NslEmptyState`
  - ค่าทั้งหมดมาจาก token (สี, มุมโค้ง `shape`, ระยะ/ความสูงตาม `density`, ฟอนต์/ขนาดตาม `type`, เงาตาม `elevation`) — มีเทสต์ guard ห้ามฮาร์ดโค้ดสี/มุมโค้ง/ขนาดตัวอักษรในไฟล์ component
  - จอสัมผัสพื้นที่แตะ ≥ 44 · Semantics ครบ (ปุ่มมี action แตะ) · โฟกัสคีย์บอร์ดเห็นวงชัด · contrast ≥ 4.5 ทุกธีมในตัว × 2 โหมด (ตรวจจากสีที่เรนเดอร์จริง)
- `NslGallery` : เพิ่มส่วน "Components" (พรีวิวด้วย `tokens` ที่ส่งเข้ามา) — ข้อความเดิมของ Gallery ไม่เปลี่ยน

## 1.1.0 — 2026-11-16

เพิ่มอย่างเดียว (ไฟล์/แอปจาก 1.0 ใช้ต่อได้ทั้งหมด):

- ส่วนขยาย `lyra` (22 คีย์: body, accentDark, summary, snippet, chipText, border, dash, edge, navIndicator, สีประเภท 7, ป้ายสถานะ 3 คู่) + ธีมในตัว `nsl.lyra.paper` (กระดาษอุ่นของ Lyra)
- `NslExtensionDef.accentDependents` : คีย์ของส่วนขยายที่คำนวณจาก accent จะถูกคำนวณใหม่เมื่อธีมลูกหรือค่า lite เปลี่ยน accent (`lyra.accentDark`, `nebular.fkChip`) — ผลข้างเคียง: ธีมลูกของ `nsl.nebular` ที่เปลี่ยน accent จะได้ `fkChip` ตาม accent ใหม่ (เดิมค้างเป็นสีเขียวน้ำเงินของฐาน)
- `kBuiltinThemeIds` เพิ่ม `nsl.lyra.paper`
- API ของ Dart: `NslThemeStore.standard(documents:, settingsRoot:)` — ไฟล์ธีมที่ `Documents/NSL/Themes` แยกจากค่าตั้ง (`%APPDATA%\NSL`) ; ตัวสร้างเดิมใช้ได้ ; **รูปแบบไฟล์ธีมและ schema ไม่เปลี่ยน**
- แก้: `checkContrast`/`isUnusable` คิดความโปร่งใสของสี `#RRGGBBAA` (ผสมบนพื้นก่อนวัด) — สีทึบผลเท่าเดิม
- แก้: watcher ข้ามเหตุการณ์ "ย้าย" ของการเขียนแบบ atomic (ตัวกรอง `.tmp` ดูต้นทางแทนปลายทาง)
- `schema/tokens.schema.json`: เพิ่มค่า preset (hex) และ `accentDependents` ของส่วนขยาย (เว็บ NSL Palette อ่านไปใช้) — เพิ่มอย่างเดียว

## 1.0.0 — 2026-11-16 (freeze)

สิ่งที่ freeze ไว้ใน v1.0 (เพิ่มได้ใน 1.x แต่แก้ความหมายไม่ได้):

- สี core 30 token — เพิ่ม `selected`, `accentBorder`, `textFaint` (รายชื่อตัวจริงอยู่ที่ `schema/tokens.schema.json`)
- `tint(base)` : `accentTints` / `tintFor` (พอร์ตสูตร HSL ของ NSL Utility; ขยับให้ผ่าน 4.5:1 เฉพาะกรณีที่ของเดิมต่ำกว่าเกณฑ์) + ชุด `categorical` 8 สี
- ชุดปรับแต่ง lite : `NslAppearance` (โหมด + preset/สีกำหนดเอง), `kAccentPresets` 8 ชุด, `NslAppearancePanel`, เก็บใน `ui-settings.json`
  ลำดับความสำคัญ: ธีมในตัว < ไฟล์ธีม < ค่า lite
- ฟอนต์สามบทบาท `family` / `content` / `mono` + `minSize`
- `NslThemeStorage` (interface) + `NslThemeStore` (ดิสก์) + `NslMemoryThemeStorage` ; นำเข้า/ส่งออก `.nslt` ผ่าน `NslThemeController`
- `NslTokens.toArgbMap()` สำหรับโค้ด native
- `visualDensityFor(touch:)` และ `kMinTapTarget`
- ฟิลด์ `core` ในไฟล์ธีม + `kNslCoreVersion`
- `schema/tokens.schema.json` (สร้างจาก `buildTokensSchema()` ; มีเทสต์ตรวจว่าตรงกัน)
- id ธีมในตัว: `nsl.default`, `nsl.nebular`, `nsl.spectrum` ; คีย์ส่วนขยาย `nebular`, `spectrum`
  (**หลังปล่อยแอปทางการ ห้ามเปลี่ยน id**)

## 0.1.0

- แกนเริ่มต้น: tokens, derive, contrast, `.nslt`, ที่เก็บธีม + watcher + safe mode, adjust, `NslGallery`
