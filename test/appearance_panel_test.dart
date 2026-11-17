import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

/// ตัวห่อที่ทำตัวเหมือนแอป: เก็บค่าไว้แล้วส่งกลับเข้า panel (และบันทึกประวัติการเปลี่ยน)
class _Host extends StatefulWidget {
  const _Host({required this.history, this.initial = NslAppearance.none, this.strings = NslAppearanceStrings.th});
  final List<NslAppearance> history;
  final NslAppearance initial;
  final NslAppearanceStrings strings;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late NslAppearance v = widget.initial;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: NslAppearancePanel(
          value: v,
          strings: widget.strings,
          onChanged: (a) {
            widget.history.add(a);
            setState(() => v = a);
          },
        ),
      );
}

Future<void> _pump(WidgetTester t, List<NslAppearance> h,
    {NslAppearance initial = NslAppearance.none, Brightness b = Brightness.light, double width = 360, NslAppearanceStrings strings = NslAppearanceStrings.th}) async {
  t.view.physicalSize = Size(width, 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    theme: ThemeData(brightness: b, useMaterial3: true),
    home: Scaffold(body: _Host(history: h, initial: initial, strings: strings)),
  ));
}

void main() {
  testWidgets('เลือกโหมด และ preset → onChanged ส่งค่าที่ถูกต้อง (โหมดคงอยู่ตอนเปลี่ยน accent)', (t) async {
    final h = <NslAppearance>[];
    await _pump(t, h);
    await t.tap(find.byKey(const ValueKey('nsl-mode-dark')));
    await t.pump();
    expect(h.last.mode, NslModeChoice.dark);
    await t.tap(find.byKey(const ValueKey('nsl-preset-blue')));
    await t.pump();
    expect(h.last.presetId, 'blue');
    expect(h.last.mode, NslModeChoice.dark);
    expect(h.last.customAccent, isNull);
  });

  testWidgets('สีกำหนดเอง: เปิดตัวแก้ไม่เปลี่ยนสี ; พิมพ์ hex ถูกต้อง → ตั้งสีและล้าง preset ; hex ผิด → แจ้งและไม่ส่งค่า', (t) async {
    final h = <NslAppearance>[];
    await _pump(t, h, initial: const NslAppearance(presetId: 'teal'));
    await t.tap(find.byKey(const ValueKey('nsl-custom')));
    await t.pump();
    expect(h, isEmpty);
    expect(find.byKey(const ValueKey('nsl-hex')), findsOneWidget);

    await t.enterText(find.byKey(const ValueKey('nsl-hex')), '#112233');
    await t.pump();
    expect(h.last.customAccent, const Color(0xFF112233));
    expect(h.last.presetId, isNull);

    final n = h.length;
    await t.enterText(find.byKey(const ValueKey('nsl-hex')), '#12G');
    await t.pump();
    expect(h.length, n);
    expect(find.text(NslAppearanceStrings.th.invalidHex), findsOneWidget);

    await t.enterText(find.byKey(const ValueKey('nsl-hex')), 'AABBCC'); // ไม่ใส่ # ก็รับ
    await t.pump();
    expect(h.last.customAccent, const Color(0xFFAABBCC));
    expect(find.text(NslAppearanceStrings.th.invalidHex), findsNothing);
  });

  testWidgets('ไม่รับสีที่มีความโปร่งใส (#RRGGBBAA) — accent ต้องทึบ', (t) async {
    final h = <NslAppearance>[];
    await _pump(t, h);
    await t.tap(find.byKey(const ValueKey('nsl-custom')));
    await t.pump();
    await t.enterText(find.byKey(const ValueKey('nsl-hex')), '#11223380');
    await t.pump();
    expect(h, isEmpty);
    expect(find.text(NslAppearanceStrings.th.invalidHex), findsOneWidget);
  });

  testWidgets('ลากสไลเดอร์เฉดสี → สีเปลี่ยนและช่อง hex ตามทัน ; ปุ่มคืนค่าล้าง accent คงโหมด', (t) async {
    final h = <NslAppearance>[];
    await _pump(t, h, initial: const NslAppearance(mode: NslModeChoice.light, customAccent: Color(0xFF7B58D6)));
    expect(find.byKey(const ValueKey('nsl-hex')), findsOneWidget); // เปิดตัวแก้ให้เองเมื่อใช้สีกำหนดเองอยู่
    await t.drag(find.byKey(const ValueKey('nsl-hue')), const Offset(120, 0));
    await t.pump();
    expect(h, isNotEmpty);
    final c = h.last.customAccent!;
    expect(c, isNot(const Color(0xFF7B58D6)));
    final field = t.widget<TextField>(find.byKey(const ValueKey('nsl-hex')));
    expect(field.controller!.text.toUpperCase(), '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}');

    await t.tap(find.byKey(const ValueKey('nsl-reset')));
    await t.pump();
    expect(h.last.hasAccent, isFalse);
    expect(h.last.mode, NslModeChoice.light);
    expect(find.byKey(const ValueKey('nsl-reset')), findsNothing); // ไม่มี accent แล้วไม่ต้องมีปุ่ม
  });

  testWidgets('ใช้ได้ทั้งธีมสว่าง/มืด, ภาษาอังกฤษ, จอแคบ 320 พร้อมตัวอักษรใหญ่ — ไม่ overflow และมี label ให้ screen reader', (t) async {
    for (final b in Brightness.values) {
      final h = <NslAppearance>[];
      await _pump(t, h, b: b, width: 320, strings: NslAppearanceStrings.en, initial: const NslAppearance(presetId: 'green'));
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Reset to theme'), findsOneWidget);
      expect(find.bySemanticsLabel('Green'), findsOneWidget);
      expect(t.takeException(), isNull);
    }
    t.view.physicalSize = const Size(320, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: Scaffold(body: _Host(history: [], initial: const NslAppearance(customAccent: Color(0xFF7B58D6)))),
      ),
    ));
    await t.pump();
    expect(t.takeException(), isNull);
  });

  testWidgets('ส่ง preset ของแอปเองเข้าไปแทนชุดเริ่มต้นได้', (t) async {
    t.view.physicalSize = const Size(360, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final h = <NslAppearance>[];
    const mine = [
      NslAccentPreset('amber', 'อำพัน', 'Amber', (Color(0xFFA7680C), Color(0xFFF5EDE0), Color(0xFF724708)), (Color(0xFFF4B860), Color(0xFF40311C), Color(0xFFEECEA0))),
    ];
    await t.pumpWidget(MaterialApp(
      home: Scaffold(body: NslAppearancePanel(value: NslAppearance.none, presets: mine, onChanged: h.add)),
    ));
    expect(find.byKey(const ValueKey('nsl-preset-amber')), findsOneWidget);
    expect(find.byKey(const ValueKey('nsl-preset-blue')), findsNothing);
    await t.tap(find.byKey(const ValueKey('nsl-preset-amber')));
    expect(h.single.presetId, 'amber');
  });
}
