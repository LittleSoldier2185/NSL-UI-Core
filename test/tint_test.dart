// ค่า golden สร้างจากสำเนา verbatim ของ accentTints / subjectTints ใน NSL Utility (lib/ui.dart)
// — พอร์ตใน nsl_ui ต้องให้ค่าเท่ากันทุกบิต เพื่อให้สีที่ผู้ใช้เคยตั้งไม่เปลี่ยน
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

const _golden = <(int, bool, int, int, int, int, int)>[
  (0xFF7B58D6, false, 0xFF542DB8, 0xFFE7E3F2, 0xFF2D1862, 0xFFE7E3F2, 0xFF301A6A),
  (0xFF7B58D6, true, 0xFF7B58D6, 0xFF28213A, 0xFFBBACE2, 0xFF2C2442, 0xFFB8A5E9),
  (0xFFF4B860, false, 0xFFA7680C, 0xFFF5EDE0, 0xFF724708, 0xFFF5EDE0, 0xFF7C4D09),
  (0xFFF4B860, true, 0xFFB5710D, 0xFF40311C, 0xFFEECEA0, 0xFF49371D, 0xFFF8D096),
  (0xFF0F766E, false, 0xFF0F766E, 0xFFE1F4F3, 0xFF0E6D65, 0xFFE1F4F3, 0xFF0F766E),
  (0xFF0F766E, true, 0xFF129187, 0xFF1E3E3B, 0xFFA4EAE4, 0xFF1F4744, 0xFF9BF2EC),
  (0xFFFFFFFF, false, 0xFF955050, 0xFFEEE7E7, 0xFF502B2B, 0xFFEEE7E7, 0xFF562E2E),
  (0xFFFFFFFF, true, 0xFFB47474, 0xFF342828, 0xFFD4B9B9, 0xFF3B2B2B, 0xFFD8B6B6),
  (0xFF000000, false, 0xFF532D2D, 0xFFEEE7E7, 0xFF502B2B, 0xFFEEE7E7, 0xFF562E2E),
  (0xFF000000, true, 0xFF8B4B4B, 0xFF342828, 0xFFD4B9B9, 0xFF3B2B2B, 0xFFD8B6B6),
  (0xFF808080, false, 0xFF955050, 0xFFEEE7E7, 0xFF502B2B, 0xFFEEE7E7, 0xFF562E2E),
  (0xFF808080, true, 0xFFA65A5A, 0xFF342828, 0xFFD4B9B9, 0xFF3B2B2B, 0xFFD8B6B6),
  (0xFFFF0000, false, 0xFFE00606, 0xFFF6DFDF, 0xFF770303, 0xFFF6DFDF, 0xFF810303),
  (0xFFFF0000, true, 0xFFF90606, 0xFF421A1A, 0xFFF29C9C, 0xFF4B1B1B, 0xFFFC9292),
  (0xFF00FF00, false, 0xFF038603, 0xFFDFF6DF, 0xFF037703, 0xFFDFF6DF, 0xFF038103),
  (0xFF00FF00, true, 0xFF049504, 0xFF1A421A, 0xFF9CF29C, 0xFF1B4B1B, 0xFF92FC92),
  (0xFF2459C9, false, 0xFF2356C3, 0xFFE2E8F3, 0xFF132E68, 0xFFE2E8F3, 0xFF143270),
  (0xFF2459C9, true, 0xFF2459C9, 0xFF20293C, 0xFFA8BCE6, 0xFF212D45, 0xFFA0B9EE),
  (0xFFFFE082, false, 0xFF906D04, 0xFFF6F0DF, 0xFF775B03, 0xFFF6F0DF, 0xFF816203),
  (0xFFFFE082, true, 0xFFA98004, 0xFF42381A, 0xFFF2DC9C, 0xFF4B3F1B, 0xFFFCE292),
  (0xFF14958B, false, 0xFF12837A, 0xFFE1F4F2, 0xFF0E6C65, 0xFFE1F4F2, 0xFF10756D),
  (0xFF14958B, true, 0xFF139086, 0xFF1E3E3B, 0xFFA5E9E4, 0xFF204643, 0xFF9CF2EB),
];

void main() {
  test('accentTints / tintFor เท่าของ NSL Utility ทุกบิต เมื่อของเดิมอ่านได้ (golden 22 กรณี) ; ที่ของเดิมต่ำกว่า 4.5 ถูกขยับให้ผ่าน', () {
    var deviated = 0;
    for (final g in _golden) {
      final base = Color(g.$1), dark = g.$2;
      final why = '${g.$1.toRadixString(16)} dark=$dark';
      final a = accentTints(base, dark);
      expect(a.$1.toARGB32(), g.$3, reason: 'accent $why'); // ผ่านเกณฑ์กับขาวอยู่แล้ว ไม่ถูกแตะ
      expect(a.$2.toARGB32(), g.$4, reason: 'soft $why');
      if (contrastRatio(Color(g.$5), Color(g.$4)) >= 4.5) {
        expect(a.$3.toARGB32(), g.$5, reason: 'ink $why');
      } else {
        deviated++;
        expect(contrastRatio(a.$3, a.$2), greaterThanOrEqualTo(4.5), reason: 'ink (ขยับ) $why');
      }
      final t = tintFor(base, dark);
      expect(t.$1.toARGB32(), g.$6, reason: 'tint bg $why');
      if (contrastRatio(Color(g.$7), Color(g.$6)) >= 4.5) {
        expect(t.$2.toARGB32(), g.$7, reason: 'tint fg $why');
      } else {
        deviated++;
        expect(contrastRatio(t.$2, t.$1), greaterThanOrEqualTo(4.5), reason: 'tint fg (ขยับ) $why');
      }
    }
    // ค่าที่ขยับต้องเป็นส่วนน้อย (สีที่ของเดิมอ่านยากเท่านั้น)
    expect(deviated, lessThan(12));
  });

  test('tintFor: ตัวอักษรอ่านได้บนพื้นสำหรับสีสุ่ม 500 สี × 2 โหมด (>= 4.5 ; golden ที่ผ่านอยู่แล้วไม่ถูกแตะ)', () {
    var seed = 7;
    int next() => seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
    for (var i = 0; i < 500; i++) {
      final c = Color(0xFF000000 | (next() & 0xFFFFFF));
      for (final dark in [false, true]) {
        final t = tintFor(c, dark);
        expect(contrastRatio(t.$2, t.$1), greaterThanOrEqualTo(4.5), reason: '${c.toARGB32().toRadixString(16)} dark=$dark');
        final a = accentTints(c, dark);
        expect(contrastRatio(a.$3, a.$2), greaterThanOrEqualTo(4.5), reason: 'ink ${c.toARGB32().toRadixString(16)} dark=$dark');
        expect(contrastRatio(a.$1, const Color(0xFFFFFFFF)), greaterThanOrEqualTo(dark ? 3.6 : 4.5), reason: 'accent ${c.toARGB32().toRadixString(16)} dark=$dark');
      }
    }
  });
}
