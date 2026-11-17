import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

NslTokens _tokens(Brightness b) => resolveTokens(kBuiltinDev, b);

Future<NslTokens> _read(WidgetTester tester, ThemeData theme, {Widget Function(Widget)? wrap}) async {
  late NslTokens got;
  Widget child = Builder(builder: (c) {
    got = c.nsl;
    return const SizedBox();
  });
  if (wrap != null) child = wrap(child);
  await tester.pumpWidget(MaterialApp(theme: theme, home: child));
  await tester.pumpAndSettle(); // MaterialApp เล่นแอนิเมชันเปลี่ยนธีม 200ms — รอให้จบก่อนอ่านค่า
  return got;
}

void main() {
  group('context.nsl', () {
    testWidgets('มี NslTheme → ใช้ token นั้น', (tester) async {
      final t = _tokens(Brightness.dark);
      final got = await _read(tester, ThemeData(brightness: Brightness.dark, extensions: [NslTheme(t)]));
      expect(got, t);
    });

    testWidgets('ไม่มี NslTheme → ถอยไปธีมในตัวตามโหมดสว่าง/มืด (ไม่พัง)', (tester) async {
      final light = await _read(tester, ThemeData(brightness: Brightness.light));
      final dark = await _read(tester, ThemeData(brightness: Brightness.dark));
      expect(light, resolveTokens(kBuiltinDefault, Brightness.light));
      expect(dark, resolveTokens(kBuiltinDefault, Brightness.dark));
      expect(light.isDark, isFalse);
      expect(dark.isDark, isTrue);
    });

    testWidgets('NslThemeScope ใส่ token ให้ลูก โดยไม่ทำให้ extension อื่นหาย', (tester) async {
      final other = _tokens(Brightness.light);
      final got = await _read(
        tester,
        ThemeData(extensions: [NslTheme(_tokens(Brightness.dark))]),
        wrap: (c) => NslThemeScope(tokens: other, child: c),
      );
      expect(got, other);
    });

    testWidgets('NslThemeScope ซ้อนกัน : ชั้นในชนะ', (tester) async {
      final a = _tokens(Brightness.light), b = _tokens(Brightness.dark);
      final got = await _read(
        tester,
        ThemeData(),
        wrap: (c) => NslThemeScope(tokens: a, child: NslThemeScope(tokens: b, child: c)),
      );
      expect(got, b);
    });
  });

  group('NslTheme', () {
    test('เท่ากันตาม token · copyWith · lerp สลับที่ครึ่งทาง', () {
      final a = NslTheme(_tokens(Brightness.light)), b = NslTheme(_tokens(Brightness.dark));
      expect(a, NslTheme(_tokens(Brightness.light)));
      expect(a == b, isFalse);
      expect(a.copyWith(tokens: b.tokens), b);
      expect(a.copyWith(), a);
      expect(a.lerp(b, 0.4), a);
      expect(a.lerp(b, 0.5), b);
      expect(a.lerp(null, 1), a);
    });
  });

  group('NslComponentMetrics', () {
    test('controlHeight ตามความหนาแน่น และบนจอสัมผัสไม่ต่ำกว่า 44', () {
      NslTokens d(NslDensity x) => NslTokens(brightness: Brightness.light, colors: _tokens(Brightness.light).colors, density: x);
      expect(d(NslDensity.compact).controlHeight(), lessThan(d(NslDensity.normal).controlHeight()));
      expect(d(NslDensity.normal).controlHeight(), lessThan(d(NslDensity.comfortable).controlHeight()));
      for (final x in NslDensity.values) {
        expect(d(x).controlHeight(touch: true), greaterThanOrEqualTo(kMinTapTarget));
      }
      // ค่าที่สูงกว่า 44 อยู่แล้วไม่ถูกลด
      expect(d(NslDensity.comfortable).controlHeight(touch: true), d(NslDensity.comfortable).controlHeight());
    });

    test('gap เพิ่มตามความหนาแน่น', () {
      NslTokens d(NslDensity x) => NslTokens(brightness: Brightness.light, colors: _tokens(Brightness.light).colors, density: x);
      expect(d(NslDensity.compact).gap, lessThan(d(NslDensity.normal).gap));
      expect(d(NslDensity.normal).gap, lessThan(d(NslDensity.comfortable).gap));
    });

    test('legibleOn: ผ่านอยู่แล้วคืนค่าเดิม · ไม่ผ่านขยับเข้าหาดำ/ขาวจนผ่าน · พื้นโปร่งผสมบน surface', () {
      final t = _tokens(Brightness.light), c = t.colors;
      expect(t.legibleOn(c.text, c.surface), c.text); // ผ่านอยู่แล้ว ไม่แตะ
      // ขาวบนพื้นกลาง ๆ (contrast ต่ำ) → ได้สีที่ผ่าน 4.5 บนพื้นนั้น
      const mid = Color(0xFF14958B); // accent ของ nebular โหมดมืด : ขาวบนนี้ได้ 3.68
      final fixed = t.legibleOn(const Color(0xFFFFFFFF), mid);
      expect(contrastRatio(fixed, mid), greaterThanOrEqualTo(4.5));
      // พื้นมืดมาก ตัวอักษรเข้มเกินไป → ขยับไปทางขาว
      const dark = Color(0xFF101010);
      final up = t.legibleOn(const Color(0xFF303030), dark);
      expect(contrastRatio(up, dark), greaterThanOrEqualTo(4.5));
      expect(up.computeLuminance(), greaterThan(const Color(0xFF303030).computeLuminance()));
      // พื้นโปร่งใส : วัดบน surface (ไม่ใช่ RGB ดิบของสีโปร่ง)
      final translucent = c.text.withValues(alpha: 0.06);
      expect(t.legibleOn(c.text, translucent), c.text);
    });

    test('textStyle: ฟอนต์จากธีม, ขนาดคูณ scale และไม่ต่ำกว่า minSize', () {
      final base = _tokens(Brightness.light);
      final t = NslTokens(
        brightness: Brightness.light,
        colors: base.colors,
        type: const NslType(family: 'Foo', scale: 1.2, minSize: 14),
      );
      final s = t.textStyle(10, weight: FontWeight.w600, color: base.colors.text);
      expect(s.fontFamily, 'Foo');
      expect(s.fontFamilyFallback, contains(kNslThaiFont));
      expect(s.fontSize, 14); // 10×1.2=12 < minSize 14
      expect(s.fontWeight, FontWeight.w600);
      expect(s.color, base.colors.text);
      expect(t.textStyle(20).fontSize, closeTo(24, 1e-9));
      // ไม่ระบุฟอนต์ → Noto Sans Thai ของ nsl_ui
      expect(base.textStyle(12).fontFamily, kNslThaiFont);
    });
  });

  group('guard: ไฟล์ component ต้องไม่ฮาร์ดโค้ดสี/มุมโค้ง/ขนาดตัวอักษร', () {
    // ไฟล์ที่ต้องอ่านค่าจาก token เท่านั้น (nsl_theme / metrics + ทุกไฟล์ใน components/)
    final files = <File>[
      File('lib/src/theme/nsl_theme.dart'),
      File('lib/src/theme/component_metrics.dart'),
      File('lib/src/theme/nsl_theme_data.dart'),
      if (Directory('lib/src/components').existsSync())
        ...Directory('lib/src/components').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')),
    ];

    final rules = <String, RegExp>{
      'สีตายตัว Color(0x…)': RegExp(r'Color\(\s*0x'),
      'สีตายตัว Colors.<ชื่อ> (ยกเว้น transparent)': RegExp(r'Colors\.(?!transparent\b)\w+'),
      'มุมโค้งตัวเลข BorderRadius.circular(<เลข>)': RegExp(r'BorderRadius\.circular\(\s*\d'),
      'มุมโค้งตัวเลข Radius.circular(<เลข>)': RegExp(r'(?<!Border)Radius\.circular\(\s*\d'),
      'ขนาดตัวอักษรตัวเลข fontSize: <เลข>': RegExp(r'fontSize:\s*\d'),
    };

    test('พบไฟล์ที่ต้องตรวจ', () => expect(files.length, greaterThanOrEqualTo(2)));

    for (final f in files) {
      test(f.path.replaceAll('\\', '/'), () {
        final code = f.readAsStringSync().split('\n').where((l) => !l.trimLeft().startsWith('//')).join('\n');
        for (final e in rules.entries) {
          expect(e.value.hasMatch(code), isFalse, reason: '${f.path}: ${e.key}');
        }
      });
    }
  });
}
