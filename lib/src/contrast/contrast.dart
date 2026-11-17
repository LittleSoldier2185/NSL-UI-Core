import 'dart:math' as math;
import 'dart:ui';

/// อัตราส่วน contrast ตามมาตรฐาน WCAG (1.0 – 21.0)
///
/// ย้ายมาจาก NSL Resonance (`contrast`) โดยคงสูตรเดิมทุกตัวอักษร
double contrastRatio(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

/// ทำให้ [accent] เข้มขึ้น (ธีมสว่าง) หรืออ่อนลง (ธีมมืด) จนอ่านเป็นตัวอักษรบน [surface] ได้ (>= 4.5:1)
///
/// ย้ายมาจาก NSL Resonance (`inkFor`) โดยคงสูตรเดิม
Color inkFor(Color accent, Color surface, bool light) {
  final toward = light ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  var ink = accent;
  for (var k = 1; contrastRatio(ink, surface) < 4.5 && k <= 20; k++) {
    ink = Color.lerp(accent, toward, k / 20)!;
  }
  return ink;
}

/// สีตัวอักษรที่อ่านได้บนพื้น [accent] (เข้มหรือขาว แล้วแต่ตัวไหน contrast สูงกว่า)
///
/// ย้ายมาจาก NSL Resonance (`onAccentFor`) โดยคงสูตรเดิม
Color onAccentFor(Color accent) {
  const dark = Color(0xFF1A1204);
  const white = Color(0xFFFFFFFF);
  return contrastRatio(accent, dark) >= contrastRatio(accent, white) ? dark : white;
}

/// ขยับ [fg] เข้าหาดำ (ธีมสว่าง) หรือขาว (ธีมมืด) จนได้ contrast >= [min] เทียบกับ [bg]
///
/// ถ้าผ่านอยู่แล้วคืนค่าเดิม ; ถ้าขยับสุดแล้วยังไม่ผ่านคืนดำ/ขาวสนิท
Color ensureContrast(Color fg, Color bg, double min, {required bool light}) {
  if (contrastRatio(fg, bg) >= min) return fg;
  final toward = light ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  for (var k = 1; k <= 20; k++) {
    final c = Color.lerp(fg, toward, k / 20)!;
    if (contrastRatio(c, bg) >= min) return c;
  }
  return toward;
}
