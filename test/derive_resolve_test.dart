import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

NslThemeSpec _spec({
  String id = 't',
  String? ext,
  Map<String, Color> light = const {},
  Map<String, Color> dark = const {},
  Map<String, Map<String, Color>> lightExt = const {},
}) =>
    NslThemeSpec(
      id: id,
      name: id,
      extendsId: ext,
      light: NslModeSpec(colors: light, extensions: lightExt),
      dark: NslModeSpec(colors: dark),
    );

const _roots = <String, Color>{
  'bg': Color(0xFFEEEEEE),
  'surface': Color(0xFFFFFFFF),
  'text': Color(0xFF111111),
  'accent': Color(0xFF0F766E),
};

void main() {
  group('deriveColors', () {
    test('ขาดสี root → โยน ArgumentError', () {
      expect(() => deriveColors({'bg': const Color(0xFF000000)}, Brightness.light), throwsArgumentError);
    });

    test('ครบทุก token เมื่อมีแค่ root', () {
      final c = deriveColors(_roots, Brightness.light);
      for (final k in kCoreColorKeys) {
        expect(c.toMap().containsKey(k), isTrue, reason: k);
      }
    });

    test('ค่าที่ระบุไม่ถูกแตะ', () {
      final c = deriveColors({..._roots, 'border': const Color(0xFF123456)}, Brightness.light);
      expect(c.border, const Color(0xFF123456));
    });

    test('ค่าที่ derive อ่านออก: ตัวอักษรรอง/accentInk/onAccent ผ่านเกณฑ์', () {
      for (final b in Brightness.values) {
        final t = resolveTokens(_spec(light: _roots, dark: _roots), b);
        final failures = contrastFailures(t).map((e) => e.name).toList();
        // textMuted/สีสถานะ/accentInk ที่ derive ต้องผ่าน (border/surface ขึ้นกับค่าผู้ใช้จึงไม่ตรวจที่นี่)
        expect(failures.where((n) => n != 'border/surface'), isEmpty, reason: '$b: $failures');
      }
    });

    test('สีสถานะต่างกันตามโหมด', () {
      final l = deriveColors(_roots, Brightness.light);
      final d = deriveColors(_roots, Brightness.dark);
      expect(l.danger, isNot(d.danger));
    });
  });

  group('resolveTokens', () {
    NslThemeSpec? lookup(String id) => builtinThemeById(id);

    test('ไม่มี extends และขาด root → NslResolveException บอกชื่อที่ขาด', () {
      expect(
        () => resolveTokens(_spec(light: const {'bg': Color(0xFF000000)}), Brightness.light),
        throwsA(isA<NslResolveException>().having((e) => e.message, 'message', contains('surface'))),
      );
    });

    test('extends ธีมในตัว: ได้ค่าจากฐานทั้งหมด', () {
      final t = resolveTokens(_spec(ext: kBuiltinDevId), Brightness.dark, lookup: lookup);
      final base = resolveTokens(kBuiltinDev, Brightness.dark);
      expect(t, base);
    });

    test('ธีมลูกทับเฉพาะที่ระบุ', () {
      final t = resolveTokens(_spec(ext: kBuiltinDevId, light: const {'bg': Color(0xFF010203)}), Brightness.light, lookup: lookup);
      expect(t.colors.bg, const Color(0xFF010203));
      expect(t.colors.surface, const Color(0xFFFFFFFF));
    });

    test('เปลี่ยน accent โดยไม่ระบุ accentInk/accentTint/onAccent → คำนวณใหม่ ไม่ใช้ค่าเก่าของฐาน', () {
      const newAccent = Color(0xFFD97706);
      final base = resolveTokens(kBuiltinDev, Brightness.light);
      final t = resolveTokens(_spec(ext: kBuiltinDevId, light: const {'accent': newAccent}), Brightness.light, lookup: lookup);
      expect(t.colors.accent, newAccent);
      expect(t.colors.accentInk, isNot(base.colors.accentInk));
      expect(t.colors.accentTint, isNot(base.colors.accentTint));
      expect(contrastRatio(t.colors.accentInk, t.colors.surface), greaterThanOrEqualTo(4.5));
    });

    test('เปลี่ยน accent และระบุ accentInk เอง → ใช้ค่าที่ระบุ', () {
      final t = resolveTokens(
        _spec(ext: kBuiltinDevId, light: const {'accent': Color(0xFFD97706), 'accentInk': Color(0xFF111111)}),
        Brightness.light,
        lookup: lookup,
      );
      expect(t.colors.accentInk, const Color(0xFF111111));
    });

    test('extends หายไป → NslResolveException', () {
      expect(() => resolveTokens(_spec(ext: 'nope'), Brightness.light, lookup: lookup), throwsA(isA<NslResolveException>()));
    });

    test('extends วนเป็นวง → NslResolveException (ไม่วนไม่จบ)', () {
      final a = _spec(id: 'a', ext: 'b');
      final b = _spec(id: 'b', ext: 'a');
      NslThemeSpec? l(String id) => id == 'a' ? a : (id == 'b' ? b : null);
      expect(() => resolveTokens(a, Brightness.light, lookup: l), throwsA(isA<NslResolveException>()));
    });

    test('สายการสืบทอดลึกเกินกำหนด → NslResolveException', () {
      final specs = {
        for (var i = 0; i < 20; i++) 't$i': _spec(id: 't$i', ext: 't${i + 1}'),
        't20': _spec(id: 't20', light: _roots, dark: _roots),
      };
      expect(() => resolveTokens(specs['t0']!, Brightness.light, lookup: (id) => specs[id]), throwsA(isA<NslResolveException>()));
    });

    test('ส่วนขยายที่รู้จักถูกเติมค่า derive ให้ครบแม้ธีมไม่ระบุ', () {
      final t = resolveTokens(_spec(light: _roots, dark: _roots), Brightness.light);
      for (final k in kDevExtension.keys) {
        expect(t.ext('nebular', k), isNotNull, reason: k);
      }
      expect(t.ext('spectrum', 'panelBottom'), isNotNull);
    });

    test('ส่วนขยายที่ไม่รู้จักผ่านไปตามเดิม', () {
      final t = resolveTokens(
        _spec(light: _roots, dark: _roots, lightExt: const {'future': {'k': Color(0xFF010101)}}),
        Brightness.light,
      );
      expect(t.ext('future', 'k'), const Color(0xFF010101));
    });

    test('ค่าสไตล์: ค่าเริ่มต้น และ radius ที่ระบุทับเฉพาะช่อง', () {
      final plain = resolveTokens(_spec(light: _roots), Brightness.light);
      expect(plain.shape, const NslShape());
      expect(plain.density, NslDensity.normal);
      expect(plain.type.scale, 1.0);
      final s = NslThemeSpec(id: 's', name: 's', light: const NslModeSpec(colors: _roots), radius: const {'md': 10}, scale: 1.1, density: NslDensity.compact);
      final t = resolveTokens(s, Brightness.light);
      expect(t.shape.md, 10);
      expect(t.shape.sm, 6);
      expect(t.type.scale, 1.1);
      expect(t.density, NslDensity.compact);
    });

    test('ฟอนต์สำรองปิดท้ายด้วย Noto Sans Thai เสมอ แม้ธีมระบุฟอนต์อื่น', () {
      final t = resolveTokens(NslThemeSpec(id: 'f', name: 'f', light: const NslModeSpec(colors: _roots), family: 'Comic Sans MS'), Brightness.light);
      expect(t.type.effectiveFamily, 'Comic Sans MS');
      expect(t.type.fallback, contains(kNslThaiFont));
      expect(t.type.fallback, isNot(contains('Comic Sans MS')));
      // ไม่ระบุ → ฟอนต์หลักคือ Noto Sans Thai และไม่ซ้ำในรายการสำรอง
      final d = resolveTokens(_spec(light: _roots), Brightness.light);
      expect(d.type.effectiveFamily, kNslThaiFont);
      expect(d.type.fallback, isNot(contains(kNslThaiFont)));
    });
  });
}
