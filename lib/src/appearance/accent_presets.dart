import 'dart:ui';

import '../derive/tint.dart';
import '../tokens/nsl_tokens.dart';

/// accent สำเร็จรูป: ค่าสีของทั้งสองโหมดระบุตรง ๆ (ไม่ผ่านการคำนวณ) เพื่อให้ได้สีเดิมเป๊ะ
class NslAccentPreset {
  const NslAccentPreset(this.id, this.nameTh, this.nameEn, this.light, this.dark);

  /// รหัสคงที่ (เก็บในไฟล์ตั้งค่า) — ห้ามเปลี่ยนหลังปล่อยทางการ
  final String id;
  final String nameTh, nameEn;
  final NslAccentSet light, dark;

  NslAccentSet set(bool isDark) => isDark ? dark : light;
}

/// accent 8 ชุดเริ่มต้นของ core (ค่ามาจาก NSL Utility ซึ่งเป็นชุดที่ผู้ใช้เคยเห็นอยู่แล้ว)
/// แอปจะส่งชุดของตัวเองให้ `NslAppearancePanel` แทนก็ได้
const kAccentPresets = <NslAccentPreset>[
  NslAccentPreset('teal', 'เขียวน้ำทะเล', 'Teal', (Color(0xFF0B6E7A), Color(0xFFD8EEF0), Color(0xFF08525B)),
      (Color(0xFF1B8C9A), Color(0xFF1C3F45), Color(0xFF8ADAE3))),
  NslAccentPreset('blue', 'น้ำเงิน', 'Blue', (Color(0xFF2459C9), Color(0xFFDCE7FB), Color(0xFF1B4396)),
      (Color(0xFF3A74E0), Color(0xFF1B2C4D), Color(0xFF9DBBFA))),
  NslAccentPreset('purple', 'ม่วง', 'Purple', (Color(0xFF6842C0), Color(0xFFE8E1F7), Color(0xFF4A2F8E)),
      (Color(0xFF7B58D6), Color(0xFF2A2145), Color(0xFFC7B3F7))),
  NslAccentPreset('pink', 'ชมพู', 'Pink', (Color(0xFFB92D6A), Color(0xFFFBE1EC), Color(0xFF8A1F50)),
      (Color(0xFFD24A86), Color(0xFF45203A), Color(0xFFF5A8C8))),
  NslAccentPreset('orange', 'ส้ม', 'Orange', (Color(0xFFBF5A12), Color(0xFFFCE8D6), Color(0xFF8A3E06)),
      (Color(0xFFDB6D1E), Color(0xFF45290F), Color(0xFFF8B885))),
  NslAccentPreset('green', 'เขียว', 'Green', (Color(0xFF178A5E), Color(0xFFDDF3EA), Color(0xFF0F6B49)),
      (Color(0xFF22A877), Color(0xFF143B2D), Color(0xFF8EE0BF))),
  NslAccentPreset('red', 'แดง', 'Red', (Color(0xFFC03A3A), Color(0xFFFBE4E4), Color(0xFF8E2626)),
      (Color(0xFFDB5555), Color(0xFF452222), Color(0xFFF5AAAA))),
  NslAccentPreset('slate', 'เทาอมฟ้า', 'Slate', (Color(0xFF475569), Color(0xFFE2E8F0), Color(0xFF334155)),
      (Color(0xFF64748B), Color(0xFF232B36), Color(0xFFCBD5E1))),
];

/// หา preset จาก id (null ถ้าไม่มี)
NslAccentPreset? accentPresetById(String id, [List<NslAccentPreset> presets = kAccentPresets]) {
  for (final p in presets) {
    if (p.id == id) return p;
  }
  return null;
}

/// ชุดสี categorical สำหรับกราฟ/หมวดหมู่ที่แอปไม่มีสีของตัวเอง : 8 สีที่ต่างกันชัด ตามโหมดของ token
/// (ใช้คู่กับ `tintFor(color, isDark)` เมื่อต้องการพื้น/ตัวอักษรที่อ่านได้) — ค่าเริ่มต้นคงที่ใน v1.0 ธีมยังปรับไม่ได้
extension NslCategorical on NslTokens {
  List<Color> get categorical => [for (final p in kAccentPresets) p.set(isDark).$1];
}
