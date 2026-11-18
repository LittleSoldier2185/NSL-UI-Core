import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

/// สีประจำชนิดเอกสารของ NSL Nebular (ส่วนขยาย `nebular`: docEr/docDfd/docFlow/docWire/docScreen/docApi)
const _types = ['Er', 'Dfd', 'Flow', 'Wire', 'Screen', 'Api'];

void main() {
  for (final b in [Brightness.light, Brightness.dark]) {
    group('สีชนิดเอกสาร (${b.name})', () {
      final t = resolveTokens(kBuiltinDev, b);

      test('ทุกชนิดมีครบ 3 สี และสีหลักไม่ซ้ำกันระหว่างชนิด', () {
        final mains = <Color>{};
        for (final type in _types) {
          for (final suffix in ['', 'Ink', 'Tint']) {
            expect(t.ext('nebular', 'doc$type$suffix'), isNotNull, reason: 'doc$type$suffix');
          }
          mains.add(t.ext('nebular', 'doc$type')!);
        }
        expect(mains.length, _types.length);
      });

      test('ตัวอักษร (Ink) บนพื้นอ่อน (Tint) ผ่าน 4.5:1', () {
        for (final type in _types) {
          final ink = t.ext('nebular', 'doc${type}Ink')!;
          final tint = t.ext('nebular', 'doc${type}Tint')!;
          expect(contrastRatio(ink, tint), greaterThanOrEqualTo(4.5), reason: 'doc$type ${b.name}');
        }
      });
    });
  }

  test('โหมดสว่างตรงกับค่าในดีไซน์ NSL Nebular', () {
    final t = resolveTokens(kBuiltinDev, Brightness.light);
    expect(t.ext('nebular', 'docEr'), const Color(0xFF0F766E));
    expect(t.ext('nebular', 'docFlow'), const Color(0xFF6D4FC2));
    expect(t.ext('nebular', 'docApiInk'), const Color(0xFF155E75));
  });

  test('ธีมที่ไม่ระบุสีชนิดเอกสารได้ค่า derive ครบ และไม่ตาม accent ของธีมลูก', () {
    final base = resolveTokens(kBuiltinDev, Brightness.light);
    final child = NslThemeSpec(
      id: 'user.orange',
      name: 'Orange',
      extendsId: 'nsl.nebular',
      light: const NslModeSpec(colors: {'accent': Color(0xFFD97706)}),
    );
    final other = resolveTokens(child, Brightness.light, lookup: (id) => id == 'nsl.nebular' ? kBuiltinDev : null);
    for (final type in _types) {
      expect(other.ext('nebular', 'doc$type'), base.ext('nebular', 'doc$type'), reason: type);
    }
  });
}
