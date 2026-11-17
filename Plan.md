# NSL UI — Plan (UI Core ร่วมทุกแอป + ปรับแต่งผ่าน NSL Dev)

> สถานะ: **ปรับแผนเมื่อ 2026-11-16** — ดู **หัวข้อ 9 (ฉบับปรับปรุง)** ซึ่งแทนที่ส่วนที่ขัดกันในหัวข้อ 1, 5 (เฟส 6), 8 · ขอบเขต: ระดับ 1–3 เท่านั้น
> ข้อมูลฐานมาจากการอ่านโค้ดจริงของ NSL Dev (`NSL-Modeler`) และ NSL Resonance (`NSL-Media-Player`) เมื่อ 2026-11-15

## 1. เป้าหมายและขอบเขต

**ทำ (ระดับ 1–3)**
1. **Design token**: สี, ฟอนต์, มุมโค้ง, เงา, ระยะห่าง — นิยามที่เดียว ใช้ร่วมกันทุกแอป
2. **Widget ร่วม** ที่ซ้ำกันจริง (ทยอยย้าย ไม่บังคับครบ)
3. **สไตล์ของ component**: รูปทรง (shape), ความหนาแน่น (density), ความสูงของเงา (elevation), สัดส่วนตัวอักษร (font scale)
4. **ไฟล์ธีม `.nslt`** + **Theme Editor ใน NSL Dev** พรีวิวสด และส่งธีมไปทุกแอปบนเครื่อง

**ไม่ทำ**
- ผู้ใช้จัดเลย์เอาต์เอง (ย้ายแผง/เพิ่มลบ widget) — ระดับ 4
- ธีมที่มีสคริปต์, รูปพื้นหลัง, หรือ path ภายนอก (v1 เป็นข้อมูลล้วนเท่านั้น)
- สีที่ผู้ใช้ตั้งในเอกสาร (เช่น สีตารางใน `.nsld`) — เป็นข้อมูลเอกสาร ไม่ใช่ธีม
- สีเวทีวิดีโอของ Resonance (`NslStage`) — ตั้งใจให้มืดเสมอ ไม่ปรับได้

**หลักการ**: ผู้ใช้เปลี่ยน "หน้าตา" ได้ ไม่เปลี่ยน "โครงสร้าง" · ธีมต้องไม่ทำให้ใช้งานไม่ได้ (มี safe mode เสมอ)

## 2. สถานะปัจจุบัน (ที่วัดได้)

| หัวข้อ | NSL Dev | NSL Resonance |
|---|---|---|
| ระบบสี | `Palette` 27 สี + `C.xxx` static global (`C.use(p)`) | `NslPalette` 14 สี เป็น `ThemeExtension` (`context.pal` 74 จุด) |
| จุดที่เรียกสี | `C.xxx` **657 จุด / 58 ไฟล์** (7 ตัวแรก = 483 จุด: muted 180, primary 70, border 57, text 46, primaryDark 46, danger 46, surface 38) | `context.pal.xxx` |
| สีฮาร์ดโค้ดนอก `theme.dart` | ~35 จุด กระจุกที่ `sql_dock` 13, `sql_view` 9 (สี syntax) | ~33 จุด กระจุกที่ `player_page` 11, `photo_viewer` 11 (เวที/โหมดมืด) |
| มุมโค้ง `BorderRadius.circular(n)` | ~100 จุด (6, 8, 10, 7 เด่น) | ~85 จุด (10, 16, 12, 999 เด่น) |
| ขนาดฟอนต์ | 12.5 (104), 13 (61), 12 (39), 14, 11.5 | 13 (45), 12 (43), 12.5, 14 |
| ฟอนต์ | Noto Sans Thai ฝังในแอป | Segoe UI |
| หน้าต่าง | `WindowBackend` interface + method channel `nsl_dev/window` | `window_manager` ตรง ๆ |
| การสลับธีม | สร้างต้นไม้วิดเจ็ตใหม่ทั้งหมด | `MaterialApp.theme/darkTheme` ปกติ |
| ตัวตรวจ contrast | ไม่มี | มี (`contrast`, `inkFor`, `onAccentFor`) |

ข้อสรุป: งานย้ายจริงเล็กกว่าที่ดูจากจำนวนรวม เพราะ (ก) Dev เรียกผ่าน `C` จุดเดียว ทำ adapter ได้โดยไม่แตะ 657 จุด (ข) สีฮาร์ดโค้ดจริง ๆ เหลือราว 68 จุดนอก `theme.dart`

## 3. สถาปัตยกรรม

### 3.1 แพ็กเกจ `nsl_ui` (โฟลเดอร์ `H:\NSL Project\NSL-UI`)

```
nsl_ui/
  lib/
    nsl_ui.dart                 # export สาธารณะ
    src/
      tokens/                   # โครงสร้างข้อมูลล้วน ไม่ผูก widget
        color_tokens.dart       # NslColors (core ~24 สี)
        shape_tokens.dart       # NslShape (radius scale)
        type_tokens.dart        # NslType (font family, scale)
        density_tokens.dart     # NslDensity (spacing, row height)
        elevation_tokens.dart   # NslElevation (เงา 3 ระดับ + strength)
        extensions.dart         # NslExtension (token เฉพาะแอป)
        nsl_tokens.dart         # รวมทั้งหมด = NslTokens (immutable)
      derive/                   # คำนวณค่าที่ไม่ได้ระบุ (hover, accentInk, ...)
      contrast/                 # ย้ายมาจาก Resonance: contrast, inkFor, onAccentFor
      format/                   # .nslt: parse / validate / serialize / migrate
      store/                    # โฟลเดอร์ธีม, active.json, file watcher, safe mode
      theme/                    # NslTokens -> ThemeData (+ component themes)
      scope/                    # NslThemeScope (InheritedWidget), context.nsl
      widgets/                  # NslGallery, ปุ่ม/แผง/ช่องกรอก/ชิป ฯลฯ (ทยอยเพิ่ม)
      builtin/                  # ธีมในตัว (ต้องเหมือนของเดิมทุกค่า)
  assets/fonts/                 # Noto Sans Thai (ย้ายมาจาก NSL Dev)
  test/
```

- **dependency เดียวคือ Flutter SDK** (ห้ามพึ่ง `file_picker`, `provider`, `window_manager` ฯลฯ) — ใช้ `dart:io` ล้วนสำหรับไฟล์/watcher
- ใช้แบบ `path: ../NSL-UI` ตอนพัฒนา; ตอนออกรุ่นค่อยเปลี่ยนเป็น `git:` ผูก tag (เพราะแต่ละโปรเจกต์มี `.git` แยกกัน ไม่มี repo กลาง)

### 3.2 ตารางจับคู่ token (หัวใจของแผน)

**Core colors** (ทุกแอปต้องมี)

| Token กลาง | ใช้ทำอะไร | NSL Dev | NSL Resonance |
|---|---|---|---|
| `bg` | พื้นหลังแอป | `bg` | `bg` |
| `chrome` | แถบชื่อหน้าต่าง | `bg` (ไม่มีของเดิม) | `titleBar` |
| `surface` | พื้นแผง/การ์ด | `surface` | `panelTop` |
| `surfaceRaised` | dialog/เมนู/แผงลอย | `surfaceHi` | `panelTop` (ไม่มีของเดิม) |
| `surfaceSunken` | ช่องกรอก/ราง slider | `field` | `track` |
| `borderSoft` | เส้นแบ่งอ่อน | `borderSoft` | `panelBorder` |
| `border` | เส้นขอบปกติ | `border` | derive = กลางระหว่าง soft–strong |
| `borderStrong` | ขอบช่องกรอก | `inputBorder` | `border` |
| `text` | ตัวอักษรหลัก | `text` | `text` |
| `textMuted` | ตัวอักษรรอง | `muted` | `textDim` |
| `icon` | ไอคอน | derive = lerp(text, muted) | `icon` |
| `accent` | สีเน้น (พื้นปุ่ม ฯลฯ) | `primary` | `accent` |
| `accentInk` | สีเน้นที่อ่านเป็นตัวอักษรได้ (≥4.5:1) | `primaryDark` | `accentInk` |
| `accentTint` | พื้นอ่อนของสีเน้น | `primaryTint` | derive = accent โปร่ง ~14% |
| `onAccent` | ตัวอักษรบนพื้น accent | `Colors.white` | `onAccent` |
| `hover` | พื้นตอนเมาส์ชี้ | derive | `hover` |
| `danger` / `dangerBg` / `dangerText` | ลบ/ข้อผิดพลาด | `danger*` | derive (ปัจจุบันใช้สีตรงในโค้ด) |
| `warnBg` / `warnText` | เตือน | `warn*` | derive |
| `infoBg` / `infoText` | ข้อมูล | `info*` | derive |
| `success` / `successBg` / `successText` | สำเร็จ | derive (ใหม่) | derive (ใหม่) |
| `shadow` | สีเงา | `shadow` | `0xFF000000` |

ข้อสังเกตที่ทำให้จับคู่ได้ถูก: `primaryDark` ของ Dev (ธีมมืดเป็นสีอ่อน `5ED0C4`) ทำหน้าที่เดียวกับ `accentInk` ของ Resonance เป๊ะ

**Extension ต่อแอป** (ไม่อยู่ใน core, ลงทะเบียนเอง, มี default derive จาก core เมื่อธีมไม่ระบุ)

| Extension | Token |
|---|---|
| `dev` | `canvas`, `dot`, `tableHead`, `pkBg/pkText`, `uqBg/uqText`, `nnBg/nnText`, `boardOutside`, `boardEdge`, `fkSource`, `fkChip` |
| `dev.syntax` | สี SQL syntax (ย้ายจาก `sql_dock`/`sql_view` ~22 จุด) |
| `resonance` | `panelBottom` (ปลายไล่เฉดของแผง) |

**Shape / Type / Density / Elevation** (ระดับ 3)

```
shape.radius:   xs=4  sm=6  md=8  lg=12  xl=16  pill=999     # สอดคล้องค่าที่ใช้จริงทั้งสองแอป
type.family:    ชื่อฟอนต์หลัก (string)   # fallback ต่อท้ายเสมอ: Noto Sans Thai, Leelawadee UI, Segoe UI Symbol, Segoe UI, Tahoma
type.mono:      ชื่อฟอนต์ mono
type.scale:     0.9 – 1.2                # คูณขนาดตัวอักษรของ UI (ไม่รวมตัวหนังสือบนแคนวาส)
density:        compact | normal | comfortable   # -> visualDensity + rowHeight + padding scale
elevation.mode: shadow | flat            # flat = ใช้เส้นขอบแทนเงา
elevation.strength: 0.0 – 1.5            # คูณความเข้มเงา (ระดับ sm/md/lg/bar เดิมของ Dev)
```

### 3.3 ไฟล์ธีม `.nslt` (JSON)

```json
{
  "schema": 1,
  "id": "my-teal",
  "name": "My Teal",
  "extends": "nsl.default",
  "light": {
    "colors": { "accent": "#0F766E", "bg": "#EEF1F5" },
    "extensions": { "dev": { "tableHead": "#1F2A37" } }
  },
  "dark": {
    "colors": { "accent": "#14958B" }
  },
  "shape":   { "radius": { "md": 10 } },
  "type":    { "family": "Noto Sans Thai", "scale": 1.0 },
  "density": "normal",
  "elevation": { "mode": "shadow", "strength": 1.0 }
}
```

- ระบุบางส่วนได้ — ที่ไม่ระบุมาจาก `extends` แล้ว derive (ธีมที่ตั้งแค่ `accent` ก็ใช้ได้ครบ)
- สีรูปแบบ `#RRGGBB` หรือ `#RRGGBBAA` เท่านั้น
- ที่เก็บ *(ฉบับเดิม — ถูกแทนที่โดยหัวข้อ 9.7)*: `%APPDATA%\NSL\themes\*.nslt` · ตัวเลือกที่ใช้อยู่: `%APPDATA%\NSL\ui-settings.json` (`{ "theme": "my-teal", "mode": "system|light|dark", "perApp": { "resonance": { "theme": "nsl.default" } } }`)
- แต่ละแอปเลือกใช้ธีมกลางหรือธีมของตัวเองได้ (`perApp`)

## 4. ปัญหาและวิธีแก้

| # | ปัญหา | วิธีแก้ |
|---|---|---|
| 1 | **dependency ไม่ตรงกัน** (`file_picker` ^13 vs ^6) | `nsl_ui` พึ่งแค่ Flutter SDK จึงไม่ชน ; ส่วนที่ต้องเลือกไฟล์ (นำเข้า/ส่งออกธีม) ให้แอปส่ง callback เข้ามา ไม่ให้แพ็กเกจเรียก `file_picker` เอง |
| 2 | **ฟอนต์ไทยเพี้ยน/หาย** | ย้าย Noto Sans Thai เข้า `nsl_ui` ; chain fallback ปิดท้ายด้วย Noto Sans Thai เสมอ ไม่ว่าธีมระบุฟอนต์อะไร (ฟอนต์ที่ไม่มีในเครื่อง Flutter ตกไป fallback เอง) ; อ้างด้วย `packages/nsl_ui/Noto Sans Thai` ; ช่องเลือกฟอนต์ใช้ตัวเลือกฟอนต์ที่ Dev มีอยู่แล้ว (`font_picker_dialog`) |
| 3 | **`C` ของ Dev เป็น static global** แก้ธีมสดทั้งแอปไม่ได้ ต้อง rebuild ทั้งต้นไม้ | **ขั้น 1:** คง `C.xxx` ไว้แต่ให้เป็น adapter อ่านจาก `NslTokens` ปัจจุบัน → ไม่แตะ 657 จุด ; rebuild ทั้งต้นไม้ตอนเปลี่ยน (พฤติกรรมเดิม) ด้วย `ValueKey(themeRevision)` + debounce ~150 ms ตอนลากแก้สี ; สถานะแคนวาสอยู่ใน controller (`ChangeNotifier`) ไม่ใช่ state ของ widget จึงไม่หาย — **ต้องมีเทสต์ยืนยัน** (เลือกอะไรอยู่/ซูม/เลื่อนค้างต้องเหมือนเดิมหลังเปลี่ยนธีม) ; **ขั้น 2 (ทยอยทำ):** ไฟล์ที่แก้อยู่แล้วค่อยเปลี่ยน `C.x` → `context.nsl.colors.x` ; ตัว painter รับ token ผ่าน constructor |
| 4 | **พรีวิวธีมใน Editor ต้องตรงของจริง** | Editor เรนเดอร์ `NslGallery` (ปุ่ม, ช่องกรอก, แถวรายการ, dialog, tooltip, snackbar, ป้ายสถานะ, ตัวอย่างแถบชื่อ, ตัวอย่างการ์ดตาราง) ภายใต้ `NslThemeScope(draft)` ที่เป็น `InheritedWidget` จึงพรีวิวคนละธีมกับแอปได้ ; **ห้ามใช้ `C` ใน Gallery** (static global ทำให้พรีวิวแยกไม่ได้) ; ธีมที่แก้อยู่ยังกด "ใช้กับทั้งแอป" เพื่อดูของจริงได้ |
| 5 | **สีฮาร์ดโค้ด** (~68 จุดนอก `theme.dart`) | ย้ายตามชนิด: สี syntax → `dev.syntax` ; สถานะ → `danger/warn/info/success` ; เวทีวิดีโอ/โหมดภาพของ Resonance → คงไว้ตั้งใจ (ไม่ใช่ธีม) ทำรายการ allowlist ในไฟล์ ; **guard test** สแกน `lib/` หา `Color(0x` นอก allowlist ให้ fail |
| 6 | **มุมโค้ง/ฟอนต์/ระยะที่ฮาร์ดโค้ดกระจาย** (~185 จุด radius) | ใช้ **ratchet test**: เทสต์นับ `BorderRadius.circular(<ตัวเลข>)` ที่เหลือ ตัวเลขนับห้ามเพิ่ม (ลดได้อย่างเดียว) ทำให้ย้ายทีละไฟล์ได้โดยไม่ต้องทำให้เสร็จทีเดียว ; ความสัมพันธ์: ≤6→`sm`, 7–10→`md`, 12–16→`lg`, 999→`pill` ; widget ที่มาจาก ThemeData component themes ได้ radius ฟรี |
| 7 | **font scale ไม่ต้องแก้ 300+ จุด `fontSize:`** | ใช้ `MediaQuery.textScaler` ที่ราก (`TextScaler.linear(scale)`) → ทุก `Text` ปรับตามโดยไม่ต้องแก้โค้ด ; **ข้อยกเว้น:** subtree ของแคนวาส (ER/DFD/Flowchart/Wireframe) ครอบด้วย `TextScaler.noScaling` เพราะขนาดตัวอักษรบนแคนวาสผูกกับซูม/เลย์เอาต์ตายตัว ; จำกัดช่วง 0.9–1.2 + เทสต์ overflow ที่ 1.2 บนหน้าหลักของทั้งสองแอป |
| 8 | **density กระทบเลย์เอาต์ที่ฮาร์ดโค้ด** | สัญญาขอบเขต: density มีผลกับ widget ของ `nsl_ui` + Material controls (ผ่าน `visualDensity` และ component themes) เท่านั้น ไม่มีผลกับแคนวาสและเลย์เอาต์ที่ฮาร์ดโค้ด ; บอกในหน้า Editor ตรง ๆ |
| 9 | **ผู้ใช้ตั้งสีจนอ่านไม่ออก** | ตัวตรวจ contrast (ย้ายจาก Resonance): `text/surface ≥4.5`, `textMuted/surface ≥4.5`, `accentInk/surface ≥4.5`, `onAccent/accent ≥4.5`, `*Text/*Bg ≥4.5`, `border/surface ≥1.3` ; Editor แสดงรายงาน + ปุ่ม "แก้ให้อัตโนมัติ" ; ตอนโหลดอัตโนมัติ derive `accentInk`/`onAccent` ให้ผ่านเสมอ (เหมือน Resonance) แต่ **ไม่ปฏิเสธ** สีที่ผู้ใช้ตั้ง |
| 10 | **ล็อกตัวเองออก** (ธีมที่ใช้ไม่ได้) | **safe mode:** เปิดแอปด้วย `--default-theme` หรือถือ Shift ตอนเปิด = ใช้ธีมในตัวชั่วคราว ; ถ้า contrast ของ `text/bg` ต่ำกว่า 3:1 ตอนโหลด → ใช้ธีมในตัวและแจ้ง ; Settings มีปุ่ม "คืนค่าธีมเริ่มต้น" ที่ใช้ธีมในตัวเสมอ |
| 11 | **ส่งธีมข้ามแอปแบบสด** | Dev เขียนไฟล์ด้วย **atomic write** (เขียนไฟล์ชั่วคราวแล้ว rename) เพื่อกันแอปอื่นอ่านไฟล์ที่เขียนไม่ครบ ; แอปอื่นใช้ `Directory.watch` บนโฟลเดอร์ธีม + debounce ~200 ms ; อ่านพังหรือ validate ไม่ผ่าน = **คงธีมที่ใช้ได้ล่าสุด** ไม่ crash |
| 12 | **ไฟล์ธีมเป็นข้อมูลที่ไม่น่าเชื่อถือ** | ขนาดไฟล์ ≤ 64 KB ; parse ด้วย allowlist ของคีย์ ; ค่าตัวเลข clamp (NaN/Infinity ปฏิเสธ) ; สีต้องตรง regex ; ชื่อฟอนต์ ≤ 64 ตัวอักษร ไม่มี `/ \ :` ; **v1 ไม่มีฟิลด์ที่เป็น path/URL/สคริปต์เลย** ; fuzz test: ไฟล์เสียแบบสุ่มต้องไม่เคย throw ออกนอก loader |
| 13 | **เวอร์ชันของไฟล์ธีม** | `schema` เป็นจำนวนเต็ม ; แอปเก่าเจอคีย์ที่ไม่รู้จัก = ข้ามและ **เก็บกลับตอนบันทึก** (แบบเดียวกับชนิดเอกสารที่ไม่รู้จักใน `.nsld`) ; `schema` ใหม่กว่าที่รู้ = ปฏิเสธไฟล์นั้นพร้อมข้อความ ใช้ธีมในตัวแทน ; ใส่ฟิลด์ระดับ 1–3 ครบตั้งแต่ v1 กันต้องเปลี่ยน schema ภายหลัง |
| 14 | **ภาพ Export ต้องไม่เปลี่ยนตามธีมผู้ใช้** | คงกลไก `C.withPalette` เดิมของ Dev (export ใช้พาเลตต์สว่างเสมอ) ; adapter ต้องรองรับ `withPalette` ต่อไป |
| 15 | **หน้าตาต้องไม่เปลี่ยนตอนย้ายเข้า `nsl_ui`** | ธีมในตัวต้องเท่ากับค่าเดิมทุกตัว ตรวจด้วย **parity test** (เทียบ `kLightPalette/kDarkPalette` ของ Dev ทั้ง 27 ช่อง × 2 โหมด และ `NslPalette.of` ของ Resonance ทั้ง 14 ช่อง × 2 โหมด × 4 accent) + golden image ของหน้าหลักก่อน/หลัง |
| 16 | **Title bar ต่างกัน (channel เอง vs `window_manager`)** | ไม่ใช่ข้อบังคับของระดับ 1–3 ; ถ้ารวม ให้ `NslTitleBar` รับ `NslWindowBackend` (interface เดียวกับ `WindowBackend` ของ Dev ที่มีอยู่แล้ว) ; แต่ละแอปเขียน adapter ของตัวเอง ; ทำเป็นเฟสท้ายและเป็นทางเลือก |
| 17 | **เทสต์ Dev 1,262 ข้อห้ามพัง** | ทุกเฟสมี gate: เทสต์เดิมต้องผ่านโดยไม่แก้ (ยกเว้นที่จำเป็นจริง ให้บันทึกเหตุผลใน progress.md) |

## 5. เฟสงาน (ลำดับและเกณฑ์เสร็จ)

> ทุกเฟส: เทสต์ผ่านทั้งหมด + `flutter analyze` สะอาด + commit ต่อเฟส + อัปเดต `progress.md`

**เฟส 0 — เตรียมฐาน**
- ถ่าย golden/screenshot หน้าหลักของทั้งสองแอป (ธีมสว่าง/มืด) เป็นเส้นฐาน
- ตรวจว่า Dev 1,262 เทสต์และ Resonance เทสต์ผ่านก่อนเริ่ม
- สร้างโฟลเดอร์/repo `NSL-UI` (package `nsl_ui`)
- ✔ เสร็จเมื่อ: มีเส้นฐานและโครงแพ็กเกจที่ build ได้

**เฟส 1 — แกน `nsl_ui` (ยังไม่แตะแอป)**
- `NslTokens` (สี + shape + type + density + elevation), derive, contrast (ย้ายจาก Resonance)
- ธีมในตัว: `nsl.dev.light/dark`, `nsl.resonance.light/dark` ที่ **ค่าเท่าของเดิมทุกตัว**
- codec `.nslt` พร้อม validator, migration stub, fuzz test
- ✔ เสร็จเมื่อ: parity test ผ่าน, fuzz test ผ่าน, ครอบคลุมเทสต์หน่วย

**เฟส 2 — Resonance ใช้ `nsl_ui` ก่อน** (โครงสร้างใกล้เคียงที่สุด ความเสี่ยงต่ำ)
- `NslPalette` กลายเป็นตัวห่อ token ; `context.pal` ใช้ต่อได้ (74 จุดไม่ต้องแก้)
- ✔ เสร็จเมื่อ: golden เทียบเส้นฐานเหมือนเดิม

**เฟส 3 — Dev ใช้ `nsl_ui` ผ่าน adapter**
- `C.xxx` อ่านจาก `NslTokens` ; `C.withPalette` ยังใช้ได้ ; ย้ายฟอนต์ Noto Sans Thai ไป `nsl_ui`
- ✔ เสร็จเมื่อ: 1,262 เทสต์ผ่านไม่แก้ + golden เหมือนเดิม + เทสต์สถานะไม่หายหลังเปลี่ยนธีม

**เฟส 4 — ที่เก็บธีมและการส่งข้ามแอป**
- โฟลเดอร์ธีม, `ui-settings.json`, atomic write, watcher, safe mode
- Settings ของทั้งสองแอป: เลือกธีม / โหมด / นำเข้า-ส่งออก `.nslt` / คืนค่าเริ่มต้น
- ✔ เสร็จเมื่อ: เปลี่ยนธีมในแอปหนึ่งแล้วอีกแอปที่เปิดอยู่เปลี่ยนตามภายใน ~1 วินาที ; ไฟล์เสียไม่ทำให้แอปพัง

**เฟส 5 — ระดับ 3: สไตล์ component**
- ตัวสร้าง ThemeData + component themes (ปุ่ม, ช่องกรอก, dialog, เมนู, tooltip, snackbar, scrollbar, slider, switch, checkbox, tab, divider) จาก shape/density/elevation
- font scale ผ่าน `textScaler` + ขอบเขตแคนวาสที่ไม่ปรับ
- `NslGallery` ; guard test (สีฮาร์ดโค้ด) ; ratchet test (radius)
- ย้ายสีฮาร์ดโค้ด ~68 จุดที่ไม่ใช่ข้อยกเว้นตั้งใจ
- ✔ เสร็จเมื่อ: เปลี่ยน shape/density/scale/elevation แล้วทั้งสองแอปเปลี่ยนตาม ไม่มี overflow ที่ scale 1.2 บนหน้าหลัก

**เฟส 6 — Theme Editor ใน NSL Dev**
- โครงต้นไม้ token แบ่งกลุ่ม (สี/รูปทรง/ตัวอักษร/ความหนาแน่น/เงา/ส่วนขยายต่อแอป)
- พรีวิวสดด้วย `NslGallery` เทียบสว่าง–มืดคู่กัน
- รายงาน contrast + ปุ่มแก้อัตโนมัติ ; สร้างจากธีมในตัว/ทำสำเนา ; นำเข้า–ส่งออก ; ปุ่ม "ใช้กับทุกแอป"
- ใช้ color picker เดิมของ Dev (ย้าย/ห่อให้ไม่ผูก `C`)
- ✔ เสร็จเมื่อ: สร้างธีมใหม่ใน Dev → Resonance ใช้ได้ทันที → ปิดแล้วเปิดใหม่ยังอยู่

**เฟส 7 (ทางเลือก) — ย้าย widget ร่วมทีละชิ้น**
- ลำดับ: panel splitter → color picker → status bar → title bar (ผ่าน `NslWindowBackend`)
- ทำเมื่อแก้ไฟล์นั้นอยู่แล้วเท่านั้น ไม่ทำเป็นโครงการใหญ่

## 6. การทดสอบ

| ชนิด | ครอบคลุม |
|---|---|
| Unit | parse/validate/serialize, extends/derive, contrast, migration, clamp ค่า |
| Parity | พาเลตต์เดิม ↔ ธีมในตัว (ทุกช่อง ทั้งสองโหมด) |
| Golden | `NslGallery` สว่าง/มืด × ธีมในตัว ; หน้าหลักของแต่ละแอปก่อน/หลัง |
| Guard | ห้ามมี `Color(0x` นอก allowlist ; ratchet ของ radius |
| Widget | เปลี่ยนธีมแล้วสถานะ (เลือก/ซูม/เลื่อน) ไม่หาย ; overflow ที่ scale 1.2 และ density compact/comfortable |
| Integration | watcher ใช้ temp dir จริง (เขียน/ลบ/ไฟล์เสียครึ่งทาง) |
| Fuzz | ไฟล์ `.nslt` เสียแบบสุ่มต้องไม่ทำให้ loader throw |

## 7. ความเสี่ยง

| ความเสี่ยง | ระดับ | ลดความเสี่ยง |
|---|---|---|
| rebuild ทั้งต้นไม้ของ Dev ตอนลากสีสดอาจกระตุก | กลาง | debounce, ถ้าแย่ค่อยเป็นขั้น 2 (ย้าย `C` → `context.nsl` ไฟล์ที่หนักก่อน) |
| ธีมผู้ใช้ทำให้บาง widget อ่านยาก (ผสมสีที่ไม่ได้อยู่ใน core) | กลาง | contrast gate ครอบ extension ที่เป็นคู่ Bg/Text ด้วย |
| ย้ายฟอนต์ออกจาก Dev ทำให้ asset path เปลี่ยน | ต่ำ | ทำในเฟส 3 พร้อม golden |
| `nsl_ui` ทำ Dev/Resonance ผูกกันที่ path ข้างเคียง | ต่ำ | เปลี่ยนเป็น `git:` + tag ตอนออกรุ่น |
| ขอบเขตบวม (ผู้ใช้ขอปรับเลย์เอาต์) | กลาง | ยึดข้อ "ไม่ทำ" ในหัวข้อ 1 ; ระดับ 4 ต้องเปิดแผนใหม่ |
| schema v1 ผิดแล้วต้องแก้ทีหลัง | กลาง | ใส่ฟิลด์ระดับ 1–3 ครบ ; กติกา unknown-key ทำให้เพิ่มฟิลด์ได้โดยไม่แตก |

## 8. คำถามที่ยังเปิดอยู่ (ต้องตัดสินใจก่อนเฟส 1)

1. ชื่อแพ็กเกจ/โฟลเดอร์: `nsl_ui` / `NSL-UI` ตกลงไหม
2. ธีมเริ่มต้นของทั้งสองแอป **คงหน้าตาต่างกัน** (Dev เขียวน้ำเงิน, Resonance อำพัน) หรือรวมเป็นหน้าตาเดียวกัน — แผนนี้ตั้งสมมติฐานว่า **คงต่างกัน** ผ่านธีมในตัวคนละชุด
3. สกุลไฟล์ `.nslt` และโฟลเดอร์ `%APPDATA%\NSL\themes` ใช้ได้ไหม
4. ฟอนต์ที่ Resonance ใช้อยู่ (Segoe UI) จะเปลี่ยนไปใช้ Noto Sans Thai เป็นค่าเริ่มต้นไหม (มีผลกับหน้าตา)
5. NSL Utility (โฟลเดอร์ยังว่าง) จะเริ่มด้วย `nsl_ui` ตั้งแต่ต้นเลยหรือไม่ — ถ้าใช่ ให้ถือเป็นแอปที่ 3 ที่ตรวจว่า API ใช้ง่ายจริง

## 9. ฉบับปรับปรุง (2026-11-16) — แทนที่ส่วนที่ขัดกันข้างบน

### 9.1 เหตุผลที่ปรับ
1. **สี่แอป ไม่ใช่สองแอป** — NSL Utility ไม่ว่างแล้ว (v1.9.1, Android, 56 ไฟล์, 378 เทสต์, `Color(0x` 117 + `Colors.*` 104 จุด กระจายทั้งแอป) และมี `nsl_writer_tools` (Windows+Android, 31 ไฟล์, 139 เทสต์, สีทั้งหมดอยู่ใน `theme.dart`)
2. **Theme Editor เป็นเว็บ ไม่ใช่ส่วนหนึ่งของ NSL Dev** — แก้ editor ได้โดยไม่ต้องออกรุ่นแอป

### 9.2 การตัดสินใจ
| เรื่อง | ข้อสรุป |
|---|---|
| Editor | เว็บ **Vue + TypeScript** แทนเฟส 6 เดิม ; editor ใน `dev_copy` คงไว้เป็นต้นแบบทดลอง ไม่ย้ายเข้า `nsl_ui` |
| เวอร์ชัน core | build เว็บเก่าเก็บไว้ใต้ `/v1.0/`, `/v1.1/` ไม่เขียนทับ ; แต่ละแอปแสดงเวอร์ชัน core ที่ใช้พร้อมลิงก์ไปเว็บเวอร์ชันนั้น |
| ความเข้ากันได้ | `schema` (จำนวนเต็ม) เปลี่ยนเฉพาะการแตกหัก ; เวอร์ชัน core เป็น minor เพิ่มได้อย่างเดียว ห้ามลบ/เปลี่ยนความหมายคีย์เดิม ; ไฟล์เพิ่มฟิลด์ `core: "1.x"` ; แอป/editor เก่าเก็บคีย์ที่ไม่รู้จักกลับตอนบันทึก |
| เว็บกับ Dart ตรงกัน | TS port ของ parser/derive/contrast/resolve/autoFix ต้องผ่าน **fixture กลางที่เทสต์ Dart สร้าง** (เทียบที่ 8 บิตต่อช่อง) ; ฝั่ง Dart สร้าง `tokens.schema.json` (ชื่อ token, ชนิด, เวอร์ชันที่เริ่มมี, แอปที่ใช้) ให้เว็บสร้างฟอร์มจากไฟล์นี้ |
| พรีวิวเว็บ | HTML/CSS ขับด้วย CSS variables ; เป็นการประมาณ ไม่ pixel-identical กับ Flutter — ต้องบอกผู้ใช้ในหน้า editor |
| Android | **นำเข้าไฟล์ `.nslt` อย่างเดียว** (แต่ละแอปอยู่ใน sandbox แชร์โฟลเดอร์ไม่ได้) ; ที่เก็บธีมเป็น interface `NslThemeStorage` แยก implementation: Windows = โฟลเดอร์กลาง+watcher, Android = ที่เก็บในแอป+นำเข้า |
| Custom accent | **อยู่ใน UI Core เป็นชุดปรับแต่งแบบ "lite" ที่ทุกแอปมีให้ใช้** (ปรับสีพื้นฐานได้ ไม่ลึกเท่าเว็บ) : accent override ทับธีมใดก็ได้ + preset + สีกำหนดเอง + โหมด สว่าง/มืด/ตามระบบ ; core ให้ทั้งตัวจัดเก็บและ widget พร้อมใช้ (`NslAppearancePanel`) ; ลำดับความสำคัญ: ธีมในตัว < ไฟล์ธีม < ค่า lite ของผู้ใช้ (มีปุ่มล้างค่า) ; ปรับลึกกว่านี้ (สีรายตัว, มุมโค้ง, เงา, extension) ทำที่เว็บเท่านั้น ; ใช้อัลกอริทึม HSL เดิมของ Utility (`accentTints`) เพื่อให้สีที่ผู้ใช้เคยตั้งไม่เปลี่ยน — *ผู้ใช้ยังไม่ได้ระบุอัลกอริทึม ถือเป็นข้อสมมติ ให้ยืนยัน* |
| NSL Writer | มี **preset `nsl.writer.paper` (กระดาษอุ่น)** เป็นธีมในตัวที่คงหน้าตาเดิมทุกค่า + มี **ธีมปกติ (`nsl.default`) เหมือนแอปอื่น** ให้เลือกได้ |
| การทดลอง | ทุกแอปคัดลอกมาไว้ `experiments/<ชื่อ>_copy/` เท่านั้น |

### 9.3 core v1.0 ที่ต้องเพิ่ม (ขอบเขตเล็กที่สุดที่ครอบคลุมสี่แอป)
1. สี core เพิ่ม: `selected`, `accentBorder`, `textFaint`
2. `tint(base)` → คู่ (พื้น, ตัวอักษร) ที่ผ่าน contrast ตามโหมด + ชุดสี categorical ~8 สี (ใช้กับกราฟ Utility, ประเภท/สถานะ Writer, สีวิชา)
3. **ชุดปรับแต่ง lite** (ทุกแอปใช้): accent override + preset + custom accent + โหมด ; `NslAppearancePanel` (widget เลือก preset/สีเอง/โหมด ไม่พึ่ง `file_picker`) ; เก็บค่าใน `ui-settings.json` ผ่าน `NslThemeStorage` ; derive `accentInk/onAccent/accentTint` ให้ผ่าน contrast เสมอ
4. ฟอนต์สามบทบาท `ui` / `content` / `mono` + ขนาดตัวอักษรขั้นต่ำ ; ฝังเฉพาะ Noto Sans Thai ; ฟอนต์อื่นแอปจัดหาเอง ห้ามพึ่ง `google_fonts`
5. `NslThemeStorage` interface
6. ส่งออก token เป็นแผนที่ ARGB (สำหรับวิดเจ็ต Android ของ Utility)
7. density ไม่ลดต่ำกว่าขนาดแตะได้บนจอสัมผัส (ปุ่มขั้นต่ำ 44)
8. `tokens.schema.json` + ฟิลด์ `core` ในไฟล์
- extension ต่อแอป: `dev`, `resonance`, `writer` (ประเภท 7 + สถานะ 3 + summary/snippet/chipText/dash/edge/navIndicator), `utility` (หมวดปฏิทิน, สีวิชา)
- **freeze เป็น v1.0 ก่อนย้ายแอปใหม่** ; สิ่งอื่น (widget ร่วม, title bar, Material You) เป็น 1.x

### 9.4 เฟสใหม่ (ต่อจากเฟส 0–7)
- **เฟส 8** core v1.0 (ข้อ 9.3) แล้ว freeze
- **เฟส 9** ย้าย Writer (สำเนา) — adapter ใต้ `C.xxx`/`Palette`, ธีม `nsl.writer.paper` parity ทุกช่อง × 2 โหมด, ธีมปกติ, ทดสอบ Android ในรูปแบบนำเข้าไฟล์
- **เฟส 10** เว็บ Vue+TS : TS port, fixture กลาง, อ่าน `tokens.schema.json`, build ตามเวอร์ชัน
- **เฟส 11** ย้าย Utility (สำเนา) — ถึงระดับ adapter ก่อน (globals `isDark/accentIdx` → token) แล้วค่อยย้ายสีฮาร์ดโค้ดทีละหน้าด้วย guard/ratchet test (ไม่บล็อกเฟสอื่น)
- **เฟส 12** งานค้างของ Dev/Resonance : เมนูเลือกธีม, นำเข้า-ส่งออก `.nslt`, คืนค่าเริ่มต้น, safe mode, ย้าย `BorderRadius`/`fontSize` ฮาร์ดโค้ด
- เฟส 6 เดิม (editor ใน Dev) ถูกแทนที่ด้วยเฟส 10 ; เฟส 7 ยังเป็นทางเลือก

### 9.5 ยังไม่ได้ตรวจ / ยังเปิดอยู่
- ยังไม่ได้อ่านหน้าการเงิน/ปฏิทินของ Utility ลึก ว่ามีสีสถานะซ่อนอยู่เพิ่มหรือไม่ ; ยังไม่ได้ดู Kotlin/XML ของวิดเจ็ต Android ว่าเปลี่ยนสีตามธีมได้ระดับไหน
- ตำแหน่งโค้ดเว็บ: **โฟลเดอร์ `web/` ใน NSL-UI** (ตัดสินใจ 2026-11-16 ตอนเริ่มเฟส 10 — อ่าน `schema/` และ fixture ได้โดยตรง)
- คำถามข้อ 8.5 (NSL Utility) ตอบแล้ว: เป็นแอปที่มีอยู่จริง ย้ายเฟส 11

### 9.6 Branding (2026-11-16)
- เว็บ Theme Editor ชื่อ **NSL Palette** (เป็น branding ของ NSL) — เรียกเต็มว่า "NSL Palette" เสมอ และ **ไม่ตั้ง class ใหม่ใน `nsl_ui` ชื่อ `Palette`** เพื่อไม่ชนกับ `Palette` ของ Dev/Writer และ `NslPalette` ของ Resonance
- ชื่อแอปใหม่ (ชื่อที่ผู้ใช้เห็น):

| ชื่อเดิม | ชื่อใหม่ | โฟลเดอร์/โค้ดภายใน |
|---|---|---|
| NSL Utility | **Orbit** | `NSL Utility`, `nsl_utility` (ไม่เปลี่ยน) |
| NSL Dev (Modeler) | **Nebular** | `NSL-Modeler` (ไม่เปลี่ยน) |
| NSL Resonance | **Spectrum** | `NSL-Media-Player` (ไม่เปลี่ยน) |
| NSL Writer Tools | **Lyra** | `nsl_writer_tools` (ไม่เปลี่ยน) |

- **id ภายใน (ตัดสินใจ 2026-11-16 — เปลี่ยนตรง ๆ ไม่มี alias/migration):** เหตุผล: แอปยังไม่ปล่อยทางการ มีแต่ tester จึงไม่มีไฟล์ธีมของผู้ใช้จริงต้องรักษา ; **ทำแล้วใน `nsl_ui` และสำเนาทดลองทั้งสอง** : `nsl.dev`→`nsl.nebular`, `nsl.resonance`→`nsl.spectrum`, คีย์ extension `dev`→`nebular`, `resonance`→`spectrum` ; ที่จะใช้เมื่อย้ายแอป: `writer`→`lyra`, `utility`→`orbit`, ธีมในตัวของ Writer ตั้ง id เป็น `nsl.lyra`/`nsl.lyra.paper` ตามต้องการ ; `nsl.default` คงเดิม ; **ข้อจำกัด:** ธีมที่ tester สร้างไว้ด้วย id เก่าจะหาธีมฐานไม่เจอ — ให้ลบ/สร้างใหม่ (ลบ `%APPDATA%\NSL\themes` และ `ui-settings.json`) ; ชื่อ Dart (`kBuiltinDevId`, `kDevExtension` ฯลฯ) ยังเป็นชื่อเดิม ; ตาราง/ตัวอย่างในหัวข้อ 3 และ 5 ที่อ้าง `nsl.dev`, `dev` เป็นของเดิม ให้อ่านตามตารางนี้ ; **หลังปล่อยทางการ ห้ามเปลี่ยน id อีก** (ถ้าจำเป็นต้องมี alias)

### 9.7 ช่องทางแจกจ่ายและที่เก็บธีม (2026-11-16) — แทนที่ตำแหน่งในหัวข้อ 3.3 / 4 ข้อ 11
**สองช่องทางที่ผู้ใช้ได้ผลิตภัณฑ์:**
1. **โหลดแบบ standalone** — ผู้ใช้นำไฟล์ธีมเข้าเอง (วางลงโฟลเดอร์หรือนำเข้าผ่านปุ่มในแอป)
2. **ผ่าน NSL Launcher** (แหล่งโหลดแอป NSL ทั้งหมด) — "อัพโหลดธีม" ใน Launcher = **นำเข้าไฟล์ลงเครื่อง** (ไม่มีเซิร์ฟเวอร์/แกลเลอรีในแผนตอนนี้ ถ้าจะทำต้องมีแผนแยก: ที่โฮสต์ การดูแลเนื้อหา)

**ที่เก็บ (ตัดสินใจ):**
| อะไร | ที่ไหน | เหตุผล |
|---|---|---|
| ไฟล์ธีม `*.nslt` | `Documents\NSL\Themes` | ผู้ใช้เข้าถึง/สำรอง/ส่งต่อได้ง่ายกว่า AppData |
| ค่าตั้งภายใน `ui-settings.json` (ธีมที่เลือก, safe mode, ค่า lite) | `%APPDATA%\NSL` | เป็นค่าของเครื่อง ไม่ใช่ของที่ผู้ใช้ควรเห็น |
| Android | โฟลเดอร์ส่วนตัวของแต่ละแอป | **ไม่มี Launcher บน Android** และแอปแชร์โฟลเดอร์กันไม่ได้ → นำเข้าไฟล์ในแต่ละแอป |

- **ทุกแอปและ Launcher ใช้ที่เก็บเดียวกัน** — Launcher เป็นแค่ "ผู้เขียนไฟล์อีกตัว" เหมือนเว็บ NSL Palette ; แอปไม่ต้องรู้ว่าไฟล์มาจากช่องทางไหน ; ถ้าผู้ใช้มีทั้งแอปที่โหลดเองและแอปจาก Launcher บนเครื่องเดียวกัน ทั้งคู่เห็นธีมชุดเดียวกัน
- **หา Documents จากระบบ ไม่ต่อ path เอง** (Documents อาจถูกย้าย/เปลี่ยนชื่อ/เป็น OneDrive) : แอปส่ง `getApplicationDocumentsDirectory()` ของ path_provider เข้า `NslThemeStore.standard(documents:)` — `nsl_ui` ยังไม่พึ่ง plugin ; **ทุกแอปต้องหาด้วยวิธีเดียวกัน** ไม่งั้นเห็นโฟลเดอร์คนละที่
- ไม่ต้อง migration จาก `%APPDATA%\NSL\themes` (แอปยังไม่ปล่อย มีแต่ tester — ธีมที่ tester สร้างไว้ต้องย้ายเอง)
- **สิ่งที่ Launcher ทำได้ในอนาคต (ยังไม่ทำ):** รู้เวอร์ชัน core ของแต่ละแอปที่ติดตั้ง → เตือนว่าธีมใช้ส่วนขยายที่แอปบางตัวยังไม่รู้จัก และเปิดเว็บ Palette รุ่นที่ตรงให้
- **ยังไม่ได้ทดสอบ:** Documents ที่ย้ายไป OneDrive (Known Folder Move / Files On-Demand) กับตัวเฝ้าโฟลเดอร์ · พฤติกรรม `getApplicationDocumentsDirectory()` บน Windows ที่ย้ายโฟลเดอร์ (ตามเอกสารของ plugin อ่านจาก Known Folder แต่ยังไม่ได้ลองบนเครื่องนี้) · การทำงานจริงของ `main()` ในสำเนา (เทสต์ครอบคลุม store/ตัวควบคุม ไม่ได้บูตแอปด้วย path_provider จริง)
