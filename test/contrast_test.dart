import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

void main() {
  group('contrastRatio', () {
    test('ดำ/ขาว = 21 และสลับที่ได้ค่าเดิม', () {
      const black = Color(0xFF000000), white = Color(0xFFFFFFFF);
      expect(contrastRatio(black, white), closeTo(21, 0.001));
      expect(contrastRatio(white, black), closeTo(21, 0.001));
    });

    test('สีเดียวกัน = 1', () {
      expect(contrastRatio(const Color(0xFF336699), const Color(0xFF336699)), closeTo(1, 1e-9));
    });
  });

  group('inkFor', () {
    test('accent ที่อ่านบนพื้นได้อยู่แล้วคืนค่าเดิม', () {
      const dark = Color(0xFF0B5A54);
      expect(inkFor(dark, const Color(0xFFFFFFFF), true), dark);
    });

    test('accent สว่างบนพื้นขาวถูกทำให้เข้มจนผ่าน 4.5:1', () {
      const amber = Color(0xFFF4B860);
      final ink = inkFor(amber, const Color(0xFFFFFFFF), true);
      expect(contrastRatio(ink, const Color(0xFFFFFFFF)), greaterThanOrEqualTo(4.5));
    });

    test('ธีมมืด: accent เข้มถูกทำให้อ่อนลงจนผ่าน 4.5:1', () {
      const teal = Color(0xFF0F766E);
      const surface = Color(0xFF14151A);
      final ink = inkFor(teal, surface, false);
      expect(contrastRatio(ink, surface), greaterThanOrEqualTo(4.5));
    });
  });

  group('onAccentFor', () {
    test('พื้นสว่าง → ตัวอักษรเข้ม ; พื้นเข้ม → ขาว', () {
      expect(onAccentFor(const Color(0xFFF4B860)), const Color(0xFF1A1204));
      expect(onAccentFor(const Color(0xFF0B1F3A)), const Color(0xFFFFFFFF));
    });
  });

  group('ensureContrast', () {
    test('ผ่านอยู่แล้วไม่แตะ', () {
      const c = Color(0xFF111111);
      expect(ensureContrast(c, const Color(0xFFFFFFFF), 4.5, light: true), c);
    });

    test('ธีมสว่าง: ขยับเข้าหาดำจนผ่าน', () {
      const fg = Color(0xFFAAAAAA), bg = Color(0xFFFFFFFF);
      final r = ensureContrast(fg, bg, 4.5, light: true);
      expect(contrastRatio(r, bg), greaterThanOrEqualTo(4.5));
    });

    test('ธีมมืด: ขยับเข้าหาขาวจนผ่าน', () {
      const fg = Color(0xFF555555), bg = Color(0xFF000000);
      final r = ensureContrast(fg, bg, 4.5, light: false);
      expect(contrastRatio(r, bg), greaterThanOrEqualTo(4.5));
    });

    test('ต้องการเกินที่เป็นไปได้ → คืนดำสนิท (ไม่วนไม่จบ)', () {
      const bg = Color(0xFF808080);
      final r = ensureContrast(const Color(0xFF808080), bg, 21, light: true);
      expect(r, const Color(0xFF000000));
    });
  });
}
