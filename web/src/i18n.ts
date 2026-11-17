import { computed, ref } from 'vue';

export type Lang = 'th' | 'en';

const dict = {
  title: { th: 'NSL Palette', en: 'NSL Palette' },
  subtitle: { th: 'สร้างไฟล์ธีม .nslt สำหรับแอป NSL', en: 'Make .nslt theme files for NSL apps' },
  coreVersion: { th: 'เวอร์ชัน core', en: 'Core version' },
  otherVersions: { th: 'เวอร์ชันอื่น (ใช้ให้ตรงกับแอปของคุณ)', en: 'Other versions (match your app)' },
  versionHint: {
    th: 'ดูเวอร์ชัน core ที่แอปใช้ได้ที่ Settings ของแอป ถ้าแอปเก่ากว่า ให้เลือกเวอร์ชันเว็บให้ตรง',
    en: 'Your app shows its core version in Settings. If it is older, pick the matching web version.',
  },
  language: { th: 'ภาษา', en: 'Language' },
  theme: { th: 'ธีม', en: 'Theme' },
  name: { th: 'ชื่อธีม', en: 'Theme name' },
  id: { th: 'รหัส (ชื่อไฟล์)', en: 'ID (file name)' },
  idAuto: { th: 'ตั้งอัตโนมัติจากชื่อ', en: 'Auto from name' },
  base: { th: 'ธีมฐาน (สืบทอดค่า)', en: 'Base theme (inherits)' },
  importFiles: { th: 'นำเข้าไฟล์ .nslt', en: 'Import .nslt' },
  importHint: { th: 'เลือกได้หลายไฟล์ — ไฟล์แรกเป็นธีมที่แก้ไข ที่เหลือใช้เป็นธีมฐานได้', en: 'Pick several — the first is edited, others can be used as bases' },
  download: { th: 'ดาวน์โหลด .nslt', en: 'Download .nslt' },
  copy: { th: 'คัดลอกข้อความ', en: 'Copy text' },
  copied: { th: 'คัดลอกแล้ว', en: 'Copied' },
  reset: { th: 'ล้างการแก้ไขทั้งหมด', en: 'Reset all edits' },
  quickAccent: { th: 'ตั้งสี accent แบบเร็ว', en: 'Quick accent' },
  quickAccentHint: { th: 'เลือกสีเดียว ระบบคำนวณชุดสี accent ของทั้งสองโหมดให้อ่านได้', en: 'Pick one colour; accent sets for both modes are derived to stay readable' },
  presets: { th: 'สีสำเร็จรูป', en: 'Presets' },
  customColour: { th: 'สีกำหนดเอง', en: 'Custom colour' },
  applyAccent: { th: 'ใช้กับธีม', en: 'Apply' },
  tabColors: { th: 'สี', en: 'Colours' },
  tabExt: { th: 'ส่วนขยายต่อแอป', en: 'Per-app' },
  tabShape: { th: 'รูปทรง/ตัวอักษร', en: 'Shape & type' },
  tabStyle: { th: 'ความหนาแน่น/เงา', en: 'Density & shadow' },
  editing: { th: 'กำลังแก้โหมด', en: 'Editing mode' },
  light: { th: 'สว่าง', en: 'Light' },
  dark: { th: 'มืด', en: 'Dark' },
  inherited: { th: 'สืบทอดจากธีมฐาน/คำนวณ', en: 'Inherited / derived' },
  overridden: { th: 'กำหนดเอง', en: 'Overridden' },
  clear: { th: 'ใช้ค่าเดิม', en: 'Use inherited' },
  radius: { th: 'มุมโค้ง (px)', en: 'Corner radius (px)' },
  fontFamily: { th: 'ฟอนต์ UI', en: 'UI font' },
  fontContent: { th: 'ฟอนต์เนื้อหา', en: 'Content font' },
  fontMono: { th: 'ฟอนต์ mono', en: 'Mono font' },
  fontHint: { th: 'ใส่ชื่อฟอนต์ที่แอปมี — ไม่มีในเครื่อง = ตกไปฟอนต์สำรอง (Noto Sans Thai ปิดท้ายเสมอ)', en: 'Use a font name the app has; missing fonts fall back (Noto Sans Thai is always last)' },
  scale: { th: 'สัดส่วนตัวอักษร', en: 'Font scale' },
  minSize: { th: 'ขนาดตัวอักษรขั้นต่ำ', en: 'Minimum font size' },
  density: { th: 'ความหนาแน่น', en: 'Density' },
  densityHint: { th: 'มีผลกับ widget มาตรฐานของแอปเท่านั้น ไม่รวมแคนวาสและเลย์เอาต์ที่แอปกำหนดตายตัว', en: 'Affects standard widgets only — not canvases or layouts fixed by the app' },
  elevationMode: { th: 'การแสดงเงา', en: 'Elevation' },
  shadow: { th: 'เงา', en: 'Shadow' },
  flat: { th: 'แบน (ใช้เส้นขอบแทน)', en: 'Flat (borders instead)' },
  strength: { th: 'ความเข้มเงา', en: 'Shadow strength' },
  compact: { th: 'แน่น', en: 'Compact' },
  normal: { th: 'ปกติ', en: 'Normal' },
  comfortable: { th: 'โปร่ง', en: 'Comfortable' },
  default: { th: 'ค่าเริ่มต้น', en: 'Default' },
  preview: { th: 'ตัวอย่าง', en: 'Preview' },
  previewNote: {
    th: 'เป็นตัวอย่างโดยประมาณด้วย HTML/CSS — รูปทรงปุ่ม เงา และขนาดตัวอักษรอาจต่างจาก widget จริงของแอปเล็กน้อย แต่สีคำนวณด้วยสูตรเดียวกับแอป',
    en: 'Approximate HTML/CSS preview — shapes, shadows and sizes may differ slightly from the real app widgets, but colours use the same formulas.',
  },
  contrast: { th: 'ความอ่านออก (contrast)', en: 'Readability (contrast)' },
  autoFix: { th: 'แก้ให้ผ่านอัตโนมัติ', en: 'Auto-fix' },
  autoFixed: { th: 'ปรับแล้ว {n} ค่า', en: 'Adjusted {n} value(s)' },
  nothingToFix: { th: 'ไม่มีรายการที่ต้องแก้', en: 'Nothing to fix' },
  allPass: { th: 'ผ่านทุกข้อ', en: 'All checks pass' },
  pass: { th: 'ผ่าน', en: 'Pass' },
  failed: { th: 'ไม่ผ่าน', en: 'Fail' },
  unusable: { th: 'ธีมนี้อ่านไม่ออกจริง (ตัวอักษรหลักต่ำกว่า 3:1) แอปจะถอยไปใช้ธีมในตัว', en: 'Unreadable theme (main text below 3:1) — apps fall back to the built-in theme' },
  cannotResolve: { th: 'ใช้ธีมนี้ไม่ได้:', en: 'Cannot use this theme:' },
  notices: { th: 'ข้อความจากระบบ', en: 'Messages' },
  errImport: { th: 'นำเข้าไม่ได้:', en: 'Cannot import:' },
  warnImport: { th: 'คำเตือนตอนอ่านไฟล์:', en: 'Warnings while reading:' },
  appsInferred: { th: 'จัดหมวดอัตโนมัติจากส่วนขยายในไฟล์ : {apps} (ไฟล์นี้ไม่ได้ระบุ apps — ส่งออกจะไม่เขียนเพิ่มจนกว่าจะปรับการเลือกแอป)', en: 'Categorised automatically from the extensions in the file: {apps} (no "apps" in the file — not added on export until you change the app selection)' },
  baseMissing: { th: 'ไม่พบธีมฐาน "{id}" — เปลี่ยนเป็น "{to}" (เลือกใหม่ได้)', en: 'Base "{id}" not found — switched to "{to}" (change it if needed)' },
  reservedId: { th: 'รหัสที่ขึ้นต้นด้วย nsl. สงวนไว้สำหรับธีมในตัว — แอปจะไม่รับไฟล์นี้', en: 'IDs starting with nsl. are reserved for built-in themes — apps reject this file' },
  badId: { th: 'รหัสต้องเป็น a-z 0-9 . _ - (ขึ้นต้นด้วยตัวอักษรหรือตัวเลข ไม่เกิน 64 ตัว)', en: 'ID must be a-z 0-9 . _ - (start with a letter or digit, max 64)' },
  tooBig: { th: 'ไฟล์ใหญ่เกิน 64 KB แอปจะไม่รับ', en: 'File over 64 KB — apps reject it' },
  howToUse: { th: 'วิธีใช้ไฟล์', en: 'How to use the file' },
  howWindows: {
    th: 'Windows: วางไฟล์ในโฟลเดอร์ Documents\\NSL\\Themes แล้วทุกแอปจะเห็นทันที (หรือนำเข้าผ่านปุ่มในแอปหรือ NSL Launcher)',
    en: 'Windows: put the file in Documents\\NSL\\Themes — every app sees it live (or import it from the app or NSL Launcher)',
  },
  howAndroid: {
    th: 'Android: ใช้ปุ่มนำเข้าธีมใน Settings ของแต่ละแอป (ไม่มี Launcher บน Android และแอปแชร์ธีมกันไม่ได้ ต้องนำเข้าทีละแอป)',
    en: 'Android: use the theme import in each app’s Settings (no Launcher on Android and apps cannot share themes — import per app)',
  },
  forApps: { th: 'ทำธีมนี้ให้แอปไหน', en: 'Which apps is this theme for?' },
  forAppsHint: {
    th: 'เลือกได้หลายแอป (อย่างน้อยหนึ่ง) — ใช้เป็นตัวช่วยตอนแก้ไขเท่านั้น ไฟล์ธีมเดียวกันใช้ได้กับทุกแอป',
    en: 'Pick one or more — this only guides editing; the same file works in every app.',
  },
  status_experiment: { th: 'รองรับในสำเนาทดลอง (แอปจริงยังไม่อ่านไฟล์ธีม)', en: 'Supported in the experimental copy (the real app does not read theme files yet)' },
  status_planned: { th: 'ยังไม่ได้ย้ายมาใช้ core — ค่าที่ตั้งยังไม่มีผลกับแอปนี้', en: 'Not migrated to the core yet — settings have no effect here' },
  supportTitle: { th: 'แอปรับค่าอะไรจากธีมได้บ้าง', en: 'What each app takes from a theme' },
  supportNote: {
    th: 'ตารางนี้เขียนตามผลการย้ายในสำเนาทดลอง (ตรวจล่าสุด 2026-11-16) ไม่ได้อ่านจากแอปจริง',
    en: 'Hand-written from the experimental migrations (checked 2026-11-16); not read from the real apps.',
  },
  sup_full: { th: 'ครบ', en: 'Full' },
  sup_partial: { th: 'บางส่วน (เฉพาะ widget มาตรฐาน)', en: 'Partial (standard widgets only)' },
  sup_none: { th: 'ยังไม่มีผล', en: 'No effect yet' },
  sup_unknown: { th: 'ยังไม่ได้ตรวจ', en: 'Not checked' },
  area_colors: { th: 'สี core', en: 'Core colours' },
  area_accent: { th: 'accent / โหมด (lite)', en: 'Accent / mode (lite)' },
  area_ext: { th: 'ส่วนขยายของแอป', en: 'App extension' },
  area_shape: { th: 'มุมโค้ง', en: 'Corner radius' },
  area_type: { th: 'สัดส่วนตัวอักษร', en: 'Font scale' },
  area_fonts: { th: 'ชื่อฟอนต์', en: 'Font names' },
  area_density: { th: 'ความหนาแน่น', en: 'Density' },
  area_elevation: { th: 'เงา', en: 'Shadow' },
  previewFor: { th: 'ดูหน้าตาของ', en: 'Preview as' },
  generic: { th: 'ทั่วไป', en: 'Generic' },
  showOtherExt: { th: 'แสดงส่วนขยายของแอปอื่นด้วย', en: 'Show other apps extensions too' },
  laterExt: {
    th: 'ส่วนขยาย "{ext}" ({app}) เริ่มใน core {since} — ถ้าแอปของคุณใช้ core เก่ากว่านั้นจะข้ามค่าเหล่านี้ (ไม่พัง)',
    en: 'Extension "{ext}" ({app}) starts in core {since} — apps on an older core skip these values (nothing breaks).',
  },
  extOrbit: { th: 'Orbit ยังไม่มีค่าเฉพาะแอป', en: 'Orbit has no app-specific values yet' },
  group_surfaces: { th: 'พื้นผิว', en: 'Surfaces' },
  group_borders: { th: 'เส้นขอบ', en: 'Borders' },
  group_text: { th: 'ตัวอักษรและไอคอน', en: 'Text & icons' },
  group_accent: { th: 'สีเน้น (accent)', en: 'Accent' },
  group_status: { th: 'สถานะ', en: 'Status' },
  group_other: { th: 'อื่น ๆ', en: 'Other' },
  extNone: { th: 'ไม่มีค่าที่ต้องปรับ', en: 'Nothing to adjust' },
  extHint: { th: 'ค่าเหล่านี้ใช้เฉพาะแอปที่ระบุ — ถ้าไม่ระบุ ระบบคำนวณจากสี core ให้', en: 'Only used by the named app; if unset they are derived from core colours' },
  footer: { th: 'NSL Palette ทำงานในเบราว์เซอร์ทั้งหมด ไม่ส่งข้อมูลธีมของคุณไปที่ใด', en: 'NSL Palette runs entirely in your browser; your theme is never uploaded' },
  // ── โครงหน้าใหม่ (2026-11-17) ──
  steps: { th: 'ขั้นตอน', en: 'Steps' },
  importShort: { th: 'นำเข้า', en: 'Import' },
  step_start: { th: 'เริ่มต้น', en: 'Start' },
  step_colors: { th: 'สี', en: 'Colours' },
  step_ext: { th: 'สีเฉพาะแอป', en: 'App colours' },
  step_shape: { th: 'รูปทรงและตัวอักษร', en: 'Shape & type' },
  step_style: { th: 'ความหนาแน่นและเงา', en: 'Density & shadow' },
  step_check: { th: 'อ่านง่ายไหม', en: 'Readability' },
  step_file: { th: 'ดูไฟล์ .nslt', en: 'View .nslt file' },
  sub_start: { th: 'ฐาน · แอป · สีหลัก', en: 'Base · apps · accent' },
  sub_colors: { th: '{n} สี · ปรับแล้ว {m}', en: '{n} colours · {m} changed' },
  sub_extNone: { th: 'ไม่มีสำหรับแอปที่เลือก', en: 'None for the selected apps' },
  sub_shape: { th: 'มุมโค้ง · ฟอนต์ · ขนาด', en: 'Radius · fonts · size' },
  sub_checkPass: { th: 'ผ่านทุกคู่สี', en: 'All pairs pass' },
  sub_checkFail: { th: '{n} คู่สีอ่านยาก', en: 'Hard-to-read pairs: {n}' },
  sub_file: { th: 'คัดลอก / ตรวจก่อนส่ง', en: 'Copy / check before sharing' },
  startHint: { th: 'สามอย่างนี้พอสำหรับธีมส่วนใหญ่ — ที่เหลือคำนวณให้อัตโนมัติ', en: 'These three are enough for most themes — the rest is derived for you' },
  baseTitle: { th: 'ธีมฐาน', en: 'Base theme' },
  baseHint: { th: 'ค่าที่ไม่ได้แก้จะมาจากธีมนี้', en: 'Anything you do not change comes from this theme' },
  base_user: { th: 'นำเข้า', en: 'Imported' },
  bd_default: { th: 'ค่าเริ่มต้น', en: 'Default' },
  bd_nebular: { th: 'ออกแบบฐานข้อมูล', en: 'Database design' },
  bd_spectrum: { th: 'สื่อ', en: 'Media' },
  bd_lyra: { th: 'กระดาษ', en: 'Paper' },
  bd_orbit: { th: 'ชีวิตประจำวัน', en: 'Everyday' },
  appsTitle: { th: 'ใช้กับแอปไหน', en: 'Which apps is it for?' },
  appsHint: { th: 'ใช้จัดหมวดและเลือกพรีวิว — ไฟล์เดียวใช้ได้ทุกแอปเสมอ', en: 'Used to categorise and pick previews — one file always works in every app' },
  allApps: { th: 'ทุกแอป', en: 'All apps' },
  app_desc_nebular: { th: 'ออกแบบฐานข้อมูล · Windows', en: 'Database design · Windows' },
  app_desc_spectrum: { th: 'เล่นสื่อ · Windows', en: 'Media player · Windows' },
  app_desc_lyra: { th: 'จดโลกของเรื่องแต่ง', en: 'Worldbuilding notes' },
  app_desc_orbit: { th: 'เครื่องมือประจำวัน · Android', en: 'Everyday tools · Android' },
  status_short_experiment: { th: 'ทดลอง', en: 'Experimental' },
  status_short_planned: { th: 'ยังไม่อ่านธีม', en: 'Not reading themes yet' },
  lastApp: { th: 'ต้องเลือกอย่างน้อยหนึ่งแอป', en: 'At least one app must stay selected' },
  accentTitle: { th: 'สีหลัก', en: 'Accent colour' },
  accentHint: { th: 'สีของปุ่ม ลิงก์ และสิ่งที่เลือก — ตัวอักษรบนปุ่มและพื้นอ่อนคำนวณให้อ่านง่ายเอง', en: 'Buttons, links and selection — text on it and the soft tint are derived to stay readable' },
  next: { th: 'ถัดไป : {step} →', en: 'Next: {step} →' },
  colorsHint: { th: 'แก้เฉพาะสีที่อยากเปลี่ยน — ตัวหนา = ปรับเอง · ปุ่ม ↺ คืนค่าจากธีมฐาน', en: 'Change only what you want — bold = changed by you · ↺ restores the base value' },
  searchColors: { th: 'ค้นหาสี เช่น ปุ่ม, ตัวอักษร, เส้น', en: 'Search colours, e.g. text, border' },
  onlyOwn: { th: 'แสดงเฉพาะที่ปรับ', en: 'Only changed' },
  noColorMatch: { th: 'ไม่พบสีที่ตรงกับคำค้น', en: 'No colours match' },
  colorsInGroup: { th: '{n} สี', en: '{n} colours' },
  hardToRead: { th: '{n} อ่านยาก', en: '{n} hard to read' },
  checkHint: { th: 'ปุ่มแก้อัตโนมัติจะปรับเฉพาะสีตัวอักษร/เส้น ไม่แตะพื้นและสีหลักที่เลือก', en: 'Auto-fix only nudges text and border colours — never your backgrounds or accent' },
  summaryPass: { th: 'ตัวอักษรอ่านง่ายทุกคู่สี ทั้งสว่างและมืด', en: 'Every text pair is readable in light and dark' },
  summaryFail: { th: '{n} คู่สีอ่านยาก', en: 'Hard-to-read pairs: {n}' },
  details: { th: 'ดูรายละเอียด', en: 'Details' },
  fileTitle: { th: 'ไฟล์ .nslt', en: '.nslt file' },
  fileHint: { th: 'ข้อความนี้คือไฟล์ที่จะดาวน์โหลด — แก้ไม่ได้ตรงนี้ ให้แก้ในขั้นก่อนหน้า', en: 'This is exactly what gets downloaded — edit it in the earlier steps' },
  problemsN: { th: 'ยังมี {n} ปัญหาก่อนดาวน์โหลด', en: '{n} problem(s) before downloading' },
  both: { th: 'คู่กัน', en: 'Both' },
  previewMode: { th: 'โหมดของพรีวิว', en: 'Preview mode' },
  dismiss: { th: 'ปิด', en: 'Dismiss' },
  versionLabel: { th: 'เวอร์ชันเว็บ', en: 'Web version' },
  uiTheme: { th: 'ธีมของหน้าเว็บนี้', en: 'Theme of this page' },
  extPickApp: { th: 'เลือกพรีวิวของแอป (แท็บด้านขวา) เพื่อแก้สีเฉพาะของแอปนั้น', en: 'Pick an app preview (tabs on the right) to edit its own colours' },
  extNoneFor: { th: '{app} ไม่มีสีเฉพาะแอป — ใช้สีหลักทั้งหมด', en: '{app} has no app-specific colours — it uses the main colours' },
  editAppColors: { th: 'แก้สีของ {app}', en: 'Edit {app} colours' },
  extNoSelected: { th: 'แอปที่เลือกไว้ไม่มีสีเฉพาะแอป — เพิ่มแอปได้ที่ขั้น "เริ่มต้น"', en: 'None of the selected apps has its own colours — add apps in "Start"' },
  history: { th: 'ย้อนกลับ/ทำซ้ำ', en: 'Undo / Redo' },
  undo: { th: 'ย้อนกลับ', en: 'Undo' },
  redo: { th: 'ทำซ้ำ', en: 'Redo' },
  undoHint: { th: 'ย้อนกลับ (Ctrl+Z) · เหลือ {n} ขั้น', en: 'Undo (Ctrl+Z) · {n} step(s) left' },
  redoHint: { th: 'ทำซ้ำ (Ctrl+Y) · เหลือ {n} ขั้น', en: 'Redo (Ctrl+Y) · {n} step(s) left' },
  undone: { th: 'ย้อนกลับแล้ว', en: 'Undone' },
  redone: { th: 'ทำซ้ำแล้ว', en: 'Redone' },
  back: { th: '← กลับ : {step}', en: '← Back: {step}' },
  notInPreview: { th: 'ไม่มีในพรีวิว {app}', en: 'Not in the {app} preview' },
  seeIn: { th: 'ดูใน {app}', en: 'See in {app}' },
  ui_system: { th: 'ตามระบบ', en: 'Match system' },
  ui_light: { th: 'สว่าง', en: 'Light' },
  ui_dark: { th: 'มืด', en: 'Dark' },
  extTitleHint: { th: 'สีที่ใช้เฉพาะในแอปนั้น — ไม่ตั้งก็ได้ ระบบคำนวณจากสีหลักให้', en: 'Colours only that app uses — optional; derived from your main colours if unset' },
} as const;

export type Key = keyof typeof dict;

const KEY = 'nsl-palette-lang';
function initial(): Lang {
  try {
    const v = localStorage.getItem(KEY);
    if (v === 'th' || v === 'en') return v;
  } catch {
    /* ไม่มี storage ก็ไม่เป็นไร */
  }
  return typeof navigator !== 'undefined' && navigator.language.toLowerCase().startsWith('en') ? 'en' : 'th';
}

export const lang = ref<Lang>(initial());

export function setLang(l: Lang): void {
  lang.value = l;
  try {
    localStorage.setItem(KEY, l);
  } catch {
    /* ignore */
  }
}

/** แปลข้อความ ({name} แทนค่าจาก params) */
export function t(key: Key, params: Record<string, string | number> = {}): string {
  let s: string = dict[key][lang.value];
  for (const [k, v] of Object.entries(params)) s = s.replaceAll(`{${k}}`, String(v));
  return s;
}

export const tr = computed(() => (key: Key, params: Record<string, string | number> = {}) => {
  void lang.value;
  return t(key, params);
});
