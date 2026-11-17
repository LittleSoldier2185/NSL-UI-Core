// NslAlert · NslSpinner · NslCloseButton (เฟส 20)
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

Future<void> _pump(WidgetTester tester, Widget w, NslTokens t, {TargetPlatform platform = TargetPlatform.windows, double width = 360, bool settle = true}) async {
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(brightness: t.brightness, platform: platform, extensions: [NslTheme(t)]),
    home: Scaffold(body: Align(alignment: Alignment.topLeft, child: SizedBox(width: width, child: w))),
  ));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

BoxDecoration _deco(WidgetTester tester) => tester.widget<Container>(find.descendant(of: find.byType(NslAlert), matching: find.byType(Container)).first).decoration! as BoxDecoration;

void main() {
  final light = resolveTokens(kBuiltinDefault, Brightness.light);

  group('NslAlert', () {
    testWidgets('สีของแต่ละโทนมาจากคู่ *Bg/*Text', (tester) async {
      final c = light.colors;
      for (final (tone, bg, fg) in [
        (NslAlertTone.info, c.infoBg, c.infoText),
        (NslAlertTone.success, c.successBg, c.successText),
        (NslAlertTone.warn, c.warnBg, c.warnText),
        (NslAlertTone.danger, c.dangerBg, c.dangerText),
      ]) {
        await _pump(tester, NslAlert(message: 'ข้อความ', title: 'หัวเรื่อง', tone: tone), light);
        expect(_deco(tester).color, bg, reason: tone.name);
        expect(tester.widget<Text>(find.text('ข้อความ')).style!.color, fg, reason: tone.name);
      }
    });

    testWidgets('ไอคอนตามโทนเสมอ (ไม่สื่อด้วยสีอย่างเดียว) และเปลี่ยนได้', (tester) async {
      await _pump(tester, const NslAlert(message: 'x', tone: NslAlertTone.danger), light);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      await _pump(tester, const NslAlert(message: 'x', tone: NslAlertTone.success), light);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      await _pump(tester, const NslAlert(message: 'x', icon: Icons.star), light);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsNothing);
    });

    testWidgets('ปุ่มปิด : แสดงเมื่อมี onClose และกดได้ ; ไม่มี = ไม่แสดง', (tester) async {
      var n = 0;
      await _pump(tester, NslAlert(message: 'x', onClose: () => n++, closeTooltip: 'ปิด'), light);
      await tester.tap(find.byIcon(Icons.close));
      expect(n, 1);
      await _pump(tester, const NslAlert(message: 'x'), light);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    test('onClose โดยไม่มี closeTooltip = assert', () {
      expect(() => NslAlert(message: 'x', onClose: () {}), throwsAssertionError);
    });

    testWidgets('action อยู่ใต้ข้อความและกดได้', (tester) async {
      var n = 0;
      await _pump(tester, NslAlert(message: 'x', action: NslButton(label: 'ลองใหม่', kind: NslButtonKind.link, onPressed: () => n++)), light);
      await tester.tap(find.text('ลองใหม่'));
      expect(n, 1);
    });

    testWidgets('semantics : ป้ายรวมหัวเรื่อง+ข้อความ, live region, ปุ่มปิดยังเข้าถึงได้', (tester) async {
      final h = tester.ensureSemantics();
      await _pump(tester, NslAlert(title: 'ผิดพลาด', message: 'บันทึกไม่ได้', tone: NslAlertTone.danger, onClose: () {}, closeTooltip: 'ปิด'), light);
      final node = tester.getSemantics(find.bySemanticsLabel(RegExp('ผิดพลาด. บันทึกไม่ได้')));
      expect(node.flagsCollection.isLiveRegion, isTrue);
      expect(find.bySemanticsLabel('ปิด'), findsOneWidget);
      h.dispose();
    });

    testWidgets('announce: false = ไม่เป็น live region', (tester) async {
      final h = tester.ensureSemantics();
      await _pump(tester, const NslAlert(message: 'ทั่วไป', announce: false), light);
      expect(tester.getSemantics(find.bySemanticsLabel(RegExp('ทั่วไป'))).flagsCollection.isLiveRegion, isFalse);
      h.dispose();
    });

    for (final e in _themes.entries) {
      for (final b in Brightness.values) {
        testWidgets('contrast ≥ 4.5 ทุกโทน — ${e.key} ${b.name}', (tester) async {
          final t = resolveTokens(e.value, b);
          for (final tone in NslAlertTone.values) {
            await _pump(tester, NslAlert(title: 'หัวเรื่อง', message: 'ข้อความ', tone: tone, onClose: () {}, closeTooltip: 'ปิด'), t);
            final bg = _deco(tester).color!;
            final backdrop = Color.alphaBlend(bg, t.colors.surface);
            expect(contrastRatio(tester.widget<Text>(find.text('ข้อความ')).style!.color!, backdrop), greaterThanOrEqualTo(4.5), reason: '${tone.name} ข้อความ');
            expect(contrastRatio(tester.widget<Text>(find.text('หัวเรื่อง')).style!.color!, backdrop), greaterThanOrEqualTo(4.5), reason: '${tone.name} หัวเรื่อง');
            expect(contrastRatio(tester.widget<Icon>(find.byIcon(Icons.close)).color!, backdrop), greaterThanOrEqualTo(4.5), reason: '${tone.name} ปุ่มปิด');
          }
        });
      }
    }

    testWidgets('ข้อความยาว ในที่แคบ ไม่ overflow ทุก density', (tester) async {
      for (final d in NslDensity.values) {
        final t = NslTokens(brightness: light.brightness, colors: light.colors, shape: light.shape, type: light.type, density: d, elevation: light.elevation, extensions: light.extensions);
        await _pump(tester, NslAlert(title: 'หัวเรื่องยาวมากมาก', message: 'ข้อความที่ยาวมากมากมาก', onClose: () {}, closeTooltip: 'ปิด', action: const Text('act')), t, width: 240);
        expect(tester.takeException(), isNull, reason: d.name);
      }
    });
  });

  group('NslCloseButton', () {
    testWidgets('กดได้ มี tooltip/semantics ; ปิดใช้งานเมื่อ onPressed = null', (tester) async {
      final h = tester.ensureSemantics();
      var n = 0;
      await _pump(tester, NslCloseButton(onPressed: () => n++, tooltip: 'ปิด'), light);
      await tester.tap(find.byIcon(Icons.close));
      expect(n, 1);
      expect(find.bySemanticsLabel('ปิด'), findsOneWidget);
      await _pump(tester, const NslCloseButton(onPressed: null, tooltip: 'ปิด'), light);
      expect(tester.widget<Icon>(find.byIcon(Icons.close)).color, light.colors.textFaint);
      h.dispose();
    });

    testWidgets('จอสัมผัส : ≥ 44', (tester) async {
      await _pump(tester, NslCloseButton(onPressed: () {}, tooltip: 'ปิด'), light, platform: TargetPlatform.android);
      final s = tester.getSize(find.byType(NslCloseButton));
      expect(s.width, greaterThanOrEqualTo(44));
      expect(s.height, greaterThanOrEqualTo(44));
    });
  });

  group('NslSpinner', () {
    testWidgets('มีป้ายสำหรับโปรแกรมอ่านหน้าจอ และสี accentInk', (tester) async {
      final h = tester.ensureSemantics();
      await _pump(tester, const NslSpinner(label: 'กำลังโหลดรายการ'), light, settle: false);
      expect(find.bySemanticsLabel('กำลังโหลดรายการ'), findsOneWidget);
      expect(tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator)).color, light.colors.accentInk);
      await tester.pumpWidget(const SizedBox());
      h.dispose();
    });

    testWidgets('sm < md < lg', (tester) async {
      final s = <NslSpinnerSize, double>{};
      for (final z in NslSpinnerSize.values) {
        await _pump(tester, Align(alignment: Alignment.topLeft, child: NslSpinner(label: 'x', size: z)), light, settle: false);
        s[z] = tester.getSize(find.byType(NslSpinner)).width;
      }
      expect(s[NslSpinnerSize.sm]!, lessThan(s[NslSpinnerSize.md]!));
      expect(s[NslSpinnerSize.md]!, lessThan(s[NslSpinnerSize.lg]!));
      await tester.pumpWidget(const SizedBox());
    });

    test('วงมองเห็นได้บนพื้นผิวทุกธีม (accentInk/surface ≥ 4.5)', () {
      for (final e in _themes.entries) {
        for (final b in Brightness.values) {
          final t = resolveTokens(e.value, b);
          expect(contrastRatio(t.colors.accentInk, t.colors.surface), greaterThanOrEqualTo(4.5), reason: 'accentInk ${e.key} ${b.name}');
        }
      }
    });
  });
}
