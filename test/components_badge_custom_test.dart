// NslBadge สีเฉพาะแอป : background/foreground — ตัวอักษรผ่าน 4.5:1 เสมอ
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

Future<void> _pump(WidgetTester tester, Widget w, NslTokens t) async {
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(brightness: t.brightness, platform: TargetPlatform.windows, extensions: [NslTheme(t)]),
    home: Scaffold(body: Align(alignment: Alignment.topLeft, child: w)),
  ));
  await tester.pumpAndSettle();
}

Color _bg(WidgetTester tester) => (tester.widget<Container>(find.descendant(of: find.byType(NslBadge), matching: find.byType(Container)).first).decoration! as BoxDecoration).color!;
Color _fg(WidgetTester tester) => tester.widget<Text>(find.descendant(of: find.byType(NslBadge), matching: find.byType(Text))).style!.color!;

void main() {
  final light = resolveTokens(kBuiltinDefault, Brightness.light);

  testWidgets('ใช้สีพื้นที่ระบุแทนสีของโทน', (tester) async {
    await _pump(tester, const NslBadge('ร่าง', background: Color(0xFFEAE3D6), foreground: Color(0xFF4F463C)), light);
    expect(_bg(tester), const Color(0xFFEAE3D6));
    expect(_fg(tester), const Color(0xFF4F463C));
  });

  testWidgets('ไม่ระบุ background = เหมือนเดิม (ตามโทน)', (tester) async {
    await _pump(tester, const NslBadge('ok', tone: NslBadgeTone.success, foreground: Color(0xFF000000)), light);
    expect(_bg(tester), light.colors.successBg);
    expect(_fg(tester), light.colors.successText);
  });

  testWidgets('foreground ไม่ระบุ → ใช้สีตัวอักษรหลักของธีม', (tester) async {
    await _pump(tester, const NslBadge('x', background: Color(0xFFFFFFFF)), light);
    expect(_fg(tester), light.colors.text);
  });

  testWidgets('ตัวอักษรที่อ่านไม่ออกถูกขยับให้ผ่าน 4.5:1', (tester) async {
    // เหลืองอ่อนบนเหลืองอ่อน = อ่านไม่ออก
    await _pump(tester, const NslBadge('เตือน', background: Color(0xFFFFF4C2), foreground: Color(0xFFFFE680)), light);
    expect(contrastRatio(_fg(tester), _bg(tester)), greaterThanOrEqualTo(4.5));
  });

  testWidgets('พื้นโปร่ง : วัดบนสีพื้นผิว', (tester) async {
    const bg = Color(0x33FF0000);
    await _pump(tester, const NslBadge('โปร่ง', background: bg, foreground: Color(0xFFFF8080)), light);
    final backdrop = Color.alphaBlend(bg, light.colors.surface);
    expect(contrastRatio(_fg(tester), backdrop), greaterThanOrEqualTo(4.5));
  });

  group('สีสุ่มหลายแบบ × ธีม × โหมด : ผ่าน 4.5 เสมอ', () {
    const samples = [Color(0xFF000000), Color(0xFFFFFFFF), Color(0xFF808080), Color(0xFFFF0000), Color(0xFF00FF00), Color(0xFF0000FF), Color(0xFFFFFF00), Color(0xFF7B58D6)];
    for (final e in _themes.entries) {
      for (final b in Brightness.values) {
        testWidgets('${e.key} ${b.name}', (tester) async {
          final t = resolveTokens(e.value, b);
          for (final bg in samples) {
            for (final fg in samples) {
              await _pump(tester, NslBadge('ป้าย', background: bg, foreground: fg), t);
              expect(contrastRatio(_fg(tester), bg), greaterThanOrEqualTo(4.5), reason: 'bg=$bg fg=$fg');
            }
          }
        });
      }
    }
  });

  testWidgets('semantics เหมือนเดิม : มีป้าย', (tester) async {
    final h = tester.ensureSemantics();
    await _pump(tester, const NslBadge('ร่าง', background: Color(0xFFEAE3D6)), light);
    expect(find.bySemanticsLabel('ร่าง'), findsOneWidget);
    h.dispose();
  });
}
