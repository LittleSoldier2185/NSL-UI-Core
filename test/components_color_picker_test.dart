import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

final _themes = <String, NslThemeSpec>{
  'default': kBuiltinDefault,
  'nebular': kBuiltinDev,
  'spectrum': builtinResonance(),
  'lyra.paper': kBuiltinLyraPaper,
};

Future<void> _pump(WidgetTester tester, Widget w, {NslTokens? tokens, TargetPlatform platform = TargetPlatform.windows, double width = 360}) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final t = tokens ?? resolveTokens(kBuiltinDefault, Brightness.light);
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(brightness: t.brightness, platform: platform, extensions: [NslTheme(t)]),
    home: Scaffold(body: SingleChildScrollView(child: Align(alignment: Alignment.topLeft, child: SizedBox(width: width, child: w)))),
  ));
  await tester.pumpAndSettle();
}

String _hexText(WidgetTester tester) => tester.widget<TextField>(find.byType(TextField)).controller!.text;

void main() {
  const teal = Color(0xFF0F766E);

  testWidgets('แสดงรหัสสีเริ่มต้นในช่องและตัวอย่าง', (tester) async {
    await _pump(tester, NslColorPicker(color: teal, onChanged: (_) {}));
    expect(_hexText(tester), '0F766E');
    expect(find.text('#0F766E'), findsOneWidget);
  });

  testWidgets('พิมพ์ hex ถูกต้อง → onChanged ; รับ 3 หลัก, มี #, ตัวเล็ก', (tester) async {
    final got = <Color>[];
    await _pump(tester, NslColorPicker(color: teal, onChanged: got.add));
    await tester.enterText(find.byType(TextField), 'ff0000');
    expect(got.last.toARGB32(), 0xFFFF0000);
    await tester.enterText(find.byType(TextField), '#0f0');
    expect(got.last.toARGB32(), 0xFF00FF00);
    await tester.enterText(find.byType(TextField), '00F');
    expect(got.last.toARGB32(), 0xFF0000FF);
  });

  testWidgets('hex ไม่ถูกต้อง → แสดงข้อความผิด ไม่เรียก onChanged และไม่ทับสิ่งที่พิมพ์', (tester) async {
    final got = <Color>[];
    await _pump(tester, NslColorPicker(color: teal, onChanged: got.add));
    await tester.enterText(find.byType(TextField), 'ff00');
    await tester.pump();
    expect(got, isEmpty);
    expect(find.text(NslColorPickerStrings.th.hexInvalid), findsOneWidget);
    expect(_hexText(tester), 'ff00');
    await tester.enterText(find.byType(TextField), 'ff0000');
    await tester.pump();
    expect(find.text(NslColorPickerStrings.th.hexInvalid), findsNothing);
  });

  testWidgets('สีโปร่ง 8 หลักไม่ถูกรับ', (tester) async {
    final got = <Color>[];
    await _pump(tester, NslColorPicker(color: teal, onChanged: got.add));
    await tester.enterText(find.byType(TextField), 'ff000080');
    expect(got, isEmpty);
  });

  testWidgets('ช่อง hex กรองตัวอักษรที่ไม่ใช่ hex', (tester) async {
    await _pump(tester, NslColorPicker(color: teal, onChanged: (_) {}));
    await tester.enterText(find.byType(TextField), 'xyz12g');
    expect(_hexText(tester), '12');
  });

  testWidgets('แตะสีสำเร็จรูป → เปลี่ยนสีและ hex', (tester) async {
    final got = <Color>[];
    await _pump(tester, NslColorPicker(color: teal, onChanged: got.add, presets: const [teal, Color(0xFFFF0000)]));
    final red = find.bySemanticsLabel('สี #FF0000');
    expect(red, findsOneWidget);
    await tester.tap(red);
    await tester.pump();
    expect(got.last.toARGB32(), 0xFFFF0000);
    expect(_hexText(tester), 'FF0000');
  });

  testWidgets('แตะสีสำเร็จรูปที่เลือกอยู่แล้ว → ไม่เรียก onChanged ซ้ำ', (tester) async {
    final got = <Color>[];
    await _pump(tester, NslColorPicker(color: teal, onChanged: got.add, presets: const [teal]));
    await tester.tap(find.bySemanticsLabel('สี #0F766E'));
    expect(got, isEmpty);
  });

  testWidgets('แตะบนแถบเฉดสี → เปลี่ยน hue', (tester) async {
    final got = <Color>[];
    await _pump(tester, NslColorPicker(color: const Color(0xFFFF0000), onChanged: got.add));
    final r = tester.getRect(find.bySemanticsLabel('เฉดสี'));
    await tester.tapAt(Offset(r.left + r.width / 3, r.center.dy));
    await tester.pump();
    expect(HSVColor.fromColor(got.last).hue, closeTo(120, 3));
  });

  testWidgets('แตะพื้นที่สี → ปรับความสดและความสว่าง', (tester) async {
    final got = <Color>[];
    await _pump(tester, NslColorPicker(color: const Color(0xFFFF0000), onChanged: got.add));
    final r = tester.getRect(find.bySemanticsLabel('ความสดและความสว่าง'));
    await tester.tapAt(Offset(r.left + r.width * 0.5, r.top + r.height * 0.5));
    await tester.pump();
    final h = HSVColor.fromColor(got.last);
    expect(h.saturation, closeTo(0.5, 0.03));
    expect(h.value, closeTo(0.5, 0.03));
  });

  testWidgets('คีย์บอร์ด : ลูกศรปรับความสว่าง', (tester) async {
    final got = <Color>[];
    await _pump(tester, NslColorPicker(color: const Color(0xFF808000), onChanged: got.add));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final before = HSVColor.fromColor(const Color(0xFF808000));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(got, isNotEmpty);
    expect(HSVColor.fromColor(got.last).value, lessThan(before.value));
  });

  testWidgets('semantics : slider เพิ่ม/ลดได้ และบอกค่า', (tester) async {
    final handle = tester.ensureSemantics();
    final got = <Color>[];
    await _pump(tester, NslColorPicker(color: const Color(0xFFFF0000), onChanged: got.add));
    final node = tester.getSemantics(find.bySemanticsLabel('เฉดสี'));
    final data = node.getSemanticsData();
    expect(data.value, '0°');
    expect(data.hasAction(SemanticsAction.increase), isTrue);
    expect(data.hasAction(SemanticsAction.decrease), isTrue);
    tester.semantics.increase(find.semantics.byLabel('เฉดสี'));
    await tester.pump();
    expect(HSVColor.fromColor(got.last).hue, closeTo(5, 1));
    handle.dispose();
  });

  testWidgets('เปลี่ยน color จากภายนอก → ตัวเลือกตาม', (tester) async {
    await _pump(tester, NslColorPicker(color: teal, onChanged: (_) {}));
    await _pump(tester, NslColorPicker(color: const Color(0xFFFF0000), onChanged: (_) {}));
    expect(_hexText(tester), 'FF0000');
  });

  testWidgets('color มี alpha → ถือเป็นสีทึบ', (tester) async {
    await _pump(tester, NslColorPicker(color: const Color(0x800F766E), onChanged: (_) {}));
    expect(_hexText(tester), '0F766E');
  });

  testWidgets('สีเทา/ดำ/ขาว ไม่ล้ม', (tester) async {
    for (final c in const [Color(0xFF000000), Color(0xFFFFFFFF), Color(0xFF808080)]) {
      await _pump(tester, NslColorPicker(color: c, onChanged: (_) {}));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('strings อังกฤษ', (tester) async {
    await _pump(tester, NslColorPicker(color: teal, onChanged: (_) {}, strings: NslColorPickerStrings.en));
    expect(find.text('Hex colour'), findsOneWidget);
    expect(find.bySemanticsLabel('Hue'), findsOneWidget);
  });

  group('ทุกธีม × 2 โหมด : ไม่ overflow และตัวอย่างสีอ่านออก', () {
    for (final e in _themes.entries) {
      for (final b in Brightness.values) {
        testWidgets('${e.key} ${b.name}', (tester) async {
          final t = resolveTokens(e.value, b);
          await _pump(tester, NslColorPicker(color: t.colors.accent, onChanged: (_) {}, presets: [t.colors.accent, t.colors.danger, t.colors.success]), tokens: t, width: 300);
          expect(tester.takeException(), isNull);
          final label = tester.widget<Text>(find.textContaining('#').first);
          final box = tester.widget<Container>(find.ancestor(of: find.textContaining('#').first, matching: find.byType(Container)).first);
          final bg = (box.decoration! as BoxDecoration).color!;
          expect(contrastRatio(label.style!.color!, bg), greaterThanOrEqualTo(4.5));
        });
      }
    }
  });

  testWidgets('จอสัมผัส : swatch และแถบ ≥ 44', (tester) async {
    await _pump(tester, NslColorPicker(color: teal, onChanged: (_) {}, presets: const [teal, Color(0xFFFF0000)]), platform: TargetPlatform.android);
    expect(tester.getSize(find.bySemanticsLabel('สี #FF0000')).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(find.bySemanticsLabel('เฉดสี')).height, greaterThanOrEqualTo(44));
  });
}
