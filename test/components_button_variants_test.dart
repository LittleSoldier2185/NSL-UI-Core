// NslButton แบบ Bootstrap : ชนิด success/warning/info/link, ขนาด sm/md/lg, outline, loading
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

final _themes = <String, NslThemeSpec>{
  'default': kBuiltinDefault,
  'nebular': kBuiltinDev,
  'spectrum': builtinResonance(),
  'lyra.paper': kBuiltinLyraPaper,
  'orbit': kBuiltinOrbit,
};

Future<void> _pump(WidgetTester tester, Widget w, NslTokens t, {TargetPlatform platform = TargetPlatform.windows, double width = 320}) async {
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(brightness: t.brightness, platform: platform, extensions: [NslTheme(t)]),
    home: Scaffold(body: Align(alignment: Alignment.topLeft, child: SizedBox(width: width, child: Align(alignment: Alignment.topLeft, child: w)))),
  ));
  await tester.pumpAndSettle();
}

Color _bg(WidgetTester tester) => tester.widget<Material>(find.descendant(of: find.byType(NslButton), matching: find.byType(Material)).first).color!;
TextStyle _label(WidgetTester tester) => tester.widget<Text>(find.descendant(of: find.byType(NslButton), matching: find.byType(Text))).style!;

void main() {
  final light = resolveTokens(kBuiltinDefault, Brightness.light);

  group('ทุกชนิด × solid/outline × ธีม × โหมด : ตัวอักษรอ่านออก ≥ 4.5', () {
    for (final e in _themes.entries) {
      for (final b in Brightness.values) {
        testWidgets('${e.key} ${b.name}', (tester) async {
          final t = resolveTokens(e.value, b);
          for (final kind in NslButtonKind.values) {
            for (final outline in [false, true]) {
              await _pump(tester, NslButton(label: 'ปุ่ม', kind: kind, outline: outline, onPressed: () {}), t);
              final bg = _bg(tester);
              final backdrop = Color.alphaBlend(bg, t.colors.surface);
              final fg = _label(tester).color!;
              expect(contrastRatio(fg, backdrop), greaterThanOrEqualTo(4.5), reason: '${kind.name} outline=$outline');
            }
          }
        });
      }
    }
  });

  group('ขนาด', () {
    testWidgets('sm < md < lg ; ตัวอักษร 13 / 14 / 16', (tester) async {
      final h = <NslButtonSize, double>{};
      final f = <NslButtonSize, double>{};
      for (final s in NslButtonSize.values) {
        await _pump(tester, NslButton(label: 'ปุ่ม', size: s, onPressed: () {}), light);
        h[s] = tester.getSize(find.byType(NslButton)).height;
        f[s] = _label(tester).fontSize!;
      }
      expect(h[NslButtonSize.sm]!, lessThan(h[NslButtonSize.md]!));
      expect(h[NslButtonSize.md]!, lessThan(h[NslButtonSize.lg]!));
      expect(f, {NslButtonSize.sm: 13, NslButtonSize.md: 14, NslButtonSize.lg: 16});
    });

    testWidgets('ค่าเริ่มต้น (md) สูงเท่าเดิม = controlHeight', (tester) async {
      await _pump(tester, NslButton(label: 'ปุ่ม', onPressed: () {}), light);
      expect(tester.getSize(find.byType(NslButton)).height, light.controlHeight());
    });

    testWidgets('จอสัมผัส : ทุกขนาดสูง ≥ 44', (tester) async {
      for (final s in NslButtonSize.values) {
        await _pump(tester, NslButton(label: 'ปุ่ม', size: s, onPressed: () {}), light, platform: TargetPlatform.android);
        expect(tester.getSize(find.byType(NslButton)).height, greaterThanOrEqualTo(44), reason: s.name);
      }
    });
  });

  group('outline', () {
    testWidgets('พื้นโปร่ง ขอบและตัวอักษรสีของชนิด', (tester) async {
      await _pump(tester, NslButton(label: 'ปุ่ม', kind: NslButtonKind.success, outline: true, onPressed: () {}), light);
      expect(_bg(tester), Colors.transparent);
      final shape = tester.widget<Material>(find.descendant(of: find.byType(NslButton), matching: find.byType(Material)).first).shape! as RoundedRectangleBorder;
      expect(shape.side.color, light.colors.success);
    });

    testWidgets('danger outline = พื้นโปร่ง ขอบ danger (ไม่ใช่พื้นแดงอ่อน)', (tester) async {
      await _pump(tester, NslButton(label: 'ลบ', kind: NslButtonKind.danger, outline: true, onPressed: () {}), light);
      expect(_bg(tester), Colors.transparent);
      await _pump(tester, NslButton(label: 'ลบ', kind: NslButtonKind.danger, onPressed: () {}), light);
      expect(_bg(tester), light.colors.dangerBg);
    });

    testWidgets('ปิดใช้งาน : พื้นโปร่งยังโปร่ง ตัวอักษรจาง', (tester) async {
      await _pump(tester, const NslButton(label: 'ปุ่ม', kind: NslButtonKind.primary, outline: true, onPressed: null), light);
      expect(_label(tester).color, light.colors.textFaint);
    });
  });

  group('ชนิดใหม่', () {
    testWidgets('success/warning/info ทึบ : พื้นเป็นสีของชนิด', (tester) async {
      final c = light.colors;
      for (final (k, color) in [(NslButtonKind.success, c.success), (NslButtonKind.warning, c.warnText), (NslButtonKind.info, c.infoText)]) {
        await _pump(tester, NslButton(label: 'ปุ่ม', kind: k, onPressed: () {}), light);
        expect(_bg(tester), color, reason: k.name);
      }
    });

    testWidgets('link : ไม่มีพื้น ขีดเส้นใต้ กดได้', (tester) async {
      var n = 0;
      await _pump(tester, NslButton(label: 'ลิงก์', kind: NslButtonKind.link, onPressed: () => n++), light);
      expect(_bg(tester), Colors.transparent);
      expect(_label(tester).decoration, TextDecoration.underline);
      await tester.tap(find.text('ลิงก์'));
      expect(n, 1);
    });
  });

  group('loading', () {
    testWidgets('มีวงหมุน กดไม่ได้ ไม่เทาลง', (tester) async {
      var n = 0;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(extensions: [NslTheme(light)]),
        home: Scaffold(body: Align(alignment: Alignment.topLeft, child: NslButton(label: 'บันทึก', kind: NslButtonKind.primary, loading: true, onPressed: () => n++))),
      ));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('บันทึก'), warnIfMissed: false);
      expect(n, 0);
      expect(_bg(tester), light.colors.accent);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('ไม่ loading = ไม่มีวงหมุน', (tester) async {
      await _pump(tester, NslButton(label: 'บันทึก', onPressed: () {}), light);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  testWidgets('ข้อความยาว + ไอคอน + ขนาด lg ในที่แคบ ไม่ overflow', (tester) async {
    for (final s in NslButtonSize.values) {
      await _pump(tester, NslButton(label: 'ข้อความปุ่มที่ยาวมากมากมากมากมาก' * 2, icon: Icons.save, size: s, onPressed: () {}, expand: true), light, width: 140);
      expect(tester.takeException(), isNull, reason: s.name);
    }
  });

  testWidgets('semantics ของชนิดใหม่ : มีป้ายและ action แตะ', (tester) async {
    final h = tester.ensureSemantics();
    await _pump(tester, NslButton(label: 'สำเร็จ', kind: NslButtonKind.success, onPressed: () {}), light);
    expect(find.bySemanticsLabel('สำเร็จ'), findsOneWidget);
    h.dispose();
  });
}
