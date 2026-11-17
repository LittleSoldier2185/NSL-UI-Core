# NSL UI — ความคืบหน้า

แผนทั้งหมด: [`Plan.md`](Plan.md) · สถานะ: **การทดลอง** (ต่อกับสำเนาของแอปใน `experiments/` เท่านั้น ; แอปจริงยังไม่ถูกแตะ)

อัปเดตล่าสุด: 2026-11-16 · `nsl_ui` **v1.1.0 เทสต์ 154 ข้อผ่าน** · เว็บ NSL Palette (`web/`) **เทสต์ 57 ข้อผ่าน** · สำเนา Resonance (ใช้ `nsl_ui`) 287 ข้อผ่าน (254 เดิม + 33 ใหม่) · สำเนา Dev (ใช้ `nsl_ui`) **1,286 ข้อผ่าน (1,262 เดิมโดยไม่แก้ + 24 ใหม่)** · `flutter analyze` ของ `nsl_ui` และสำเนาทั้งสองสะอาด (สำเนา Resonance เท่าต้นฉบับ 77 info)

## กติกาของงานทดลองนี้
- **ห้ามแก้ไฟล์เดิมของ NSL Dev / NSL Resonance** (รวม `pubspec.yaml`) — ถ้าต้องทดลองกับแอป ให้ทำด้วยไฟล์ใหม่แยกต่างหากเท่านั้น
- **ทุกแอปที่จะทดลอง (รวม nsl_writer_tools และ NSL Utility) ให้คัดลอกมาไว้ใน `experiments/<ชื่อ>_copy/` แล้วทดลองกับสำเนาเท่านั้น** (ผู้ใช้ยืนยัน 2026-11-16) ; คัดลอกเฉพาะที่จำเป็น ไม่ลอก `build/`, `.dart_tool/`, `.git` ; ถ้าแอปมี `windows/` หรือ `android/` ที่ต้องรัน ให้เปลี่ยนชื่อผลิตภัณฑ์/applicationId ในสำเนาเพื่อไม่ให้ข้อมูลปนกับแอปจริง
- เทสต์ parity อ่านไฟล์ `theme.dart` ของแอปแบบอ่านอย่างเดียวผ่าน relative import (ไม่คัดลอกค่ามาไว้)
- ยังไม่ได้ `git init` / commit (รอตัดสินใจ)

## เฟสที่ทำแล้ว

### เฟส 0 — เส้นฐาน [เสร็จบางส่วน]
- เทสต์เดิมก่อนเริ่ม: NSL Dev **1,262 ผ่าน**, NSL Resonance **254 ผ่าน**
- git status ของสองแอปหลังทำงาน: ไม่มีไฟล์ที่ track ถูกแก้ (มีแต่ไฟล์ untracked ที่มีอยู่ก่อน)
- **ยังไม่ได้ทำ:** golden/screenshot หน้าหลักของแอป (ต้องรันแอปจริง — ทำพร้อมเฟส 2/3)

### เฟส 1 — แกน `nsl_ui` [เสร็จ]
- โครง: `tokens/` (สี core 27 ตัว, shape, type, density, elevation, ส่วนขยายต่อแอป) · `derive/` · `contrast/` · `format/` (`.nslt` parse/serialize/resolve) · `builtin/`
- ธีมในตัว: `nsl.dev`, `nsl.resonance(accent)`, `nsl.default` (ตอนนี้เท่า `nsl.dev`)
- dependency: Flutter SDK อย่างเดียว · ฟอนต์ Noto Sans Thai คัดลอกมาไว้ใน `assets/fonts/` (ของ Dev ยังอยู่ที่เดิม)
- เทสต์ 71 ข้อ: contrast, derive/resolve (สืบทอด, วนลูป, ลึกเกิน, ล้างค่าที่ขึ้นกับ accent), codec (round trip, clamp, Infinity, path/URL, ขนาดไฟล์, คีย์ไม่รู้จัก), **fuzz 3,000 รอบ + JSON ชนิดผิด + ซ้อนลึก 5,000 ชั้น ไม่โยน exception**, **parity กับ `theme.dart` จริง**
  - Dev: ทุกช่องของ `Palette` + `C.danger*/boardOutside/boardEdge/fkSource/fkChip` × 2 โหมด
  - Resonance: `NslPalette.of` ทุกช่อง × 2 โหมด × 8 accent + ฟังก์ชัน `contrast/inkFor/onAccentFor` เท่าต้นฉบับ

### เฟส 2 — Resonance ใช้ `nsl_ui` [เสร็จในสำเนาทดลอง `experiments/resonance_copy/`]
วิธี: ตัวเลือก ก (สำเนาเฉพาะ `lib`, `test`, `pubspec`, `analysis_options`) — **ไฟล์จริงใน `NSL-Media-Player` ไม่ถูกแตะ** (git status ไม่มีไฟล์ track ที่ถูกแก้)

ไฟล์ที่ต่างจากต้นฉบับ (ทั้งหมด 3 ไฟล์):
- `pubspec.yaml`: เพิ่ม `nsl_ui` (`path: ../..`)
- `lib/ui/theme.dart`: `NslPalette.of` สร้างจาก `nsl_ui` (`builtinResonance(accent)`) ; เพิ่ม `NslPalette.fromTokens` ; `contrast/inkFor/onAccentFor` เป็นตัวห่อฟังก์ชันของ `nsl_ui` ; `buildTheme(b, accent, {theme})` รับธีมจากไฟล์ `.nslt` ได้ (ไม่ส่ง = พฤติกรรมเดิม) — **API เดิมคงครบ** (`context.pal`, `NslPalette.of`, ชื่อฟังก์ชัน) จึงไม่ต้องแก้ไฟล์ UI อื่นเลย
- `test/nsl_ui_theme_test.dart` (ใหม่): เทียบกับ `theme.dart` ต้นฉบับแบบอ่านอย่างเดียว (palette 14 ช่อง × 2 โหมด × 6 accent, `buildTheme`, ฟังก์ชัน contrast) + ธีมจากไฟล์ `.nslt` (extends, accent เปลี่ยน → accentInk คำนวณใหม่, โหมดที่ไม่ระบุคงเดิม, ฐานหาย → โยนให้ผู้เรียกจับ) + เรนเดอร์ `AppSidebar` จริงภายใต้ธีมจากไฟล์

ผล: เทสต์เดิม 254 ข้อผ่านโดยไม่แก้ · ใหม่ 30 ข้อ · `flutter analyze` ได้ 77 รายการเท่าต้นฉบับ (info ของเดิมทั้งหมด ไม่มีรายการใน `theme.dart`)

เกณฑ์เสร็จของเฟสตามแผน: "golden เทียบเส้นฐานเหมือนเดิม" — **ยังไม่ได้ทำ golden ภาพ** ใช้เทสต์เทียบค่าสี + เทสต์ widget เดิม 6 ไฟล์ที่เรนเดอร์ผ่าน `buildTheme` แทน (ยังไม่ได้ลองรันแอปจริงดูด้วยตา)

ที่ยังไม่ได้ต่อ (ตั้งใจ): `main.dart` ของสำเนายังเรียก `buildTheme(brightness, accent)` แบบเดิม — ยังไม่มีทางเลือกธีมใน Settings (เฟส 4)

### เฟส 3 — NSL Dev ใช้ `nsl_ui` [เสร็จในสำเนาทดลอง `experiments/dev_copy/`]
วิธี: ตัวเลือก ก เช่นเดียวกับเฟส 2 (สำเนา lib, test, assets, samples, pubspec, analysis_options, CHANGELOG.md — เทสต์ `version_status_test` อ่านไฟล์นี้) — **ไฟล์จริงใน `NSL-Modeler` ไม่ถูกแตะ**

ไฟล์ที่ต่างจากต้นฉบับ (4 ไฟล์ + เทสต์ใหม่ 1 ไฟล์):
- `pubspec.yaml`: เพิ่ม `nsl_ui` (`path: ../..`)
- `lib/ui/theme.dart`: `Palette` เพิ่มฟิลด์ที่เดิมฮาร์ดโค้ดอยู่ใน `C` (`danger*`, `boardOutside/Edge`, `fkSource`, `fkChip`) + `tokens` ; `Palette.fromTokens` ; `kLightPalette/kDarkPalette` กลายเป็น `final` คำนวณจากธีมในตัว `nsl.dev` (ไม่มีค่าสีตายตัวในไฟล์นี้อีก) ; `paletteFor(brightness, {theme})` ; `C.danger/board/fk` อ่านจากพาเลตต์ ; **เงาตาม `elevation.strength` และโหมด `flat`** (ค่าเริ่มต้นเท่าเดิม) ; `buildTheme([Palette?])` (เดิมค่าตั้งต้นเป็น const)
- `lib/state/app_settings.dart`: `nslTheme`, `themeRevision`, `setNslTheme()` (ยังไม่เก็บลง settings.json)
- `lib/main.dart`: เรียก `paletteFor(..., theme: settings.nslTheme)` + **จับ `NslResolveException` แล้วถอยไปธีมในตัว** ; เพิ่ม `themeRevision` ใน key ของ `MaterialApp` (เพื่อสร้างต้นไม้ใหม่ตอนเปลี่ยนธีม — วิธีเดียวกับที่ภาษา/โหมดมืดใช้อยู่แล้ว)
- `test/nsl_ui_theme_test.dart` (ใหม่ 14 ข้อ)

**โค้ดที่เรียก `C.xxx` (657 จุด / 58 ไฟล์) ไม่ต้องแก้แม้แต่บรรทัดเดียว** — adapter ตามแผนใช้ได้จริง

เทสต์ใหม่: เทียบกับ `theme.dart` ต้นฉบับแบบอ่านอย่างเดียว (Palette ทุกช่อง × 2 โหมด, `C.*` ที่คำนวณตามโหมด, เงาทั้ง 4 ระดับ, `buildTheme`) · ธีมจากไฟล์ (`paletteFor`, flat/strength ของเงา, ธีมใช้ไม่ได้) · **แอปจริง `NslDevApp`**: ใส่ธีมจากไฟล์แล้วสีเปลี่ยนสด, ถอยไปธีมในตัวเมื่อธีมใช้ไม่ได้, โหมดมืด, **เปลี่ยนธีมสดแล้วเอกสาร/แท็บที่เปิด/สถานะแก้ไขไม่หาย** (controller อยู่นอกต้นไม้วิดเจ็ต — ยืนยันความเสี่ยงข้อ 3 ในแผนแล้ว ว่าไม่เกิดขึ้น)

ผล: เทสต์เดิม 1,262 ผ่านโดยไม่แก้ · `flutter analyze` สะอาด · diff ของ `lib` ราว 542 บรรทัด ส่วนใหญ่คือการลบค่าสีตายตัวออกจาก `theme.dart`

**ยังไม่ได้ทำ (ตั้งใจ ไว้เฟส 5):** มุมโค้ง/ขนาดฟอนต์/density ยังเป็นค่าตายตัวของแอป (dialog 14, popup 10 ฯลฯ ไม่ตรงบันไดของ shape ถ้าเปลี่ยนจะไม่ตรง parity) — ตอนนี้ธีมจากไฟล์ปรับได้เฉพาะ **สี + เงา** ยังไม่ครบระดับ 3 ; ยังไม่ได้ย้าย Noto Sans Thai ไปใช้ของ `nsl_ui` ; ยังไม่ได้ทำ golden ภาพ/รันแอปจริงดูด้วยตา ; สี syntax SQL ยังเป็นค่าตายตัวใน `sql_dock`/`sql_view`

### เฟส 4 — ที่เก็บธีมกลาง + watcher + safe mode [เสร็จในแกนและสำเนาทดลองทั้งสอง ; ยังไม่มี UI เลือกธีมในแอป]
- `nsl_ui/lib/src/store/theme_store.dart`: `NslThemeStore(root)` อ่าน/เขียน `<root>/themes/*.nslt` และ `<root>/ui-settings.json` ; `defaultRoot()` = `%APPDATA%\NSL` ; เขียนแบบ atomic (ไฟล์ชั่วคราว + rename) ; `watch()` ดูโฟลเดอร์ (debounce, มองข้าม `.tmp`)
- ความปลอดภัยของไฟล์ในโฟลเดอร์ (ถือเป็นข้อมูลไม่น่าเชื่อถือ): ไม่ตาม symlink, ข้ามไฟล์ใหญ่เกิน 64KB, ผ่าน `parseNslt` เท่านั้น, ห้าม id ที่ขึ้นต้น `nsl.` (สงวนธีมในตัว), ชื่อไฟล์ต้องตรง id, `saveTheme` ปฏิเสธ id ที่มี `/`, `\`, `..` ; ไฟล์ที่ข้ามถูกรายงานใน `problems`
- `nsl_ui/lib/src/store/theme_controller.dart`: `NslThemeController` (ChangeNotifier) — `select`, `setSafeMode`, `startWatching`, `activeSpec` เป็น null เมื่อ safe mode/ไม่ได้เลือก/ไฟล์หาย/resolve ไม่ผ่าน (ธีมผู้ใช้ extends ธีมผู้ใช้อีกไฟล์ได้)
- Dev (สำเนา): `NslDevApp(themes:)` ฟังตัวควบคุม → `AppSettings.setNslTheme(spec, lookup:)` ; `main()` สร้างตัวควบคุมจาก `%APPDATA%\NSL` ; `--safe-mode` ข้ามธีมผู้ใช้ ; ล้มเหลวตอนเปิด = ใช้ธีมในตัว
- Resonance (สำเนา): `NslApp(themes:)` ฟังตัวควบคุมผ่าน `Listenable.merge` ; `buildTheme(..., lookup:)` ; ธีมใช้ไม่ได้ถอยไปธีมในตัว ; `--safe-mode` เหมือนกัน
- เทสต์ใหม่: nsl_ui 14 (รวมสองตัวควบคุมคนละอินสแตนซ์เห็นธีมของกันและกันผ่าน watcher), Dev 3 (บูต `NslDevApp` จริง: เลือกธีม, safe mode, ไฟล์เสีย, อีกโปรแกรมเขียนไฟล์ → แอปเปลี่ยนสด), Resonance 2 (ที่ `buildTheme` เพราะ `NslApp` ต้องใช้ media_kit จึงไม่ได้บูตทั้งแอปในเทสต์) ; ทุกเทสต์ใช้โฟลเดอร์ชั่วคราว ไม่เขียน APPDATA จริง
- **ข้อจำกัด:** ยังไม่มีเมนูเลือกธีม/ปุ่ม safe mode ในแอป (ตั้งผ่าน `ui-settings.json` หรือ `--safe-mode`) ; ยังไม่ได้ทดสอบ `Directory.watch` ข้ามสองโปรเซสจริงบนเครื่อง (ทดสอบข้ามอินสแตนซ์ในโปรเซสเดียว) ; ยังไม่รันแอปจริงดูด้วยตา ; Resonance ยังไม่ได้บูตทั้ง `NslApp` ในเทสต์

### เฟส 5 — รูปทรง/density/ขนาดตัวอักษรจากธีม + `NslGallery` [เสร็จบางส่วนในสำเนาทดลอง]
- `nsl_ui/lib/src/theme/adjust.dart`: ตัวคูณจากค่าเริ่มต้น (`radiusFactor` = shape.md÷8, `radius(base)`, `visualDensity`, `fontSizeFactor`, `scaledTextTheme`) — ธีมที่ไม่แตะค่าเหล่านี้ได้ผลเท่าเดิมทุกค่า (มีเทสต์ parity เทียบ `theme.dart` ต้นฉบับ) ; รัศมีเฉพาะตัวของแอป (dialog 14 ฯลฯ) จึงขยับตามธีมโดยคงสัดส่วน
- `nsl_ui/lib/src/widgets/nsl_gallery.dart`: `NslGallery` หน้าตัวอย่าง widget มาตรฐาน + ตารางสี/contrast สำหรับพรีวิวใน Theme Editor
- Dev (สำเนา) `buildTheme`: รัศมี dialog/popup/snackbar/tooltip, `visualDensity`, ขนาดตัวอักษรตามธีม ; Resonance (สำเนา): `visualDensity` + ขนาดตัวอักษร
- **ข้อค้นพบ:** `ThemeData.textTheme` ไม่มีขนาดตัวอักษร (null) จนกว่า MaterialApp จะ localize → `TextTheme.apply(fontSizeFactor)` assert ; แก้โดยเติมขนาดมาตรฐาน Material 2021 ก่อนคูณ (ทำเฉพาะเมื่อ scale ≠ 1)
- **ข้อจำกัด (ยังไม่ครบระดับ 3):** ปรับได้เฉพาะ component ของ Material ที่ผ่าน ThemeData ; `BorderRadius.circular(n)` ที่ฮาร์ดโค้ดในหน้าจอของ Dev (~หลายร้อยจุด) และ `TextStyle(fontSize: n)` แบบตายตัวยังไม่ตามธีม — ต้องย้ายทีละหน้า (ควรมีเทสต์ ratchet กันเพิ่ม) ; ยังไม่มีเทสต์ guard ห้าม `Color(0x` ; ยังไม่ย้าย Noto Sans Thai ; `NslGallery` ยังไม่ได้ใช้ใน Dev จริง (รอ Theme Editor เฟส 6)

### เฟส 6 — Theme Editor ใน NSL Dev [เสร็จในสำเนาทดลอง `experiments/dev_copy/`]
- `nsl_ui/lib/src/editor/theme_draft.dart`: `NslThemeDraft` โมเดลแก้ไข (ไม่มี UI) — fromSpec/toSpec, resolve พรีวิว, `failures`, `autoFix` (ขยับสีตัวอักษร/เส้นขอบ/onAccent ให้ผ่าน contrast โดยไม่แตะสีพื้นและ accent ที่ผู้ใช้เลือก ; ลองสองทิศ จึงแก้กรณีขาวบน accent สว่างได้), `slugify` ; เพิ่ม `parseHexColor` (ใช้ parser เดียวกับไฟล์)
- `dev_copy/lib/ui/theme_editor.dart`: หน้าจอเต็ม — ชื่อ/ธีมฐาน/โหมดสว่าง-มืด/สี root 4 ตัว (hex)/มุมโค้ง/ขนาดตัวอักษร/density/ไม่ใช้เงา + รายงาน contrast + ปุ่มแก้อัตโนมัติ + พรีวิวด้วย `NslGallery` ใต้ `buildTheme` จริงของ Dev ; ปุ่มจานสีในแถบบน (แสดงเฉพาะเมื่อมีที่เก็บธีมกลาง) ; บันทึก = เขียนลงที่เก็บกลาง + เลือกใช้ → Resonance เปลี่ยนตามผ่าน watcher
- ความปลอดภัย: ช่องสีรับเฉพาะ `#RRGGBB(AA)` ผ่าน parser ของไฟล์ (ข้อความอื่นถูกทิ้ง) ; ชื่อที่ slug แล้วขึ้นต้น `nsl.` ถูกปฏิเสธก่อนเขียนไฟล์ ; id เป็นชื่อไฟล์ผ่าน `isValidThemeId` เสมอ
- เทสต์ใหม่: nsl_ui 6 (draft), Dev 4 (บูต `NslDevApp` จริง: แก้+บันทึก → ไฟล์/สีแอป/อีกตัวควบคุมเห็น, hex แปลกถูกทิ้ง + ชื่อสงวนถูกปฏิเสธไม่เขียนไฟล์, autofix ธีมมืดของ Dev ผ่าน, ไม่มีที่เก็บ = ไม่มีปุ่ม)
- **ข้อจำกัด:** ยังเป็นการทดลอง — ไม่มีตัวเลือกสีละเอียด (color picker) แก้เฉพาะสี root 4 ตัวที่เหลือคำนวณจาก derive ; ไม่มีลบธีม/เปลี่ยน id ; ธีมฐานเลือกได้แค่ในตัว 2 ตัว ; พรีวิวแสดง widget มาตรฐาน ไม่ใช่หน้าจอจริงของ Dev ; ยังไม่ได้รันแอปจริงดูด้วยตา

### เฟส 8 — core v1.0 [เสร็จ ; freeze เป็น `nsl_ui` 1.0.0 เมื่อ 2026-11-16]
เปลี่ยน id ภายในก่อน (งานแรก): `nsl.dev`→`nsl.nebular`, `nsl.resonance`→`nsl.spectrum`, extension `dev`→`nebular`, `resonance`→`spectrum` — เทสต์ผ่านเท่าเดิมทั้งสามชุด

สิ่งที่ทำ (ทุกข้อมีเทสต์ — `test/tint_test.dart`, `test/phase8_test.dart`, `test/appearance_panel_test.dart`):
- **token สีใหม่** `selected`, `accentBorder`, `textFaint` (รวม 30 token) ; derive จาก root ได้ ; `accentBorder` เป็นค่าที่ขึ้นกับ accent (ถูกคำนวณใหม่เมื่อธีมลูกเปลี่ยน accent) ส่วน `selected` ไม่ใช่
- **`tint`** `accentTints` / `tintFor` พอร์ตจาก NSL Utility — golden 22 กรณีสร้างจากสำเนา verbatim ของฟังก์ชันเดิม ; **ส่วนเบี่ยงเบนจากของเดิมที่ตั้งใจ:** ของเดิมไม่รับประกัน contrast ของตัวอักษรบนพื้นอ่อน (สีฟ้าอมเขียวสดได้ ~4.2:1) จึงเติม `ensureContrast` 4.5 — ค่าที่ผ่านอยู่แล้วคงเดิมทุกบิต เปลี่ยนเฉพาะสีที่ของเดิมอ่านยาก (ผู้ใช้ Utility ที่ตั้งสีเองบางสีอาจเห็นตัวอักษรเข้ม/อ่อนขึ้นเล็กน้อย) ; ชุด `categorical` 8 สี
- **ชุด lite**: `NslAppearance` (โหมด + preset หรือสีกำหนดเอง), `kAccentPresets` 8 ชุด (ค่าจาก Utility ตรง ๆ), `NslThemeSpec.withAppearance`, `resolveTokens` ใช้ค่า lite ทับ accent (ลำดับ ธีมในตัว < ไฟล์ธีม < lite), `NslThemeController.setAppearance/effective/themeMode`, เก็บใน `ui-settings.json` (อ่านแบบไม่โยน), ค่า lite **ไม่ถูกเขียนลงไฟล์ธีม** ; widget `NslAppearancePanel` (โหมด, preset, สีเอง hex+HSL, คืนค่า, ข้อความไทย/อังกฤษ, ส่ง preset ของแอปเองได้, ไม่ overflow ที่ 320px/ตัวอักษร 1.5×)
- **ฟอนต์สามบทบาท** `type.family/content/mono` + `minSize` (clamp 8–16) + `NslType.fit()`
- **ที่เก็บ**: `NslThemeStorage` interface, `NslThemeStore` implements, `NslMemoryThemeStorage` ; `store_models.dart` แยกออกมาไม่พึ่ง `dart:io` ; นำเข้า/ส่งออก `.nslt` ผ่านตัวควบคุม (`importThemeText` ปฏิเสธไฟล์เสีย/ใหญ่/id สงวน ไม่โยน) — Android ใช้ `NslThemeStore` ชี้โฟลเดอร์ส่วนตัวของแอป + นำเข้าไฟล์
- `toArgbMap()`, `visualDensityFor(touch:)` + `kMinTapTarget`, ฟิลด์ `core` + `kNslCoreVersion` ("1.0" ; ไฟล์จาก core ใหม่กว่า = เตือนและเก็บคีย์ไม่รู้จักกลับ), `schema/tokens.schema.json` สร้างจาก `buildTokensSchema()` (เทสต์ตรวจว่าตรง ; อัปเดตด้วย `NSL_UPDATE_SCHEMA=1 flutter test test/phase8_test.dart`)
- `CHANGELOG.md` + `pubspec` เป็น 1.0.0 ; **ยังไม่ได้ติด git tag เพราะ `NSL-UI` ยังไม่ใช่ git repo**

ผล: `nsl_ui` 122 ผ่าน, `flutter analyze` สะอาด ; สำเนา Resonance 287 ผ่าน (analyze 77 info เท่าเดิม), สำเนา Dev 1,286 ผ่าน (analyze สะอาด) หลัง core เปลี่ยน — ไม่ต้องแก้สำเนา

ข้อสังเกต/สิ่งที่ยังไม่ทำ:
- ตัดงาน "แยก `dart:io` ด้วย conditional export" ออก เพราะเว็บ NSL Palette เป็น Vue+TS ไม่ได้คอมไพล์ `nsl_ui`
- `NslAppearancePanel` ยังไม่ถูกใช้ในแอปใด (เฟส 9 และ 12) ; ยังไม่มี UI นำเข้าไฟล์ในแอป (เลือกไฟล์เป็นหน้าที่ของแอป เพราะ core ไม่พึ่ง `file_picker`)
- ชุด `categorical` เป็นค่าคงที่ ธีมปรับไม่ได้ใน v1.0 ; ฟอนต์ `content` ยังไม่มีผลต่อ `ThemeData` (แอปอ่านจาก token เอง)
- สี custom accent ใช้อัลกอริทึม HSL ของ Utility ตามข้อสมมติใน Plan 9.2 (ยังรอผู้ใช้ยืนยัน)

### เฟส 9 — Lyra (nsl_writer_tools) ใช้ `nsl_ui` [เสร็จในสำเนาทดลอง `experiments/lyra_copy/`]
วิธี: คัดลอก `lib`, `test`, `assets`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml` (ไม่ลอก `windows/`, `android/`, `build/`) — **ไฟล์จริงใน `nsl_writer_tools` ไม่ถูกแตะ** (ไม่ใช่ git repo จึงตรวจด้วยการเทียบไฟล์: ในสำเนาต่างจากต้นฉบับ 3 ไฟล์ใน `lib` + `pubspec.yaml` + เทสต์ใหม่ 1 ไฟล์) — เส้นฐานก่อนแก้: 139 เทสต์ผ่าน, analyze สะอาด

**core เปลี่ยนเป็น 1.1.0** (เพิ่มอย่างเดียว ดู `CHANGELOG.md`): ส่วนขยาย `lyra` 22 คีย์, ธีมในตัว `nsl.lyra.paper`, `accentDependents` ของส่วนขยาย ; เทสต์ใหม่ `test/core11_test.dart` 8 ข้อ

ไฟล์ที่ต่างจากต้นฉบับในสำเนา:
- `pubspec.yaml`: เพิ่ม `nsl_ui` (`path: ../..`)
- `lib/theme.dart`: `Palette` เพิ่มฟิลด์ `onAccent` (เดิมแอปใช้ `p.bg` เป็นสีตัวอักษรบนปุ่ม accent — ค่าเท่าเดิม แต่ตามค่า lite ได้) ; `Palette.fromTokens` ; `Palette.light/dark` กลายเป็น `final` คำนวณจาก `nsl.lyra.paper` (ไม่มีค่าสีตายตัวในไฟล์นี้อีก) ; `paletteFor(brightness, {theme, lookup})` ; `buildTheme([Palette?])` — **`C.xxx` และไฟล์ UI อื่นไม่ต้องแก้แม้แต่บรรทัดเดียว**
- `lib/app.dart`: `NslApp(themes:)` ฟังตัวควบคุม สร้างพาเลตต์จาก `effective(kBuiltinLyraPaper)` (ธีมผู้ใช้ + ค่า lite) เก็บแคชไว้เพื่อให้ identity เปลี่ยนเมื่อธีมเปลี่ยนจริง (กลไก `C.p` + markAllDirty เดิมทำงานต่อ) ; ธีมใช้ไม่ได้ = ถอยไปกระดาษอุ่น
- `lib/main.dart`: สร้างตัวควบคุม — Windows ใช้ `%APPDATA%\NSL` (แชร์กับแอปอื่น + watcher), Android ใช้โฟลเดอร์ส่วนตัวของแอป (นำเข้าไฟล์) ; `--safe-mode` ข้ามธีมผู้ใช้ ; ล้มเหลวตอนเปิด = ธีมในตัว
- `test/nsl_ui_theme_test.dart` (ใหม่ 16 ข้อ): **parity กับ `theme.dart` ต้นฉบับแบบอ่านอย่างเดียว** (Palette 26 ช่อง + onAccent × 2 โหมด, สีประเภท 7 + สถานะ 3, `buildTheme`) · ธีมปกติ `nsl.default` ใช้ได้ (ทุกประเภท/สถานะมีสี แยกกัน ป้ายอ่านได้) · ค่า lite (accent) ทับกระดาษอุ่นโดยสีกระดาษ/ประเภท/สถานะไม่เปลี่ยน · **แอปจริง `NslApp`**: นำเข้า `.nslt` (แบบ Android) → เลือก → สีเปลี่ยนสด หน้าที่เปิดอยู่ไม่หาย, ค่า lite เปลี่ยนสด + safe mode ล้าง, ธีมใช้ไม่ได้ถอยไปกระดาษอุ่น, ธีมปกติโหมดมืดบนจอ PC ไม่ overflow

ผล: **155 เทสต์ผ่าน (139 เดิมโดยไม่แก้ + 16 ใหม่)** · `flutter analyze` สะอาด · สำเนา Dev 1,286 และ Resonance 287 ยังผ่านกับ core 1.1

ข้อค้นพบ:
1. **accent กลางโทนในโหมดมืดทำให้ตัวอักษรบนปุ่มได้ไม่เกิน ~4.4:1** (เช่น preset น้ำเงิน 3A74E0 ได้ 4.42 ไม่ว่าจะขาวหรือเข้ม) — เป็นข้อจำกัดทางคณิตศาสตร์ของสีช่วงนั้น (ขาวและเข้มต่ำกว่า 4.5 พร้อมกัน) ไม่ใช่บั๊ก ; กฎ `onAccent/accent >= 4.5` ในแผนข้อ 9 จึงรับประกันไม่ได้กับ accent ทุกสี → ถ้าจะให้ผ่านจริงต้องขยับ accent เอง (ไม่ทำ เพราะต้องคงสีเดิมของ preset)
2. **`accentDark` ของ Writer ไม่ใช่ `accentInk`** (ใช้เป็นสี hover และในโหมดมืดเข้มกว่า accent) จึงใส่ในส่วนขยาย `lyra` แทนการยัดเข้า core ; `accentInk` ของ Writer ให้ core derive (แอปไม่ได้ใช้)
3. กติกา "ล้างค่าที่ขึ้นกับ accent" เดิมครอบคลุมเฉพาะสี core ; ส่วนขยายมีค่าลักษณะเดียวกัน (`fkChip` ของ Dev, `accentDark` ของ Lyra) จึงเพิ่มกลไกให้ส่วนขยายประกาศคีย์เอง — ธีมลูกของ `nsl.nebular` ที่เปลี่ยน accent จะเห็น `fkChip` ตาม accent ใหม่ (พฤติกรรมใหม่ที่ตั้งใจ)

ยังไม่ได้ทำ (ตั้งใจ ไว้เฟส 12 หรือหลังจากนี้): มุมโค้ง/ขนาดตัวอักษร/density จากธีม (Lyra ยังใช้ค่าตายตัวของแอป — ปรับได้เฉพาะสี) · ใช้ `NslAppearancePanel` ใน Settings ของ Lyra และผูกโหมดสว่าง/มืดของ lite กับ `themeModeProvider` เดิม (ตอนนี้โหมดยังมาจาก `ThemePrefs` ของแอปอย่างเดียว ค่าโหมดใน lite ถูกเมินในแอปนี้) · ปุ่มนำเข้าไฟล์ใน UI (ต้องใช้ `file_picker` ของแอป) · สี `Color(0x` นอก `theme.dart` อีก 3 จุด (graph_view/entry_editor/entry_detail) ยังไม่ย้าย · ยังไม่ได้คัดลอก `windows/` `android/` จึงยังรันเป็นแอปจริงไม่ได้ · ยังไม่ได้ทดสอบบน Android จริง (ทดสอบเส้นทางนำเข้าไฟล์ผ่านตัวควบคุมเท่านั้น)

### เฟส 10 — เว็บ NSL Palette (Vue 3 + TypeScript) [เสร็จรอบแรก — โฟลเดอร์ `NSL-UI/web/`]
**ตัดสินใจ (2026-11-16):** โค้ดเว็บอยู่ใน `NSL-UI/web/` (โฟลเดอร์เดียวกับ core เพื่ออ่าน `schema/` และ fixture โดยไม่ต้องคัดลอกข้าม repo) — คำถามที่ค้างใน Plan 9.5 ตอบแล้ว

สิ่งที่ทำ:
- **ฝั่ง Dart สร้างแหล่งความจริงให้เว็บ:** `schema/tokens.schema.json` เพิ่มค่า preset (hex) และ `accentDependents` ของส่วนขยาย ; `test/web_fixtures_test.dart` (3 ข้อ) สร้าง/ตรวจ `web/src/generated/builtin-themes.json` (ธีมในตัวเป็นข้อความ `.nslt`) และ `web/fixtures/core-fixtures.json` — ถ้าแก้ core แล้วลืมรีเจนเนอเรต เทสต์ Dart ล้มและบอกคำสั่ง
- **TS port ใน `web/src/core/`:** color (พอร์ตสูตร `Color.lerp/alphaBlend/computeLuminance/HSLColor` ของ Flutter รุ่นที่ติดตั้ง — อ่านจากซอร์ส sky_engine จริง), contrast, derive, tint, presets, extensions (nebular/spectrum/lyra), appearance (lite), parse/serialize `.nslt`, resolve, contrast report, draft + autoFix — ไม่มีสำเนาค่าสีของธีมในตัว/preset ในโค้ด TS (อ่านจากไฟล์ที่ Dart สร้าง)
- **เทสต์ parity `tests/fixtures.test.ts` เทียบกับ Dart ที่ 8 บิตต่อช่อง:** tint 824 กรณี · resolve 158 กรณี (ธีมในตัว/ธีมผู้ใช้/ค่า lite ทุก preset + สีกำหนดเอง/ธีมเสีย: ฐานหาย วนลูป ลึกเกิน ไม่มี root) · parse 349 กรณี (เขียนมือ + สุ่มกลายพันธุ์ 300) เทียบ ok/ข้อผิดพลาด/คำเตือน/ข้อความที่เขียนกลับ · contrast · autoFix — **ทดสอบแล้วว่าเทสต์จับความผิดจริง** (แก้สูตร derive 0.05→0.06, tint 0.18→0.19, ข้อความเตือน parser ทีละจุด → เทสต์ล้มทุกครั้ง ; คืนค่าแล้วผ่าน)
- **หน้าเว็บ:** ชื่อ/รหัส/ธีมฐาน, นำเข้าหลายไฟล์ (ไฟล์แรกแก้ ที่เหลือเป็นธีมฐานได้) + drag&drop, accent เร็ว (8 preset + สีกำหนดเอง ผ่านสูตร lite เดียวกับแอป), แท็บ สี (จัดกลุ่มตาม schema, ตัวเลือก+hex+ย้อนกลับค่าสืบทอด) / ส่วนขยายต่อแอป / รูปทรง+ฟอนต์ 3 บทบาท+scale+minSize / density+เงา, พรีวิวสว่าง-มืดคู่กันด้วย CSS variables, รายงาน contrast + แก้อัตโนมัติ, ดาวน์โหลด/คัดลอก `.nslt`, ปิดส่งออกเมื่อ id สงวน/ผิดรูปแบบ/ใหญ่เกิน 64 KB, ไทย/อังกฤษ, ตัวสลับเวอร์ชันจาก `versions.json`
- **build ตามเวอร์ชัน:** `npm run build` → `dist/v1.1/` + `dist/versions.json` + `dist/index.html` ส่งต่อไปล่าสุด ; **ไม่เขียนทับเวอร์ชันเดิม** (ต้อง `--force`) ; `base './'` วางใต้ path ไหนก็ได้ ; ขนาด JS 128 KB (gzip 48 KB)
- เทสต์เว็บ 39 ข้อ: parity 11 · ตรรกะ editor 18 (นำเข้า/ส่งออกไป-กลับ, ไฟล์เสีย/ใหญ่/id สงวน, ฐานหาย, คีย์ไม่รู้จักถูกเก็บกลับ, autoFix, ข้อมูลไม่น่าเชื่อถือไม่ทำให้พัง) · หน้าเว็บใน jsdom 10 (พิมพ์/คลิกแล้วไฟล์ส่งออกเปลี่ยน, สลับแท็บ/ภาษา, ปุ่มถูกปิดเมื่อ id สงวน, ชื่อธีมที่เป็น HTML ถูก escape, ไม่มี Vue warn) · ตรวจด้วยตาจากภาพ Chrome headless ของ build จริงแล้ว 1 ภาพ (โหมดมืดของระบบ, ภาษาอังกฤษ)

**เพิ่มหลังรอบแรก (2026-11-16): เลือกแอปที่ธีมนี้ทำให้** — ตามที่ผู้ใช้เสนอ (เว็บ 39 → 56 เทสต์)
- การ์ด "ทำธีมนี้ให้แอปไหน": เลือกได้หลายแอป (Nebular / Spectrum / Lyra / Orbit) อย่างน้อยหนึ่งเสมอ — **เป็นตัวช่วยตอนแก้ไขเท่านั้น ไม่เขียนลงไฟล์ธีม** (schema ไม่เปลี่ยน ไฟล์เดียวใช้ได้กับทุกแอป) ; เริ่มต้นเลือกครบทุกแอป
- **ธีมฐานเริ่มต้นตามแอป:** แอปเดียว = ธีมในตัวของแอปนั้น (Lyra → กระดาษอุ่น), หลายแอป = `nsl.default` ; เลิกเปลี่ยนตามแอปทันทีที่ผู้ใช้เลือกธีมฐานเองหรือนำเข้าไฟล์ ; ค่าเริ่มต้นของธีมใหม่จึงเปลี่ยนจาก `nsl.nebular` เป็น `nsl.default`
- **แท็บส่วนขยายกรองตามแอปที่เลือก** (Orbit ยังไม่มีส่วนขยาย) + ตัวเลือก "แสดงส่วนขยายของแอปอื่นด้วย"
- **พรีวิวหน้าตาเฉพาะแอป** (`components/mocks/`): Nebular = ตาราง ER (พื้นกระดาน หัวตาราง ป้าย PK/UQ/NN แถว FK) · Spectrum = เครื่องเล่น (แผงไล่เฉด `panelBottom` แถบเลื่อน ปุ่มเล่น) · Lyra = รายการโลกนิยาย (ป้ายประเภท 7 สถานะ 3 กราฟ ฟอนต์เนื้อหา) · Orbit = การ์ดการเงิน โดนัท ตารางวันนี้ เมนูล่าง ; แท็บสลับดูได้ + แท็บ "ทั่วไป" ; ตัวแปร CSS มาจาก `previewVars.ts` (สีทั้งหมดผ่านฟังก์ชัน resolve ตัวเดียวกับแอป)
- **ตารางความรองรับ** (`apps.ts`, **เขียนมือ** ตามผลเฟส 3/5/9 ไม่ได้มาจาก Dart ต้องอัปเดตเมื่อย้ายแอปเพิ่ม): สี/accent/ส่วนขยาย/มุมโค้ง/สัดส่วนตัวอักษร/ชื่อฟอนต์/density/เงา × 4 แอป (✓ ครบ ◐ บางส่วน ✕ ยังไม่มีผล ? ยังไม่ได้ตรวจ — มีข้อความสำหรับ screen reader) + สถานะต่อแอป ("รองรับในสำเนาทดลอง แอปจริงยังไม่อ่านไฟล์ธีม" / Orbit "ยังไม่ได้ย้าย") — เทสต์ตรวจว่าตารางครบทุกแอปทุกหมวด และชื่อส่วนขยายมีอยู่ใน schema จริง
- **คำเตือนเวอร์ชัน:** ส่วนขยายที่เริ่มหลัง core 1.0 (ตอนนี้คือ `lyra` ใน 1.1) แจ้งผู้ใช้ว่าแอปที่ใช้ core เก่ากว่าจะข้ามค่าเหล่านั้น (ไม่พัง)
- ลิงก์เลือกแอปตั้งแต่เปิด: `?apps=lyra,orbit` (ค่าไม่รู้จัก/ว่าง = ทุกแอป)
- ตรวจด้วยตาจากภาพ Chrome headless ทั้ง 4 แอป พบและแก้บั๊กหน้าตา 3 จุดจากภาพ: ตัวเลขเวลาของ Spectrum ล้นกรอบ · ชื่อคลาส `.card`/`.head` ของพรีวิว Orbit ชนกับ CSS ส่วนกลางของหน้าเว็บ · แถบเมนูล่างของ Orbit จัดแนวไม่ตรง
- **ข้อจำกัดที่ต้องรู้:** พรีวิวของแต่ละแอปเป็นภาพ "โดยประมาณจากการออกแบบที่รู้" ไม่ได้ถอดจากหน้าจอจริง (โดยเฉพาะ Orbit ที่ยังไม่ได้ย้าย — เป็นหน้าตาที่คาดว่าจะเป็น) ; ตารางความรองรับอาจล้าสมัยถ้าลืมอัปเดต

ข้อค้นพบ:
1. `1.0` ใน JSON: Dart ถือเป็น double (`"schema": 1.0` ถูกปฏิเสธ) แต่ `JSON.parse` ใน TS ให้ 1 (รับ) — เป็นความต่างที่แก้ไม่ได้ใน TS และไม่กระทบไฟล์ที่ editor สร้างเอง ; บันทึกใน `web/README.md`
2. ธีม `nsl.nebular` โหมดมืดไม่ผ่านกฎ `onAccent/accent` (3.68:1) — หน้าเว็บแสดงรายการนี้เป็นสีแดงทันทีที่เปิด (ตรงกับข้อค้นพบข้อ 1 ของโปรเจกต์ ; ปุ่ม "แก้อัตโนมัติ" จะขยับ `onAccent` ให้ผ่าน)

ยังไม่ทำ / ข้อจำกัด: ยังไม่ได้ host หรือเปิดใช้งานจริง (ที่อยู่เว็บ/โดเมนยังไม่กำหนด) · พรีวิวเป็น HTML/CSS ประมาณการ ไม่ตรง widget จริงเป๊ะ (บอกผู้ใช้ในหน้าแล้ว) · ไม่มีตัวเลือกสีแบบ HSL/สไลเดอร์ (ใช้ตัวเลือกสีของเบราว์เซอร์ + hex) · ไม่มีเลิกทำ/ทำซ้ำ · ไม่บันทึกงานที่แก้ค้างไว้ (รีเฟรช = เริ่มใหม่) · ตัวสลับเวอร์ชันยังไม่ได้ทดสอบกับ `versions.json` หลายเวอร์ชันบนโฮสต์จริง · ยังไม่ได้ทดสอบเบราว์เซอร์อื่นนอกจาก Chrome · โค้ด Vue ยังไม่ผ่านตัวตรวจ accessibility อัตโนมัติ (มี aria-label/focus ring/สีแยกจากสัญลักษณ์ ✓/✗ ตามที่ตั้งใจ แต่ไม่ได้วัด)

### ที่เก็บธีมและช่องทางแจกจ่าย [ทำแล้ว 2026-11-16 — รายละเอียดใน `Plan.md` 9.7]
ผู้ใช้ตัดสินใจ: (1) สองช่องทาง — standalone (นำเข้าไฟล์เอง) และ NSL Launcher (นำเข้าไฟล์ลงเครื่อง ไม่มีแกลเลอรีออนไลน์) · (2) **Android ไม่มี Launcher** → นำเข้าไฟล์ในแต่ละแอป · (3) ไฟล์ธีมเก็บที่ **`Documents\NSL\Themes`**
- `nsl_ui`: `NslThemeStore.standard(documents:, settingsRoot:)` — ไฟล์ธีมที่ `<documents>/NSL/Themes` แยกจากค่าตั้ง (`%APPDATA%\NSL\ui-settings.json`) ; ไม่มี APPDATA = ค่าตั้งอยู่ข้างไฟล์ธีม ; ตัวสร้างเดิม `NslThemeStore(dir)` (ธีมที่ `<dir>/themes`) ยังใช้ได้ (Android และเทสต์) ; ไม่มีการเปลี่ยนรูปแบบไฟล์ธีม/schema
- **watcher ดูสองโฟลเดอร์** (ไฟล์ธีมใน Documents + ค่าตั้งใน AppData) — ธีมใหม่และการเลือกธีมจากแอปอื่นเห็นสด
- **บั๊กเดิมที่เจอและแก้:** ตัวกรองไฟล์ `.tmp` ของ watcher ข้ามเหตุการณ์ "ย้าย" (rename `x.tmp`→`x`) เพราะ `path` ของเหตุการณ์นั้นคือต้นทาง `.tmp` — ที่เก็บแบบเดิมรอดเพราะการดูแบบ recursive ส่งเหตุการณ์ของโฟลเดอร์มาด้วย (พิสูจน์ด้วยโปรแกรมทดลองที่พิมพ์เหตุการณ์จริงบน Windows) ; แก้ให้ดูปลายทางของเหตุการณ์ย้าย
- สำเนา Dev/Resonance/Lyra: `main.dart` ใช้ `NslThemeStore.standard(documents: getApplicationDocumentsDirectory())` ; Lyra บน Android ใช้โฟลเดอร์ส่วนตัว ; สำเนา Resonance เพิ่ม `path_provider` (Dev/Lyra มีอยู่แล้ว) ; หาไม่ได้/ล้มเหลว = ธีมในตัว ไม่ให้แอปเปิดไม่ขึ้น
- เว็บ NSL Palette: ข้อความ "วิธีใช้ไฟล์" บอก `Documents\NSL\Themes` และว่า Android ไม่มี Launcher (เทสต์ใหม่ 1 ข้อ)
- เทสต์ใหม่ `test/store_layout_test.dart` (8 ข้อ): ที่ตั้งไฟล์ถูก ไม่มีอะไรหลุดผิดโฟลเดอร์ ไม่เหลือ `.tmp` · ผู้ใช้วางไฟล์เองก็เห็น · กรณีไม่มี APPDATA · กติกาความปลอดภัยเดิม (id สงวน/path/ชื่อไม่ตรง/ไฟล์ใหญ่) ใช้ต่อ · ตัวสร้างเดิมไม่เปลี่ยน · watcher ธีมใหม่/ค่าตั้งใหม่ข้ามสองโฟลเดอร์ · ตัวควบคุมสองแอปเห็นธีมและตัวเลือกของกันสด
- ผล: `nsl_ui` 141 ผ่าน · Dev 1,286 · Resonance 287 · Lyra 155 ผ่านโดยไม่ต้องแก้เทสต์เดิม ; ข้อความเก่าในไฟล์นี้ที่อ้าง `%APPDATA%\NSL\themes` (เฟส 4, 9) เป็นประวัติ — ถูกแทนที่โดยหัวข้อนี้
- **ยังไม่ได้ทดสอบ:** Documents ที่ย้ายไป OneDrive กับ watcher · `getApplicationDocumentsDirectory()` บน Windows ที่ย้ายโฟลเดอร์ (ตามเอกสาร plugin ใช้ Known Folder แต่ไม่ได้ลองบนเครื่องนี้) · `main()` ของสำเนาทั้งสามกับ path_provider จริง (เทสต์ครอบคลุม store/ตัวควบคุม) · Launcher ยังไม่มีให้ทดสอบ

### NSL Launcher (โปรเจกต์ใหม่ `H:\NSL Project\NSL-Launcher`) และการแก้ contrast ของสีโปร่งใส [2026-11-17]
- ผู้ใช้ให้สร้าง **NSL Launcher** (แหล่งโหลดแอป NSL ทั้งหมด Windows) ตามดีไซน์ใน Design canvas ; Launcher **ไม่พึ่ง `nsl_ui` ตั้งใจ** — มี engine ธีมของตัวเอง (port จาก core) ที่ตรวจกับ `web/fixtures/core-fixtures.json` ชุดเดียวกับเว็บ ; รายละเอียดอยู่ใน `NSL-Launcher/Plan.md` และ `progress.md` (เฟส 0–1 เสร็จ ยังไม่มี UI)
- ไฟล์ที่ core สร้างให้ Launcher ใช้ (ซิงก์ด้วย `NSL-Launcher/tool/sync_from_core.ps1`): `web/src/generated/builtin-themes.json`, `web/fixtures/core-fixtures.json` — **แก้ core แล้วรีเจนเนอเรต fixture ต้องรันสคริปต์นี้ด้วย**
- **บั๊กใน core ที่เจอและแก้:** `checkContrast`/`isUnusable` ไม่คิดความโปร่งใสของสี `#RRGGBBAA` (เทียบ RGB ดิบ) → ป้ายสถานะที่พื้นเป็นสีโปร่ง 14% ถูกรายงานว่าไม่ผ่าน (~1.2:1) ทั้งที่อ่านชัด และเส้นขอบขาวจาง ๆ 6% ผ่านโดยไม่ควรผ่าน ; แก้ให้ผสมสีโปร่งบนพื้นด้านหลังก่อนวัด (Dart `contrast_report.dart` + TS `contrastReport.ts`) ; สีทึบผลเท่าเดิม (ธีมในตัวทั้งหมดไม่เปลี่ยน) ; เทสต์ใหม่ `test/contrast_alpha_test.dart` (5 ข้อ) + ธีม `user.translucent` ใน fixture (Dart/เว็บ/Launcher ตรงกันทั้งสามฝั่ง)
- ชื่อธีมในตัวของ core เปลี่ยนให้ตรงแบรนด์: `nsl.nebular` = "NSL Nebular" (เดิม "NSL Dev"), `nsl.spectrum` = "NSL Spectrum" (เดิม "NSL Resonance") — id ไม่เปลี่ยน (Launcher แสดงชื่อเหล่านี้ในหน้าตั้งค่า)
- **เฟส 3 ของ Launcher (2026-11-17):** แก้ที่ core — `NslThemeStore.saveSettings` คงคีย์ที่ไม่รู้จักใน `ui-settings.json` ไว้ (เดิมเขียนทับทั้งไฟล์) และเพิ่ม `NslThemeController.deleteTheme` ; เทสต์ใหม่ `store_preserve_test.dart` 8 ข้อ ; ตรวจแล้วสำเนา Dev 1,286 / Resonance 287 / Lyra 155 ยังผ่านโดยไม่แก้เทสต์เดิม
- เส้นขอบขาว 12% ของดีไซน์ Launcher บนพื้น `#0E1D45` ได้ ~1.43:1 (ผ่านเกณฑ์ 1.3) ; ขาว 6% ได้ต่ำกว่า 1.3

### การรันสำเนาเป็นแอปจริง (Windows) [ตั้งค่าแล้ว ; ผลรันบนเครื่องผู้ใช้ยังไม่ยืนยัน]
- สำเนาตอนแรกไม่มี `windows/` (คัดลอกมาแค่ `lib`, `test`, `assets`) → `flutter run -d windows` ขึ้น "No Windows desktop project configured" ; แก้โดยคัดลอก `windows/` จากแอปจริงมาไว้ในสำเนาทั้งสอง (อ่านอย่างเดียว ไม่ลอก `flutter/ephemeral`)
- **กันข้อมูลปนกับแอปจริง:** Windows เก็บ settings/autosave/การเชื่อมต่อฐานข้อมูลตาม `ProductName` ใน `windows/runner/Runner.rc` → ในสำเนาเปลี่ยนเป็น `nsl_dev Experiment` และ `NSL Resonance Experiment` (แก้เฉพาะไฟล์ในสำเนา) สำเนาจึงใช้โฟลเดอร์ข้อมูลของตัวเอง
- ที่เก็บธีมกลาง: ไฟล์ธีมที่ `Documents\NSL\Themes` และค่าตั้งที่ `%APPDATA%\NSL` ใช้ร่วมกันระหว่างสำเนาทั้งสาม (ตั้งใจ — ดูหัวข้อ "ที่เก็บธีมและช่องทางแจกจ่าย") ; แอปจริงยังไม่อ่านโฟลเดอร์นี้ ; ทางกู้ถ้าธีมทำให้ใช้งานไม่ได้: เปิดด้วย `--safe-mode` หรือลบไฟล์ธีมที่มีปัญหาใน `Documents\NSL\Themes` (หรือ `%APPDATA%\NSL\ui-settings.json` เพื่อล้างธีมที่เลือก)
- Resonance build ครั้งแรกกำลังรันบนเครื่องผู้ใช้: log มีเพียง warning (file_picker, CMake ของ media_kit) และข้อความ `Get-Item ... C:\Users\...\AppData` จากสคริปต์ cargokit ของ `smtc_windows` — ยังไม่ทราบว่า build สำเร็จหรือไม่ ; ถ้าล้มที่ `smtc_windows` ให้ลอง Dev ก่อน (ไม่มี plugin นี้)
- ยังไม่มีใครเห็นผลด้วยตา : เทสต์ทั้งหมดเป็น widget test/unit test

## เฟสถัดไป (ปรับแผน 2026-11-16 — รายละเอียดใน `Plan.md` หัวข้อ 9)
เหตุผลที่ปรับ: (1) มีสี่แอป — NSL Utility (Android, v1.9.1) และ nsl_writer_tools (Windows+Android) เพิ่มเข้ามา (2) Theme Editor ย้ายเป็นเว็บ Vue+TS แบบแยกเวอร์ชันตาม core เพื่อไม่ต้องออกรุ่นแอปเวลาแก้ editor
- [x] **เฟส 8** core v1.0 — เสร็จและ freeze 2026-11-16 (ดูหัวข้อ "เฟส 8" ด้านบน)
- [x] **เฟส 9** ย้าย Writer (Lyra) ในสำเนา `experiments/lyra_copy/` — เสร็จ (ดูหัวข้อ "เฟส 9" ด้านบน ; ธีมในตัวชื่อ id `nsl.lyra.paper`)
- [x] **เฟส 10** เว็บ NSL Palette (Vue+TS) ใน `web/` — เสร็จรอบแรก (ดูหัวข้อ "เฟส 10" ด้านบน ; ยังไม่ได้ host/ใช้งานจริง)
- [ ] **เฟส 11** ย้าย Utility ในสำเนา: adapter ก่อน แล้วย้ายสีฮาร์ดโค้ดทีละหน้า
- [ ] **เฟส 12** งานค้าง Dev/Resonance: UI เลือกธีม, นำเข้า-ส่งออก, safe mode, ย้าย radius/fontSize
- **Branding (2026-11-16):** เว็บ = **NSL Palette** ; แอป: Utility→Orbit, Dev→Nebular, Resonance→Spectrum, Writer Tools→Lyra (ชื่อที่ผู้ใช้เห็นเท่านั้น โฟลเดอร์/โค้ดภายในไม่เปลี่ยน) ; **id ภายใน (ทำแล้ว 2026-11-16):** เปลี่ยนตรง ๆ ไม่มี alias เพราะยังไม่ปล่อยทางการ — `nsl.dev`→`nsl.nebular`, `nsl.resonance`→`nsl.spectrum`, extension `dev`→`nebular`, `resonance`→`spectrum` ใน `nsl_ui` + `dev_copy` + `resonance_copy` ; เทสต์หลังเปลี่ยน: `nsl_ui` 95 ผ่าน, Resonance copy 287 ผ่าน, Dev copy 1,286 ผ่าน ; ธีมที่ tester สร้างด้วย id เก่าต้องสร้างใหม่ (ลบ `%APPDATA%\NSL\themes` + `ui-settings.json`) ; ชื่อ Dart (`kBuiltinDevId` ฯลฯ) ยังเป็นเดิม ; ข้อความเก่าในไฟล์นี้ที่อ้าง `nsl.dev`/`nsl.resonance` เป็นบันทึกประวัติ — ดู `Plan.md` 9.6
- เฟส 6 (editor ใน Dev) ถูกแทนที่ด้วยเฟส 10 ; editor ใน `dev_copy` คงไว้เป็นต้นแบบ

## ข้อค้นพบระหว่างทำ
1. **ธีมมืดของ NSL Dev มี contrast ต่ำกว่าเกณฑ์อยู่แล้ว:** ตัวอักษรขาวบนปุ่ม accent `#14958B` ได้ 3.68:1 (เกณฑ์ 4.5) — ธีมในตัวคงค่าเดิมเพื่อ parity ; ตัวตรวจ contrast ของ `nsl_ui` จึงรายงานรายการนี้ (ไม่ใช่บั๊กของ `nsl_ui`) ; ควรตัดสินใจว่าจะแก้ที่แอปหรือไม่
2. **ไฟล์ `.nslt` เก็บสี 8 บิตต่อช่อง** แต่ `inkFor` (Color.lerp) ให้ค่าช่องเป็นทศนิยม → resolve จากไฟล์ที่เขียนกลับต่างจากต้นฉบับระดับเศษทศนิยมที่ตามองไม่เห็น (เทสต์เทียบที่ 8 บิต) ; เขียนซ้ำรอบที่สองได้ข้อความเดิม
3. **สืบทอด `nsl.resonance` แล้วเปลี่ยน accent:** `accentInk` คำนวณกับพื้นของธีม (`18191F`) ไม่ใช่ `14151A` แบบที่ Resonance ใช้เอง — ต่างเล็กน้อย ยังผ่าน 4.5:1 เสมอ (มีเทสต์)

## ที่ยังไม่ทำ (ตามเฟสในแผน)
- เฟส 4 เหลือ: UI เลือกธีม/safe mode ในแอปทั้งสอง · เฟส 5 เหลือ: ย้าย `BorderRadius`/`fontSize` ฮาร์ดโค้ดทีละหน้า + ratchet test
- สี syntax SQL ของ Dev (`dev.syntax`) ยังไม่ได้อ่านและยังไม่อยู่ในส่วนขยาย

## ตัวเลือกสำหรับการทดลองกับแอปโดยไม่แตะไฟล์หลัก
- **ก. สำเนาแอปในโฟลเดอร์ทดลอง** (เช่น `NSL-UI/experiments/dev_copy/`) แก้ได้อิสระ แต่เก็บ build/.dart_tool ซ้ำ และสำเนาจะเก่าเมื่อแอปจริงเปลี่ยน
- **ข. แอปทดลองเล็กใน `NSL-UI/example/`** ที่ใช้ `nsl_ui` และเรนเดอร์ widget จำลองหน้าตาของแต่ละแอป ไม่แตะโค้ดแอปเลย แต่ไม่ได้พิสูจน์กับโค้ดจริง
- **ค. `git worktree`/branch แยกของแอป** ไฟล์หลักบน branch หลักไม่ถูกแตะ แต่ยังคือการแก้ไฟล์เดิมใน branch ทดลอง (ขัดกับความหมายของ "ไฟล์แยก" หรือไม่ ขึ้นกับคุณ)
