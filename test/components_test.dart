import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsl_ui/nsl_ui.dart';

NslTokens _base(NslThemeSpec s, Brightness b) => resolveTokens(s, b);

NslTokens _with(
  NslTokens t, {
  NslDensity? density,
  NslShape? shape,
  NslType? type,
  NslElevation? elevation,
}) =>
    NslTokens(
      brightness: t.brightness,
      colors: t.colors,
      shape: shape ?? t.shape,
      type: type ?? t.type,
      density: density ?? t.density,
      elevation: elevation ?? t.elevation,
      extensions: t.extensions,
    );

final _themes = <String, NslThemeSpec>{
  'default': kBuiltinDefault,
  'nebular': kBuiltinDev,
  'spectrum': builtinResonance(),
  'lyra.paper': kBuiltinLyraPaper,
};

Future<void> _pump(
  WidgetTester tester,
  Widget w,
  NslTokens tokens, {
  TargetPlatform platform = TargetPlatform.windows,
  double width = 320,
  double systemTextScale = 1.0,
}) async {
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(brightness: tokens.brightness, platform: platform, extensions: [NslTheme(tokens)]),
    builder: (c, child) => MediaQuery(
      data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(systemTextScale)),
      child: child!,
    ),
    home: Scaffold(body: Align(alignment: Alignment.topLeft, child: SizedBox(width: width, child: w))),
  ));
  await tester.pumpAndSettle();
}

Material _materialOf(WidgetTester tester, Finder of) => tester.widget<Material>(find.descendant(of: of, matching: find.byType(Material)).first);

Color _bg(WidgetTester tester, Finder of) => _materialOf(tester, of).color!;

BorderRadius _radius(WidgetTester tester, Finder of) => ((_materialOf(tester, of).shape) as RoundedRectangleBorder).borderRadius as BorderRadius;

void main() {
  final light = _base(kBuiltinDefault, Brightness.light);

  group('NslButton', () {
    testWidgets('กดแล้วเรียก onPressed · ปิดใช้งาน (null) กดไม่ได้', (tester) async {
      var n = 0;
      await _pump(tester, NslButton(label: 'บันทึก', onPressed: () => n++), light);
      await tester.tap(find.byType(NslButton));
      expect(n, 1);
      await _pump(tester, const NslButton(label: 'บันทึก', onPressed: null), light);
      await tester.tap(find.byType(NslButton), warnIfMissed: false);
      expect(n, 1);
    });

    testWidgets('สีมาจาก token ตามชนิด', (tester) async {
      final c = light.colors;
      for (final (k, bg) in [
        (NslButtonKind.primary, c.accent),
        (NslButtonKind.secondary, c.surface),
        (NslButtonKind.danger, c.dangerBg),
        (NslButtonKind.ghost, Colors.transparent),
      ]) {
        await _pump(tester, NslButton(label: 'x', kind: k, onPressed: () {}), light);
        expect(_bg(tester, find.byType(NslButton)), bg, reason: '$k');
      }
    });

    testWidgets('ปิดใช้งาน : พื้นและตัวอักษรเปลี่ยนเป็นสีปิดใช้งาน', (tester) async {
      await _pump(tester, const NslButton(label: 'x', kind: NslButtonKind.primary, onPressed: null), light);
      expect(_bg(tester, find.byType(NslButton)), light.colors.surfaceSunken);
      expect(tester.widget<Text>(find.text('x')).style!.color, light.colors.textFaint);
    });

    testWidgets('มุมโค้งตาม shape.md ของธีม', (tester) async {
      await _pump(tester, NslButton(label: 'x', onPressed: () {}), _with(light, shape: const NslShape(md: 3)));
      expect(_radius(tester, find.byType(NslButton)), BorderRadius.circular(3));
      await _pump(tester, NslButton(label: 'x', onPressed: () {}), _with(light, shape: const NslShape(md: 20)));
      expect(_radius(tester, find.byType(NslButton)), BorderRadius.circular(20));
    });

    testWidgets('ความสูงตาม density · จอสัมผัสไม่ต่ำกว่า 44', (tester) async {
      double h(WidgetTester t) => t.getSize(find.byType(NslButton)).height;
      final hs = <double>[];
      for (final d in NslDensity.values) {
        await _pump(tester, NslButton(label: 'x', onPressed: () {}), _with(light, density: d));
        hs.add(h(tester));
        await _pump(tester, NslButton(label: 'x', onPressed: () {}), _with(light, density: d), platform: TargetPlatform.android);
        expect(h(tester), greaterThanOrEqualTo(kMinTapTarget), reason: 'touch ${d.name}');
      }
      expect(hs[0], lessThan(hs[1]));
      expect(hs[1], lessThan(hs[2]));
    });

    testWidgets('ใช้ฟอนต์และขนาดจากธีม (scale/minSize)', (tester) async {
      await _pump(tester, NslButton(label: 'x', onPressed: () {}), _with(light, type: const NslType(family: 'Foo', scale: 1.2)));
      final s = tester.widget<Text>(find.text('x')).style!;
      expect(s.fontFamily, 'Foo');
      expect(s.fontSize, closeTo(14 * 1.2, 1e-9));
    });

    testWidgets('Semantics: เป็นปุ่ม มีชื่อ และสถานะเปิด/ปิดใช้งาน', (tester) async {
      final h = tester.ensureSemantics();
      await _pump(tester, NslButton(label: 'บันทึก', semanticLabel: 'บันทึกไฟล์', onPressed: () {}), light);
      expect(tester.getSemantics(find.bySemanticsLabel('บันทึกไฟล์')),
          isSemantics(label: 'บันทึกไฟล์', isButton: true, isEnabled: true, hasEnabledState: true, hasTapAction: true, isFocusable: true));
      await _pump(tester, const NslButton(label: 'บันทึก', onPressed: null), light);
      expect(tester.getSemantics(find.bySemanticsLabel('บันทึก')),
          isSemantics(label: 'บันทึก', isButton: true, isEnabled: false, hasEnabledState: true, hasTapAction: false, isFocusable: false));
      h.dispose();
    });

    testWidgets('โฟกัสคีย์บอร์ด (Tab) แสดงวงโฟกัส และ Enter กดได้', (tester) async {
      var n = 0;
      await _pump(tester, NslButton(label: 'x', onPressed: () => n++), light);
      bool ring() => tester
          .widgetList<DecoratedBox>(find.descendant(of: find.byType(NslButton), matching: find.byType(DecoratedBox)))
          .any((d) => d.position == DecorationPosition.foreground && (d.decoration as BoxDecoration).border != null);
      expect(ring(), isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(ring(), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(n, 1);
    });

    testWidgets('expand = เต็มความกว้าง', (tester) async {
      await _pump(tester, NslButton(label: 'x', expand: true, onPressed: () {}), light, width: 300);
      expect(tester.getSize(find.byType(NslButton)).width, 300);
    });
  });

  group('NslIconButton', () {
    testWidgets('กดได้ · ปิดใช้งานกดไม่ได้ · มี tooltip เป็นชื่อ semantics', (tester) async {
      final h = tester.ensureSemantics();
      var n = 0;
      await _pump(tester, NslIconButton(icon: Icons.add, tooltip: 'เพิ่ม', onPressed: () => n++), light);
      await tester.tap(find.byType(NslIconButton));
      expect(n, 1);
      expect(tester.getSemantics(find.bySemanticsLabel('เพิ่ม')), isSemantics(label: 'เพิ่ม', isButton: true, hasTapAction: true));
      expect(find.byTooltip('เพิ่ม'), findsOneWidget);
      await _pump(tester, const NslIconButton(icon: Icons.add, tooltip: 'เพิ่ม', onPressed: null), light);
      await tester.tap(find.byType(NslIconButton), warnIfMissed: false);
      expect(n, 1);
      h.dispose();
    });

    testWidgets('selected : พื้น selected + ไอคอน accentInk', (tester) async {
      await _pump(tester, NslIconButton(icon: Icons.add, tooltip: 't', selected: true, onPressed: () {}), light);
      expect(_bg(tester, find.byType(NslIconButton)), light.colors.selected);
      expect(tester.widget<Icon>(find.byIcon(Icons.add)).color, light.legibleOn(light.colors.accentInk, light.colors.selected));
      await _pump(tester, NslIconButton(icon: Icons.add, tooltip: 't', onPressed: () {}), light);
      expect(_bg(tester, find.byType(NslIconButton)), Colors.transparent);
      expect(tester.widget<Icon>(find.byIcon(Icons.add)).color, light.colors.icon);
    });

    testWidgets('จัตุรัสตาม density และจอสัมผัสไม่เล็กกว่า 44', (tester) async {
      // Align : _pump ให้ความกว้างแบบบังคับ ซึ่งจะยืดปุ่ม — ให้ความกว้างแบบหลวมเพื่อวัดขนาดธรรมชาติ
      Widget loose() => Align(alignment: Alignment.topLeft, child: NslIconButton(icon: Icons.add, tooltip: 't', onPressed: () {}));
      await _pump(tester, loose(), _with(light, density: NslDensity.compact));
      final s = tester.getSize(find.byType(NslIconButton));
      expect(s.width, s.height);
      await _pump(tester, loose(), _with(light, density: NslDensity.compact), platform: TargetPlatform.android);
      expect(tester.getSize(find.byType(NslIconButton)).shortestSide, greaterThanOrEqualTo(kMinTapTarget));
    });
  });

  group('NslPanel', () {
    BoxDecoration deco(WidgetTester t) => t
        .widgetList<Container>(find.descendant(of: find.byType(NslPanel), matching: find.byType(Container)))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .first;

    testWidgets('พื้นตามระดับ · ขอบ borderSoft · มุมโค้ง shape.lg', (tester) async {
      final c = light.colors;
      for (final (tone, bg) in [(NslPanelTone.surface, c.surface), (NslPanelTone.raised, c.surfaceRaised), (NslPanelTone.sunken, c.surfaceSunken)]) {
        await _pump(tester, NslPanel(tone: tone, child: const Text('x')), light);
        final d = deco(tester);
        expect(d.color, bg, reason: '$tone');
        expect((d.border as Border).top.color, c.borderSoft);
        expect(d.borderRadius, BorderRadius.circular(light.shape.lg));
      }
    });

    testWidgets('เงา : เฉพาะ raised เมื่อ elevation=shadow ; flat/strength 0/ระดับอื่น = ไม่มีเงา', (tester) async {
      await _pump(tester, const NslPanel(tone: NslPanelTone.raised, child: Text('x')), light);
      expect(deco(tester).boxShadow, isNotEmpty);
      await _pump(tester, const NslPanel(tone: NslPanelTone.raised, child: Text('x')),
          _with(light, elevation: const NslElevation(mode: NslElevationMode.flat)));
      expect(deco(tester).boxShadow, isNull);
      await _pump(tester, const NslPanel(tone: NslPanelTone.raised, child: Text('x')), _with(light, elevation: const NslElevation(strength: 0)));
      expect(deco(tester).boxShadow, isNull);
      await _pump(tester, const NslPanel(child: Text('x')), light);
      expect(deco(tester).boxShadow, isNull);
    });

    testWidgets('onTap : กดได้ + Semantics ปุ่ม · ไม่มี onTap ไม่ใช่ปุ่ม', (tester) async {
      final h = tester.ensureSemantics();
      var n = 0;
      await _pump(tester, NslPanel(onTap: () => n++, semanticLabel: 'เปิดรายการ', child: const Text('x')), light);
      await tester.tap(find.byType(NslPanel));
      expect(n, 1);
      // ป้ายของแผงรวมกับข้อความข้างใน ("เปิดรายการ\nx") จึงจับด้วย regex
      expect(find.bySemanticsLabel(RegExp('เปิดรายการ')), findsOneWidget);
      expect(tester.getSemantics(find.bySemanticsLabel(RegExp('เปิดรายการ'))), isSemantics(isButton: true, hasTapAction: true));
      await _pump(tester, const NslPanel(child: Text('x')), light);
      expect(find.byType(InkWell), findsNothing);
      h.dispose();
    });

    testWidgets('ระยะในตาม density', (tester) async {
      Future<double> inner(NslDensity d) async {
        await _pump(tester, const NslPanel(child: SizedBox(key: Key('c'), width: 10, height: 10)), _with(light, density: d));
        return tester.getTopLeft(find.byKey(const Key('c'))).dx - tester.getTopLeft(find.byType(NslPanel)).dx;
      }

      final a = await inner(NslDensity.compact), b = await inner(NslDensity.normal), c = await inner(NslDensity.comfortable);
      expect(a, lessThan(b));
      expect(b, lessThan(c));
    });
  });

  group('NslBadge', () {
    testWidgets('สี/ตัวอักษรตามโทน', (tester) async {
      final c = light.colors;
      for (final (tone, bg, fg) in [
        (NslBadgeTone.neutral, c.surface, c.textMuted),
        (NslBadgeTone.success, c.successBg, c.successText),
        (NslBadgeTone.info, c.infoBg, c.infoText),
        (NslBadgeTone.warn, c.warnBg, c.warnText),
        (NslBadgeTone.danger, c.dangerBg, c.dangerText),
        (NslBadgeTone.accent, c.accentTint, light.legibleOn(c.accentInk, c.accentTint)),
      ]) {
        await _pump(tester, NslBadge('สถานะ', tone: tone), light);
        final d = tester.widget<Container>(find.descendant(of: find.byType(NslBadge), matching: find.byType(Container)).first).decoration as BoxDecoration;
        expect(d.color, bg, reason: '$tone');
        expect(tester.widget<Text>(find.text('สถานะ')).style!.color, fg, reason: '$tone');
        expect(d.borderRadius, BorderRadius.circular(light.shape.pill));
      }
    });

    testWidgets('ไอคอนเสริม · ชื่อ semantics เท่าข้อความ', (tester) async {
      final h = tester.ensureSemantics();
      await _pump(tester, const NslBadge('ผิดพลาด', tone: NslBadgeTone.danger, icon: Icons.error), light);
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.bySemanticsLabel('ผิดพลาด'), findsOneWidget);
      h.dispose();
    });
  });

  group('NslProgressBar', () {
    // ความกว้างของส่วนที่เติม = ColoredBox ชั้นในสุด (ชั้นนอก = ราง)
    double fillWidth(WidgetTester t) => t.getSize(find.descendant(of: find.byType(NslProgressBar), matching: find.byType(ColoredBox)).last).width;

    testWidgets('ความกว้างส่วนเติมตามค่า · ตัดค่านอกช่วง · NaN = 0', (tester) async {
      Future<double> w(double v) async {
        await _pump(tester, NslProgressBar(value: v, label: 'p'), light, width: 200);
        return fillWidth(tester);
      }

      expect(await w(0.25), closeTo(50, 1e-6));
      expect(await w(0), 0);
      expect(await w(1), 200);
      expect(await w(1.7), 200);
      expect(await w(-0.3), 0);
      expect(await w(double.nan), 0);
    });

    testWidgets('สีราง/สีเติมตามโทน · ความสูงตาม density · มุมกลม', (tester) async {
      final c = light.colors;
      for (final (tone, fill) in [(NslProgressTone.accent, c.accent), (NslProgressTone.success, c.success), (NslProgressTone.danger, c.danger)]) {
        await _pump(tester, NslProgressBar(value: 0.5, label: 'p', tone: tone), light);
        final boxes = tester.widgetList<ColoredBox>(find.descendant(of: find.byType(NslProgressBar), matching: find.byType(ColoredBox))).toList();
        expect(boxes.first.color, c.border, reason: 'ราง $tone');
        expect(boxes.last.color, fill, reason: 'เติม $tone');
      }
      final hs = <double>[];
      for (final d in NslDensity.values) {
        await _pump(tester, const NslProgressBar(value: 0.5, label: 'p'), _with(light, density: d));
        hs.add(tester.getSize(find.byType(NslProgressBar)).height);
      }
      expect(hs[0], lessThan(hs[1]));
      expect(hs[1], lessThan(hs[2]));
      await _pump(tester, const NslProgressBar(value: 0.5, label: 'p'), light);
      expect(tester.widget<ClipRRect>(find.byType(ClipRRect)).borderRadius, BorderRadius.circular(light.shape.pill));
    });

    testWidgets('Semantics: ชื่อ + ค่าเปอร์เซ็นต์ (ส่วนตกแต่งข้างในไม่ถูกอ่าน)', (tester) async {
      final h = tester.ensureSemantics();
      await _pump(tester, const NslProgressBar(value: 0.256, label: 'ดาวน์โหลด'), light);
      expect(tester.getSemantics(find.bySemanticsLabel('ดาวน์โหลด')), isSemantics(label: 'ดาวน์โหลด', value: '26%'));
      h.dispose();
    });
  });

  group('NslEmptyState', () {
    testWidgets('แสดงไอคอน/หัวข้อ/คำอธิบาย/ปุ่ม และปุ่มกดได้', (tester) async {
      var n = 0;
      await _pump(
        tester,
        NslEmptyState(
          icon: Icons.inbox,
          title: 'ยังไม่มีรายการ',
          message: 'เริ่มจากสร้างรายการแรกของคุณ',
          action: NslButton(label: 'สร้าง', kind: NslButtonKind.primary, onPressed: () => n++),
        ),
        light,
      );
      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('ยังไม่มีรายการ'), findsOneWidget);
      expect(find.text('เริ่มจากสร้างรายการแรกของคุณ'), findsOneWidget);
      await tester.tap(find.byType(NslButton));
      expect(n, 1);
    });

    testWidgets('สีหัวข้อ=text · คำอธิบาย=textMuted · ไอคอน=icon ; ส่วนที่ไม่ระบุไม่แสดง', (tester) async {
      await _pump(tester, const NslEmptyState(title: 'T', message: 'M', icon: Icons.inbox), light);
      expect(tester.widget<Text>(find.text('T')).style!.color, light.colors.text);
      expect(tester.widget<Text>(find.text('M')).style!.color, light.colors.textMuted);
      expect(tester.widget<Icon>(find.byIcon(Icons.inbox)).color, light.colors.icon);
      await _pump(tester, const NslEmptyState(title: 'T'), light);
      expect(find.byType(Icon), findsNothing);
      expect(find.byType(NslButton), findsNothing);
      expect(find.text('M'), findsNothing);
    });

    testWidgets('จัดกึ่งกลาง · ข้อความกว้างไม่เกิน 360 แม้พื้นที่กว้างมาก', (tester) async {
      // หน้าจอทดสอบกว้าง 800 ; ใช้ 700 ให้พอดีหน้าจอ (ถ้าเกินจะถูกบีบ และจุดกึ่งกลางเพี้ยน)
      await _pump(tester, SizedBox(height: 300, child: NslEmptyState(title: 'T' * 200, message: 'M' * 400)), light, width: 700);
      final title = tester.getRect(find.text('T' * 200));
      expect(title.width, lessThanOrEqualTo(360));
      expect(title.center.dx, closeTo(350, 1)); // กึ่งกลางของพื้นที่กว้าง 700
    });

    testWidgets('พื้นที่พอ = เนื้อหากึ่งกลางแนวตั้ง · พื้นที่ไม่พอ = เลื่อนได้ (ไม่ล้น)', (tester) async {
      await _pump(tester, const SizedBox(height: 400, child: NslEmptyState(title: 'T')), light, width: 300);
      final area = tester.getRect(find.byType(NslEmptyState));
      expect(tester.getRect(find.text('T')).center.dy, closeTo(area.center.dy, 1));
      await _pump(tester, SizedBox(height: 80, child: NslEmptyState(icon: Icons.inbox, title: 'T', message: 'M' * 200)), light, width: 150);
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      // เลื่อนลงไปถึงข้อความท้ายสุดได้
      await tester.drag(find.byType(NslEmptyState), const Offset(0, -500));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('ไอคอนเป็นของตกแต่ง : ไม่ถูกอ่านโดยโปรแกรมอ่านหน้าจอ', (tester) async {
      final h = tester.ensureSemantics();
      await _pump(tester, const NslEmptyState(title: 'ว่าง', icon: Icons.inbox), light);
      expect(find.bySemanticsLabel('ว่าง'), findsOneWidget);
      // `find.semantics` ไม่มีตัวหาตามไอคอน → ตรวจว่าไอคอนอยู่ใต้ ExcludeSemantics ของ component เอง
      expect(
        find.descendant(of: find.byType(NslEmptyState), matching: find.ancestor(of: find.byIcon(Icons.inbox), matching: find.byType(ExcludeSemantics))),
        findsOneWidget,
      );
      h.dispose();
    });

    testWidgets('ไม่ overflow : พื้นที่แคบ + ตัวอักษร 1.2 + system 1.5 ทุก density', (tester) async {
      for (final d in NslDensity.values) {
        await _pump(
          tester,
          SizedBox(
            height: 500,
            child: NslEmptyState(
              icon: Icons.inbox,
              title: 'หัวข้อยาวมากสำหรับทดสอบการตัดบรรทัดภาษาไทย',
              message: 'คำอธิบายยาวมากมาก ' * 8,
              action: NslButton(label: 'ปุ่มที่มีข้อความยาวมากเหมือนกัน', onPressed: () {}),
            ),
          ),
          _with(light, density: d, type: const NslType(scale: 1.2)),
          width: 150,
          systemTextScale: 1.5,
        );
        expect(tester.takeException(), isNull, reason: d.name);
      }
    });

    for (final e in _themes.entries) {
      for (final b in Brightness.values) {
        test('contrast ข้อความ ${e.key} ${b.name} ≥ 4.5 บน surface', () {
          final c = _base(e.value, b).colors;
          expect(contrastRatio(c.text, c.surface), greaterThanOrEqualTo(4.5));
          expect(contrastRatio(c.textMuted, c.surface), greaterThanOrEqualTo(4.5));
        });
      }
    }
  });

  group('NslGallery ส่วน Components', () {
    testWidgets('พรีวิวด้วย tokens ที่ส่งเข้ามา ไม่ใช่ธีมของแอปที่ถือ Gallery', (tester) async {
      final dark = _base(kBuiltinDev, Brightness.dark);
      // แอปเป็นธีมสว่าง แต่พรีวิวธีมมืด
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: Brightness.light, extensions: [NslTheme(light)]),
        home: Scaffold(body: NslGallery(tokens: dark)),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('nsl-gallery-components')), findsOneWidget);
      final primary = find.ancestor(of: find.text('Nsl primary'), matching: find.byType(NslButton)).first;
      expect(_bg(tester, primary), dark.colors.accent);
      // ป้ายของ component ต้องไม่ซ้ำข้อความเดิมของ Gallery (adjust_gallery_test จับ 'Primary' และ 'accent' อย่างละ 1)
      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('accent'), findsOneWidget);
    });

    for (final w in [320.0, 600.0]) {
      testWidgets('ไม่ overflow ที่ความกว้าง $w', (tester) async {
        tester.view.physicalSize = Size(w, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MaterialApp(theme: ThemeData(extensions: [NslTheme(light)]), home: Scaffold(body: NslGallery(tokens: light))));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('ทุกธีมในตัว × สว่าง/มืด × density × ขนาดตัวอักษร : ไม่ overflow ที่ความกว้างแคบ', () {
    const longText = 'ข้อความยาวมากสำหรับทดสอบการตัดคำของ component ภาษาไทยและ English ปนกัน';
    for (final e in _themes.entries) {
      for (final b in Brightness.values) {
        testWidgets('${e.key} ${b.name}', (tester) async {
          final base = _base(e.value, b);
          for (final d in NslDensity.values) {
            for (final scale in [0.9, 1.0, 1.2]) {
              final t = _with(base, density: d, type: NslType(scale: scale));
              await _pump(
                tester,
                // เลื่อนได้ : ต้องการจับ overflow ภายในแต่ละ component ไม่ใช่ความสูงรวมของตัวอย่างที่ซ้อนกัน
                SizedBox(height: 400, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final k in NslButtonKind.values) NslButton(label: longText, kind: k, icon: Icons.save, onPressed: () {}),
                  const NslButton(label: longText, onPressed: null),
                  NslButton(label: longText, expand: true, onPressed: () {}),
                  Row(children: [for (final i in [Icons.add, Icons.remove]) NslIconButton(icon: i, tooltip: 't', onPressed: () {})]),
                  const NslPanel(tone: NslPanelTone.raised, child: Text(longText)),
                  for (final tone in NslBadgeTone.values) NslBadge(longText, tone: tone, icon: Icons.info),
                  for (final tone in NslProgressTone.values) NslProgressBar(value: 0.4, label: longText, tone: tone),
                ]))),
                t,
                width: 180,
                systemTextScale: 1.5,
              );
              expect(tester.takeException(), isNull, reason: '${e.key} ${b.name} ${d.name} scale $scale');
            }
          }
        });
      }
    }
  });

  group('contrast ของสีที่ component เรนเดอร์จริง (ทุกธีมในตัว × 2 โหมด) ≥ 4.5', () {
    // อ่านสีจาก widget ที่เรนเดอร์จริง ไม่ใช่คำนวณจาก token — จึงจับได้ถ้า component ใช้คู่สีผิด/ลืมกันสีไม่ผ่าน
    for (final e in _themes.entries) {
      for (final b in Brightness.values) {
        testWidgets('${e.key} ${b.name}', (tester) async {
          final t = _base(e.value, b);
          await _pump(
            tester,
            Column(children: [
              for (final k in NslButtonKind.values) NslButton(key: ValueKey('btn-${k.name}'), label: 'b-${k.name}', kind: k, onPressed: () {}),
              for (final tone in NslBadgeTone.values) NslBadge('g-${tone.name}', tone: tone),
              NslIconButton(key: const ValueKey('icon-selected'), icon: Icons.add, tooltip: 't', selected: true, onPressed: () {}),
            ]),
            t,
          );
          void check(String what, Color fg, Color bg) {
            final back = Color.alphaBlend(bg, t.colors.surface);
            final r = contrastRatio(Color.alphaBlend(fg, back), back);
            expect(r, greaterThanOrEqualTo(4.5), reason: '${e.key} ${b.name} $what: ${r.toStringAsFixed(2)}');
          }

          for (final k in NslButtonKind.values) {
            check('button ${k.name}', tester.widget<Text>(find.text('b-${k.name}')).style!.color!, _bg(tester, find.byKey(ValueKey('btn-${k.name}'))));
          }
          for (final tone in NslBadgeTone.values) {
            final box = tester.widget<Container>(find.ancestor(of: find.text('g-${tone.name}'), matching: find.byType(Container)).first);
            check('badge ${tone.name}', tester.widget<Text>(find.text('g-${tone.name}')).style!.color!, (box.decoration as BoxDecoration).color!);
          }
          check('icon button selected', tester.widget<Icon>(find.byIcon(Icons.add)).color!, _bg(tester, find.byKey(const ValueKey('icon-selected'))));
        });
      }
    }
  });
}
